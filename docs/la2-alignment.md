# LA2 ↔ Code Alignment

How the final LA2 document (`CS413-LA2.docx`, Feature F-01: Barcode-Based Checkout) maps to
this repository, and where the document needs updating. Checked against commit `6d3b3f6` on
23 Nov 2026.

## Matches (no change needed)

| LA2 claim | Where in code |
|---|---|
| Layered client + BaaS, no custom server | `lib/features/*`, `lib/shared/repositories/`, Firebase only |
| `BarcodeScannerView` adapts `mobile_scanner` | `lib/features/scanner/presentation/barcode_scanner_view.dart` |
| go_router role guard | `lib/core/router/route_guard.dart` |
| `CartNotifier` (Riverpod) owns the cart and generates the sale ID | `lib/features/sales/application/cart_notifier.dart` (`checkoutSaleId()`) |
| `CheckoutService` passes the sale ID through | `lib/features/sales/application/checkout_service.dart` |
| `ProductRepository` / `SalesRepository` interfaces + Firebase implementations | `lib/shared/repositories/`, `lib/features/{products,sales}/data/` |
| Checkout is one transaction: re-read stock, immutable sale, decrement, movements, daily stats; nothing saved if short | `FirestoreSalesRepository._transaction` |
| Per-day receipt counter, `YYYYMMDD-0001` | `counters/receipts_yyyyMMdd`, `lib/features/sales/domain/receipt_number.dart` |
| Money as integer centavos | `lib/core/utils/money.dart`, all `*Centavos` fields |
| Offline batched-write fallback; may leave stock negative; offline receipts marked; negative stock flagged to Owner | `FirestoreSalesRepository._batch`, `ReceiptNumber.offline`, Alerts → Negative stock |
| Same sale ID on retry prevents a duplicate sale | idempotency check at the start of `_transaction` |
| Rules: active user, `cashierId`, change = tendered − total, sales immutable, stock decrement only with a new sale | `firebase/firestore.rules` (`isActive`, `validSale`, `isSaleStockUpdate`, `partOfNewSale`) |
| Error types `ProductNotFound`, `InsufficientStock`, `NetworkUnavailable`, `PermissionDenied`, `InvalidPayment` | `lib/core/errors/failure.dart` |
| Automated tests exist | `test/` (unit, widget, golden), `integration_test/sale_flow_test.dart` |
| Emulator rule tests run in CI | `.github/workflows/ci.yml` job `rules` → `firebase/rules-tests` |

## Update the document

| # | LA2 says | Code actually does | Suggested wording |
|---|---|---|---|
| 1 | `CheckoutService` is a "proposed refactor" | Implemented and tested (`test/features/sales/application/checkout_service_test.dart`) | "CheckoutService (implemented)". This covers the lab's "implement or improve one interaction". |
| 2 | AlertService: the refactor calls it after each sale; the current build runs it when the Owner opens the app | Both are in the current build: after each sale (`CheckoutService`) and once per launch for the Owner (`lowStockNotificationProvider`) | "AlertService runs after each sale and once when the Owner opens the app; each product is notified at most once per day." |
| 3 | `createSale(cart, tenderedCentavos, cashier, saleId)` | `createSale(cart, tenderedCentavos, {cashier, saleId, now})`, plus `createSaleOffline` with the same parameters | Add `now` (device time, used only for the Manila day key; the stored timestamp comes from the server). |
| 4 | Collections: users, products, sales, stock_movements, daily_stats, settings, plus a receipt counter | Also `barcodes` (one document per barcode, so two products cannot share one) and `counters` (the receipt counter collection) | Add `barcodes` and name the counter collection `counters`. |
| 5 | Transaction aborts if any item is short | Also aborts if a product was archived (`ProductNotFound`) or its price changed since it was scanned (`PriceChangedFailure`); the cart is then refreshed | Mention the price-change check and the cart refresh. |
| 6 | Five error types | Those five plus `PriceChangedFailure`, `ConflictFailure`, `NotFoundFailure`, `AuthFailure`, `DuplicateBarcodeFailure`, `UnknownFailure`, and others | "Main failures in the F-01 contracts are …; the full set is in `failure.dart`." |
| 7 | `CheckoutService` double-submit handling not described | A second tap while a checkout is running returns the same pending sale | Optional: add to the error scenario. |
| 8 | Online/offline choice not detailed | Uses `connectivity_plus`; if the device reports online but the transaction fails with `NetworkUnavailable`, it falls back to the offline batch | Optional: add to the error scenario. |

## LA1 (still outdated)

LA1 must match the above: project name **TindaScan**, Flutter, `mobile_scanner` (replaces
Quagga2), `fl_chart` (replaces Chart.js), `excel` (replaces SheetJS). The component worksheet
can be taken directly from [COMPONENTS.md](COMPONENTS.md).
