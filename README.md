# TindaScan

**A Smart Inventory and Sales Management System with Barcode Scanning for Small Sari-Sari Stores.**

Flutter (Android-first) + Firebase Authentication + Cloud Firestore. It runs on
the free Spark plan: no Cloud Functions, no custom claims.

## Features

| Area | Owner | Staff |
|---|---|---|
| **Sell / checkout**: continuous barcode scanning, name search, cart with stock limits, cash payment with change, atomic stock update, shareable receipt | ✅ | ✅ |
| **Products**: search (any word or barcode), category and low-stock filters, add/edit with barcode scan, items without barcodes, archive/restore | ✅ full | 👁 read-only lookup |
| **Stock**: restock, damaged/spoiled, count correction, per-product history | ✅ | — |
| **Alerts**: low stock (badge and daily notification), expiring within 7 days, negative stock after offline sales, suggested restock list | ✅ | — |
| **Dashboard**: today's sales, transactions and profit; 7/30-day trend; top 5 best-sellers; lowest stock | ✅ | — |
| **Reports**: sales (daily/weekly/monthly), best-sellers, inventory, stock movements; Excel export | ✅ | — |
| **Staff accounts** and **Settings** (store name, default alert level, language, sample data) | ✅ | — |
| Profile, sign out, English/Filipino, offline banner | ✅ | ✅ |

## Design system

Minimal, calm and fast: one green-teal accent, warm off-white background,
white cards with thin outlines instead of shadows, and large tap targets.

- **Tokens** live in `lib/core/theme/`: `Gaps` (4/8 grid), `AppRadii` (12/16/24), `AppMotion` (150/250/400 ms with ease-out curves), `Breakpoints`, and the `AppTokens` theme extension for status colors (success, warning, danger), card outline and receipt paper. Widgets read them through `context.tokens` and `context.motion` and never hardcode colors or durations.
- **Themes:** light and dark from one seed color, plus System mode, switchable in Settings. Typography is Plus Jakarta Sans with two weights; every price and quantity uses tabular figures.
- **Motion** respects the accessibility setting: when animations are turned off, `context.motion` returns zero durations and all entrances, count-ups and the scan line become static. Entrances are staggered for at most 10 list items.
- **Navigation adapts:** a bottom bar on phones, a navigation rail on tablets (extended on wide screens), and Products as list + detail on tablets. Owners get Dashboard · Sell · Products · More; staff get Sell · Products · Profile.
- **Components** (`lib/core/widgets/`): AppCard, StatCard, StockPill, PrimaryButton/SecondaryButton, AppTextField, QuantityStepper, AnimatedCounter, EmptyState/ErrorState, SectionHeader, SkeletonList, `showAppBottomSheet`, `showAppSnackBar`, ConfirmDialog, OfflineBanner, SuccessCheck. Debug builds have a **Design gallery** under Settings showing them in light and dark.
- **Feedback:** haptics on scan, add to cart, sale and errors, plus an optional scan sound; both can be toggled in Settings. Reversible actions (remove from cart, clear cart, archive product) show **Undo** instead of a confirm dialog.

## Architecture

```
lib/
  main.dart, app.dart, bootstrap.dart
  core/       config (env), constants, errors, l10n, router, theme, utils, widgets
  features/
    auth/       sign-in, owner setup, staff accounts, session + role guards
    products/   catalog CRUD, search, barcode uniqueness
    scanner/    reusable BarcodeScannerView, scan screen, lookup
    sales/      cart, payment, atomic checkout, receipt
    stock/      adjustments, movement history, restock list
    alerts/     low-stock / expiry / negative-stock, notifications
    dashboard/  daily_stats aggregation + fl_chart charts
    reports/    report screens + .xlsx export (in an isolate)
    settings/   store settings, language, sample data
    home/       role-filtered menu
    (each feature: data / domain / application / presentation)
  shared/     models · repository interfaces · providers (DI)
firebase/     firestore.rules · firestore.indexes.json · rules-tests/
```

The code is layered: **widgets → Riverpod notifiers → repository interfaces →
Firebase implementations**. The UI never touches Firestore directly. Tests swap
the repository providers for mocks or `fake_cloud_firestore`.

Key decisions:

| Decision | Why |
|---|---|
| Role stored in `users/{uid}` instead of custom claims | Custom claims need the Admin SDK (Cloud Functions, Blaze plan). The rules read the role with `get()`. |
| Staff accounts are created on a **secondary FirebaseApp** | Creating a user signs that user in, so a second app instance keeps the owner signed in. |
| Owner setup is a single **batched write** (profile + store + `settings/setup`) | The rules use `existsAfter()` to allow it only once, even if two devices race. |
| Money is stored as integer **centavos** | Exact arithmetic. Only `Money.format` turns it into `₱` text. |
| "Today" means **Asia/Manila** (fixed UTC+8) | Day boundaries don't depend on the phone's time zone. |
| Firebase config is passed with `--dart-define-from-file` | Dev and prod projects stay separate, and nothing project-specific gets committed. |
| Checkout is one **Firestore transaction** | It re-reads stock, aborts if anything changed, then writes the sale, stock decrements, movements, receipt counter and daily stats together, so there are no partial writes. The sale id doubles as an idempotency key, so a retry never charges twice. |
| **`daily_stats/{yyyyMMdd}`** aggregates | Updated with `FieldValue.increment` inside each sale, so dashboards read 7–30 small documents instead of every sale. |
| `barcodes/{code}` claim documents | Make barcodes unique, checked inside the same transaction that creates the product. |
| Word-prefix `keywords` on products | Firestore has no "contains" search. Typing "pancit" finds "Lucky Me Pancit Canton" with one indexed `array-contains` query. |

### Offline trade-off

Firestore persistence keeps the catalog and cart usable offline. Transactions,
however, need the server. When offline (or when a transaction fails with a
network error), checkout falls back to a **batched write with
`FieldValue.increment(-qty)`**. It is applied to the local cache immediately and
synced later, and its receipt number looks like `20261119-XABC123`.

**Risk:** two offline phones can sell the same last item, so stock can go
**negative** after sync. The owner sees these under **Alerts → Negative** with
instructions to recount. If the server rejects an offline sale when it syncs
(for example, the product was archived in the meantime), that sale is dropped
and logged.

## Prerequisites

- Flutter 3.35+ (Dart 3.9+). Upgrading to the latest stable is recommended; after `flutter upgrade` you can remove the `dependency_overrides: meta` block in `pubspec.yaml`.
- Android Studio with an Android SDK (API 23+ device or emulator)
- Node.js 20+ and **Java 11+** (Java is needed for the Firebase Emulator Suite)
- Firebase CLI: `npm i -g firebase-tools`

> **OneDrive note:** OneDrive marks synced folders read-only, which makes
> `flutter gen-l10n`, `flutter test` and Gradle fail with "doesn't allow
> reading and writing". Move the project outside OneDrive (recommended), or run
> `attrib -r /s /d .\*` in the project folder.

## Setup

### 1. Firebase projects (dev and prod)

1. In the [Firebase console](https://console.firebase.google.com), create two projects, `tindascan-dev` and `tindascan-prod`.
2. In each one, enable **Authentication → Email/Password** and create a **Cloud Firestore** database (choose a region near PH, such as `asia-southeast1`).
3. Add an **Android app** with package name `com.tindascan.app`.
4. Copy `env/dev.example.json` to `env/dev.json` (and `prod.example.json` to `prod.json`), then fill in the values from *Project settings → Your apps*. You can also run `flutterfire configure` once and copy the values out of the generated file. Both `env/*.json` files are git-ignored.

### 2. App Check (Play Integrity)

1. Firebase console → **App Check** → register the Android app with **Play Integrity**. This needs the app's SHA-256, from `cd android && ./gradlew signingReport`.
2. Debug builds use the **debug provider**. Run the app once, copy the debug token from logcat (`DebugAppCheckProvider`), and add it under *App Check → Manage debug tokens*.
3. After testing, turn on **enforcement** for Cloud Firestore and Authentication.

### 3. Deploy rules and indexes

```powershell
firebase login
firebase use --add   # pick tindascan-dev, alias "dev"
firebase deploy --only firestore:rules,firestore:indexes
```

### 4. Run

```powershell
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

### 5. Add sample products (optional)

In a **debug** build, sign in as the owner and open **Settings → Add 20 sample
products**. It inserts 20 common sari-sari items with realistic PH (480-prefix)
EAN-13 barcodes, stock levels, a few low-stock items and a few expiry dates.
Running it again skips barcodes that already exist.

### 6. Create the first Owner account

When the app starts for the first time, it finds that `settings/setup` is
missing and opens **Set up your store**. Enter the store name, your name, email
and password (8+ characters). That account becomes the **Owner**. The flow
can't be repeated: the rules reject a second setup. Staff accounts are then
created by the owner under **Staff accounts → Add staff**.

## Local emulators (no cloud project needed)

```powershell
firebase emulators:start --only auth,firestore --project demo-tindascan
flutter run --dart-define-from-file=env/emulator.json
```

`env/emulator.json` points at `10.0.2.2`, which is the host machine as seen
from the Android emulator. On a physical phone, set `FIREBASE_EMULATOR_HOST` to
your PC's LAN IP. App Check is skipped in emulator mode.

## Tests

```powershell
flutter analyze
```
```powershell
flutter test --coverage
```

There are about 190 tests: unit tests (money, Manila time, cart, change, stock rules,
receipt numbers, aggregation, restock, Excel), repository tests on
`fake_cloud_firestore` (including atomic checkout, idempotent retry and no
partial writes), notifier tests with mocktail, and widget tests. The widget
tests cover login, the product form, a full sale through the real screens, and
every owner screen at 1.5× text size. Design tests check WCAG AA contrast
for every color pair in both themes and verify that motion turns off when
animations are disabled. Golden images of StatCard, StockPill and the Sell
screen in light and dark are in `test/golden/goldens/`. Regenerate them after
intentional design changes:

```powershell
flutter test --update-goldens --tags golden
```

Logic-layer coverage is about 86%.

Integration test (needs a device or emulator; runs on an in-memory Firestore):

```powershell
flutter test integration_test/sale_flow_test.dart
```

CI (`.github/workflows/ci.yml`) runs the format check, analyze and tests, plus
the rules tests on the emulator.

Security-rules tests (owner vs staff vs deactivated vs unauthenticated) run
against the Firestore emulator and need Java:

```powershell
cd firebase/rules-tests
npm install
npm run test:emulator
```

## Android release

- `minSdk` is 23 (Firebase Auth / ML Kit). Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `CAMERA`, `POST_NOTIFICATIONS`, `VIBRATE`.
- **Signing:** create a keystore (`keytool -genkey -v -keystore tindascan.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tindascan`), then add `android/key.properties`:
  ```
  storePassword=...
  keyPassword=...
  keyAlias=tindascan
  storeFile=C:/path/to/tindascan.jks
  ```
  Both files are git-ignored. Never commit them.
- **R8** shrinking is on for release. Keep rules are in `android/app/proguard-rules.pro`. If a release build crashes where debug doesn't, check `build/app/outputs/mapping/release/` and add keep rules.
- Build: `flutter build appbundle --release --dart-define-from-file=env/prod.json`

## Manual QA checklist

Run on a real Android phone with `env/dev.json`.

- [ ] First launch shows **Set up your store**. Creating the owner signs in, and a second setup attempt from another phone fails.
- [ ] Owner creates a staff account and stays signed in. Staff can sign in on another phone.
- [ ] Staff home shows only Sell, Products and My profile. Opening `/reports` by deep link bounces to home.
- [ ] Owner deactivates the staff account; the staff phone is signed out with the "deactivated" message.
- [ ] Settings → Add 20 sample products (debug), then Products lists them, search "pancit" finds Lucky Me, and the low-stock filter works.
- [ ] Add a product with **Scan barcode**. Adding the same barcode again shows "already used".
- [ ] Add a product with **No barcode** (`TS-…` code) and sell it by name search.
- [ ] Sell: continuous scanning adds +1 per scan (holding the code steady does not add repeatedly), the torch toggles, and denying the camera shows "Allow camera". After "Don't ask again" it shows "Open settings".
- [ ] Scanning an unknown barcode shows "Product not found". The owner gets "Add this product" with the barcode prefilled; staff do not.
- [ ] Adding more than the stock shows "Only N left".
- [ ] Payment: change is correct, Confirm is disabled until the cash covers the total, and double-tapping Confirm creates one sale.
- [ ] Receipt shows `yyyyMMdd-0001`, the next sale shows `-0002`, and Share sends the text receipt.
- [ ] On two phones, sell the last unit on one. The other phone's checkout fails with a stock message and the cart refreshes.
- [ ] Airplane mode: the offline banner shows, a sale completes with an `X…` receipt, and it syncs after reconnecting.
- [ ] Adjust stock (restock, damaged, correction) and check that the history lists each change.
- [ ] Alerts: low stock, expiring within 7 days, negative. The home badge count matches. A low-stock notification appears once per day.
- [ ] Dashboard: today's totals match the receipts, and the 7/30-day toggle and charts render.
- [ ] Reports: change the range and grouping, export each report to Excel, and open the file in Sheets or Excel (₱ formatting, totals row).
- [ ] Switch language to Filipino in Settings; texts change. Set phone font size to the largest; nothing overflows.
- [ ] Settings → Theme Dark/Light/System switches instantly. Turn on Android "Remove animations"; the app shows no entrances, count-ups or scan line.
- [ ] On a tablet (or a resized emulator), the navigation rail appears and Products shows list + detail side by side.
- [ ] Swipe a cart line left to remove it, then tap Undo.
- [ ] The Android back button on Sell with items asks to discard.

## Reused components

See [docs/COMPONENTS.md](docs/COMPONENTS.md) for the license and integration
point of each package (for the Component Worksheet).

## Known risks

- **Free tier:** every query is limited and paginated, and dashboards read at most 30 small documents. Each security-rule check also reads `users/{uid}` (cached per request). One store stays well within the Spark free tier of 50k reads and 20k writes per day.
- **Scan accuracy:** poor light or damaged barcodes can fail to scan. Every scan screen has a torch and manual entry.
- **Internet dependency:** checkout transactions need a connection. Offline sales use the batched fallback described above.
- **Staff accounts can't be deleted from the client.** Deactivating one blocks it everywhere (the rules check `active`). Deleting the Auth record needs the Firebase console.
- **Device clock:** sale day keys use the device clock, while stored timestamps use the server clock.

## Git conventions

Use [Conventional Commits](https://www.conventionalcommits.org/): `feat(auth): …`,
`fix(rules): …`, `test: …`, `docs: …`, `chore: …`.
