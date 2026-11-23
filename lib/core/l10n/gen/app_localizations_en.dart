// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TindaScan';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of TindaScan?';

  @override
  String get nothingHereYet => 'Nothing here yet.';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get errorPermission => 'You don\'t have permission to do that.';

  @override
  String get errorNotFound => 'We couldn\'t find that record.';

  @override
  String get errorConflict =>
      'The data changed on another device. Please try again.';

  @override
  String get errorRateLimit =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorSetupDone =>
      'This store is already set up. Please sign in instead.';

  @override
  String errorDuplicateBarcode(String barcode) {
    return 'Barcode $barcode is already used by another product.';
  }

  @override
  String errorInsufficientStock(String product, int available) {
    return 'Not enough stock for $product. Only $available left.';
  }

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorEmailInUse => 'That email is already registered.';

  @override
  String get errorWeakPassword => 'That password is too weak.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorAccountDisabled => 'This account has been disabled.';

  @override
  String get errorRecentLogin => 'Please sign in again to continue.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get fieldInvalidEmail => 'Enter a valid email address.';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get fieldPasswordMismatch => 'Passwords do not match.';

  @override
  String fieldTooLong(int max) {
    return 'Too long (maximum $max characters).';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get nameLabel => 'Full name';

  @override
  String get storeNameLabel => 'Store name';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Welcome! Sign in to your store.';

  @override
  String get loginButton => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetEmailSent =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get enterEmailFirst => 'Enter your email first.';

  @override
  String get deactivatedMessage =>
      'Your account has been deactivated. Please contact the store owner.';

  @override
  String get sessionRejectedMessage =>
      'Your saved sign-in is no longer valid for this store. Please sign in again.';

  @override
  String get setupTitle => 'Set up your store';

  @override
  String get setupSubtitle =>
      'Create the owner account. This can only be done once.';

  @override
  String get setupButton => 'Create owner account';

  @override
  String get accountIssueTitle => 'Account not ready';

  @override
  String get accountIssueMessage =>
      'You are signed in, but this account has no store profile. Please ask the store owner to create your account again.';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleStaff => 'Staff';

  @override
  String get menuStaff => 'Staff accounts';

  @override
  String get menuProfile => 'My profile';

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileRole => 'Role';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get staffTitle => 'Staff accounts';

  @override
  String get staffEmpty => 'No staff yet. Tap \"Add staff\" to create one.';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffNewTitle => 'New staff account';

  @override
  String get staffCreated => 'Staff account created.';

  @override
  String get staffActive => 'Active';

  @override
  String get staffInactive => 'Deactivated';

  @override
  String staffDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get staffDeactivateMessage =>
      'They will be signed out right away and can no longer use the app.';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String get staffActivate => 'Reactivate';

  @override
  String get staffPasswordHint =>
      'Give this password to the staff member in person. They can change it later with \"Forgot password\".';

  @override
  String get firebaseNotConfiguredTitle => 'Firebase is not configured';

  @override
  String get firebaseNotConfiguredMessage =>
      'Run the app with --dart-define-from-file=env/dev.json. See the README for setup steps.';

  @override
  String get connectionIssueTitle => 'Cannot reach the store server';

  @override
  String get connectionIssueMessage =>
      'TindaScan could not check whether this store is set up yet.';

  @override
  String get connectionIssuePermissionHint =>
      'The server refused the request. If this Firebase project is new, deploy the security rules first (see \"Deploy rules and indexes\" in the README) and check that FIREBASE_PROJECT_ID in env/dev.json matches the project.';

  @override
  String errorProductUnavailable(String product) {
    return '$product is no longer available.';
  }

  @override
  String errorPriceChanged(String product) {
    return 'The price of $product changed. The cart was updated; please check the total.';
  }

  @override
  String get errorInsufficientPayment =>
      'The amount received is less than the total.';

  @override
  String get errorExport => 'Could not create the report file.';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get close => 'Close';

  @override
  String get share => 'Share';

  @override
  String get loadMore => 'Load more';

  @override
  String get clear => 'Clear';

  @override
  String get discard => 'Discard';

  @override
  String get offlineBanner => 'Offline: changes will sync later';

  @override
  String get menuSell => 'Sell';

  @override
  String get menuProducts => 'Products';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuAlerts => 'Alerts';

  @override
  String get menuRestock => 'Restock list';

  @override
  String get menuReports => 'Reports';

  @override
  String get menuSettings => 'Settings';

  @override
  String get productsTitle => 'Products';

  @override
  String get productsSearchHint => 'Search name or barcode';

  @override
  String get productsEmpty => 'No products found.';

  @override
  String get productsLowStockFilter => 'Low stock';

  @override
  String get productsArchivedFilter => 'Archived';

  @override
  String get productsAllCategories => 'All';

  @override
  String get productAdd => 'Add product';

  @override
  String get productNewTitle => 'New product';

  @override
  String get productEditTitle => 'Edit product';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get productBarcodeLabel => 'Barcode';

  @override
  String get productNoBarcode => 'No barcode: generate a code';

  @override
  String get productScanBarcode => 'Scan barcode';

  @override
  String get productCategoryLabel => 'Category';

  @override
  String get productPriceLabel => 'Selling price (₱)';

  @override
  String get productCostLabel => 'Cost price (₱)';

  @override
  String get productInitialStockLabel => 'Starting stock';

  @override
  String get productThresholdLabel => 'Low-stock alert at';

  @override
  String get productExpiryLabel => 'Expiry date (optional)';

  @override
  String get productNoExpiry => 'No expiry date';

  @override
  String get productPickDate => 'Pick date';

  @override
  String get productSaved => 'Product saved.';

  @override
  String get productPriceBelowCost => 'Note: selling price is below cost.';

  @override
  String productStockCount(int count) {
    return '$count in stock';
  }

  @override
  String get productPrice => 'Price';

  @override
  String get productCost => 'Cost';

  @override
  String get productProfit => 'Profit per item';

  @override
  String productExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get productExpired => 'Expired';

  @override
  String productArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get productArchiveMessage =>
      'It will be hidden from selling. Past sales stay unchanged, and you can restore it later.';

  @override
  String get productArchivedBadge => 'Archived';

  @override
  String get productAdjustStock => 'Adjust stock';

  @override
  String get productHistory => 'Stock history';

  @override
  String get productInternalCode => 'Internal code (no printed barcode)';

  @override
  String get productInitialStockNote => 'Initial stock';

  @override
  String get productLowStockBadge => 'Low';

  @override
  String get productNotFound => 'Product not found';

  @override
  String productNotFoundMessage(String barcode) {
    return 'No product has the barcode $barcode.';
  }

  @override
  String get productAddThis => 'Add this product';

  @override
  String get productStockNote =>
      'To change stock later, use \"Adjust stock\" so every change is recorded.';

  @override
  String get fieldInvalidBarcode => 'Use letters, numbers and dashes only.';

  @override
  String get fieldInvalidMoney => 'Enter an amount like 12.50.';

  @override
  String fieldInvalidQuantity(int max) {
    return 'Enter a whole number from 0 to $max.';
  }

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categoryNoodles => 'Noodles';

  @override
  String get categoryCannedGoods => 'Canned goods';

  @override
  String get categoryCondiments => 'Condiments';

  @override
  String get categoryRiceGrains => 'Rice & grains';

  @override
  String get categoryDairy => 'Milk & dairy';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryPersonalCare => 'Personal care';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryFrozen => 'Frozen';

  @override
  String get categoryOthers => 'Others';

  @override
  String get scannerTitle => 'Scan barcode';

  @override
  String get scannerSemantics => 'Camera barcode scanner';

  @override
  String get scannerTorchOn => 'Turn flashlight on';

  @override
  String get scannerTorchOff => 'Turn flashlight off';

  @override
  String get scannerPermissionNeeded =>
      'TindaScan needs the camera to scan barcodes.';

  @override
  String get scannerAllowCamera => 'Allow camera';

  @override
  String get scannerPermissionDenied =>
      'Camera access is turned off. Turn it on in Settings, or type the barcode instead.';

  @override
  String get scannerOpenSettings => 'Open settings';

  @override
  String get scannerError =>
      'The camera could not start. Type the barcode instead.';

  @override
  String get scannerManualHint => 'Type barcode';

  @override
  String get scannerManualSubmit => 'Use code';

  @override
  String get scannerHint => 'Point the camera at the barcode';

  @override
  String get sellTitle => 'Sell';

  @override
  String get sellSearchHint => 'Search product to add';

  @override
  String get sellCartEmpty => 'Scan or search a product to start a sale.';

  @override
  String get sellTotal => 'Total';

  @override
  String sellCharge(String amount) {
    return 'Charge $amount';
  }

  @override
  String sellItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get sellShowScanner => 'Show scanner';

  @override
  String get sellHideScanner => 'Hide scanner';

  @override
  String sellAdded(String name) {
    return 'Added $name';
  }

  @override
  String get sellRemove => 'Remove';

  @override
  String get sellIncrease => 'Add one';

  @override
  String get sellDecrease => 'Remove one';

  @override
  String get sellDiscardTitle => 'Discard this sale?';

  @override
  String get sellDiscardMessage => 'The items in the cart will be removed.';

  @override
  String get sellClearCart => 'Clear cart';

  @override
  String get sellOutOfStock => 'Out of stock';

  @override
  String get paymentTitle => 'Cash payment';

  @override
  String get paymentTendered => 'Amount received (₱)';

  @override
  String get paymentChange => 'Change';

  @override
  String get paymentExact => 'Exact';

  @override
  String get paymentConfirm => 'Confirm sale';

  @override
  String get paymentOfflineNote =>
      'You\'re offline. The sale will be saved on this phone and synced later.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String receiptNo(String number) {
    return 'Receipt #$number';
  }

  @override
  String receiptCashier(String name) {
    return 'Cashier: $name';
  }

  @override
  String get receiptCash => 'Cash';

  @override
  String get receiptNewSale => 'New sale';

  @override
  String get receiptThanks => 'Thank you! Come again.';

  @override
  String get receiptOffline => 'Saved offline: will sync when online';

  @override
  String get receiptSaleComplete => 'Sale complete';

  @override
  String get stockAdjustTitle => 'Adjust stock';

  @override
  String get stockTypeRestock => 'Restock';

  @override
  String get stockTypeSpoilage => 'Damaged';

  @override
  String get stockTypeAdjustment => 'Correction';

  @override
  String get stockQuantityLabel => 'Quantity';

  @override
  String get stockCorrectionLabel => 'Actual count on the shelf';

  @override
  String get stockNoteLabel => 'Note (optional)';

  @override
  String stockCurrent(int count) {
    return 'Current stock: $count';
  }

  @override
  String stockAfter(int count) {
    return 'After saving: $count';
  }

  @override
  String get stockSaved => 'Stock updated.';

  @override
  String get stockNoChange => 'The count is the same as the current stock.';

  @override
  String get stockHistoryEmpty => 'No stock changes yet.';

  @override
  String get movementRestock => 'Restock';

  @override
  String get movementSale => 'Sale';

  @override
  String get movementSpoilage => 'Damaged / spoiled';

  @override
  String get movementAdjustment => 'Correction';

  @override
  String movementBy(String name) {
    return 'by $name';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsLowStock => 'Low stock';

  @override
  String get alertsExpiring => 'Expiring';

  @override
  String get alertsNegative => 'Negative';

  @override
  String get alertsLowStockEmpty => 'All products are well stocked.';

  @override
  String alertsExpiringEmpty(int days) {
    return 'Nothing expires in the next $days days.';
  }

  @override
  String get alertsNegativeEmpty => 'No products have negative stock.';

  @override
  String get alertsNegativeExplain =>
      'These went below zero because sales were made offline on more than one phone. Count the shelf and use \"Adjust stock\" to correct them.';

  @override
  String get notificationChannelName => 'Low-stock alerts';

  @override
  String get notificationChannelDescription =>
      'Tells you when a product is running low.';

  @override
  String notificationLowStockTitle(String name) {
    return 'Low stock: $name';
  }

  @override
  String notificationLowStockBody(int count) {
    return 'Only $count left. Time to restock.';
  }

  @override
  String get restockTitle => 'Suggested restock';

  @override
  String get restockEmpty => 'Nothing to restock right now.';

  @override
  String restockNeeded(int count) {
    return 'Buy $count';
  }

  @override
  String restockExplain(int multiplier) {
    return 'Each item is brought back up to $multiplier× its low-stock alert level.';
  }

  @override
  String get restockShareTitle => 'Restock list';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardTodaySales => 'Today\'s sales';

  @override
  String get dashboardTransactions => 'Transactions';

  @override
  String get dashboardProfit => 'Est. profit';

  @override
  String get dashboardSalesTrend => 'Sales trend';

  @override
  String get dashboard7Days => '7 days';

  @override
  String get dashboard30Days => '30 days';

  @override
  String get dashboardTopSellers => 'Top 5 best-sellers';

  @override
  String get dashboardLowestStock => 'Lowest stock';

  @override
  String get dashboardNoSales => 'No sales in this period yet.';

  @override
  String dashboardSold(int count) {
    return '$count sold';
  }

  @override
  String dashboardLowStockCount(int count) {
    return '$count products are low on stock';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsRange => 'Date range';

  @override
  String get reportsSales => 'Sales';

  @override
  String get reportsBestSellers => 'Best-sellers';

  @override
  String get reportsInventory => 'Inventory';

  @override
  String get reportsMovements => 'Stock movements';

  @override
  String get reportsGroupDaily => 'Daily';

  @override
  String get reportsGroupWeekly => 'Weekly';

  @override
  String get reportsGroupMonthly => 'Monthly';

  @override
  String get reportsExport => 'Export to Excel';

  @override
  String get reportsPeriodCol => 'Period';

  @override
  String get reportsSalesCol => 'Sales';

  @override
  String get reportsCostCol => 'Cost';

  @override
  String get reportsProfitCol => 'Profit';

  @override
  String get reportsTransactionsCol => 'Transactions';

  @override
  String get reportsItemsCol => 'Items sold';

  @override
  String get reportsQtyCol => 'Qty';

  @override
  String get reportsProductCol => 'Product';

  @override
  String get reportsTotalRow => 'Total';

  @override
  String get reportsValueCol => 'Stock value (cost)';

  @override
  String get reportsDateCol => 'Date';

  @override
  String get reportsTypeCol => 'Type';

  @override
  String get reportsChangeCol => 'Change';

  @override
  String get reportsUserCol => 'By';

  @override
  String get reportsNoteCol => 'Note';

  @override
  String get reportsReceiptCol => 'Receipt';

  @override
  String get reportsCashierCol => 'Cashier';

  @override
  String get reportsBarcodeCol => 'Barcode';

  @override
  String get reportsCategoryCol => 'Category';

  @override
  String get reportsPriceCol => 'Price';

  @override
  String get reportsStockCol => 'Stock';

  @override
  String get reportsTransactionsSheet => 'Transactions';

  @override
  String get reportsEmpty => 'No data for this range.';

  @override
  String reportsCapped(int count) {
    return 'Only the first $count records are included.';
  }

  @override
  String reportsRangeTooLong(int days) {
    return 'Pick a range of $days days or less.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDefaultThreshold => 'Default low-stock alert level';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone default';

  @override
  String get settingsSeedTitle => 'Sample data (debug builds only)';

  @override
  String get settingsSeedButton => 'Add 20 sample products';

  @override
  String settingsSeedDone(int count) {
    return 'Added $count sample products.';
  }

  @override
  String get settingsSeedExplain =>
      'For testing. Products whose barcode already exists are skipped.';

  @override
  String get errorIndexNotReady =>
      'The database is still being prepared. Please try again in a few minutes. (If this continues, deploy the Firestore indexes; see the README.)';

  @override
  String get navMore => 'More';

  @override
  String get moreInventory => 'Inventory & reports';

  @override
  String get moreStore => 'Store';

  @override
  String stockPillLow(int count) {
    return '$count left';
  }

  @override
  String get scanManualChip => 'Type code';

  @override
  String scanCartCount(int count) {
    return '$count in cart';
  }

  @override
  String get done => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get sellScan => 'Scan';

  @override
  String get sellEmptyAction => 'Scan a product';

  @override
  String get cartCleared => 'Cart cleared';

  @override
  String cartRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String dashboardVsYesterday(String delta) {
    return '$delta vs yesterday';
  }

  @override
  String get dashboardNoYesterday => 'No sales yesterday';

  @override
  String get alertsOutOfStock => 'Out of stock';

  @override
  String get alertsExpiringSoon => 'Expiring soon';

  @override
  String get alertsRestockAction => 'Restock';

  @override
  String productArchivedSnack(String name) {
    return '$name archived';
  }

  @override
  String get productsSelectHint => 'Select a product to see its details.';

  @override
  String get reportsToday => 'Today';

  @override
  String get reports7d => '7D';

  @override
  String get reports30d => '30D';

  @override
  String get reportsCustom => 'Custom';

  @override
  String get reportsExported => 'Report ready to share.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsFeedbackSection => 'Feedback';

  @override
  String get settingsHaptics => 'Vibration feedback';

  @override
  String get settingsHapticsHint =>
      'Vibrate on scan, add to cart and completed sales.';

  @override
  String get settingsScanSound => 'Sound on successful scan';

  @override
  String get settingsStoreSection => 'Store';

  @override
  String get settingsDesignGallery => 'Design gallery (debug)';

  @override
  String get designGalleryTitle => 'Design gallery';

  @override
  String get signOutUnsyncedTitle => 'Some sales haven\'t synced yet';

  @override
  String get signOutUnsyncedMessage =>
      'This phone has sales that are not on the server yet. They only sync while you are signed in here. Connect to the internet and wait a moment before signing out, or they will wait on this phone until you sign in again.';

  @override
  String get signOutAnyway => 'Sign out anyway';

  @override
  String lostSalesBanner(String receipts) {
    return 'These offline sales were not saved: $receipts. Re-enter them and tell the owner.';
  }

  @override
  String reportsSalesCapped(int count) {
    return 'The Transactions sheet has only the latest $count sales. Use a shorter range for the full list.';
  }
}
