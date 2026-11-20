# School PDF — Worker entry point (GitHub)

**Start here for all School PDF Google Play / cPanel release tasks.** This repository is **school**, not FOODEX. No new mobile feature scope unless requested and reviewed.

1. Read [the canonical bilingual/Arabic release handoff](docs/SCHOOLPDF_V1_1_3_RELEASE_HANDOFF_AR.md), then [Issue #10](https://github.com/walidatiyaai2025-gif/school/issues/10) and its latest comments.
2. Re-fetch GitHub `main` HEAD, open PRs/issues, CI checks, signed artifacts and live acceptance evidence **every time**. The handoff's SHAs are historical anchors, not a substitute for fresh verification.
3. Respect the user's Laravel **ONE ZIP → WEB SETUP → LIVE SITE → ADMIN ZIP UPDATES** standard. Never overwrite an installed cPanel project with a fresh Setup ZIP, bypass Ed25519 or checksums, ask for production Composer/Artisan/npm commands, or touch production databases to test.
4. Branch/PR narrowly, run tests, merge only when required checks on the exact head pass; post concise PR/commit/CI/artifact evidence to Issue #10.
5. **Owner-owned gates**: signed Play upload keystore and four GitHub Secrets, live dashboard version/backup/update, public site/mail verification, real store screenshots, Organization legal/trader status and compliance declarations. Never fabricate completion or expose secrets.
6. Signed **cPanel Update v1.1.3** is from verified [run #44686475320](https://github.com/walidatiyaai2025-gif/school/actions/runs/44686475320), source `b8c93ce`. The later `d75116e` CI fix does not change that ZIP. The unsigned AAB is **NOT FOR PLAY**.
7. Keep **Issue #10 open** until actual live update and Google Play acceptance are verified; do not treat green CI as proof of deployment. Follow the detailed acceptance checklist in the handoff.
