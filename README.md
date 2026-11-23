# TindaScan

A smart inventory and sales management app with barcode scanning for small sari-sari
stores. Flutter (Android-first) on Firebase Authentication and Cloud Firestore, with no
custom server.

CS 413 Advanced Software Engineering, Batangas State University (Alangilan), 1st Semester
AY 2026-2027. Group: Andal, Jaycee F. and Castillo, Cloyd Robin C.

## Features

- **Barcode checkout (F-01):** scan with the camera, build a cart, take cash payment, and
  record the sale with an atomic stock update.
- **Two roles:** Owner (products, stock, staff, dashboard, reports, settings) and
  Staff/Cashier (Sell). Owners land on Dashboard, staff on Sell.
- **Inventory:** products with barcodes, stock adjustments with a movement history, low-stock,
  out-of-stock and expiry alerts, and a restock list.
- **Dashboard and reports:** daily sales, best sellers, lowest stock, and Excel (`.xlsx`)
  export.
- **Offline-aware:** sales still work without internet (see [Checkout](#checkout-f-01)).
- English and Filipino, light and dark themes.

## Architecture

Layered client with a Backend-as-a-Service:

| Layer | Main parts |
|---|---|
| Presentation | `SellScreen`, `BarcodeScannerView` (wraps `mobile_scanner`), `go_router` role guard |
| Business logic | `CartNotifier` (Riverpod), `CheckoutService`, `AlertService` |
| Data | `ProductRepository`, `SalesRepository`, and other interfaces in `lib/shared/repositories/`, with Firestore implementations in `lib/features/*/data/` |
| Backend | Firebase Authentication, Cloud Firestore, `firebase/firestore.rules` |

Code is organised by feature (`lib/features/<feature>/{domain,application,data,presentation}`),
with shared models and repository interfaces in `lib/shared/` and cross-cutting code in
`lib/core/`. Reused packages, their licenses and integration points are listed in
[docs/COMPONENTS.md](docs/COMPONENTS.md).

### Checkout (F-01)

1. `CartNotifier` looks up each scanned barcode and keeps the cart. It also generates the
   sale ID, which stays the same until the cart changes.
2. `CheckoutService` validates the payment and the cashier, then calls
   `SalesRepository.createSale(cart, tenderedCentavos, cashier:, saleId:, now:)`.
3. **Online:** one Firestore transaction re-reads stock and prices, creates the immutable
   sale with a receipt number like `20261123-0001`, decrements stock, writes
   `stock_movements`, and updates `daily_stats`. If any item is short, nothing is saved.
4. **Offline:** transactions need the server, so `createSaleOffline` writes a batch that
   syncs later. Its receipt is marked (`20261123-XAB12CD`), and stock can go negative after
   sync; the Owner sees those products under Alerts.
5. Retrying with the same sale ID returns the existing sale, so a lost response cannot charge
   twice.
6. After the sale, `AlertService` checks the new stock levels for low-stock notifications.
   It also runs when the Owner opens the app.

Money is stored as integer centavos. Failures are typed (`ProductNotFound`,
`InsufficientStock`, `PriceChangedFailure`, `InvalidPayment`, `PermissionDenied`,
`NetworkUnavailable`, and others in `lib/core/errors/failure.dart`).

### Security

The router guard only hides screens. Real enforcement is in `firebase/firestore.rules`: an
active user is required, a sale's `cashierId` must match the signed-in user,
`change = tendered - total`, sales are immutable, and stock can only be decremented as part
of a new sale.

## Setup

Requirements: Flutter 3.41+ (CI uses 3.41.9), and for rules tests Node 22 and Java 21.

```sh
flutter pub get
flutter gen-l10n
```

### Firebase configuration

The app does not commit `firebase_options.dart`. Options are passed per flavor with
`--dart-define-from-file`:

1. Copy `env/dev.example.json` to `env/dev.json` (git-ignored).
2. Fill in the values from the Firebase console (or run `flutterfire configure` once and copy
   them over).
3. Run:

```sh
flutter run --dart-define-from-file=env/dev.json
```

### Local emulators (no real project needed)

```sh
firebase emulators:start
flutter run --dart-define-from-file=env/emulator.json
```

`env/emulator.json` uses the `demo-tindascan` project and host `10.0.2.2` (the Android
emulator's address for your computer).

## Tests

```sh
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --exclude-tags golden       # unit and widget tests
flutter test --tags golden               # golden images (rendered on Windows)
flutter test integration_test            # needs a device or emulator

cd firebase/rules-tests && npm install && npm run test:emulator   # security rules
```

CI (`.github/workflows/ci.yml`) runs format, analyze, the unit and widget tests, and the
rules tests on the Firestore emulator for every push to `main` and every pull request.

## Project docs

- [CHANGELOG.md](CHANGELOG.md)
- [docs/COMPONENTS.md](docs/COMPONENTS.md): component worksheet
- [docs/la2-alignment.md](docs/la2-alignment.md): how the code maps to the LA2 document
- `docs/decision-log.md`, `docs/technical-debt.md`, `docs/roadmap.md`, `docs/activity-log.md`
