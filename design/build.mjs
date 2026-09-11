// Wraps each screens/<Name>.body.html fragment into a Design Component
// artboard at design/<Name>.dc.html, injecting the shared theme.
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const theme = readFileSync('theme.css', 'utf8');
// Shipping pairing first, then the candidates under review on page 3.
const FONTS = 'https://fonts.googleapis.com/css2'
  + '?family=Instrument+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400'
  + '&family=Newsreader:opsz,wght@6..72,300;6..72,400;6..72,500;6..72,600'
  + '&family=DM+Serif+Display'
  + '&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600;9..40,700'
  + '&family=Playfair+Display:wght@400;500;600;700'
  + '&family=Karla:wght@400;500;600;700'
  + '&family=Cormorant+Garamond:wght@400;500;600;700'
  + '&family=Jost:wght@400;500;600;700'
  + '&family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700'
  + '&family=Public+Sans:wght@400;500;600;700'
  + '&display=swap';

const frags = readdirSync('screens').filter((f) => f.endsWith('.body.html')).sort();
for (const f of frags) {
  const name = f.replace('.body.html', '');
  const body = readFileSync(join('screens', f), 'utf8').trimEnd();
  const out = `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="${FONTS}">
  <style>
${theme.trimEnd()}
  </style>
</helmet>
${body}
</x-dc>
</body>
</html>
`;
  writeFileSync(`${name}.dc.html`, out);
  console.log(`  ${name}.dc.html  (${(out.length / 1024).toFixed(1)} KB)`);
}
console.log(`built ${frags.length} artboards`);
