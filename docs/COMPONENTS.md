# Reused Components (Component Worksheet)

Versions are the ones resolved in `pubspec.lock`. Licenses were checked against
each package's `LICENSE` file in the pub cache. "BSD-3" means the BSD 3-Clause
License.

| Component | Version | License | Replaces | Integration point in TindaScan |
|---|---|---|---|---|
| **firebase_auth** | 6.7.1 | BSD-3 | — | `lib/features/auth/data/firebase_auth_repository.dart`: email/password sign-in, owner registration, staff creation on a secondary `FirebaseApp`, password reset, sign-out. Behind the `AuthRepository` interface. |
| **cloud_firestore** | 6.10.2 | BSD-3 | — | All `lib/features/*/data/firestore_*_repository.dart` files: product catalog (`products`, `barcodes`), atomic checkout transaction (`sales`, `stock_movements`, `counters`, `daily_stats`), stock adjustments, settings, users. Offline persistence is enabled in `lib/bootstrap.dart`. Security rules are in `firebase/firestore.rules`. |
| **firebase_core** | 4.15.2 | BSD-3 | — | `lib/bootstrap.dart` (`Firebase.initializeApp` with per-flavor options from `lib/core/config/env.dart`). |
| **firebase_app_check** | 0.4.9 | BSD-3 | — | `lib/bootstrap.dart`: Play Integrity in release builds, the debug provider in debug builds. |
| **mobile_scanner** | 7.5.0 | BSD-3 | Quagga2 | `lib/features/scanner/presentation/barcode_scanner_view.dart` (reusable scanner: torch, frame overlay, debounce, haptics, lifecycle). Used by the Sell screen (continuous mode), `ScanScreen` (single scan for the product form and lookup). |
| **fl_chart** | 1.3.1 | MIT | Chart.js | `lib/features/dashboard/presentation/dashboard_charts.dart`: 7/30-day sales line chart, top-5 best-sellers bar chart, lowest-stock bar chart. |
| **excel** | 4.0.6 | MIT | SheetJS | `lib/features/reports/domain/excel_export.dart`: `.xlsx` generation with a bold header row, `₱` number format, totals row and multiple sheets. Runs in an isolate via `compute()` from `report_providers.dart`. |
| **share_plus** | 12.0.2 | BSD-3 | — | `report_providers.dart` (share the exported `.xlsx`), `receipt_screen.dart` (share the receipt as text), `restock_list_screen.dart` (share the shopping list). |
| **path_provider** | 2.1.5 | BSD-3 | — | Temp folder for exported reports; app-support folder for `LocalPrefs` (`lib/core/services/local_prefs.dart`). |
| flutter_riverpod | 3.3.2 | MIT | — | State management and dependency injection (`lib/shared/providers`, every `application/` folder). |
| go_router | 17.2.3 | BSD-3 | — | `lib/core/router/app_router.dart` with role guards in `route_guard.dart`. |
| intl | 0.20.2 | BSD-3 | — | Number and date formatting (`money.dart`, `formatters.dart`), gen-l10n. |
| connectivity_plus | 7.3.1 | BSD-3 | — | `lib/core/connectivity/connectivity_providers.dart`: offline banner and the offline checkout path. |
| flutter_local_notifications | 20.1.0 | BSD-3 | — | `lib/features/alerts/data/notification_service.dart`: low-stock notifications (at most once per product per day). |
| permission_handler | 12.0.3 | MIT | — | Camera permission flow, including the "permanently denied" case with an "Open settings" shortcut, in `barcode_scanner_view.dart`. |
| **Design system** | | | | |
| flutter_animate | 4.5.2 | BSD-3 | — | `lib/core/widgets/motion.dart` (staggered list entrances, section entrances, shake on unknown barcode) and the scanner sheet's pulsing cart counter. Skipped when animations are disabled. |
| google_fonts | 8.1.0 | BSD-3 (fonts: SIL OFL 1.1) | — | `lib/core/theme/app_typography.dart`: Plus Jakarta Sans text theme and JetBrains Mono for the receipt (cached after first download; disabled in tests). |
| animations | 2.2.0 | BSD-3 | — | `lib/core/theme/app_theme.dart`: shared-axis page transitions for pushed screens. |
| skeletonizer | 3.0.0 | MIT | — | `SkeletonList` in `lib/core/widgets/state_views.dart` and skeleton rows on Products, Alerts, Restock: shimmer placeholders instead of spinners. |
| flutter_slidable | 4.0.3 | MIT | — | `lib/features/sales/presentation/sell_screen.dart`: swipe-to-remove cart lines (with Undo). |
| material_symbols_icons | 4.2960.0 | Apache-2.0 | — | Rounded Material Symbols used across all redesigned screens (navigation, actions, states). |
| **Dev only** | | | | |
| flutter_lints | 5.0.0 | BSD-3 | — | `analysis_options.yaml`. |
| mocktail | 1.0.5 | MIT | — | Repository mocks in notifier tests. |
| fake_cloud_firestore | 4.4.0 | BSD-3 | — | Repository, controller and widget tests (`test/`), plus the integration test. |
| @firebase/rules-unit-testing | 6.x | Apache-2.0 | — | `firebase/rules-tests/` (Node, runs on the Firestore emulator). |
