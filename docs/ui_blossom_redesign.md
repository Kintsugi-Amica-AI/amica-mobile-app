# UI refresh — "Blossom" (light default + dark)

Replaces the flat "Warm Dawn" look with a softer pastel style drawn from three
reference designs (MEHRAX fashion app, SafeHer women-safety case study, LUCID
dream-insights app): airy gradient grounds, rounded 24px cards, pill buttons,
soft tinted shadows, circular icon chips and a floating pill nav bar.

## Palette (token → role)

| Token | Light | Dark | Role |
|---|---|---|---|
| `ivory` | `#FFF8FB` | `#140F1C` | ground (under the gradient washes) |
| `card` | `#FFFFFF` | `#211A2D` | raised surface |
| `plum` / `plum70` / `plum45` | `#2B1B3A` / `#5E4C6E` / `#756385` | `#F5EEF8` / `#C7B8D2` / `#9D8DAB` | text |
| `accent` → `accentEnd` | `#7C4DEB` → `#B84A9C` | same | brand gradient, primary actions |
| `accentInk` / `accentSoft` | `#6D3FC9` / `#F0E9FF` | `#C3AEFF` / `#2A2140` | brand text / tinted chips |
| `terracotta` | `#D93360` | `#D93360` | **emergency only** (SOS) |
| `sage` / `gold` / `sky` | green / amber on peach / blue | lighter variants | safe / warning / info |

All text tokens are ≥ 4.5:1 on the surfaces they are used on.
Rose-red is still reserved for emergency; the brand gradient is lavender → orchid so it never reads as SOS.

## Theme switching

* Default is **Light**. `AmicaThemeController` now persists the choice
  (`shared_preferences`, key `amica_theme_mode`) and is loaded in `main()`.
* **Profile → How Amica behaves → Appearance** and **Settings → Appearance**
  show a Light · Dark · System pill selector (`ThemeModeSelector`).
* The moon button on Home still toggles Dark (discreet mode) in one tap.

## How the gradient ground works

`AppTheme` sets `scaffoldBackgroundColor: Colors.transparent` and wraps every
page route in `AmicaBackground` through a custom `PageTransitionsBuilder`, so
every screen (including ones pushed with a bare `MaterialPageRoute`) gets the
ground without per-screen changes. Nested `AmicaBackground`s paint nothing.

## Glass (added in the second pass)

* Tokens `glassFill` / `glassBorder` / `glassHighlight` (+ `glassGradient`).
* `AmicaCard` / `GlassCard` are frosted: a translucent fill with a sheen and a bright rim. They skip real blur,
  because over the smooth pastel ground it would look the same and cost a blur pass per card.
* `AmicaGlass` is real `BackdropFilter` glass. It is used where busy content sits behind: the journey sheets
  and the map buttons. `strong: true` raises the fill so text keeps full contrast over the map.
* The bottom nav pill is frosted.

## Map (`AmicaMapView`)

* The basemap follows the theme: a pastel day style and a dark aubergine night style.
* Markers are drawn on a canvas at runtime: a "you" dot with a halo, and a gradient teardrop pin with a heart.
* The route is drawn in the accent colour over a white casing.
* Google's zoom and my-location buttons are replaced by frosted buttons: recentre, show whole route, zoom in and zoom out.

## Profile

* Tapping **Edit** (or the identity card) opens a sheet that edits name, phone and medical notes
  (`UserProfileService.updateProfile`; notes are stored in `safetySettings.medicalNotes`).
* Each **Add** in "Your safety setup" goes straight to the fix: add a guardian, open Settings for the voice phrase,
  or open the edit sheet for the phone number or medical notes.

## Bus & train trips (third pass)

* Backend `getTransitPlan` (in `amica-cloud-backend/functions/src/services/transitService.ts`):
  * It first tries the Routes API with `TRANSIT` to get real lines and stops.
  * If that returns nothing, it finds the nearest bus stops or stations to both ends with Places Nearby Search,
    then composes walk → ride → walk.
  * It returns the get-on and get-off stops, the other nearby stops the rider can pick, and the legs.
* The same `GOOGLE_DIRECTIONS_API_KEY` needs **Routes API** and **Places API (New)** enabled.
* Journeys (bus or train):
  * A "Your bus trip" timeline shows the walks and stops, with chips to pick another stop. Tapping a stop on the map also picks it.
  * The plan is saved on the journey as `transitPlan` and shown on the live timer.
* Stop alert:
  * It uses the same map and frosted-sheet layout as the Journeys screens, with a Bus / Train switch.
  * The rider enters where she is going. The alarm targets the suggested **get-off stop**, and the typed place is
    saved as `metadata.finalDestination`.
* Home's "Walk with me" tile now opens the Journeys tab instead of a duplicate screen.
* The fake incoming-call and in-call screens deliberately still look like the phone's own call UI. A branded
  pastel call screen would give the deterrent away.
