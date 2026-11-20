# School PDF v1.1.4 — Families-safe AdMob release (2026-11-20)

- Android signed AAB 1.1.4+4 (package com.fiftysols.schoolpdf, target SDK 36), AdMob SDK enabled with one clearly labelled Banner on Home and Files.
- Neutral age screen: child, teen, adult; child/teen/unknown always CHILD age treatment, G-rated and non-personalized requests. No AD_ID permission and no third-party mediation adapters.
- Google UMP consent on appropriate audiences with a privacy-options setting. Advertising never blocks offline PDF functions.
- Existing AdMob App ID, Standard Banner Unit ID and edited app-ads.txt are preserved.
- Super Admin → Ads now provides explicit Families policy review/approval, AdMob-only activation, immediate off switch and host emergency stop. Ads are not remotely enabled before real approval.
- Additive ad_approvals migration; migrations, credentials, .env, DB, uploaded files and live Ads seller file remain safe.
- Setup ZIP and digitally signed Update ZIP from supported 1.1.3, from same exact tested source SHA, must pass MariaDB fresh install and upgrade, backup/rollback tests.
- **Before live ads:** Owner must finish AdMob Privacy & messaging (UMP), self-certified SDK and mediation source review, Google Play Families/Ads/Data Safety declarations, real-device child/adult testing, and activate approved AdMob banner on Dashboard. No claimed Play acceptance until verified.
