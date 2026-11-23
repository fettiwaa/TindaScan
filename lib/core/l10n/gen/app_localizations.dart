import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TindaScan'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of TindaScan?'**
  String get signOutConfirm;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHereYet;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that record.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'The data changed on another device. Please try again.'**
  String get errorConflict;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimit;

  /// No description provided for @errorSetupDone.
  ///
  /// In en, this message translates to:
  /// **'This store is already set up. Please sign in instead.'**
  String get errorSetupDone;

  /// No description provided for @errorDuplicateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode {barcode} is already used by another product.'**
  String errorDuplicateBarcode(String barcode);

  /// No description provided for @errorInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for {product}. Only {available} left.'**
  String errorInsufficientStock(String product, int available);

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is too weak.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorAccountDisabled;

  /// No description provided for @errorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errorRecentLogin;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @fieldInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get fieldInvalidEmail;

  /// No description provided for @fieldPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String fieldPasswordTooShort(int min);

  /// No description provided for @fieldPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get fieldPasswordMismatch;

  /// No description provided for @fieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long (maximum {max} characters).'**
  String fieldTooLong(int max);

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nameLabel;

  /// No description provided for @storeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeNameLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Sign in to your store.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first.'**
  String get enterEmailFirst;

  /// No description provided for @deactivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated. Please contact the store owner.'**
  String get deactivatedMessage;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your store'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the owner account. This can only be done once.'**
  String get setupSubtitle;

  /// No description provided for @setupButton.
  ///
  /// In en, this message translates to:
  /// **'Create owner account'**
  String get setupButton;

  /// No description provided for @accountIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not ready'**
  String get accountIssueTitle;

  /// No description provided for @accountIssueMessage.
  ///
  /// In en, this message translates to:
  /// **'You are signed in, but this account has no store profile. Please ask the store owner to create your account again.'**
  String get accountIssueMessage;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @menuStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts'**
  String get menuStaff;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get menuProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts'**
  String get staffTitle;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff yet. Tap \"Add staff\" to create one.'**
  String get staffEmpty;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// No description provided for @staffNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New staff account'**
  String get staffNewTitle;

  /// No description provided for @staffCreated.
  ///
  /// In en, this message translates to:
  /// **'Staff account created.'**
  String get staffCreated;

  /// No description provided for @staffActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get staffActive;

  /// No description provided for @staffInactive.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get staffInactive;

  /// No description provided for @staffDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String staffDeactivateTitle(String name);

  /// No description provided for @staffDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be signed out right away and can no longer use the app.'**
  String get staffDeactivateMessage;

  /// No description provided for @staffDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get staffDeactivate;

  /// No description provided for @staffActivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get staffActivate;

  /// No description provided for @staffPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Give this password to the staff member in person. They can change it later with \"Forgot password\".'**
  String get staffPasswordHint;

  /// No description provided for @firebaseNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured'**
  String get firebaseNotConfiguredTitle;

  /// No description provided for @firebaseNotConfiguredMessage.
  ///
  /// In en, this message translates to:
  /// **'Run the app with --dart-define-from-file=env/dev.json. See the README for setup steps.'**
  String get firebaseNotConfiguredMessage;

  /// No description provided for @connectionIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the store server'**
  String get connectionIssueTitle;

  /// No description provided for @connectionIssueMessage.
  ///
  /// In en, this message translates to:
  /// **'TindaScan could not check whether this store is set up yet.'**
  String get connectionIssueMessage;

  /// No description provided for @connectionIssuePermissionHint.
  ///
  /// In en, this message translates to:
  /// **'The server refused the request. If this Firebase project is new, deploy the security rules first (see \"Deploy rules and indexes\" in the README) and check that FIREBASE_PROJECT_ID in env/dev.json matches the project.'**
  String get connectionIssuePermissionHint;

  /// No description provided for @errorProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{product} is no longer available.'**
  String errorProductUnavailable(String product);

  /// No description provided for @errorPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'The price of {product} changed. The cart was updated; please check the total.'**
  String errorPriceChanged(String product);

  /// No description provided for @errorInsufficientPayment.
  ///
  /// In en, this message translates to:
  /// **'The amount received is less than the total.'**
  String get errorInsufficientPayment;

  /// No description provided for @errorExport.
  ///
  /// In en, this message translates to:
  /// **'Could not create the report file.'**
  String get errorExport;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline: changes will sync later'**
  String get offlineBanner;

  /// No description provided for @menuSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get menuSell;

  /// No description provided for @menuProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get menuProducts;

  /// No description provided for @menuDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get menuDashboard;

  /// No description provided for @menuAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get menuAlerts;

  /// No description provided for @menuRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock list'**
  String get menuRestock;

  /// No description provided for @menuReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get menuReports;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or barcode'**
  String get productsSearchHint;

  /// No description provided for @productsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get productsEmpty;

  /// No description provided for @productsLowStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsLowStockFilter;

  /// No description provided for @productsArchivedFilter.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get productsArchivedFilter;

  /// No description provided for @productsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsAllCategories;

  /// No description provided for @productAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productAdd;

  /// No description provided for @productNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get productNewTitle;

  /// No description provided for @productEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productEditTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @productBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productBarcodeLabel;

  /// No description provided for @productNoBarcode.
  ///
  /// In en, this message translates to:
  /// **'No barcode: generate a code'**
  String get productNoBarcode;

  /// No description provided for @productScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get productScanBarcode;

  /// No description provided for @productCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategoryLabel;

  /// No description provided for @productPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling price (₱)'**
  String get productPriceLabel;

  /// No description provided for @productCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost price (₱)'**
  String get productCostLabel;

  /// No description provided for @productInitialStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting stock'**
  String get productInitialStockLabel;

  /// No description provided for @productThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert at'**
  String get productThresholdLabel;

  /// No description provided for @productExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date (optional)'**
  String get productExpiryLabel;

  /// No description provided for @productNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get productNoExpiry;

  /// No description provided for @productPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get productPickDate;

  /// No description provided for @productSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved.'**
  String get productSaved;

  /// No description provided for @productPriceBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Note: selling price is below cost.'**
  String get productPriceBelowCost;

  /// No description provided for @productStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String productStockCount(int count);

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// No description provided for @productCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get productCost;

  /// No description provided for @productProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit per item'**
  String get productProfit;

  /// No description provided for @productExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String productExpires(String date);

  /// No description provided for @productExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get productExpired;

  /// No description provided for @productArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String productArchiveTitle(String name);

  /// No description provided for @productArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden from selling. Past sales stay unchanged, and you can restore it later.'**
  String get productArchiveMessage;

  /// No description provided for @productArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get productArchivedBadge;

  /// No description provided for @productAdjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get productAdjustStock;

  /// No description provided for @productHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get productHistory;

  /// No description provided for @productInternalCode.
  ///
  /// In en, this message translates to:
  /// **'Internal code (no printed barcode)'**
  String get productInternalCode;

  /// No description provided for @productInitialStockNote.
  ///
  /// In en, this message translates to:
  /// **'Initial stock'**
  String get productInitialStockNote;

  /// No description provided for @productLowStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get productLowStockBadge;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @productNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No product has the barcode {barcode}.'**
  String productNotFoundMessage(String barcode);

  /// No description provided for @productAddThis.
  ///
  /// In en, this message translates to:
  /// **'Add this product'**
  String get productAddThis;

  /// No description provided for @productStockNote.
  ///
  /// In en, this message translates to:
  /// **'To change stock later, use \"Adjust stock\" so every change is recorded.'**
  String get productStockNote;

  /// No description provided for @fieldInvalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers and dashes only.'**
  String get fieldInvalidBarcode;

  /// No description provided for @fieldInvalidMoney.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 12.50.'**
  String get fieldInvalidMoney;

  /// No description provided for @fieldInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 0 to {max}.'**
  String fieldInvalidQuantity(int max);

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categoryNoodles.
  ///
  /// In en, this message translates to:
  /// **'Noodles'**
  String get categoryNoodles;

  /// No description provided for @categoryCannedGoods.
  ///
  /// In en, this message translates to:
  /// **'Canned goods'**
  String get categoryCannedGoods;

  /// No description provided for @categoryCondiments.
  ///
  /// In en, this message translates to:
  /// **'Condiments'**
  String get categoryCondiments;

  /// No description provided for @categoryRiceGrains.
  ///
  /// In en, this message translates to:
  /// **'Rice & grains'**
  String get categoryRiceGrains;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Milk & dairy'**
  String get categoryDairy;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryPersonalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal care'**
  String get categoryPersonalCare;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get categoryFrozen;

  /// No description provided for @categoryOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get categoryOthers;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scannerTitle;

  /// No description provided for @scannerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Camera barcode scanner'**
  String get scannerSemantics;

  /// No description provided for @scannerTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Turn flashlight on'**
  String get scannerTorchOn;

  /// No description provided for @scannerTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn flashlight off'**
  String get scannerTorchOff;

  /// No description provided for @scannerPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'TindaScan needs the camera to scan barcodes.'**
  String get scannerPermissionNeeded;

  /// No description provided for @scannerAllowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get scannerAllowCamera;

  /// No description provided for @scannerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Turn it on in Settings, or type the barcode instead.'**
  String get scannerPermissionDenied;

  /// No description provided for @scannerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get scannerOpenSettings;

  /// No description provided for @scannerError.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Type the barcode instead.'**
  String get scannerError;

  /// No description provided for @scannerManualHint.
  ///
  /// In en, this message translates to:
  /// **'Type barcode'**
  String get scannerManualHint;

  /// No description provided for @scannerManualSubmit.
  ///
  /// In en, this message translates to:
  /// **'Use code'**
  String get scannerManualSubmit;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode'**
  String get scannerHint;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellTitle;

  /// No description provided for @sellSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search product to add'**
  String get sellSearchHint;

  /// No description provided for @sellCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Scan or search a product to start a sale.'**
  String get sellCartEmpty;

  /// No description provided for @sellTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sellTotal;

  /// No description provided for @sellCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge {amount}'**
  String sellCharge(String amount);

  /// No description provided for @sellItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String sellItems(int count);

  /// No description provided for @sellShowScanner.
  ///
  /// In en, this message translates to:
  /// **'Show scanner'**
  String get sellShowScanner;

  /// No description provided for @sellHideScanner.
  ///
  /// In en, this message translates to:
  /// **'Hide scanner'**
  String get sellHideScanner;

  /// No description provided for @sellAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String sellAdded(String name);

  /// No description provided for @sellRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sellRemove;

  /// No description provided for @sellIncrease.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get sellIncrease;

  /// No description provided for @sellDecrease.
  ///
  /// In en, this message translates to:
  /// **'Remove one'**
  String get sellDecrease;

  /// No description provided for @sellDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this sale?'**
  String get sellDiscardTitle;

  /// No description provided for @sellDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'The items in the cart will be removed.'**
  String get sellDiscardMessage;

  /// No description provided for @sellClearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get sellClearCart;

  /// No description provided for @sellOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get sellOutOfStock;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get paymentTitle;

  /// No description provided for @paymentTendered.
  ///
  /// In en, this message translates to:
  /// **'Amount received (₱)'**
  String get paymentTendered;

  /// No description provided for @paymentChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get paymentChange;

  /// No description provided for @paymentExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get paymentExact;

  /// No description provided for @paymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm sale'**
  String get paymentConfirm;

  /// No description provided for @paymentOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. The sale will be saved on this phone and synced later.'**
  String get paymentOfflineNote;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt #{number}'**
  String receiptNo(String number);

  /// No description provided for @receiptCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier: {name}'**
  String receiptCashier(String name);

  /// No description provided for @receiptCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get receiptCash;

  /// No description provided for @receiptNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get receiptNewSale;

  /// No description provided for @receiptThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Come again.'**
  String get receiptThanks;

  /// No description provided for @receiptOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline: will sync when online'**
  String get receiptOffline;

  /// No description provided for @receiptSaleComplete.
  ///
  /// In en, this message translates to:
  /// **'Sale complete'**
  String get receiptSaleComplete;

  /// No description provided for @stockAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get stockAdjustTitle;

  /// No description provided for @stockTypeRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get stockTypeRestock;

  /// No description provided for @stockTypeSpoilage.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get stockTypeSpoilage;

  /// No description provided for @stockTypeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get stockTypeAdjustment;

  /// No description provided for @stockQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get stockQuantityLabel;

  /// No description provided for @stockCorrectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual count on the shelf'**
  String get stockCorrectionLabel;

  /// No description provided for @stockNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get stockNoteLabel;

  /// No description provided for @stockCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current stock: {count}'**
  String stockCurrent(int count);

  /// No description provided for @stockAfter.
  ///
  /// In en, this message translates to:
  /// **'After saving: {count}'**
  String stockAfter(int count);

  /// No description provided for @stockSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock updated.'**
  String get stockSaved;

  /// No description provided for @stockNoChange.
  ///
  /// In en, this message translates to:
  /// **'The count is the same as the current stock.'**
  String get stockNoChange;

  /// No description provided for @stockHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stock changes yet.'**
  String get stockHistoryEmpty;

  /// No description provided for @movementRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get movementRestock;

  /// No description provided for @movementSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get movementSale;

  /// No description provided for @movementSpoilage.
  ///
  /// In en, this message translates to:
  /// **'Damaged / spoiled'**
  String get movementSpoilage;

  /// No description provided for @movementAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get movementAdjustment;

  /// No description provided for @movementBy.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String movementBy(String name);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get alertsLowStock;

  /// No description provided for @alertsExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get alertsExpiring;

  /// No description provided for @alertsNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get alertsNegative;

  /// No description provided for @alertsLowStockEmpty.
  ///
  /// In en, this message translates to:
  /// **'All products are well stocked.'**
  String get alertsLowStockEmpty;

  /// No description provided for @alertsExpiringEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing expires in the next {days} days.'**
  String alertsExpiringEmpty(int days);

  /// No description provided for @alertsNegativeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products have negative stock.'**
  String get alertsNegativeEmpty;

  /// No description provided for @alertsNegativeExplain.
  ///
  /// In en, this message translates to:
  /// **'These went below zero because sales were made offline on more than one phone. Count the shelf and use \"Adjust stock\" to correct them.'**
  String get alertsNegativeExplain;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alerts'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Tells you when a product is running low.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationLowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock: {name}'**
  String notificationLowStockTitle(String name);

  /// No description provided for @notificationLowStockBody.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left. Time to restock.'**
  String notificationLowStockBody(int count);

  /// No description provided for @restockTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested restock'**
  String get restockTitle;

  /// No description provided for @restockEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restock right now.'**
  String get restockEmpty;

  /// No description provided for @restockNeeded.
  ///
  /// In en, this message translates to:
  /// **'Buy {count}'**
  String restockNeeded(int count);

  /// No description provided for @restockExplain.
  ///
  /// In en, this message translates to:
  /// **'Each item is brought back up to {multiplier}× its low-stock alert level.'**
  String restockExplain(int multiplier);

  /// No description provided for @restockShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Restock list'**
  String get restockShareTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get dashboardTodaySales;

  /// No description provided for @dashboardTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get dashboardTransactions;

  /// No description provided for @dashboardProfit.
  ///
  /// In en, this message translates to:
  /// **'Est. profit'**
  String get dashboardProfit;

  /// No description provided for @dashboardSalesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get dashboardSalesTrend;

  /// No description provided for @dashboard7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get dashboard7Days;

  /// No description provided for @dashboard30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get dashboard30Days;

  /// No description provided for @dashboardTopSellers.
  ///
  /// In en, this message translates to:
  /// **'Top 5 best-sellers'**
  String get dashboardTopSellers;

  /// No description provided for @dashboardLowestStock.
  ///
  /// In en, this message translates to:
  /// **'Lowest stock'**
  String get dashboardLowestStock;

  /// No description provided for @dashboardNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period yet.'**
  String get dashboardNoSales;

  /// No description provided for @dashboardSold.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String dashboardSold(int count);

  /// No description provided for @dashboardLowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products are low on stock'**
  String dashboardLowStockCount(int count);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get reportsRange;

  /// No description provided for @reportsSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportsSales;

  /// No description provided for @reportsBestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best-sellers'**
  String get reportsBestSellers;

  /// No description provided for @reportsInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get reportsInventory;

  /// No description provided for @reportsMovements.
  ///
  /// In en, this message translates to:
  /// **'Stock movements'**
  String get reportsMovements;

  /// No description provided for @reportsGroupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reportsGroupDaily;

  /// No description provided for @reportsGroupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsGroupWeekly;

  /// No description provided for @reportsGroupMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsGroupMonthly;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get reportsExport;

  /// No description provided for @reportsPeriodCol.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsPeriodCol;

  /// No description provided for @reportsSalesCol.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportsSalesCol;

  /// No description provided for @reportsCostCol.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get reportsCostCol;

  /// No description provided for @reportsProfitCol.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get reportsProfitCol;

  /// No description provided for @reportsTransactionsCol.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsTransactionsCol;

  /// No description provided for @reportsItemsCol.
  ///
  /// In en, this message translates to:
  /// **'Items sold'**
  String get reportsItemsCol;

  /// No description provided for @reportsQtyCol.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get reportsQtyCol;

  /// No description provided for @reportsProductCol.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get reportsProductCol;

  /// No description provided for @reportsTotalRow.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsTotalRow;

  /// No description provided for @reportsValueCol.
  ///
  /// In en, this message translates to:
  /// **'Stock value (cost)'**
  String get reportsValueCol;

  /// No description provided for @reportsDateCol.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsDateCol;

  /// No description provided for @reportsTypeCol.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reportsTypeCol;

  /// No description provided for @reportsChangeCol.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get reportsChangeCol;

  /// No description provided for @reportsUserCol.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get reportsUserCol;

  /// No description provided for @reportsNoteCol.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get reportsNoteCol;

  /// No description provided for @reportsReceiptCol.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get reportsReceiptCol;

  /// No description provided for @reportsCashierCol.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get reportsCashierCol;

  /// No description provided for @reportsBarcodeCol.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get reportsBarcodeCol;

  /// No description provided for @reportsCategoryCol.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsCategoryCol;

  /// No description provided for @reportsPriceCol.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get reportsPriceCol;

  /// No description provided for @reportsStockCol.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get reportsStockCol;

  /// No description provided for @reportsTransactionsSheet.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsTransactionsSheet;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data for this range.'**
  String get reportsEmpty;

  /// No description provided for @reportsCapped.
  ///
  /// In en, this message translates to:
  /// **'Only the first {count} records are included.'**
  String reportsCapped(int count);

  /// No description provided for @reportsRangeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Pick a range of {days} days or less.'**
  String reportsRangeTooLong(int days);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDefaultThreshold.
  ///
  /// In en, this message translates to:
  /// **'Default low-stock alert level'**
  String get settingsDefaultThreshold;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample data (debug builds only)'**
  String get settingsSeedTitle;

  /// No description provided for @settingsSeedButton.
  ///
  /// In en, this message translates to:
  /// **'Add 20 sample products'**
  String get settingsSeedButton;

  /// No description provided for @settingsSeedDone.
  ///
  /// In en, this message translates to:
  /// **'Added {count} sample products.'**
  String settingsSeedDone(int count);

  /// No description provided for @settingsSeedExplain.
  ///
  /// In en, this message translates to:
  /// **'For testing. Products whose barcode already exists are skipped.'**
  String get settingsSeedExplain;

  /// No description provided for @errorIndexNotReady.
  ///
  /// In en, this message translates to:
  /// **'The database is still being prepared. Please try again in a few minutes. (If this continues, deploy the Firestore indexes; see the README.)'**
  String get errorIndexNotReady;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @moreInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory & reports'**
  String get moreInventory;

  /// No description provided for @moreStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get moreStore;

  /// No description provided for @stockPillLow.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String stockPillLow(int count);

  /// No description provided for @scanManualChip.
  ///
  /// In en, this message translates to:
  /// **'Type code'**
  String get scanManualChip;

  /// No description provided for @scanCartCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in cart'**
  String scanCartCount(int count);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @sellScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get sellScan;

  /// No description provided for @sellEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Scan a product'**
  String get sellEmptyAction;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @cartRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String cartRemoved(String name);

  /// No description provided for @dashboardVsYesterday.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs yesterday'**
  String dashboardVsYesterday(String delta);

  /// No description provided for @dashboardNoYesterday.
  ///
  /// In en, this message translates to:
  /// **'No sales yesterday'**
  String get dashboardNoYesterday;

  /// No description provided for @alertsOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get alertsOutOfStock;

  /// No description provided for @alertsExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get alertsExpiringSoon;

  /// No description provided for @alertsRestockAction.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get alertsRestockAction;

  /// No description provided for @productArchivedSnack.
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String productArchivedSnack(String name);

  /// No description provided for @productsSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a product to see its details.'**
  String get productsSelectHint;

  /// No description provided for @reportsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsToday;

  /// No description provided for @reports7d.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get reports7d;

  /// No description provided for @reports30d.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get reports30d;

  /// No description provided for @reportsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsCustom;

  /// No description provided for @reportsExported.
  ///
  /// In en, this message translates to:
  /// **'Report ready to share.'**
  String get reportsExported;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsFeedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settingsFeedbackSection;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on scan, add to cart and completed sales.'**
  String get settingsHapticsHint;

  /// No description provided for @settingsScanSound.
  ///
  /// In en, this message translates to:
  /// **'Sound on successful scan'**
  String get settingsScanSound;

  /// No description provided for @settingsStoreSection.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get settingsStoreSection;

  /// No description provided for @settingsDesignGallery.
  ///
  /// In en, this message translates to:
  /// **'Design gallery (debug)'**
  String get settingsDesignGallery;

  /// No description provided for @designGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Design gallery'**
  String get designGalleryTitle;

  /// No description provided for @signOutUnsyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'Some sales haven\'t synced yet'**
  String get signOutUnsyncedTitle;

  /// No description provided for @signOutUnsyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'This phone has sales that are not on the server yet. They only sync while you are signed in here. Connect to the internet and wait a moment before signing out, or they will wait on this phone until you sign in again.'**
  String get signOutUnsyncedMessage;

  /// No description provided for @signOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get signOutAnyway;

  /// No description provided for @lostSalesBanner.
  ///
  /// In en, this message translates to:
  /// **'These offline sales were not saved: {receipts}. Re-enter them and tell the owner.'**
  String lostSalesBanner(String receipts);

  /// No description provided for @reportsSalesCapped.
  ///
  /// In en, this message translates to:
  /// **'The Transactions sheet has only the latest {count} sales. Use a shorter range for the full list.'**
  String reportsSalesCapped(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
