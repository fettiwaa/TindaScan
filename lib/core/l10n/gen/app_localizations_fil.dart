// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'TindaScan';

  @override
  String get loading => 'Naglo-load…';

  @override
  String get retry => 'Subukan muli';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get save => 'I-save';

  @override
  String get signOut => 'Mag-sign out';

  @override
  String get signOutConfirm => 'Mag-sign out sa TindaScan?';

  @override
  String get nothingHereYet => 'Wala pang laman dito.';

  @override
  String get errorNetwork =>
      'Walang internet. Pakisuri ang koneksyon at subukan muli.';

  @override
  String get errorPermission => 'Wala kang pahintulot na gawin iyan.';

  @override
  String get errorNotFound => 'Hindi namin mahanap ang record na iyon.';

  @override
  String get errorConflict =>
      'Nagbago ang datos sa ibang device. Pakisubukan muli.';

  @override
  String get errorRateLimit =>
      'Masyadong maraming subok. Maghintay sandali at subukan muli.';

  @override
  String get errorSetupDone =>
      'Naka-set up na ang tindahang ito. Mag-sign in na lang.';

  @override
  String errorDuplicateBarcode(String barcode) {
    return 'Ang barcode na $barcode ay gamit na ng ibang produkto.';
  }

  @override
  String errorInsufficientStock(String product, int available) {
    return 'Kulang ang stock ng $product. $available na lang ang natitira.';
  }

  @override
  String get errorInvalidCredentials => 'Mali ang email o password.';

  @override
  String get errorEmailInUse => 'Nakarehistro na ang email na iyan.';

  @override
  String get errorWeakPassword => 'Masyadong mahina ang password.';

  @override
  String get errorInvalidEmail => 'Maglagay ng tamang email address.';

  @override
  String get errorAccountDisabled => 'Na-disable na ang account na ito.';

  @override
  String get errorRecentLogin => 'Mag-sign in muli para magpatuloy.';

  @override
  String get errorUnknown => 'May nangyaring mali. Pakisubukan muli.';

  @override
  String get fieldRequired => 'Kailangan ito.';

  @override
  String get fieldInvalidEmail => 'Maglagay ng tamang email address.';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Gumamit ng hindi bababa sa $min na character.';
  }

  @override
  String get fieldPasswordMismatch => 'Hindi magkatugma ang mga password.';

  @override
  String fieldTooLong(int max) {
    return 'Masyadong mahaba (hanggang $max na character).';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Kumpirmahin ang password';

  @override
  String get nameLabel => 'Buong pangalan';

  @override
  String get storeNameLabel => 'Pangalan ng tindahan';

  @override
  String get showPassword => 'Ipakita ang password';

  @override
  String get hidePassword => 'Itago ang password';

  @override
  String get loginTitle => 'Mag-sign in';

  @override
  String get loginSubtitle =>
      'Maligayang pagdating! Mag-sign in sa iyong tindahan.';

  @override
  String get loginButton => 'Mag-sign in';

  @override
  String get forgotPassword => 'Nakalimutan ang password?';

  @override
  String get resetEmailSent =>
      'Naipadala na ang email para i-reset ang password. Tingnan ang inbox.';

  @override
  String get enterEmailFirst => 'Ilagay muna ang iyong email.';

  @override
  String get deactivatedMessage =>
      'Na-deactivate ang iyong account. Makipag-ugnayan sa may-ari ng tindahan.';

  @override
  String get sessionRejectedMessage =>
      'Hindi na valid ang naka-save mong sign-in para sa tindahang ito. Mag-sign in ulit.';

  @override
  String get setupTitle => 'I-set up ang tindahan';

  @override
  String get setupSubtitle =>
      'Gumawa ng account ng may-ari. Isang beses lang ito magagawa.';

  @override
  String get setupButton => 'Gumawa ng account ng may-ari';

  @override
  String get accountIssueTitle => 'Hindi pa handa ang account';

  @override
  String get accountIssueMessage =>
      'Naka-sign in ka, pero walang profile sa tindahan ang account na ito. Hilingin sa may-ari na gawin muli ang iyong account.';

  @override
  String homeGreeting(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get roleOwner => 'May-ari';

  @override
  String get roleStaff => 'Tindero/Tindera';

  @override
  String get menuStaff => 'Mga account ng staff';

  @override
  String get menuProfile => 'Aking profile';

  @override
  String get profileTitle => 'Aking profile';

  @override
  String get profileRole => 'Tungkulin';

  @override
  String get profileSaved => 'Na-save ang profile.';

  @override
  String get staffTitle => 'Mga account ng staff';

  @override
  String get staffEmpty =>
      'Wala pang staff. Pindutin ang \"Magdagdag ng staff\".';

  @override
  String get staffAdd => 'Magdagdag ng staff';

  @override
  String get staffNewTitle => 'Bagong account ng staff';

  @override
  String get staffCreated => 'Nagawa ang account ng staff.';

  @override
  String get staffActive => 'Aktibo';

  @override
  String get staffInactive => 'Naka-deactivate';

  @override
  String staffDeactivateTitle(String name) {
    return 'I-deactivate si $name?';
  }

  @override
  String get staffDeactivateMessage =>
      'Masa-sign out sila agad at hindi na magagamit ang app.';

  @override
  String get staffDeactivate => 'I-deactivate';

  @override
  String get staffActivate => 'I-activate muli';

  @override
  String get staffPasswordHint =>
      'Ibigay nang personal ang password na ito sa staff. Mapapalitan nila ito gamit ang \"Nakalimutan ang password\".';

  @override
  String get firebaseNotConfiguredTitle =>
      'Hindi pa naka-configure ang Firebase';

  @override
  String get firebaseNotConfiguredMessage =>
      'Patakbuhin ang app gamit ang --dart-define-from-file=env/dev.json. Basahin ang README.';

  @override
  String get connectionIssueTitle => 'Hindi maabot ang server ng tindahan';

  @override
  String get connectionIssueMessage =>
      'Hindi masuri ng TindaScan kung naka-set up na ang tindahang ito.';

  @override
  String get connectionIssuePermissionHint =>
      'Tinanggihan ng server ang request. Kung bago ang Firebase project, i-deploy muna ang security rules (tingnan ang \"Deploy rules and indexes\" sa README) at tiyaking tugma ang FIREBASE_PROJECT_ID sa env/dev.json.';

  @override
  String errorProductUnavailable(String product) {
    return 'Hindi na available ang $product.';
  }

  @override
  String errorPriceChanged(String product) {
    return 'Nagbago ang presyo ng $product. Na-update ang cart; pakisuri ang kabuuan.';
  }

  @override
  String get errorInsufficientPayment => 'Kulang ang natanggap na bayad.';

  @override
  String get errorExport => 'Hindi magawa ang report file.';

  @override
  String get add => 'Idagdag';

  @override
  String get edit => 'I-edit';

  @override
  String get archive => 'I-archive';

  @override
  String get restore => 'Ibalik';

  @override
  String get close => 'Isara';

  @override
  String get share => 'Ibahagi';

  @override
  String get loadMore => 'Mag-load pa';

  @override
  String get clear => 'I-clear';

  @override
  String get discard => 'Itapon';

  @override
  String get offlineBanner => 'Offline: magsi-sync mamaya ang mga pagbabago';

  @override
  String get menuSell => 'Magbenta';

  @override
  String get menuProducts => 'Mga produkto';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuAlerts => 'Mga alerto';

  @override
  String get menuRestock => 'Listahan ng ire-restock';

  @override
  String get menuReports => 'Mga report';

  @override
  String get menuSettings => 'Mga setting';

  @override
  String get productsTitle => 'Mga produkto';

  @override
  String get productsSearchHint => 'Hanapin ang pangalan o barcode';

  @override
  String get productsEmpty => 'Walang nahanap na produkto.';

  @override
  String get productsLowStockFilter => 'Mababa ang stock';

  @override
  String get productsArchivedFilter => 'Naka-archive';

  @override
  String get productsAllCategories => 'Lahat';

  @override
  String get productAdd => 'Magdagdag ng produkto';

  @override
  String get productNewTitle => 'Bagong produkto';

  @override
  String get productEditTitle => 'I-edit ang produkto';

  @override
  String get productNameLabel => 'Pangalan ng produkto';

  @override
  String get productBarcodeLabel => 'Barcode';

  @override
  String get productNoBarcode => 'Walang barcode: gumawa ng code';

  @override
  String get productScanBarcode => 'I-scan ang barcode';

  @override
  String get productCategoryLabel => 'Kategorya';

  @override
  String get productPriceLabel => 'Presyo ng benta (₱)';

  @override
  String get productCostLabel => 'Puhunan (₱)';

  @override
  String get productInitialStockLabel => 'Panimulang stock';

  @override
  String get productThresholdLabel => 'Alerto kapag umabot sa';

  @override
  String get productExpiryLabel => 'Petsa ng expiry (opsyonal)';

  @override
  String get productNoExpiry => 'Walang expiry';

  @override
  String get productPickDate => 'Pumili ng petsa';

  @override
  String get productSaved => 'Na-save ang produkto.';

  @override
  String get productPriceBelowCost =>
      'Paalala: mas mababa ang presyo kaysa puhunan.';

  @override
  String productStockCount(int count) {
    return '$count ang stock';
  }

  @override
  String get productPrice => 'Presyo';

  @override
  String get productCost => 'Puhunan';

  @override
  String get productProfit => 'Tubo bawat piraso';

  @override
  String productExpires(String date) {
    return 'Mag-e-expire sa $date';
  }

  @override
  String get productExpired => 'Expired na';

  @override
  String productArchiveTitle(String name) {
    return 'I-archive ang $name?';
  }

  @override
  String get productArchiveMessage =>
      'Itatago ito sa pagbebenta. Hindi magbabago ang mga nakaraang benta, at maibabalik mo ito mamaya.';

  @override
  String get productArchivedBadge => 'Naka-archive';

  @override
  String get productAdjustStock => 'I-adjust ang stock';

  @override
  String get productHistory => 'Kasaysayan ng stock';

  @override
  String get productInternalCode => 'Internal na code (walang barcode)';

  @override
  String get productInitialStockNote => 'Panimulang stock';

  @override
  String get productLowStockBadge => 'Mababa';

  @override
  String get productNotFound => 'Hindi nahanap ang produkto';

  @override
  String productNotFoundMessage(String barcode) {
    return 'Walang produktong may barcode na $barcode.';
  }

  @override
  String get productAddThis => 'Idagdag ang produktong ito';

  @override
  String get productStockNote =>
      'Para baguhin ang stock, gamitin ang \"I-adjust ang stock\" para maitala ang bawat pagbabago.';

  @override
  String get fieldInvalidBarcode =>
      'Letra, numero at gitling lang ang gamitin.';

  @override
  String get fieldInvalidMoney => 'Maglagay ng halaga tulad ng 12.50.';

  @override
  String fieldInvalidQuantity(int max) {
    return 'Maglagay ng buong numero mula 0 hanggang $max.';
  }

  @override
  String get categoryBeverages => 'Inumin';

  @override
  String get categorySnacks => 'Meryenda';

  @override
  String get categoryNoodles => 'Noodles';

  @override
  String get categoryCannedGoods => 'De-lata';

  @override
  String get categoryCondiments => 'Pampalasa';

  @override
  String get categoryRiceGrains => 'Bigas at butil';

  @override
  String get categoryDairy => 'Gatas';

  @override
  String get categoryBread => 'Tinapay';

  @override
  String get categoryPersonalCare => 'Pansariling gamit';

  @override
  String get categoryHousehold => 'Gamit sa bahay';

  @override
  String get categoryFrozen => 'Frozen';

  @override
  String get categoryOthers => 'Iba pa';

  @override
  String get scannerTitle => 'I-scan ang barcode';

  @override
  String get scannerSemantics => 'Camera para sa barcode';

  @override
  String get scannerTorchOn => 'Buksan ang flashlight';

  @override
  String get scannerTorchOff => 'Patayin ang flashlight';

  @override
  String get scannerPermissionNeeded =>
      'Kailangan ng TindaScan ang camera para mag-scan.';

  @override
  String get scannerAllowCamera => 'Payagan ang camera';

  @override
  String get scannerPermissionDenied =>
      'Naka-off ang camera. I-on ito sa Settings, o i-type na lang ang barcode.';

  @override
  String get scannerOpenSettings => 'Buksan ang Settings';

  @override
  String get scannerError =>
      'Hindi mabuksan ang camera. I-type na lang ang barcode.';

  @override
  String get scannerManualHint => 'I-type ang barcode';

  @override
  String get scannerManualSubmit => 'Gamitin';

  @override
  String get scannerHint => 'Itutok ang camera sa barcode';

  @override
  String get sellTitle => 'Magbenta';

  @override
  String get sellSearchHint => 'Maghanap ng produktong idadagdag';

  @override
  String get sellCartEmpty => 'Mag-scan o maghanap ng produkto para magsimula.';

  @override
  String get sellTotal => 'Kabuuan';

  @override
  String sellCharge(String amount) {
    return 'Singilin $amount';
  }

  @override
  String sellItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get sellShowScanner => 'Ipakita ang scanner';

  @override
  String get sellHideScanner => 'Itago ang scanner';

  @override
  String sellAdded(String name) {
    return 'Naidagdag ang $name';
  }

  @override
  String get sellRemove => 'Alisin';

  @override
  String get sellIncrease => 'Dagdagan ng isa';

  @override
  String get sellDecrease => 'Bawasan ng isa';

  @override
  String get sellDiscardTitle => 'Itapon ang bentang ito?';

  @override
  String get sellDiscardMessage => 'Aalisin ang mga item sa cart.';

  @override
  String get sellClearCart => 'I-clear ang cart';

  @override
  String get sellOutOfStock => 'Ubos na';

  @override
  String get paymentTitle => 'Bayad na cash';

  @override
  String get paymentTendered => 'Natanggap na bayad (₱)';

  @override
  String get paymentChange => 'Sukli';

  @override
  String get paymentExact => 'Eksakto';

  @override
  String get paymentConfirm => 'Kumpirmahin ang benta';

  @override
  String get paymentOfflineNote =>
      'Offline ka. Ise-save ang benta sa teleponong ito at isi-sync mamaya.';

  @override
  String get receiptTitle => 'Resibo';

  @override
  String receiptNo(String number) {
    return 'Resibo #$number';
  }

  @override
  String receiptCashier(String name) {
    return 'Kahera: $name';
  }

  @override
  String get receiptCash => 'Cash';

  @override
  String get receiptNewSale => 'Bagong benta';

  @override
  String get receiptThanks => 'Salamat po! Balik po kayo.';

  @override
  String get receiptOffline => 'Na-save offline: isi-sync pag may internet';

  @override
  String get receiptSaleComplete => 'Tapos ang benta';

  @override
  String get stockAdjustTitle => 'I-adjust ang stock';

  @override
  String get stockTypeRestock => 'Restock';

  @override
  String get stockTypeSpoilage => 'Sira';

  @override
  String get stockTypeAdjustment => 'Pagwawasto';

  @override
  String get stockQuantityLabel => 'Dami';

  @override
  String get stockCorrectionLabel => 'Aktwal na bilang sa estante';

  @override
  String get stockNoteLabel => 'Tala (opsyonal)';

  @override
  String stockCurrent(int count) {
    return 'Kasalukuyang stock: $count';
  }

  @override
  String stockAfter(int count) {
    return 'Pagkatapos i-save: $count';
  }

  @override
  String get stockSaved => 'Na-update ang stock.';

  @override
  String get stockNoChange => 'Pareho ang bilang sa kasalukuyang stock.';

  @override
  String get stockHistoryEmpty => 'Wala pang pagbabago sa stock.';

  @override
  String get movementRestock => 'Restock';

  @override
  String get movementSale => 'Benta';

  @override
  String get movementSpoilage => 'Sira / panis';

  @override
  String get movementAdjustment => 'Pagwawasto';

  @override
  String movementBy(String name) {
    return 'ni $name';
  }

  @override
  String get alertsTitle => 'Mga alerto';

  @override
  String get alertsLowStock => 'Mababa';

  @override
  String get alertsExpiring => 'Mag-e-expire';

  @override
  String get alertsNegative => 'Negatibo';

  @override
  String get alertsLowStockEmpty => 'Sapat ang stock ng lahat ng produkto.';

  @override
  String alertsExpiringEmpty(int days) {
    return 'Walang mag-e-expire sa susunod na $days araw.';
  }

  @override
  String get alertsNegativeEmpty => 'Walang produktong may negatibong stock.';

  @override
  String get alertsNegativeExplain =>
      'Naging negatibo ang mga ito dahil may bentang offline sa higit sa isang telepono. Bilangin ang nasa estante at gamitin ang \"I-adjust ang stock\" para itama.';

  @override
  String get notificationChannelName => 'Mga alerto sa mababang stock';

  @override
  String get notificationChannelDescription =>
      'Sinasabi kapag paubos na ang isang produkto.';

  @override
  String notificationLowStockTitle(String name) {
    return 'Mababa ang stock: $name';
  }

  @override
  String notificationLowStockBody(int count) {
    return '$count na lang ang natitira. Oras nang mag-restock.';
  }

  @override
  String get restockTitle => 'Mungkahing i-restock';

  @override
  String get restockEmpty => 'Walang kailangang i-restock ngayon.';

  @override
  String restockNeeded(int count) {
    return 'Bumili ng $count';
  }

  @override
  String restockExplain(int multiplier) {
    return 'Ibinabalik ang bawat item sa $multiplier× ng antas ng alerto nito.';
  }

  @override
  String get restockShareTitle => 'Listahan ng ire-restock';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardTodaySales => 'Benta ngayon';

  @override
  String get dashboardTransactions => 'Mga transaksyon';

  @override
  String get dashboardProfit => 'Tantiyang tubo';

  @override
  String get dashboardSalesTrend => 'Takbo ng benta';

  @override
  String get dashboard7Days => '7 araw';

  @override
  String get dashboard30Days => '30 araw';

  @override
  String get dashboardTopSellers => 'Top 5 pinakamabenta';

  @override
  String get dashboardLowestStock => 'Pinakamababang stock';

  @override
  String get dashboardNoSales => 'Wala pang benta sa panahong ito.';

  @override
  String dashboardSold(int count) {
    return '$count nabenta';
  }

  @override
  String dashboardLowStockCount(int count) {
    return '$count produkto ang mababa ang stock';
  }

  @override
  String get reportsTitle => 'Mga report';

  @override
  String get reportsRange => 'Saklaw ng petsa';

  @override
  String get reportsSales => 'Benta';

  @override
  String get reportsBestSellers => 'Pinakamabenta';

  @override
  String get reportsInventory => 'Imbentaryo';

  @override
  String get reportsMovements => 'Galaw ng stock';

  @override
  String get reportsGroupDaily => 'Araw-araw';

  @override
  String get reportsGroupWeekly => 'Lingguhan';

  @override
  String get reportsGroupMonthly => 'Buwanan';

  @override
  String get reportsExport => 'I-export sa Excel';

  @override
  String get reportsPeriodCol => 'Panahon';

  @override
  String get reportsSalesCol => 'Benta';

  @override
  String get reportsCostCol => 'Puhunan';

  @override
  String get reportsProfitCol => 'Tubo';

  @override
  String get reportsTransactionsCol => 'Transaksyon';

  @override
  String get reportsItemsCol => 'Naibentang item';

  @override
  String get reportsQtyCol => 'Dami';

  @override
  String get reportsProductCol => 'Produkto';

  @override
  String get reportsTotalRow => 'Kabuuan';

  @override
  String get reportsValueCol => 'Halaga ng stock (puhunan)';

  @override
  String get reportsDateCol => 'Petsa';

  @override
  String get reportsTypeCol => 'Uri';

  @override
  String get reportsChangeCol => 'Pagbabago';

  @override
  String get reportsUserCol => 'Ni';

  @override
  String get reportsNoteCol => 'Tala';

  @override
  String get reportsReceiptCol => 'Resibo';

  @override
  String get reportsCashierCol => 'Kahera';

  @override
  String get reportsBarcodeCol => 'Barcode';

  @override
  String get reportsCategoryCol => 'Kategorya';

  @override
  String get reportsPriceCol => 'Presyo';

  @override
  String get reportsStockCol => 'Stock';

  @override
  String get reportsTransactionsSheet => 'Mga transaksyon';

  @override
  String get reportsEmpty => 'Walang datos sa saklaw na ito.';

  @override
  String reportsCapped(int count) {
    return 'Ang unang $count record lang ang kasama.';
  }

  @override
  String reportsRangeTooLong(int days) {
    return 'Pumili ng saklaw na $days araw o mas maikli.';
  }

  @override
  String get settingsTitle => 'Mga setting';

  @override
  String get settingsDefaultThreshold => 'Default na antas ng alerto sa stock';

  @override
  String get settingsSaved => 'Na-save ang mga setting.';

  @override
  String get settingsLanguage => 'Wika';

  @override
  String get settingsLanguageSystem => 'Default ng telepono';

  @override
  String get settingsSeedTitle => 'Sample na datos (debug lang)';

  @override
  String get settingsSeedButton => 'Magdagdag ng 20 sample na produkto';

  @override
  String settingsSeedDone(int count) {
    return 'Nakapagdagdag ng $count sample na produkto.';
  }

  @override
  String get settingsSeedExplain =>
      'Para sa pagsubok. Nilalaktawan ang mga may barcode na.';

  @override
  String get errorIndexNotReady =>
      'Inihahanda pa ang database. Pakisubukan muli makalipas ang ilang minuto. (Kung magpatuloy, i-deploy ang Firestore indexes; tingnan ang README.)';

  @override
  String get navMore => 'Iba pa';

  @override
  String get moreInventory => 'Imbentaryo at report';

  @override
  String get moreStore => 'Tindahan';

  @override
  String stockPillLow(int count) {
    return '$count na lang';
  }

  @override
  String get scanManualChip => 'I-type ang code';

  @override
  String scanCartCount(int count) {
    return '$count sa cart';
  }

  @override
  String get done => 'Tapos';

  @override
  String get undo => 'Ibalik';

  @override
  String get sellScan => 'I-scan';

  @override
  String get sellEmptyAction => 'Mag-scan ng produkto';

  @override
  String get cartCleared => 'Na-clear ang cart';

  @override
  String cartRemoved(String name) {
    return 'Inalis ang $name';
  }

  @override
  String dashboardVsYesterday(String delta) {
    return '$delta kumpara kahapon';
  }

  @override
  String get dashboardNoYesterday => 'Walang benta kahapon';

  @override
  String get alertsOutOfStock => 'Ubos na';

  @override
  String get alertsExpiringSoon => 'Malapit nang mag-expire';

  @override
  String get alertsRestockAction => 'I-restock';

  @override
  String productArchivedSnack(String name) {
    return 'Na-archive ang $name';
  }

  @override
  String get productsSelectHint =>
      'Pumili ng produkto para makita ang detalye.';

  @override
  String get reportsToday => 'Ngayon';

  @override
  String get reports7d => '7A';

  @override
  String get reports30d => '30A';

  @override
  String get reportsCustom => 'Iba pa';

  @override
  String get reportsExported => 'Handa nang ibahagi ang report.';

  @override
  String get settingsAppearance => 'Itsura';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Maliwanag';

  @override
  String get settingsThemeDark => 'Madilim';

  @override
  String get settingsFeedbackSection => 'Feedback';

  @override
  String get settingsHaptics => 'Pag-vibrate';

  @override
  String get settingsHapticsHint =>
      'Mag-vibrate sa pag-scan, pagdagdag sa cart at natapos na benta.';

  @override
  String get settingsScanSound => 'Tunog kapag na-scan';

  @override
  String get settingsStoreSection => 'Tindahan';

  @override
  String get settingsDesignGallery => 'Design gallery (debug)';

  @override
  String get designGalleryTitle => 'Design gallery';

  @override
  String get signOutUnsyncedTitle => 'May benta pang hindi na-sync';

  @override
  String get signOutUnsyncedMessage =>
      'May mga benta sa phone na ito na wala pa sa server. Nasi-sync lang ang mga ito habang naka-sign in ka rito. Kumonekta muna sa internet at maghintay sandali bago mag-sign out, o maiiwan ang mga ito sa phone hanggang mag-sign in ka ulit.';

  @override
  String get signOutAnyway => 'Mag-sign out pa rin';

  @override
  String lostSalesBanner(String receipts) {
    return 'Hindi na-save ang mga offline na bentang ito: $receipts. I-encode ulit at sabihan ang may-ari.';
  }

  @override
  String reportsSalesCapped(int count) {
    return 'Ang pinakabagong $count benta lang ang nasa Transactions sheet. Gumamit ng mas maikling saklaw para sa buong listahan.';
  }
}
