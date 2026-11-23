# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed (F-01 checkout refactor)
- Checkout logic moved into a UI-independent `CheckoutService` (payment validation, online transaction or offline fallback, cart refresh on stock conflicts, double-submit guard, alert hand-off).
- `CartController` renamed to `CartNotifier` with `addByBarcode(barcode)`; the scanner sheet uses it directly.
- `SaleRepository` renamed to `SalesRepository`; `checkout`/`checkoutOffline` became `createSale`/`createSaleOffline(cart, tenderedCentavos, {cashier, saleId, now})`.
- New `AlertService` owns low-stock notification rules (once per product per day), used after each sale and on the owner's app start.
- Typed failures renamed to `ProductNotFound`, `InsufficientStock`, `InvalidPayment`, `PermissionDenied` and `NetworkUnavailable`.

### Changed (design system)
- New minimal design: green-teal seed, warm off-white background, outlined white cards, Plus Jakarta Sans, tabular figures, Material Symbols Rounded.
- Light, dark and system themes with a Settings toggle; design tokens exposed as a `ThemeExtension`.
- Adaptive navigation: bottom bar (phone) / navigation rail (tablet, extended on wide). Owners land on Dashboard, staff on Sell; owner sections moved to a "More" tab.
- Sell redesigned: sticky summary with an animated total, quantity steppers, swipe-to-remove with Undo, continuous scanning in a bottom sheet (animated scan line, success/unknown feedback, pulsing cart counter), payment as a bottom sheet with quick-cash chips (exact, ₱50–₱1000).
- Receipt as a perforated paper card with monospace figures and an animated success check.
- Dashboard: greeting, hero card with count-up, change vs yesterday and sparkline, stat cards, animated trend chart, proportional best-seller and lowest-stock bars.
- Products: collapsing large title, search that hides on scroll, letter avatars with Hero transition, stock pills, skeleton loading, two-pane layout on tablets.
- Alerts grouped into Out of stock / Low stock / Expiring soon with one-tap Restock (bottom sheet).
- Reports: Today / 7D / 30D / Custom chips, summary cards, prominent Export button with progress and success message.
- Haptics and scan-sound toggles; Undo for reversible actions; floating snackbars with icons; skeleton loading.
- Motion respects the system "remove animations" setting.
- Debug-only Design gallery; golden, contrast and reduced-motion tests.

### Added
- Stage 1: project setup, per-flavor Firebase config, App Check, offline persistence.
- Email/password authentication with Owner/Staff roles stored in `users/{uid}`.
- One-time owner setup guarded by `settings/setup`.
- Staff account management (secondary FirebaseApp), deactivation with forced sign-out.
- Role-based routing guards (go_router + Riverpod session).
- Firestore security rules and composite indexes for all collections, with emulator tests.
- English and Filipino localization (gen-l10n), with an in-app language switch.
- Products: paginated catalog, word/barcode search, category and low-stock filters, add/edit with barcode scan, internal codes for items without barcodes, unique barcodes, archive/restore.
- Reusable barcode scanner (mobile_scanner) with torch, permission handling, debounce, haptics, lifecycle handling and manual entry.
- Sell/checkout: continuous scanning, cart with stock limits, cash payment with change, atomic Firestore transaction (sale + stock + movements + receipt counter + daily stats), idempotent retries, offline batched fallback, shareable receipt.
- Stock adjustments (restock, spoilage, correction) with paginated history.
- Alerts: low stock (badge and once-a-day notification), expiring within 7 days, negative stock; suggested restock list.
- Owner dashboard with fl_chart (sales trend, best-sellers, lowest stock) backed by `daily_stats`.
- Reports (sales by day/week/month, best-sellers, inventory, stock movements) with Excel export generated in an isolate.
- Settings (store name, default alert level, language) and a debug-only seeder for 20 sample products.
- Offline banner, connection-issue screen, CI workflow, integration test.
