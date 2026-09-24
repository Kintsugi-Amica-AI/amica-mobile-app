#!/usr/bin/env python3
"""Generate the Fake Call caller voice clips with Gemini TTS.

Run this once on a developer machine. It is not part of the app build. The
clips it writes are bundled as assets, so Fake Call plays them with no
network, no API key in the app, and no per-call cost.

    pip install -r requirements.txt     (only needed if ffmpeg is not on PATH)
    set GEMINI_API_KEY=...          (Windows)   /  export GEMINI_API_KEY=...
    python generate.py                          # all clips, en/si/ta
    python generate.py --langs en --only friend_pickup

Writes:
    assets/audio/fake_call/<lang>/<clip>.m4a
    assets/audio/fake_call/<lang>/filler_<gender>.m4a
    assets/audio/fake_call/manifest.json   (read by FakeCallAudioService)

Each spoken line is cached in .cache/ by its text, voice and style, so editing
one line in scripts.json and re-running only pays for that line.

--offline-test replaces Gemini with beeps so the audio pipeline can be checked
without a key.
"""

from __future__ import annotations

import argparse
import array
import base64
import hashlib
import io
import json
import math
import os
import shutil
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request
import wave
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP_ROOT = HERE.parent.parent
DEFAULT_OUT = APP_ROOT / "assets" / "audio" / "fake_call"
ASSET_PREFIX = "assets/audio/fake_call"
CACHE_DIR = HERE / ".cache"

# Tried in order until one answers. The first uses the current request shape
# (style in speech_metadata); older models fall back to the legacy shape
# (style written into the prompt).
DEFAULT_MODELS = [
    "gemini-3.8-flash-tts",
    "gemini-3.8-flash-lite-tts",
    "gemini-3.1-flash-tts-preview",
    "gemini-2.5-flash-preview-tts",
    "gemini-2.5-pro-preview-tts",
]

SAMPLE_RATE = 16000  # phone-call bandwidth; plenty for a narrowband line
LEAD_IN_SECONDS = 1.8  # the user says "Hello?" first, like a real call
FILLER_LEAD_IN_SECONDS = 3.0


# --------------------------------------------------------------------------
# Setup helpers
# --------------------------------------------------------------------------

def load_env_file() -> None:
    env = HERE / ".env"
    if not env.exists():
        return
    for raw in env.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def find_ffmpeg() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg  # type: ignore

        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        sys.exit(
            "ffmpeg not found. Install it, or run: pip install imageio-ffmpeg"
        )


def run_ffmpeg(ffmpeg: str, args: list[str], stdin: bytes | None = None) -> bytes:
    proc = subprocess.run(
        [ffmpeg, "-hide_banner", "-loglevel", "error", *args],
        input=stdin,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode("utf-8", "replace"))
    return proc.stdout


# --------------------------------------------------------------------------
# Text to speech
# --------------------------------------------------------------------------

def pcm_to_wav(pcm: bytes, rate: int = 24000) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm)
    return buf.getvalue()


class FatalTtsError(RuntimeError):
    """The key or project cannot use Gemini at all; retrying will not help."""


class QuotaExhausted(RuntimeError):
    """Every model is rate limited for longer than --max-wait."""


class _RateLimited(Exception):
    def __init__(self, delay: float):
        super().__init__(f"rate limited for {delay:.0f}s")
        self.delay = delay


class _Unsupported(Exception):
    """This request shape does not work with this model."""


class _ModelGone(Exception):
    """The model does not exist or this key cannot use it."""


class _Transient(Exception):
    """Network blip, 5xx, or a reply without audio: worth another try."""


def wav_seconds(wav: bytes) -> float:
    with wave.open(io.BytesIO(wav)) as w:
        return w.getnframes() / float(w.getframerate())


def speech_seconds(wav: bytes) -> float:
    """Length from the first to the last audible sample (edge silence cut)."""
    with wave.open(io.BytesIO(wav)) as w:
        rate = w.getframerate()
        samples = array.array("h", w.readframes(w.getnframes()))
    if sys.byteorder == "big":
        samples.byteswap()
    loud = [i for i, v in enumerate(samples) if abs(v) > 500]  # about -36 dBFS
    return (loud[-1] - loud[0]) / rate if loud else 0.0


def max_line_seconds(text: str) -> float:
    """Upper bound for a line spoken at a relaxed pace.

    When a model reads the style notes aloud it adds about 10 s to the line,
    far past this bound, while a slow but correct reading stays under it.
    """
    latin = all(ord(ch) < 0x250 for ch in text)
    return 2.5 + len(text) * (0.12 if latin else 0.16)


class GeminiTts:
    """Gemini TTS over the REST API (no SDK, so no SDK-version surprises).

    Models are tried in order. A model that is rate limited is parked until
    its limit resets and the next model is used meanwhile; the run only
    waits when every model is parked.
    """

    ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent"
    SHAPES = ("current", "legacy")
    TRIES_PER_COMBO = 2

    def __init__(self, models: list[str], max_wait: float = 90.0):
        self._max_wait = max_wait
        self._key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
        if not self._key:
            sys.exit(
                "Set GEMINI_API_KEY (or put it in tool/fake_call_audio/.env). "
                "Get one at https://aistudio.google.com/apikey"
            )
        self._models = models
        self._dead: set[str] = set()
        self._bad: set[tuple[str, str]] = set()
        self._cool_until: dict[str, float] = {}
        self._last_used: tuple[str, str] | None = None
        self.warnings: list[str] = []

    # -- one HTTP request -------------------------------------------------

    def _body(self, shape: str, text: str, voice: str, style: str) -> dict:
        if shape == "current":
            # Style travels apart from the words, so it can never be spoken.
            return {
                "contents": [{
                    "role": "user",
                    "parts": [{"text": text, "speechMetadata": {"style": style}}],
                }],
                "generationConfig": {
                    "responseModalities": ["AUDIO"],
                    "speechConfig": {"voiceConfig": {"voice": voice}},
                },
            }
        # Older models take one prompt. The director's-notes layout is the
        # one Google's TTS prompting guide uses to keep notes unspoken.
        prompt = (
            "Read only the TRANSCRIPT aloud. Never read the notes.\n\n"
            f"### DIRECTOR'S NOTES\n{style}\n\n"
            f"### TRANSCRIPT\n{text}"
        )
        return {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}
                },
            },
        }

    def _request(self, model: str, shape: str, text: str, voice: str, style: str) -> bytes:
        request = urllib.request.Request(
            self.ENDPOINT.format(model),
            data=json.dumps(self._body(shape, text, voice, style)).encode("utf-8"),
            headers={"Content-Type": "application/json", "x-goog-api-key": self._key},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            self._raise_for(error)
        except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
            raise _Transient(f"network: {error}") from error

        for part in (payload.get("candidates") or [{}])[0].get("content", {}).get("parts", []):
            inline = part.get("inlineData") or part.get("inline_data")
            if inline and inline.get("data"):
                data = base64.b64decode(inline["data"])
                if data[:4] == b"RIFF":
                    return data
                mime = inline.get("mimeType", "")
                rate = 24000
                if "rate=" in mime:
                    rate = int(mime.split("rate=")[1].split(";")[0])
                return pcm_to_wav(data, rate)
        raise _Transient("reply had no audio")

    @staticmethod
    def _raise_for(error: urllib.error.HTTPError):
        try:
            info = json.loads(error.read().decode("utf-8")).get("error", {})
        except Exception:  # noqa: BLE001
            info = {}
        status = info.get("status", "")
        message = f"{error.code} {status}: {info.get('message', error.reason)}"
        lowered = message.lower()
        if (
            error.code == 401
            or "api_key_invalid" in lowered
            or "api key not valid" in lowered
            or "denied access" in lowered
        ):
            raise FatalTtsError(message)
        if error.code == 429:
            delay = 30.0
            for detail in info.get("details", []):
                retry = str(detail.get("retryDelay", ""))
                if retry.endswith("s"):
                    try:
                        delay = float(retry[:-1])
                    except ValueError:
                        pass
            raise _RateLimited(max(delay, 5.0))
        if error.code in (403, 404):
            raise _ModelGone(message)
        if error.code == 400:
            raise _Unsupported(message)
        raise _Transient(message)

    # -- one line, across models -----------------------------------------

    def synthesize(self, text: str, voice: str, style: str) -> bytes:
        limit = max_line_seconds(text)
        tries: dict[tuple[str, str], int] = {}
        best: tuple[float, bytes, str] | None = None
        last_error = "no model available"

        while True:
            options = [
                (model, shape)
                for model in self._models
                if model not in self._dead
                for shape in self.SHAPES
                if (model, shape) not in self._bad
                and tries.get((model, shape), 0) < self.TRIES_PER_COMBO
            ]
            if not options:
                break
            now = time.monotonic()
            ready = [o for o in options if self._cool_until.get(o[0], 0) <= now]
            if not ready:
                wait = min(self._cool_until[o[0]] for o in options) - now
                if wait > self._max_wait:
                    raise QuotaExhausted(
                        f"every model is rate limited for at least {wait / 60:.0f} more min"
                    )
                print(f"  every model is rate limited, waiting {wait:.0f}s")
                time.sleep(max(wait, 1.0))
                continue

            model, shape = ready[0]
            combo = f"{model}/{shape}"
            try:
                wav = self._request(model, shape, text, voice, style)
            except _RateLimited as error:
                self._cool_until[model] = time.monotonic() + error.delay
                print(f"  {model} rate limited for {error.delay:.0f}s, switching model")
                continue
            except _Unsupported as error:
                self._bad.add((model, shape))
                last_error = str(error)
                print(f"  {combo} not usable: {last_error[:140]}")
                continue
            except _ModelGone as error:
                self._dead.add(model)
                last_error = str(error)
                print(f"  {model} not available: {last_error[:140]}")
                continue
            except _Transient as error:
                tries[(model, shape)] = tries.get((model, shape), 0) + 1
                last_error = str(error)
                print(f"  {combo}: {last_error[:140]}; retrying")
                time.sleep(2)
                continue

            seconds = speech_seconds(wav)
            if seconds > limit:
                tries[(model, shape)] = tries.get((model, shape), 0) + 1
                last_error = (
                    f"{seconds:.1f}s of speech, expected under {limit:.1f}s "
                    "(style notes probably read aloud)"
                )
                print(f"  {combo}: {last_error}")
                if best is None or seconds < best[0]:
                    best = (seconds, wav, combo)
                continue

            if self._last_used != (model, shape):
                print(f"  using {combo}")
                self._last_used = (model, shape)
            return wav

        # Nothing passed the length check. A take only a little over the bound
        # is a slow reading, not leaked notes: keep it, but flag it.
        if best is not None and best[0] <= limit * 1.4:
            note = f"{text!r} ({best[2]}, {best[0]:.1f}s) - listen to check"
            print(f"  WARNING: kept a long take: {note}")
            self.warnings.append(note)
            return best[1]
        raise RuntimeError(f"no usable audio for {text!r}: {last_error}")


class BeepTts:
    """Stand-in for --offline-test: one beep per word, 24 kHz WAV."""

    def synthesize(self, text: str, voice: str, style: str) -> bytes:
        rate = 24000
        freq = 220 + (sum(map(ord, voice)) % 200)
        frames = bytearray()
        for _ in range(max(1, len(text.split()))):
            for i in range(int(rate * 0.22)):
                frames += struct.pack("<h", int(8000 * math.sin(2 * math.pi * freq * i / rate)))
            frames += b"\x00\x00" * int(rate * 0.08)
        return pcm_to_wav(bytes(frames), rate)


def line_cache_path(model_tag: str, text: str, voice: str, style: str) -> Path:
    # v2: lines cached before the read-the-notes-aloud fix are ignored.
    key = hashlib.sha1(f"v2|{model_tag}|{voice}|{style}|{text}".encode("utf-8")).hexdigest()
    return CACHE_DIR / f"{key}.wav"


def clip_is_done(out: Path, lines, voice: str, style: str, model_tag: str) -> bool:
    """True when the clip exists and was built from the current script.

    Every line must still be in the cache: if a line in scripts.json was
    edited, its cache entry is missing and the clip is rebuilt.
    """
    return out.exists() and all(
        line_cache_path(model_tag, text, voice, style).exists() for text, _ in lines
    )


def cached_line(tts, model_tag: str, text: str, voice: str, style: str) -> bytes:
    path = line_cache_path(model_tag, text, voice, style)
    if path.exists():
        return path.read_bytes()
    print(f"  tts [{voice}] {text}")
    wav = tts.synthesize(text, voice, style)
    CACHE_DIR.mkdir(exist_ok=True)
    path.write_bytes(wav)
    return wav


# --------------------------------------------------------------------------
# Audio assembly
# --------------------------------------------------------------------------

def to_pcm16k(ffmpeg: str, wav: bytes) -> bytes:
    """Decode, trim edge silence, and resample one line to 16 kHz mono PCM."""
    trim = (
        "silenceremove=start_periods=1:start_threshold=-45dB,"
        "areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse"
    )
    return run_ffmpeg(
        ffmpeg,
        ["-i", "pipe:0", "-af", trim, "-ac", "1", "-ar", str(SAMPLE_RATE),
         "-f", "s16le", "pipe:1"],
        stdin=wav,
    )


def silence(seconds: float) -> bytes:
    return b"\x00\x00" * int(SAMPLE_RATE * seconds)


def render_clip(ffmpeg: str, pcm: bytes, out_path: Path) -> int:
    """Phone-line treatment + faint line hiss, encoded as AAC. Returns ms."""
    duration = len(pcm) / 2 / SAMPLE_RATE
    filters = (
        "[0:a]highpass=f=300,lowpass=f=3400,"
        "acompressor=threshold=-20dB:ratio=3:attack=5:release=80,"
        "loudnorm=I=-18:TP=-2:LRA=11,aresample=16000[v];"
        f"anoisesrc=d={duration:.2f}:c=pink:r=16000:a=0.0025,"
        "highpass=f=300,lowpass=f=3400[n];"
        "[v][n]amix=inputs=2:duration=first:normalize=0[out]"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    run_ffmpeg(
        ffmpeg,
        ["-y", "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "pipe:0",
         "-filter_complex", filters, "-map", "[out]",
         "-c:a", "aac", "-b:a", "32k", "-ar", "16000", "-ac", "1",
         "-movflags", "+faststart", str(out_path)],
        stdin=pcm,
    )
    return int(duration * 1000)


def build(tts, model_tag, ffmpeg, lines, voice, style, lead_in, out_path) -> int:
    pcm = bytearray(silence(lead_in))
    for text, pause in lines:
        pcm += to_pcm16k(ffmpeg, cached_line(tts, model_tag, text, voice, style))
        pcm += silence(float(pause))
    return render_clip(ffmpeg, bytes(pcm), out_path)


# --------------------------------------------------------------------------
# Manifest
# --------------------------------------------------------------------------

def write_manifest(scripts: dict, out_dir: Path) -> dict:
    """List every clip that exists on disk, whichever run produced it."""
    clips, fillers = [], []
    langs = sorted({lang for c in scripts["clips"].values() for lang in c["lines"]})
    for lang in langs:
        for clip_id, clip in scripts["clips"].items():
            path = out_dir / lang / f"{clip_id}.m4a"
            if not path.exists() or lang not in clip["lines"]:
                continue
            role = scripts["roles"][clip["role"]]
            clips.append({
                "id": clip_id,
                "language": lang,
                "role": clip["role"],
                "gender": role["gender"],
                "asset": f"{ASSET_PREFIX}/{lang}/{clip_id}.m4a",
                "transcript": " ".join(text for text, _ in clip["lines"][lang]),
            })
        for gender in ("female", "male"):
            path = out_dir / lang / f"filler_{gender}.m4a"
            if not path.exists():
                continue
            fillers.append({
                "language": lang,
                "gender": gender,
                "asset": f"{ASSET_PREFIX}/{lang}/filler_{gender}.m4a",
                "transcript": " ".join(t for t, _ in scripts["fillers"]["lines"].get(lang, [])),
            })
    manifest = {"version": 1, "clips": clips, "fillers": fillers}
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return manifest


# --------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--langs", nargs="+", default=["en", "si", "ta"])
    parser.add_argument("--only", nargs="+", help="clip ids to (re)build")
    parser.add_argument("--no-fillers", action="store_true")
    parser.add_argument("--model", action="append",
                        help="TTS model id to try (repeatable). Default: "
                             + ", ".join(DEFAULT_MODELS))
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--rebuild", action="store_true",
                        help="rebuild clips that are already finished "
                             "(cached lines are still reused)")
    parser.add_argument("--max-wait", type=float, default=90,
                        help="seconds to wait when every model is rate limited "
                             "before stopping for later (default 90)")
    parser.add_argument("--offline-test", action="store_true",
                        help="use beeps instead of Gemini (pipeline check)")
    args = parser.parse_args()

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")  # Sinhala/Tamil on a cp1252 console
    if args.offline_test and args.out == DEFAULT_OUT:
        args.out = HERE / ".offline_test"  # never overwrite the real clips with beeps

    load_env_file()
    ffmpeg = find_ffmpeg()
    scripts = json.loads((HERE / "scripts.json").read_text(encoding="utf-8"))

    if args.offline_test:
        tts, model_tag = BeepTts(), "offline-test"
    else:
        models = args.model or DEFAULT_MODELS
        tts, model_tag = GeminiTts(models, args.max_wait), "gemini"

    failed: list[str] = []
    stop_message = ""
    try:
        failed = generate_all(args, scripts, tts, model_tag, ffmpeg)
    except QuotaExhausted as error:
        stop_message = (
            f"\nStopped: {error}.\n"
            "Everything finished so far is saved and listed in the manifest.\n"
            "Run the same command again once the quota resets; finished clips "
            "are skipped and only the missing ones are generated."
        )
    except KeyboardInterrupt:
        stop_message = (
            "\nStopped by you. Finished clips are saved; run again to continue."
        )
    except FatalTtsError as error:
        stop_message = (
            "\nGemini refused this API key's project, so nothing more can be "
            "generated with it:\n  " + str(error)[:300] + "\n\n"
            "This is an account problem, not a script problem. Finished clips "
            "are saved and listed in the manifest.\n"
            "Fix: open https://aistudio.google.com, check the project's status "
            "and billing, or create a key in a new project, then run this again."
        )

    # Every clip file on disk is complete (a failed build removes its file),
    # so the manifest is always safe to write, even after a stop.
    manifest = write_manifest(scripts, args.out)
    print(f"manifest: {len(manifest['clips'])} clips, {len(manifest['fillers'])} fillers")
    if stop_message:
        sys.exit(stop_message)
    for note in getattr(tts, "warnings", []):
        print(f"check: {note}")
    if failed:
        print("not built (run again to retry; finished lines are cached):")
        for name in failed:
            print(f"  {name}")
        sys.exit(1)


def generate_all(args, scripts, tts, model_tag, ffmpeg) -> list[str]:
    """Builds every requested clip. Returns the ones that failed.

    A clip that fails is skipped (and any older copy removed, so the
    manifest never lists stale audio); the rest of the run carries on.
    Only an account-level refusal (FatalTtsError) stops the run.
    """
    failed: list[str] = []

    def attempt(name: str, out: Path, lines, voice: str, style: str, lead_in: float):
        if not args.rebuild and clip_is_done(out, lines, voice, style, model_tag):
            print(f"[{name}] already built, skipping")
            return
        print(f"[{name}]")
        try:
            ms = build(tts, model_tag, ffmpeg, lines, voice, style, lead_in, out)
        except (FatalTtsError, QuotaExhausted, KeyboardInterrupt):
            # Stopping mid-clip: drop the half-built file so it is redone.
            if out.exists():
                out.unlink()
            raise
        except Exception as error:  # noqa: BLE001
            print(f"  SKIPPED: {error}")
            failed.append(name)
            if out.exists():
                out.unlink()
            return
        shown = out.relative_to(APP_ROOT) if out.is_relative_to(APP_ROOT) else out
        print(f"  -> {shown} ({ms / 1000:.1f}s)")

    for lang in args.langs:
        lang_style = scripts["styles"].get(lang, "")
        for clip_id, clip in scripts["clips"].items():
            if args.only and clip_id not in args.only:
                continue
            lines = clip["lines"].get(lang)
            if not lines:
                continue
            role = scripts["roles"][clip["role"]]
            attempt(f"{lang}/{clip_id}", args.out / lang / f"{clip_id}.m4a", lines,
                    role["voice"], lang_style + role["style"], LEAD_IN_SECONDS)

        if args.no_fillers or args.only:
            continue
        filler_lines = scripts["fillers"]["lines"].get(lang)
        if not filler_lines:
            continue
        for gender in ("female", "male"):
            role = scripts["roles"][scripts["fillers"][gender]["role"]]
            attempt(f"{lang}/filler_{gender}", args.out / lang / f"filler_{gender}.m4a",
                    filler_lines, role["voice"],
                    lang_style + role["style"] + " Short, quiet listening noises.",
                    FILLER_LEAD_IN_SECONDS)
    return failed

if __name__ == "__main__":
    main()
