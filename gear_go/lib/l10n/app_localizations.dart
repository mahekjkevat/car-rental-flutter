import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @yourUltimateCarRentalExperience.
  ///
  /// In en, this message translates to:
  /// **'Your Ultimate Car Rental Experience'**
  String get yourUltimateCarRentalExperience;

  /// No description provided for @ourStory.
  ///
  /// In en, this message translates to:
  /// **'Our Story'**
  String get ourStory;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Feel free to reach out to us for any assistance.'**
  String get welcomeMessage;

  /// No description provided for @aboutUsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsSectionTitle;

  /// No description provided for @connectWithUs.
  ///
  /// In en, this message translates to:
  /// **'Connect With Us'**
  String get connectWithUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @ourFeatures.
  ///
  /// In en, this message translates to:
  /// **'Our Features'**
  String get ourFeatures;

  /// No description provided for @luxuryFleet.
  ///
  /// In en, this message translates to:
  /// **'Luxury Fleet'**
  String get luxuryFleet;

  /// No description provided for @luxuryFleetDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose from premium sedans, SUVs, and sports cars.'**
  String get luxuryFleetDesc;

  /// No description provided for @easyBooking.
  ///
  /// In en, this message translates to:
  /// **'Easy Booking'**
  String get easyBooking;

  /// No description provided for @easyBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Book your car in seconds with our intuitive app.'**
  String get easyBookingDesc;

  /// No description provided for @securePayments.
  ///
  /// In en, this message translates to:
  /// **'Secure Payments'**
  String get securePayments;

  /// No description provided for @securePaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Safe transactions with trusted payment gateways.'**
  String get securePaymentsDesc;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get support;

  /// No description provided for @supportDesc.
  ///
  /// In en, this message translates to:
  /// **'Our team is here to help anytime, anywhere.'**
  String get supportDesc;

  /// No description provided for @sleekInterface.
  ///
  /// In en, this message translates to:
  /// **'Sleek Interface'**
  String get sleekInterface;

  /// No description provided for @sleekInterfaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Navigate effortlessly with our user-friendly design.'**
  String get sleekInterfaceDesc;

  /// No description provided for @exclusivePerks.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Perks'**
  String get exclusivePerks;

  /// No description provided for @exclusivePerksDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock special offers and loyalty rewards.'**
  String get exclusivePerksDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @yourPrivacyMatters.
  ///
  /// In en, this message translates to:
  /// **'Your Privacy Matters'**
  String get yourPrivacyMatters;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date: January 1, 2025'**
  String get effectiveDate;

  /// No description provided for @section1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get section1Title;

  /// No description provided for @section1Content.
  ///
  /// In en, this message translates to:
  /// **'We collect information from you when you register on our app, place an order, subscribe to our newsletter, or interact with us in other ways. The types of information we may collect include your name, email address, phone number, and payment information.'**
  String get section1Content;

  /// No description provided for @section2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get section2Title;

  /// No description provided for @section2Content.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect to provide, maintain, and improve our services, process transactions, communicate with you, and send you updates and promotional materials.'**
  String get section2Content;

  /// No description provided for @section3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Security'**
  String get section3Title;

  /// No description provided for @section3Content.
  ///
  /// In en, this message translates to:
  /// **'We implement a variety of security measures to maintain the safety of your personal information. However, no method of transmission over the internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security.'**
  String get section3Content;

  /// No description provided for @section4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Your Rights'**
  String get section4Title;

  /// No description provided for @section4Content.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, correct, or delete your personal information. You can also object to the processing of your data in certain circumstances. To exercise these rights, please contact us using the information provided below.'**
  String get section4Content;

  /// No description provided for @section5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Changes to This Privacy Policy'**
  String get section5Title;

  /// No description provided for @section5Content.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new Privacy Policy on this page and updating the effective date. We encourage you to review this policy periodically for any updates.'**
  String get section5Content;

  /// No description provided for @section6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact Us'**
  String get section6Title;

  /// No description provided for @section6Content.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at support@example.com.'**
  String get section6Content;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for visiting LuxeRide’s Help Center!'**
  String get thankYou;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome_back;

  /// No description provided for @sign_in_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get sign_in_to_continue;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get no_account;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alert_please_fill.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both email and password fields.'**
  String get alert_please_fill;

  /// No description provided for @alert_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get alert_valid_email;

  /// No description provided for @alert_password_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get alert_password_length;

  /// No description provided for @alert_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get alert_invalid_email;

  /// No description provided for @alert_reset_sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get alert_reset_sent;

  /// No description provided for @alert_failed_send.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email: '**
  String get alert_failed_send;

  /// No description provided for @error_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get error_user_not_found;

  /// No description provided for @error_wrong_password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get error_wrong_password;

  /// No description provided for @error_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get error_invalid_email;

  /// No description provided for @error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error_occurred;

  /// No description provided for @error_unexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get error_unexpected;

  /// No description provided for @alert_enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get alert_enter_valid_email;

  /// No description provided for @error_failed_send.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get error_failed_send;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fillDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details'**
  String get fillDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get pleaseFillAllFields;

  /// No description provided for @nameCannotContainNumbers.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain numbers.'**
  String get nameCannotContainNumbers;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get enterValidEmail;

  /// No description provided for @passwordMustBeAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMustBeAtLeast6;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// No description provided for @pleaseEnterPinCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter your pin code'**
  String get pleaseEnterPinCode;

  /// No description provided for @enterValidPinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit pin code'**
  String get enterValidPinCode;

  /// No description provided for @pleaseEnterMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get pleaseEnterMobile;

  /// No description provided for @enterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get enterValidMobile;

  /// No description provided for @pleaseSelectState.
  ///
  /// In en, this message translates to:
  /// **'Please select a state'**
  String get pleaseSelectState;

  /// No description provided for @pleaseSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectCountry;

  /// No description provided for @licenseNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: 2 uppercase letters followed by 13 digits'**
  String get licenseNumberFormat;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License No (e.x ZZ12345678901234)'**
  String get licenseNumber;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent! Check your inbox.'**
  String get verificationEmailSent;

  /// No description provided for @error_user_already_in_use.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get error_user_already_in_use;

  /// No description provided for @error_password_too_weak.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get error_password_too_weak;

  /// No description provided for @verificationNotSent.
  ///
  /// In en, this message translates to:
  /// **'Email not verified. Check your inbox or spam.'**
  String get verificationNotSent;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found. Please sign up again.'**
  String get noUserFound;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get pinCode;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully!'**
  String get accountCreatedTitle;

  /// No description provided for @accountCreatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our app! Your account has been created.'**
  String get accountCreatedDesc;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @needAssistance.
  ///
  /// In en, this message translates to:
  /// **'Need Assistance?'**
  String get needAssistance;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqTitle;

  /// No description provided for @question1.
  ///
  /// In en, this message translates to:
  /// **'How do I reset my password?'**
  String get question1;

  /// No description provided for @answer1.
  ///
  /// In en, this message translates to:
  /// **'Go to the login page and tap \"Forgot Password?\". Follow the instructions sent to your email to reset it.'**
  String get answer1;

  /// No description provided for @question2.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get question2;

  /// No description provided for @answer2.
  ///
  /// In en, this message translates to:
  /// **'Reach us via email at mahekjkevat@gmail.com, call us, or use the live chat feature in the app.'**
  String get answer2;

  /// No description provided for @question3.
  ///
  /// In en, this message translates to:
  /// **'What payment methods are accepted?'**
  String get question3;

  /// No description provided for @answer3.
  ///
  /// In en, this message translates to:
  /// **'We support major credit cards, PayPal, and bank transfers for secure payments.'**
  String get answer3;

  /// No description provided for @question4.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get question4;

  /// No description provided for @answer4.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Settings > Account to edit your profile details, including name and contact info.'**
  String get answer4;

  /// No description provided for @question5.
  ///
  /// In en, this message translates to:
  /// **'Where are the terms and conditions?'**
  String get question5;

  /// No description provided for @answer5.
  ///
  /// In en, this message translates to:
  /// **'Find them in the Settings menu or at the bottom of our app under \"Legal\".'**
  String get answer5;

  /// No description provided for @stillHaveQuestions.
  ///
  /// In en, this message translates to:
  /// **'Still Have Questions?'**
  String get stillHaveQuestions;

  /// No description provided for @ourTeamHelp.
  ///
  /// In en, this message translates to:
  /// **'Our team is here to help you 24/7.'**
  String get ourTeamHelp;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @myRentalRecords.
  ///
  /// In en, this message translates to:
  /// **'My Rental Records'**
  String get myRentalRecords;

  /// No description provided for @searchBookings.
  ///
  /// In en, this message translates to:
  /// **'Search Bookings'**
  String get searchBookings;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for'**
  String get noResultsFor;

  /// No description provided for @noRentalsFound.
  ///
  /// In en, this message translates to:
  /// **'No rentals found'**
  String get noRentalsFound;

  /// No description provided for @bookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked on : '**
  String get bookedOn;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price : '**
  String get price;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From : '**
  String get from;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get pleaseLogin;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @yourStory.
  ///
  /// In en, this message translates to:
  /// **'I love sharing my car adventures! What’s your story?'**
  String get yourStory;

  /// No description provided for @myRentals.
  ///
  /// In en, this message translates to:
  /// **'My Rentals'**
  String get myRentals;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @activeBooking.
  ///
  /// In en, this message translates to:
  /// **'Active Booking'**
  String get activeBooking;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirm;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose a Language'**
  String get chooseLanguage;

  /// No description provided for @selectYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectYourLanguage;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Your Ultimate\nCar Rental Experience'**
  String get title;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our car rental service! Choose from a wide range of vehicles to suit your needs. Enjoy a seamless booking experience and drive away with your perfect ride today!'**
  String get subtitle;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started, Sign Up'**
  String get signup;

  /// No description provided for @signin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get signin;

  /// No description provided for @add_car.
  ///
  /// In en, this message translates to:
  /// **'Add New Car - NEW'**
  String get add_car;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Car Rental'**
  String get appTitle;

  /// No description provided for @english_text.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english_text;

  /// No description provided for @hindi_text.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi_text;

  /// No description provided for @gujarati_text.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati_text;

  /// No description provided for @topic_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get topic_intro_title;

  /// No description provided for @topic_intro_subtitle.
  ///
  /// In en, this message translates to:
  /// **'This is a brief overview.'**
  String get topic_intro_subtitle;

  /// No description provided for @topic_intro_details.
  ///
  /// In en, this message translates to:
  /// **'This lease agreement (\'Agreement\') is entered into by and between the lessor and the lessee for the rental of a vehicle.'**
  String get topic_intro_details;

  /// No description provided for @topic_def_title.
  ///
  /// In en, this message translates to:
  /// **'Definitions'**
  String get topic_def_title;

  /// No description provided for @topic_def_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Key terms and their meanings.'**
  String get topic_def_subtitle;

  /// No description provided for @topic_def_details.
  ///
  /// In en, this message translates to:
  /// **'Key terms used in this document, such as \'Vehicle,\' \'Lessor,\' and \'Lessee,\' are defined to ensure clarity and mutual understanding.'**
  String get topic_def_details;

  /// No description provided for @topic_agreement_title.
  ///
  /// In en, this message translates to:
  /// **'The Agreement'**
  String get topic_agreement_title;

  /// No description provided for @topic_agreement_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Mutual consent and responsibilities.'**
  String get topic_agreement_subtitle;

  /// No description provided for @topic_agreement_details.
  ///
  /// In en, this message translates to:
  /// **'Both parties agree to the terms and conditions outlined in this document, which govern the rental and use of the vehicle.'**
  String get topic_agreement_details;

  /// No description provided for @topic_usage_title.
  ///
  /// In en, this message translates to:
  /// **'Usage of the Vehicle'**
  String get topic_usage_title;

  /// No description provided for @topic_usage_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules and restrictions.'**
  String get topic_usage_subtitle;

  /// No description provided for @topic_usage_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee agrees to use the vehicle only for lawful purposes and not to use it for any illegal activities or modify it without permission.'**
  String get topic_usage_details;

  /// No description provided for @topic_term_title.
  ///
  /// In en, this message translates to:
  /// **'Rental Term'**
  String get topic_term_title;

  /// No description provided for @topic_term_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Duration of the lease.'**
  String get topic_term_subtitle;

  /// No description provided for @topic_term_details.
  ///
  /// In en, this message translates to:
  /// **'The rental term will begin on the date of pickup and end on the date specified in the rental reservation.'**
  String get topic_term_details;

  /// No description provided for @topic_delivery_title.
  ///
  /// In en, this message translates to:
  /// **'Delivery and Condition'**
  String get topic_delivery_title;

  /// No description provided for @topic_delivery_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection and acceptance.'**
  String get topic_delivery_subtitle;

  /// No description provided for @topic_delivery_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee acknowledges receiving the vehicle in good working condition and agrees to return it in the same state, subject to normal wear and tear.'**
  String get topic_delivery_details;

  /// No description provided for @topic_rental_title.
  ///
  /// In en, this message translates to:
  /// **'Rental Charges'**
  String get topic_rental_title;

  /// No description provided for @topic_rental_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment details.'**
  String get topic_rental_subtitle;

  /// No description provided for @topic_rental_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee agrees to pay all rental charges, including a per-day fee, mileage charges (if applicable), and any other associated costs.'**
  String get topic_rental_details;

  /// No description provided for @topic_theft_title.
  ///
  /// In en, this message translates to:
  /// **'Theft and Damages'**
  String get topic_theft_title;

  /// No description provided for @topic_theft_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Liability and responsibility.'**
  String get topic_theft_subtitle;

  /// No description provided for @topic_theft_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee is fully responsible for the vehicle during the rental term and will be liable for any damages or theft that occur.'**
  String get topic_theft_details;

  /// No description provided for @topic_violation_title.
  ///
  /// In en, this message translates to:
  /// **'Violations'**
  String get topic_violation_title;

  /// No description provided for @topic_violation_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fines and legal consequences.'**
  String get topic_violation_subtitle;

  /// No description provided for @topic_violation_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee will be responsible for all traffic violations, parking fines, and other penalties incurred during the rental period.'**
  String get topic_violation_details;

  /// No description provided for @topic_insurance_title.
  ///
  /// In en, this message translates to:
  /// **'Insurance Coverage'**
  String get topic_insurance_title;

  /// No description provided for @topic_insurance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Protection against unforeseen events.'**
  String get topic_insurance_subtitle;

  /// No description provided for @topic_insurance_details.
  ///
  /// In en, this message translates to:
  /// **'Insurance coverage details are provided, outlining the protections for the vehicle and the lessee during the rental period.'**
  String get topic_insurance_details;

  /// No description provided for @topic_maintenance_title.
  ///
  /// In en, this message translates to:
  /// **'Maintenance and Repairs'**
  String get topic_maintenance_title;

  /// No description provided for @topic_maintenance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities of both parties.'**
  String get topic_maintenance_subtitle;

  /// No description provided for @topic_maintenance_details.
  ///
  /// In en, this message translates to:
  /// **'The lessor is responsible for routine maintenance, while the lessee should promptly report any issues or damage to the vehicle.'**
  String get topic_maintenance_details;

  /// No description provided for @topic_obligations_title.
  ///
  /// In en, this message translates to:
  /// **'Lessee\'s Obligations'**
  String get topic_obligations_title;

  /// No description provided for @topic_obligations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Duties and responsibilities.'**
  String get topic_obligations_subtitle;

  /// No description provided for @topic_obligations_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee must operate the vehicle responsibly, keep it clean, and follow all terms of this agreement.'**
  String get topic_obligations_details;

  /// No description provided for @topic_termination_title.
  ///
  /// In en, this message translates to:
  /// **'Agreement Termination'**
  String get topic_termination_title;

  /// No description provided for @topic_termination_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Conditions for ending the lease.'**
  String get topic_termination_subtitle;

  /// No description provided for @topic_termination_details.
  ///
  /// In en, this message translates to:
  /// **'This agreement may be terminated by either party under specific conditions, such as a breach of contract or at the end of the rental term.'**
  String get topic_termination_details;

  /// No description provided for @topic_return_title.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Return'**
  String get topic_return_title;

  /// No description provided for @topic_return_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Procedure for returning the vehicle.'**
  String get topic_return_subtitle;

  /// No description provided for @topic_return_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee must return the vehicle to the specified location on or before the agreed-upon return date and time.'**
  String get topic_return_details;

  /// No description provided for @topic_confidentiality_title.
  ///
  /// In en, this message translates to:
  /// **'Confidentiality'**
  String get topic_confidentiality_title;

  /// No description provided for @topic_confidentiality_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Protection of private information.'**
  String get topic_confidentiality_subtitle;

  /// No description provided for @topic_confidentiality_details.
  ///
  /// In en, this message translates to:
  /// **'Both parties agree to keep all sensitive information related to this agreement confidential and not to share it with third parties.'**
  String get topic_confidentiality_details;

  /// No description provided for @topic_indemnity_title.
  ///
  /// In en, this message translates to:
  /// **'Indemnity'**
  String get topic_indemnity_title;

  /// No description provided for @topic_indemnity_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Protection against legal claims.'**
  String get topic_indemnity_subtitle;

  /// No description provided for @topic_indemnity_details.
  ///
  /// In en, this message translates to:
  /// **'The lessee agrees to indemnify and hold the lessor harmless from any legal claims arising from the use of the vehicle.'**
  String get topic_indemnity_details;

  /// No description provided for @topic_misc_title.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous Provisions'**
  String get topic_misc_title;

  /// No description provided for @topic_misc_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Other legal terms.'**
  String get topic_misc_subtitle;

  /// No description provided for @topic_misc_details.
  ///
  /// In en, this message translates to:
  /// **'This section includes additional legal provisions, such as governing law, jurisdiction, and severability clauses.'**
  String get topic_misc_details;

  /// No description provided for @my_car.
  ///
  /// In en, this message translates to:
  /// **'My Car'**
  String get my_car;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
