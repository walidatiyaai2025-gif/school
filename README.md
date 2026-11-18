# School PDF

Flutter Android/iOS student document scanner and Laravel administration backend.

## Repository structure
- `mobile/` — Flutter mobile application, local PDF conversion, image correction, history and sharing
- `backend/` — Laravel dashboard, notification campaigns, device analytics and advertising settings
- `setup/` — cPanel setup tooling and safety checks
- `.github/workflows/` — project CI

## Domain
`https://sclpdf.50sols.com`

## Import status
**Initial repository setup only.** The application source must be imported from the owner's latest local `SchoolPDF` directory, retaining the tested `backend/composer.json` and `backend/composer.lock`. Do not mistake this initial commit for a working release.

## Safety
Do not commit `.env`, database dumps, production keys, Firebase Admin service-account JSON, signing keys, or runtime dependency/build directories. Android/iOS Firebase *client* configuration can be shipped with apps, but API key restrictions and policy checks remain required.

## Release gate
The production `SchoolPDF-Setup` archive remains blocked until verified fresh-install, upgrade, recovery, and exact-head CI evidence are available. No deployment or release is implied by a Git push.

## Documentation
See `README_AR.md`, `mobile/README_AR.md`, and `setup/README_AR.md` once the source import is complete.
