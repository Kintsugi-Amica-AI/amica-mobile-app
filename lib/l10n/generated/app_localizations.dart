import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Amica'**
  String get appName;

  /// No description provided for @checkingLoginStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking login status'**
  String get checkingLoginStatus;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navJourneys.
  ///
  /// In en, this message translates to:
  /// **'Journeys'**
  String get navJourneys;

  /// No description provided for @navCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get navCircle;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get commonEnterValidEmail;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get commonTryAgain;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in and your circle can reach you again.'**
  String get loginSubtitle;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequired;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @loginNewToAmica.
  ///
  /// In en, this message translates to:
  /// **'New to Amica?'**
  String get loginNewToAmica;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// No description provided for @signupAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupAppBarTitle;

  /// No description provided for @signupJoinAmica.
  ///
  /// In en, this message translates to:
  /// **'Join Amica'**
  String get signupJoinAmica;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your profile for safety alerts and trusted contacts.'**
  String get signupSubtitle;

  /// No description provided for @signupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get signupNameLabel;

  /// No description provided for @signupPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get signupPhoneLabel;

  /// No description provided for @signupSecretPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret phrase'**
  String get signupSecretPhraseLabel;

  /// No description provided for @signupSecretPhraseHelper.
  ///
  /// In en, this message translates to:
  /// **'Say this during a fake call to trigger stealth SOS.'**
  String get signupSecretPhraseHelper;

  /// No description provided for @signupConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signupConfirmPasswordLabel;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(String field);

  /// No description provided for @signupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get signupEmailInvalid;

  /// No description provided for @signupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get signupPasswordTooShort;

  /// No description provided for @signupPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupPasswordsDoNotMatch;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed. Please try again.'**
  String get signupFailed;

  /// No description provided for @signupCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get signupCreatingAccount;

  /// No description provided for @signupCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupCreateAccountButton;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @forgotPasswordAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordAppBarTitle;

  /// No description provided for @forgotPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordHeading;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and Amica will send a password reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get forgotPasswordEmailInvalid;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox and follow the link.'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Please try again.'**
  String get forgotPasswordFailed;

  /// No description provided for @forgotPasswordSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get forgotPasswordSending;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @discreetModeTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off discreet mode'**
  String get discreetModeTurnOff;

  /// No description provided for @discreetModeTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on discreet mode'**
  String get discreetModeTurnOn;

  /// No description provided for @homeGreetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}.'**
  String homeGreetingWithName(String greeting, String name);

  /// No description provided for @homeGreetingNoName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}.'**
  String homeGreetingNoName(String greeting);

  /// No description provided for @homeNoGuardiansSubline.
  ///
  /// In en, this message translates to:
  /// **'No one can find you yet. Add someone to your circle so Amica has a person to reach.'**
  String get homeNoGuardiansSubline;

  /// No description provided for @homeGuardianCountSubline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{All calm. One person can find you in seconds if you need them.} =2{All calm. Two people can find you in seconds if you need them.} other{All calm. {count} people can find you in seconds if you need them.}}'**
  String homeGuardianCountSubline(int count);

  /// No description provided for @homeYouAreProtected.
  ///
  /// In en, this message translates to:
  /// **'You\'re protected'**
  String get homeYouAreProtected;

  /// No description provided for @homeFinishSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get homeFinishSettingUp;

  /// No description provided for @homeProtectionReadySubline.
  ///
  /// In en, this message translates to:
  /// **'Location on · Voice phrase armed · {count} {count, plural, =1{guardian} other{guardians}}'**
  String homeProtectionReadySubline(int count);

  /// No description provided for @homeAddGuardianPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add at least one guardian to your circle'**
  String get homeAddGuardianPrompt;

  /// No description provided for @homeSosHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold 2 seconds. You get 5 more to cancel before your circle is alerted.'**
  String get homeSosHoldHint;

  /// No description provided for @homeSectionQuieterOptions.
  ///
  /// In en, this message translates to:
  /// **'Quieter options'**
  String get homeSectionQuieterOptions;

  /// No description provided for @homeTileWalkWithMe.
  ///
  /// In en, this message translates to:
  /// **'Walk\nwith me'**
  String get homeTileWalkWithMe;

  /// No description provided for @homeTileFakeCall.
  ///
  /// In en, this message translates to:
  /// **'Fake\ncall'**
  String get homeTileFakeCall;

  /// No description provided for @homeTileScanPlate.
  ///
  /// In en, this message translates to:
  /// **'Scan\na plate'**
  String get homeTileScanPlate;

  /// No description provided for @homeTileStopAlert.
  ///
  /// In en, this message translates to:
  /// **'Stop\nalert'**
  String get homeTileStopAlert;

  /// No description provided for @sosHoldSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Send an SOS alert'**
  String get sosHoldSemanticLabel;

  /// No description provided for @sosHoldSemanticHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold for two seconds'**
  String get sosHoldSemanticHint;

  /// No description provided for @sosHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get sosHoldLabel;

  /// No description provided for @sosHoldReachingCircle.
  ///
  /// In en, this message translates to:
  /// **'Reaching your circle…'**
  String get sosHoldReachingCircle;

  /// No description provided for @sosHoldKeepHolding.
  ///
  /// In en, this message translates to:
  /// **'Keep holding. Release to cancel.'**
  String get sosHoldKeepHolding;

  /// No description provided for @sosHoldToSend.
  ///
  /// In en, this message translates to:
  /// **'Hold to send an SOS'**
  String get sosHoldToSend;

  /// No description provided for @profileAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileAppBarTitle;

  /// No description provided for @profileLoadingYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile'**
  String get profileLoadingYourProfile;

  /// No description provided for @profileVoicePhrase.
  ///
  /// In en, this message translates to:
  /// **'Voice phrase'**
  String get profileVoicePhrase;

  /// No description provided for @profileVoicePhraseSet.
  ///
  /// In en, this message translates to:
  /// **'“{phrase}”'**
  String profileVoicePhraseSet(String phrase);

  /// No description provided for @profileVoicePhraseNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — say it and Amica alerts silently'**
  String get profileVoicePhraseNotSet;

  /// No description provided for @profilePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & your data'**
  String get profilePrivacyTitle;

  /// No description provided for @profilePrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where recordings and locations are kept'**
  String get profilePrivacySubtitle;

  /// No description provided for @profileAllSettings.
  ///
  /// In en, this message translates to:
  /// **'All settings'**
  String get profileAllSettings;

  /// No description provided for @profileYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileYourProfile;

  /// No description provided for @profileSectionHowAmicaBehaves.
  ///
  /// In en, this message translates to:
  /// **'How Amica behaves'**
  String get profileSectionHowAmicaBehaves;

  /// No description provided for @profileSectionYourSafetySetup.
  ///
  /// In en, this message translates to:
  /// **'Your safety setup'**
  String get profileSectionYourSafetySetup;

  /// No description provided for @profileSetupDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String profileSetupDoneCount(int done, int total);

  /// No description provided for @profileGuardiansInCircle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} guardian in your circle} other{{count} guardians in your circle}}'**
  String profileGuardiansInCircle(int count);

  /// No description provided for @profileNoGuardiansYet.
  ///
  /// In en, this message translates to:
  /// **'No one in your circle yet'**
  String get profileNoGuardiansYet;

  /// No description provided for @profileVoicePhraseRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice phrase recorded'**
  String get profileVoicePhraseRecorded;

  /// No description provided for @profilePhoneConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Phone number confirmed'**
  String get profilePhoneConfirmed;

  /// No description provided for @profileMedicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Medical notes for responders'**
  String get profileMedicalNotes;

  /// No description provided for @profileDiscreetModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Discreet mode'**
  String get profileDiscreetModeTitle;

  /// No description provided for @profileDiscreetModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dark, silent, no preview in notifications'**
  String get profileDiscreetModeSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light is easiest to read by day. Dark is discreet at night.'**
  String get appearanceSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Centre on my location'**
  String get mapRecenter;

  /// No description provided for @mapShowWholeRoute.
  ///
  /// In en, this message translates to:
  /// **'Show the whole route'**
  String get mapShowWholeRoute;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @startJourneyYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get startJourneyYourLocation;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these up to date so Amica can help you faster.'**
  String get profileEditSubtitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileNameLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhoneLabel;

  /// No description provided for @profileMedicalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical notes (optional)'**
  String get profileMedicalNotesLabel;

  /// No description provided for @profileMedicalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Allergies, conditions, medication, blood group…'**
  String get profileMedicalNotesHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get profileNameRequired;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Check your connection and try again.'**
  String get profileSaveFailed;

  /// No description provided for @homeSafetyTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety tip of the day'**
  String get homeSafetyTipTitle;

  /// No description provided for @homeSafetyTip1.
  ///
  /// In en, this message translates to:
  /// **'Share your journey with someone you trust before you set off.'**
  String get homeSafetyTip1;

  /// No description provided for @homeSafetyTip2.
  ///
  /// In en, this message translates to:
  /// **'At night, sit near the driver or other passengers on buses and trains.'**
  String get homeSafetyTip2;

  /// No description provided for @homeSafetyTip3.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone charged above 20% before heading out late.'**
  String get homeSafetyTip3;

  /// No description provided for @homeSafetyTip4.
  ///
  /// In en, this message translates to:
  /// **'Trust your instincts. If a place feels wrong, leave and tell someone.'**
  String get homeSafetyTip4;

  /// No description provided for @homeSafetyTip5.
  ///
  /// In en, this message translates to:
  /// **'Check that the taxi\'s number plate matches your booking before you get in.'**
  String get homeSafetyTip5;

  /// No description provided for @homeSafetyTip6.
  ///
  /// In en, this message translates to:
  /// **'Set a secret voice phrase so you can alert your circle without touching your phone.'**
  String get homeSafetyTip6;

  /// No description provided for @phoneVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number'**
  String get phoneVerifyTitle;

  /// No description provided for @phoneVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a 6-digit code to confirm this number is yours.'**
  String get phoneVerifySubtitle;

  /// No description provided for @phoneSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get phoneSendCode;

  /// No description provided for @phoneCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {phone}'**
  String phoneCodeSentTo(String phone);

  /// No description provided for @phoneCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get phoneCodeLabel;

  /// No description provided for @phoneVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get phoneVerifyButton;

  /// No description provided for @phoneResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String phoneResendIn(int seconds);

  /// No description provided for @phoneResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get phoneResend;

  /// No description provided for @phoneChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get phoneChangeNumber;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneVerified;

  /// No description provided for @phoneVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get phoneVerifiedBadge;

  /// No description provided for @phoneNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get phoneNotVerified;

  /// No description provided for @phoneInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number, e.g. +94 77 123 4567'**
  String get phoneInvalidNumber;

  /// No description provided for @phoneErrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the SMS and try again.'**
  String get phoneErrInvalidCode;

  /// No description provided for @phoneErrExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Send a new one.'**
  String get phoneErrExpired;

  /// No description provided for @phoneErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while and try again.'**
  String get phoneErrTooMany;

  /// No description provided for @phoneErrInUse.
  ///
  /// In en, this message translates to:
  /// **'This number is already linked to another Amica account.'**
  String get phoneErrInUse;

  /// No description provided for @phoneErrNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Phone verification isn\'t turned on for this app yet.'**
  String get phoneErrNotEnabled;

  /// No description provided for @phoneErrAppNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'This app build isn\'t registered for phone verification yet.'**
  String get phoneErrAppNotAuthorized;

  /// No description provided for @phoneErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify your number. Check your connection and try again.'**
  String get phoneErrGeneric;

  /// No description provided for @phoneAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get phoneAddTitle;

  /// No description provided for @phoneAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save the number you use every day. SMS verification is coming soon.'**
  String get phoneAddSubtitle;

  /// No description provided for @phoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Phone number saved'**
  String get phoneSaved;

  /// No description provided for @profilePhoneAdded.
  ///
  /// In en, this message translates to:
  /// **'Phone number added'**
  String get profilePhoneAdded;

  /// No description provided for @profileAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get profileAddPhone;

  /// No description provided for @profileVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get profileVerifyAction;

  /// No description provided for @profilePhoneNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Confirm your phone number'**
  String get profilePhoneNotVerified;

  /// No description provided for @profileSaveFailedWithCode.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile ({code}). Check your connection and try again.'**
  String profileSaveFailedWithCode(String code);

  /// No description provided for @profileLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile'**
  String get profileLoadFailedTitle;

  /// No description provided for @profileLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your details are safe. Check your connection — this page updates by itself once you\'re back online.'**
  String get profileLoadFailedBody;

  /// No description provided for @tripTitleBus.
  ///
  /// In en, this message translates to:
  /// **'Your bus trip'**
  String get tripTitleBus;

  /// No description provided for @tripTitleTrain.
  ///
  /// In en, this message translates to:
  /// **'Your train trip'**
  String get tripTitleTrain;

  /// No description provided for @tripPlanning.
  ///
  /// In en, this message translates to:
  /// **'Finding stops near you…'**
  String get tripPlanning;

  /// No description provided for @tripTooClose.
  ///
  /// In en, this message translates to:
  /// **'It\'s close enough to walk — no bus or train needed.'**
  String get tripTooClose;

  /// No description provided for @tripNoStops.
  ///
  /// In en, this message translates to:
  /// **'No stops or stations found nearby. Amica will use the road route instead.'**
  String get tripNoStops;

  /// No description provided for @tripOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t plan the trip right now. Amica will use the road route instead.'**
  String get tripOffline;

  /// No description provided for @tripWalkToStop.
  ///
  /// In en, this message translates to:
  /// **'Walk {distance} to {stop}'**
  String tripWalkToStop(String distance, String stop);

  /// No description provided for @tripGetOnAt.
  ///
  /// In en, this message translates to:
  /// **'Get on at {stop}'**
  String tripGetOnAt(String stop);

  /// No description provided for @tripGetOffAt.
  ///
  /// In en, this message translates to:
  /// **'Get off at {stop}'**
  String tripGetOffAt(String stop);

  /// No description provided for @tripWalkToDestination.
  ///
  /// In en, this message translates to:
  /// **'Walk {distance} to your destination'**
  String tripWalkToDestination(String distance);

  /// No description provided for @tripRideSummary.
  ///
  /// In en, this message translates to:
  /// **'Ride {distance} · about {minutes} min'**
  String tripRideSummary(String distance, int minutes);

  /// No description provided for @tripMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String tripMinutes(int minutes);

  /// No description provided for @tripBusLine.
  ///
  /// In en, this message translates to:
  /// **'Bus {line}'**
  String tripBusLine(String line);

  /// No description provided for @tripTrainLine.
  ///
  /// In en, this message translates to:
  /// **'Train: {line}'**
  String tripTrainLine(String line);

  /// No description provided for @tripEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated from the nearest stops — check the route with the conductor.'**
  String get tripEstimated;

  /// No description provided for @tripChooseBoard.
  ///
  /// In en, this message translates to:
  /// **'Get on at'**
  String get tripChooseBoard;

  /// No description provided for @tripChooseAlight.
  ///
  /// In en, this message translates to:
  /// **'Get off at'**
  String get tripChooseAlight;

  /// No description provided for @tripStopAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String tripStopAway(String distance);

  /// No description provided for @stopAlertWhereGoing.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get stopAlertWhereGoing;

  /// No description provided for @stopAlertWakeBefore.
  ///
  /// In en, this message translates to:
  /// **'Amica will alert you before {stop}, the stop to get off at.'**
  String stopAlertWakeBefore(String stop);

  /// No description provided for @sosSmsDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'I need help.'**
  String get sosSmsDefaultMessage;

  /// No description provided for @sosSmsWithName.
  ///
  /// In en, this message translates to:
  /// **'AMICA SOS from {name}: {message} My location: {link}'**
  String sosSmsWithName(String name, String message, String link);

  /// No description provided for @sosSmsNoName.
  ///
  /// In en, this message translates to:
  /// **'AMICA SOS: {message} My location: {link}'**
  String sosSmsNoName(String message, String link);

  /// No description provided for @sosCircleSending.
  ///
  /// In en, this message translates to:
  /// **'Texting your circle…'**
  String get sosCircleSending;

  /// No description provided for @sosCircleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your circle. Check your connection.'**
  String get sosCircleLoadFailed;

  /// No description provided for @sosCircleTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sosCircleTryAgain;

  /// No description provided for @sosCircleOpenSmsApp.
  ///
  /// In en, this message translates to:
  /// **'Open SMS app'**
  String get sosCircleOpenSmsApp;

  /// No description provided for @sosCircleReachedCount.
  ///
  /// In en, this message translates to:
  /// **'{reached} of {total} reached'**
  String sosCircleReachedCount(int reached, int total);

  /// No description provided for @sosCircleStatusSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sosCircleStatusSending;

  /// No description provided for @sosCircleStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sosCircleStatusSent;

  /// No description provided for @sosCircleStatusUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get sosCircleStatusUnconfirmed;

  /// No description provided for @sosCircleStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sosCircleStatusFailed;

  /// No description provided for @mapTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get mapTypeTitle;

  /// No description provided for @mapTypeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get mapTypeDefault;

  /// No description provided for @mapTypeSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapTypeSatellite;

  /// No description provided for @mapTypeTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get mapTypeTerrain;

  /// No description provided for @tripFeederBusHint.
  ///
  /// In en, this message translates to:
  /// **'Too far to walk to the station'**
  String get tripFeederBusHint;

  /// No description provided for @tripRideToStation.
  ///
  /// In en, this message translates to:
  /// **'Take a bus or tuk-tuk to {station}'**
  String tripRideToStation(String station);

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogOut;

  /// No description provided for @profileLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of Amica?'**
  String get profileLogOutConfirmTitle;

  /// No description provided for @profileLogOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your circle will not be able to reach you through Amica until you log back in.'**
  String get profileLogOutConfirmBody;

  /// No description provided for @profileStayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in'**
  String get profileStayLoggedIn;

  /// No description provided for @settingsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAppBarTitle;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading settings'**
  String get settingsLoading;

  /// No description provided for @settingsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings.'**
  String get settingsCouldNotLoad;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Please try again.'**
  String get settingsCouldNotSave;

  /// No description provided for @settingsFakeCallSection.
  ///
  /// In en, this message translates to:
  /// **'Fake Call'**
  String get settingsFakeCallSection;

  /// No description provided for @settingsVolumeShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Volume-up shortcut'**
  String get settingsVolumeShortcutTitle;

  /// No description provided for @settingsVolumeShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, Amica keeps a safety shortcut notification running. Press volume up three times to open the call screen.'**
  String get settingsVolumeShortcutSubtitle;

  /// No description provided for @settingsFakeCallerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Fake caller name'**
  String get settingsFakeCallerNameLabel;

  /// No description provided for @settingsEnterCallerName.
  ///
  /// In en, this message translates to:
  /// **'Enter a caller name.'**
  String get settingsEnterCallerName;

  /// No description provided for @settingsFakeCallerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fake caller number'**
  String get settingsFakeCallerNumberLabel;

  /// No description provided for @settingsEnterCallerNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a caller number.'**
  String get settingsEnterCallerNumber;

  /// No description provided for @settingsVoiceSosSection.
  ///
  /// In en, this message translates to:
  /// **'Stealth Voice SOS'**
  String get settingsVoiceSosSection;

  /// No description provided for @settingsEnableVoiceSos.
  ///
  /// In en, this message translates to:
  /// **'Enable voice SOS'**
  String get settingsEnableVoiceSos;

  /// No description provided for @settingsListenForPhrase.
  ///
  /// In en, this message translates to:
  /// **'Listen for the secret phrase during an active fake call.'**
  String get settingsListenForPhrase;

  /// No description provided for @settingsEnableSecretPhrase.
  ///
  /// In en, this message translates to:
  /// **'Enable secret phrase'**
  String get settingsEnableSecretPhrase;

  /// No description provided for @settingsUsePhraseBelow.
  ///
  /// In en, this message translates to:
  /// **'Use the phrase below to trigger Voice SOS.'**
  String get settingsUsePhraseBelow;

  /// No description provided for @settingsSecretPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret phrase {number}'**
  String settingsSecretPhraseLabel(int number);

  /// No description provided for @settingsEnterPhrase.
  ///
  /// In en, this message translates to:
  /// **'Enter a phrase.'**
  String get settingsEnterPhrase;

  /// No description provided for @settingsPhraseAlreadyListed.
  ///
  /// In en, this message translates to:
  /// **'This phrase is already in the list.'**
  String get settingsPhraseAlreadyListed;

  /// No description provided for @settingsRemovePhrase.
  ///
  /// In en, this message translates to:
  /// **'Remove phrase'**
  String get settingsRemovePhrase;

  /// No description provided for @settingsAddPhrase.
  ///
  /// In en, this message translates to:
  /// **'Add phrase'**
  String get settingsAddPhrase;

  /// No description provided for @settingsSosMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS message for emergency contact'**
  String get settingsSosMessageLabel;

  /// No description provided for @settingsSosMessageHelper.
  ///
  /// In en, this message translates to:
  /// **'Saved with the Voice SOS alert when the phrase is spoken.'**
  String get settingsSosMessageHelper;

  /// No description provided for @settingsEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the message to send.'**
  String get settingsEnterMessage;

  /// No description provided for @settingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get settingsSaving;

  /// No description provided for @settingsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsSaveButton;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language Amica is shown in.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @contactsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your circle'**
  String get contactsAppBarTitle;

  /// No description provided for @contactsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading emergency contacts'**
  String get contactsLoading;

  /// No description provided for @contactsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load emergency contacts.\n{error}'**
  String contactsLoadError(String error);

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your circle are the people Amica reaches the moment you send an alert. Add one person you trust and the app starts working.'**
  String get contactsEmptyMessage;

  /// No description provided for @contactsAddFirstGuardian.
  ///
  /// In en, this message translates to:
  /// **'Add your first guardian'**
  String get contactsAddFirstGuardian;

  /// No description provided for @contactsAlertedTogetherNote.
  ///
  /// In en, this message translates to:
  /// **'Everyone switched on here is contacted at the same time when you send an alert.'**
  String get contactsAlertedTogetherNote;

  /// No description provided for @contactsAddGuardianFab.
  ///
  /// In en, this message translates to:
  /// **'Add guardian'**
  String get contactsAddGuardianFab;

  /// No description provided for @contactsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete contact?'**
  String get contactsDeleteConfirmTitle;

  /// No description provided for @contactsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from emergency contacts?'**
  String contactsDeleteConfirmBody(String name);

  /// No description provided for @contactsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Contact deleted'**
  String get contactsDeleted;

  /// No description provided for @contactsCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete contact'**
  String get contactsCouldNotDelete;

  /// No description provided for @contactsCouldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update contact'**
  String get contactsCouldNotUpdate;

  /// No description provided for @contactsAlertedOnSos.
  ///
  /// In en, this message translates to:
  /// **'Alerted when you send an SOS'**
  String get contactsAlertedOnSos;

  /// No description provided for @contactsMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted — will not be alerted'**
  String get contactsMuted;

  /// No description provided for @contactsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String contactsRemoveTooltip(String name);

  /// No description provided for @addContactCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save contact. Please try again.'**
  String get addContactCouldNotSave;

  /// No description provided for @addContactPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to import a contact.'**
  String get addContactPermissionRequired;

  /// No description provided for @addContactNoPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'That contact has no phone number saved. Enter one manually.'**
  String get addContactNoPhoneNumber;

  /// No description provided for @addContactCouldNotImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import that contact.'**
  String get addContactCouldNotImport;

  /// No description provided for @addContactPriorityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Priority must be a positive number'**
  String get addContactPriorityInvalid;

  /// No description provided for @addContactEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get addContactEditTitle;

  /// No description provided for @addContactAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContactAddTitle;

  /// No description provided for @addContactOpeningContacts.
  ///
  /// In en, this message translates to:
  /// **'Opening contacts...'**
  String get addContactOpeningContacts;

  /// No description provided for @addContactImportFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Import from phone contacts'**
  String get addContactImportFromPhone;

  /// No description provided for @addContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get addContactNameLabel;

  /// No description provided for @addContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get addContactPhoneLabel;

  /// No description provided for @addContactRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get addContactRelationshipLabel;

  /// No description provided for @addContactPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get addContactPriorityLabel;

  /// No description provided for @addContactPriorityHelper.
  ///
  /// In en, this message translates to:
  /// **'Lower numbers are contacted first.'**
  String get addContactPriorityHelper;

  /// No description provided for @addContactSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get addContactSaving;

  /// No description provided for @addContactSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get addContactSaveButton;

  /// No description provided for @sosArmingSendingLabel.
  ///
  /// In en, this message translates to:
  /// **'SENDING AN ALERT'**
  String get sosArmingSendingLabel;

  /// No description provided for @sosArmingAlertingLabel.
  ///
  /// In en, this message translates to:
  /// **'ALERTING YOUR CIRCLE'**
  String get sosArmingAlertingLabel;

  /// No description provided for @sosArmingReachingNow.
  ///
  /// In en, this message translates to:
  /// **'Reaching them now.'**
  String get sosArmingReachingNow;

  /// No description provided for @sosArmingCancelIfMeant.
  ///
  /// In en, this message translates to:
  /// **'Cancel if you meant to.'**
  String get sosArmingCancelIfMeant;

  /// No description provided for @sosArmingStaySafe.
  ///
  /// In en, this message translates to:
  /// **'Stay where you are if it is safe to.'**
  String get sosArmingStaySafe;

  /// No description provided for @sosArmingStopNow.
  ///
  /// In en, this message translates to:
  /// **'Stop now and nothing is sent. No one is told you nearly called.'**
  String get sosArmingStopNow;

  /// No description provided for @sosArmingSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your alert. Try again, or call 119 directly.'**
  String get sosArmingSendFailed;

  /// No description provided for @sosArmingWhenZero.
  ///
  /// In en, this message translates to:
  /// **'WHEN THE COUNT REACHES ZERO'**
  String get sosArmingWhenZero;

  /// No description provided for @sosArmingGuardianNone.
  ///
  /// In en, this message translates to:
  /// **'Your circle gets your live location'**
  String get sosArmingGuardianNone;

  /// No description provided for @sosArmingGuardianOne.
  ///
  /// In en, this message translates to:
  /// **'{name} gets your live location'**
  String sosArmingGuardianOne(String name);

  /// No description provided for @sosArmingGuardianTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second} get your live location'**
  String sosArmingGuardianTwo(String first, String second);

  /// No description provided for @sosArmingGuardianMany.
  ///
  /// In en, this message translates to:
  /// **'{names} and {last} get your live location'**
  String sosArmingGuardianMany(String names, String last);

  /// No description provided for @sosArmingRecordingAudio.
  ///
  /// In en, this message translates to:
  /// **'Your phone starts recording audio'**
  String get sosArmingRecordingAudio;

  /// No description provided for @sosArmingCallReady.
  ///
  /// In en, this message translates to:
  /// **'119 is one tap away, already dialled'**
  String get sosArmingCallReady;

  /// No description provided for @sosArmingCancelSendNothing.
  ///
  /// In en, this message translates to:
  /// **'Cancel — send nothing'**
  String get sosArmingCancelSendNothing;

  /// No description provided for @sosArmingBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get sosArmingBackToHome;

  /// No description provided for @sosActiveTriggerVoice.
  ///
  /// In en, this message translates to:
  /// **'Triggered by your voice phrase'**
  String get sosActiveTriggerVoice;

  /// No description provided for @sosActiveTriggerTimer.
  ///
  /// In en, this message translates to:
  /// **'Your journey timer ran out'**
  String get sosActiveTriggerTimer;

  /// No description provided for @sosActiveTriggerManual.
  ///
  /// In en, this message translates to:
  /// **'You sent this alert'**
  String get sosActiveTriggerManual;

  /// No description provided for @sosActiveLive.
  ///
  /// In en, this message translates to:
  /// **'ALERT LIVE'**
  String get sosActiveLive;

  /// No description provided for @sosActiveYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get sosActiveYourLocation;

  /// No description provided for @sosActiveUpdatingEvery10s.
  ///
  /// In en, this message translates to:
  /// **'Updating every 10 seconds'**
  String get sosActiveUpdatingEvery10s;

  /// No description provided for @sosActiveNoOneInCircle.
  ///
  /// In en, this message translates to:
  /// **'No one is in your circle, so only emergency services can help. Call 119.'**
  String get sosActiveNoOneInCircle;

  /// No description provided for @sosActiveCircleReachedHeader.
  ///
  /// In en, this message translates to:
  /// **'Your circle · {count} reached'**
  String sosActiveCircleReachedHeader(int count);

  /// No description provided for @sosActiveNotified.
  ///
  /// In en, this message translates to:
  /// **'Notified'**
  String get sosActiveNotified;

  /// No description provided for @sosActiveWhatAmicaIsDoing.
  ///
  /// In en, this message translates to:
  /// **'What Amica is doing'**
  String get sosActiveWhatAmicaIsDoing;

  /// No description provided for @sosActiveSharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Sharing your live location'**
  String get sosActiveSharingLocation;

  /// No description provided for @sosActiveRecordingAudio.
  ///
  /// In en, this message translates to:
  /// **'Recording audio'**
  String get sosActiveRecordingAudio;

  /// No description provided for @sosActiveSirenSounding.
  ///
  /// In en, this message translates to:
  /// **'Siren — sounding'**
  String get sosActiveSirenSounding;

  /// No description provided for @sosActiveSirenSilent.
  ///
  /// In en, this message translates to:
  /// **'Siren — silent, tap to sound'**
  String get sosActiveSirenSilent;

  /// No description provided for @sosActiveOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get sosActiveOn;

  /// No description provided for @sosActiveOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get sosActiveOff;

  /// No description provided for @sosActiveImSafe.
  ///
  /// In en, this message translates to:
  /// **'I\'m safe — stand down'**
  String get sosActiveImSafe;

  /// No description provided for @sosActiveCall119.
  ///
  /// In en, this message translates to:
  /// **'Call 119'**
  String get sosActiveCall119;

  /// No description provided for @sosActiveStandDownNote.
  ///
  /// In en, this message translates to:
  /// **'Standing down tells your circle you are okay. It does not delete the recording.'**
  String get sosActiveStandDownNote;

  /// No description provided for @sosActiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell your circle you are safe?'**
  String get sosActiveConfirmTitle;

  /// No description provided for @sosActiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will stop seeing your live location and the alert will close.'**
  String get sosActiveConfirmBody;

  /// No description provided for @sosActiveKeepLive.
  ///
  /// In en, this message translates to:
  /// **'Keep it live'**
  String get sosActiveKeepLive;

  /// No description provided for @sosActiveYesImSafe.
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m safe'**
  String get sosActiveYesImSafe;

  /// No description provided for @fakeCallPreparingCall.
  ///
  /// In en, this message translates to:
  /// **'Preparing call'**
  String get fakeCallPreparingCall;

  /// No description provided for @fakeCallAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Fake call'**
  String get fakeCallAppBarTitle;

  /// No description provided for @fakeCallHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it look like someone is expecting you'**
  String get fakeCallHeroTitle;

  /// No description provided for @fakeCallHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ring now, or schedule a call for the moment you get into a vehicle. Amica keeps the countdown running even if you close the app or lock your phone.'**
  String get fakeCallHeroSubtitle;

  /// No description provided for @fakeCallRingNowInstead.
  ///
  /// In en, this message translates to:
  /// **'Ring now instead'**
  String get fakeCallRingNowInstead;

  /// No description provided for @fakeCallCancelScheduled.
  ///
  /// In en, this message translates to:
  /// **'Cancel scheduled call'**
  String get fakeCallCancelScheduled;

  /// No description provided for @fakeCallScheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling...'**
  String get fakeCallScheduling;

  /// No description provided for @fakeCallScheduleIn.
  ///
  /// In en, this message translates to:
  /// **'Schedule in {delay}'**
  String fakeCallScheduleIn(String delay);

  /// No description provided for @fakeCallRingNow.
  ///
  /// In en, this message translates to:
  /// **'Ring now'**
  String get fakeCallRingNow;

  /// No description provided for @fakeCallDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'No real call is placed. During the call, Amica can listen for your secret phrase and send a silent SOS.'**
  String get fakeCallDisclaimer;

  /// No description provided for @fakeCallEditCallerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit caller'**
  String get fakeCallEditCallerTooltip;

  /// No description provided for @fakeCallMeIn.
  ///
  /// In en, this message translates to:
  /// **'Call me in'**
  String get fakeCallMeIn;

  /// No description provided for @fakeCallCallingIn.
  ///
  /// In en, this message translates to:
  /// **'CALLING IN'**
  String get fakeCallCallingIn;

  /// No description provided for @fakeCallKeepNotificationVisible.
  ///
  /// In en, this message translates to:
  /// **'Keep the \"Call scheduled\" notification visible. You can close Amica now.'**
  String get fakeCallKeepNotificationVisible;

  /// No description provided for @fakeCallScheduledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} will call in {delay}. You can close Amica.'**
  String fakeCallScheduledSnackbar(String name, String delay);

  /// No description provided for @fakeCallCouldNotSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not schedule the call on this device.'**
  String get fakeCallCouldNotSchedule;

  /// No description provided for @fakeCallScheduleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled call cancelled'**
  String get fakeCallScheduleCancelled;

  /// No description provided for @fakeCallCouldNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the scheduled call.'**
  String get fakeCallCouldNotCancel;

  /// No description provided for @fakeCallIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get fakeCallIncoming;

  /// No description provided for @fakeCallMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get fakeCallMobile;

  /// No description provided for @fakeCallDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get fakeCallDecline;

  /// No description provided for @fakeCallAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get fakeCallAccept;

  /// No description provided for @fakeCallActiveCouldNotCompleteVoiceSos.
  ///
  /// In en, this message translates to:
  /// **'Could not complete Voice SOS. Use manual SOS if needed.'**
  String get fakeCallActiveCouldNotCompleteVoiceSos;

  /// No description provided for @fakeCallActiveConnected.
  ///
  /// In en, this message translates to:
  /// **'Call connected'**
  String get fakeCallActiveConnected;

  /// No description provided for @fakeCallActiveMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get fakeCallActiveMute;

  /// No description provided for @fakeCallActiveKeypad.
  ///
  /// In en, this message translates to:
  /// **'Keypad'**
  String get fakeCallActiveKeypad;

  /// No description provided for @fakeCallActiveSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get fakeCallActiveSpeaker;

  /// No description provided for @fakeCallActiveAddCall.
  ///
  /// In en, this message translates to:
  /// **'Add call'**
  String get fakeCallActiveAddCall;

  /// No description provided for @fakeCallActiveHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get fakeCallActiveHold;

  /// No description provided for @fakeCallActiveBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get fakeCallActiveBluetooth;

  /// No description provided for @journeysScreenCheckingJourneys.
  ///
  /// In en, this message translates to:
  /// **'Checking your journeys'**
  String get journeysScreenCheckingJourneys;

  /// No description provided for @safetyCheckDefaultTrip.
  ///
  /// In en, this message translates to:
  /// **'your trip'**
  String get safetyCheckDefaultTrip;

  /// No description provided for @safetyCheckAreYouSafe.
  ///
  /// In en, this message translates to:
  /// **'Are you safe?'**
  String get safetyCheckAreYouSafe;

  /// No description provided for @safetyCheckTimerEnded.
  ///
  /// In en, this message translates to:
  /// **'Your journey timer for {destination} has ended.'**
  String safetyCheckTimerEnded(String destination);

  /// No description provided for @safetyCheckImSafe.
  ///
  /// In en, this message translates to:
  /// **'I am safe'**
  String get safetyCheckImSafe;

  /// No description provided for @safetyCheckSendSosNow.
  ///
  /// In en, this message translates to:
  /// **'Send SOS now'**
  String get safetyCheckSendSosNow;

  /// No description provided for @safetyCheckSafeClosesNote.
  ///
  /// In en, this message translates to:
  /// **'Tapping \"I am safe\" closes this journey. Amica will stop watching and will not contact anyone.'**
  String get safetyCheckSafeClosesNote;

  /// No description provided for @safetyCheckAnswerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Answer so Amica knows whether to alert your emergency contact.'**
  String get safetyCheckAnswerPrompt;

  /// No description provided for @safetyCheckContactAlerted.
  ///
  /// In en, this message translates to:
  /// **'Amica has alerted your emergency contact'**
  String get safetyCheckContactAlerted;

  /// No description provided for @safetyCheckAutoAlertIn.
  ///
  /// In en, this message translates to:
  /// **'Auto-alert in'**
  String get safetyCheckAutoAlertIn;

  /// No description provided for @safetyCheckEscalationExplain.
  ///
  /// In en, this message translates to:
  /// **'If you do not answer, Amica messages your primary emergency contact with your live location, then calls them.'**
  String get safetyCheckEscalationExplain;

  /// No description provided for @safetyCheckAfterEscalationNote.
  ///
  /// In en, this message translates to:
  /// **'You can still confirm you are safe, or escalate to a full SOS with your live location.'**
  String get safetyCheckAfterEscalationNote;

  /// No description provided for @startJourneyFindingOnMap.
  ///
  /// In en, this message translates to:
  /// **'Finding destination on map...'**
  String get startJourneyFindingOnMap;

  /// No description provided for @startJourneyDestinationFound.
  ///
  /// In en, this message translates to:
  /// **'Destination found on map.'**
  String get startJourneyDestinationFound;

  /// No description provided for @startJourneyDestinationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Destination not found. Pin it on the map.'**
  String get startJourneyDestinationNotFound;

  /// No description provided for @startJourneyCouldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location.'**
  String get startJourneyCouldNotGetLocation;

  /// No description provided for @startJourneyGetLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Get your current location first.'**
  String get startJourneyGetLocationFirst;

  /// No description provided for @startJourneyChooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose the destination on the map.'**
  String get startJourneyChooseDestination;

  /// No description provided for @startJourneyCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start journey.'**
  String get startJourneyCouldNotStart;

  /// No description provided for @startJourneyDestinationPinSelected.
  ///
  /// In en, this message translates to:
  /// **'Destination pin selected.'**
  String get startJourneyDestinationPinSelected;

  /// No description provided for @startJourneyDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get startJourneyDestinationLabel;

  /// No description provided for @startJourneyWalkWithMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk with me'**
  String get startJourneyWalkWithMeTitle;

  /// No description provided for @startJourneyRideWithMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride with me'**
  String get startJourneyRideWithMeTitle;

  /// No description provided for @startJourneyVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {plate}'**
  String startJourneyVehicleLabel(String plate);

  /// No description provided for @startJourneyGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get startJourneyGettingLocation;

  /// No description provided for @startJourneyGetCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get current location'**
  String get startJourneyGetCurrentLocation;

  /// No description provided for @startJourneyCurrentLocationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Current location: not selected yet'**
  String get startJourneyCurrentLocationNotSelected;

  /// No description provided for @startJourneyCurrentLocationValue.
  ///
  /// In en, this message translates to:
  /// **'Current location: {lat}, {lng}'**
  String startJourneyCurrentLocationValue(String lat, String lng);

  /// No description provided for @startJourneyDestinationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination name or address'**
  String get startJourneyDestinationNameLabel;

  /// No description provided for @startJourneyMapStartMarker.
  ///
  /// In en, this message translates to:
  /// **'Journey start'**
  String get startJourneyMapStartMarker;

  /// No description provided for @startJourneyTapMapToPin.
  ///
  /// In en, this message translates to:
  /// **'Tap map to pin destination.'**
  String get startJourneyTapMapToPin;

  /// No description provided for @startJourneyDestinationPinValue.
  ///
  /// In en, this message translates to:
  /// **'Destination pin: {lat}, {lng}'**
  String startJourneyDestinationPinValue(String lat, String lng);

  /// No description provided for @startJourneyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Journey type'**
  String get startJourneyTypeLabel;

  /// No description provided for @startJourneyTypeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get startJourneyTypeWalk;

  /// No description provided for @startJourneyTypeTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get startJourneyTypeTaxi;

  /// No description provided for @startJourneyTypeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get startJourneyTypeBus;

  /// No description provided for @startJourneyTypeTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get startJourneyTypeTrain;

  /// No description provided for @startJourneyTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get startJourneyTypeOther;

  /// No description provided for @startJourneyDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration in minutes'**
  String get startJourneyDurationLabel;

  /// No description provided for @startJourneyDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive duration'**
  String get startJourneyDurationInvalid;

  /// No description provided for @startJourneySuggestedDuration.
  ///
  /// In en, this message translates to:
  /// **'Suggested duration: {minutes} minutes (approximate; no traffic data)'**
  String startJourneySuggestedDuration(int minutes);

  /// No description provided for @startJourneyStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get startJourneyStarting;

  /// No description provided for @startJourneyStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get startJourneyStartButton;

  /// No description provided for @startJourneyStartVehicleButton.
  ///
  /// In en, this message translates to:
  /// **'Start Vehicle Journey'**
  String get startJourneyStartVehicleButton;

  /// No description provided for @journeyTimerMarkedSafe.
  ///
  /// In en, this message translates to:
  /// **'Journey marked safe'**
  String get journeyTimerMarkedSafe;

  /// No description provided for @journeyTimerMarkSafeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark journey safe'**
  String get journeyTimerMarkSafeFailed;

  /// No description provided for @journeyTimerSendingSos.
  ///
  /// In en, this message translates to:
  /// **'Sending SOS alert...'**
  String get journeyTimerSendingSos;

  /// No description provided for @journeyTimerSosCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create SOS alert'**
  String get journeyTimerSosCreateFailed;

  /// No description provided for @journeyTimerNoContactFound.
  ///
  /// In en, this message translates to:
  /// **'No active emergency contact found.'**
  String get journeyTimerNoContactFound;

  /// No description provided for @journeyTimerSmsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Emergency SMS submitted for {count} contacts.'**
  String journeyTimerSmsSubmitted(int count);

  /// No description provided for @journeyTimerMessagePrepFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare emergency message.'**
  String get journeyTimerMessagePrepFailed;

  /// No description provided for @journeyTimerNoContactFoundCall.
  ///
  /// In en, this message translates to:
  /// **'No active emergency contact found for call.'**
  String get journeyTimerNoContactFoundCall;

  /// No description provided for @journeyTimerCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}.'**
  String journeyTimerCalling(String name);

  /// No description provided for @journeyTimerCallOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open emergency call.'**
  String get journeyTimerCallOpenFailed;

  /// No description provided for @journeyTimerEmergencyLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available.'**
  String get journeyTimerEmergencyLocationUnavailable;

  /// No description provided for @journeyTimerEmergencyLocationLine.
  ///
  /// In en, this message translates to:
  /// **'Location: {url}'**
  String journeyTimerEmergencyLocationLine(String url);

  /// No description provided for @journeyTimerEmergencyAlertIntro.
  ///
  /// In en, this message translates to:
  /// **'Amica safety alert: I did not respond to my journey safety check.'**
  String get journeyTimerEmergencyAlertIntro;

  /// No description provided for @journeyTimerEmergencyVehicleLine.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {plate}.'**
  String journeyTimerEmergencyVehicleLine(String plate);

  /// No description provided for @journeyTimerEmergencyDestinationLine.
  ///
  /// In en, this message translates to:
  /// **'Destination: {name}.'**
  String journeyTimerEmergencyDestinationLine(String name);

  /// No description provided for @journeyTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journeyTimerTitle;

  /// No description provided for @journeyTimerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading journey'**
  String get journeyTimerLoading;

  /// No description provided for @journeyTimerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load journey: {error}'**
  String journeyTimerLoadError(String error);

  /// No description provided for @journeyTimerNoActiveJourney.
  ///
  /// In en, this message translates to:
  /// **'No active journey found.'**
  String get journeyTimerNoActiveJourney;

  /// No description provided for @journeyTimerStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get journeyTimerStatusActive;

  /// No description provided for @journeyTimerStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'SAFE'**
  String get journeyTimerStatusSafe;

  /// No description provided for @journeyTimerStatusSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get journeyTimerStatusSos;

  /// No description provided for @journeyTimerEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration: {minutes} minutes'**
  String journeyTimerEstimatedDuration(int minutes);

  /// No description provided for @journeyTimerTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'TIME REMAINING'**
  String get journeyTimerTimeRemaining;

  /// No description provided for @journeyTimerMapMarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey location'**
  String get journeyTimerMapMarkerTitle;

  /// No description provided for @journeyTimerSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get journeyTimerSaving;

  /// No description provided for @journeyTimerTriggerTestSos.
  ///
  /// In en, this message translates to:
  /// **'Trigger test SOS'**
  String get journeyTimerTriggerTestSos;

  /// No description provided for @stopAlertSetupFindingStop.
  ///
  /// In en, this message translates to:
  /// **'Finding your stop on the map...'**
  String get stopAlertSetupFindingStop;

  /// No description provided for @stopAlertSetupStopFound.
  ///
  /// In en, this message translates to:
  /// **'Stop found on the map.'**
  String get stopAlertSetupStopFound;

  /// No description provided for @stopAlertSetupStopNotFound.
  ///
  /// In en, this message translates to:
  /// **'Stop not found. Tap the map to pin it.'**
  String get stopAlertSetupStopNotFound;

  /// No description provided for @stopAlertSetupStopPinned.
  ///
  /// In en, this message translates to:
  /// **'Stop pinned on the map.'**
  String get stopAlertSetupStopPinned;

  /// No description provided for @stopAlertSetupLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your current location.'**
  String get stopAlertSetupLocationError;

  /// No description provided for @stopAlertSetupNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Get your current location first.'**
  String get stopAlertSetupNeedLocation;

  /// No description provided for @stopAlertSetupNeedStop.
  ///
  /// In en, this message translates to:
  /// **'Search for your stop or tap the map to pin it.'**
  String get stopAlertSetupNeedStop;

  /// No description provided for @stopAlertSetupStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the bus ride.'**
  String get stopAlertSetupStartFailed;

  /// No description provided for @stopAlertSetupValidateDropOff.
  ///
  /// In en, this message translates to:
  /// **'Name your stop so the alert can tell you where you are going'**
  String get stopAlertSetupValidateDropOff;

  /// No description provided for @stopAlertSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Bus stop alert'**
  String get stopAlertSetupTitle;

  /// No description provided for @stopAlertSetupHeadline.
  ///
  /// In en, this message translates to:
  /// **'Never miss your stop'**
  String get stopAlertSetupHeadline;

  /// No description provided for @stopAlertSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick where you are getting off. Amica watches the distance and sounds an alarm before you arrive, so you can rest on the bus without missing your stop.'**
  String get stopAlertSetupIntro;

  /// No description provided for @stopAlertSetupGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get stopAlertSetupGettingLocation;

  /// No description provided for @stopAlertSetupUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update current location'**
  String get stopAlertSetupUpdateLocation;

  /// No description provided for @stopAlertSetupLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current location: not available yet'**
  String get stopAlertSetupLocationUnavailable;

  /// No description provided for @stopAlertSetupLocationKnown.
  ///
  /// In en, this message translates to:
  /// **'Current location: {lat}, {lng}'**
  String stopAlertSetupLocationKnown(String lat, String lng);

  /// No description provided for @stopAlertSetupDropOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Where are you getting off?'**
  String get stopAlertSetupDropOffLabel;

  /// No description provided for @stopAlertSetupYouAreHereMarker.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get stopAlertSetupYouAreHereMarker;

  /// No description provided for @stopAlertSetupYourStopDefault.
  ///
  /// In en, this message translates to:
  /// **'Your stop'**
  String get stopAlertSetupYourStopDefault;

  /// No description provided for @stopAlertSetupTapToPin.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to pin your stop.'**
  String get stopAlertSetupTapToPin;

  /// No description provided for @stopAlertSetupStopPinnedAt.
  ///
  /// In en, this message translates to:
  /// **'Stop pinned at {lat}, {lng}'**
  String stopAlertSetupStopPinnedAt(String lat, String lng);

  /// No description provided for @stopAlertSetupStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start bus ride'**
  String get stopAlertSetupStartButton;

  /// No description provided for @stopAlertSetupKeepNotificationNote.
  ///
  /// In en, this message translates to:
  /// **'Keep the Amica tracking notification visible. The alarm still sounds with the app closed and the screen off.'**
  String get stopAlertSetupKeepNotificationNote;

  /// No description provided for @stopAlertSetupAlertDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert me this far from the stop'**
  String get stopAlertSetupAlertDistanceLabel;

  /// No description provided for @stopAlertSetupCheckingRoadDistance.
  ///
  /// In en, this message translates to:
  /// **'Checking the road distance to your stop...'**
  String get stopAlertSetupCheckingRoadDistance;

  /// No description provided for @stopAlertSetupDistanceStraightLine.
  ///
  /// In en, this message translates to:
  /// **'Your stop is {distance} away in a straight line.'**
  String stopAlertSetupDistanceStraightLine(String distance);

  /// No description provided for @stopAlertSetupDistanceByRoad.
  ///
  /// In en, this message translates to:
  /// **'Your stop is about {distance} away by road.'**
  String stopAlertSetupDistanceByRoad(String distance);

  /// No description provided for @stopAlertSetupTooClose.
  ///
  /// In en, this message translates to:
  /// **'You are already within {alertDistance} of this stop, so the alarm would sound straight away. Pick a shorter alert distance.'**
  String stopAlertSetupTooClose(String alertDistance);

  /// No description provided for @stopAlertActiveLocationPaused.
  ///
  /// In en, this message translates to:
  /// **'Live location paused. Amica keeps watching in the background.'**
  String get stopAlertActiveLocationPaused;

  /// No description provided for @stopAlertActiveCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not close the ride record'**
  String get stopAlertActiveCloseFailed;

  /// No description provided for @stopAlertActiveLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your ride'**
  String get stopAlertActiveLoading;

  /// No description provided for @stopAlertActiveLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the ride: {error}'**
  String stopAlertActiveLoadError(String error);

  /// No description provided for @stopAlertActiveNoRide.
  ///
  /// In en, this message translates to:
  /// **'No active bus ride found.'**
  String get stopAlertActiveNoRide;

  /// No description provided for @stopAlertActiveGettingOffAt.
  ///
  /// In en, this message translates to:
  /// **'Getting off at'**
  String get stopAlertActiveGettingOffAt;

  /// No description provided for @stopAlertActiveAlertDistance.
  ///
  /// In en, this message translates to:
  /// **'Alert distance'**
  String get stopAlertActiveAlertDistance;

  /// No description provided for @stopAlertActiveBackgroundAlarm.
  ///
  /// In en, this message translates to:
  /// **'Background alarm'**
  String get stopAlertActiveBackgroundAlarm;

  /// No description provided for @stopAlertActiveStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stopAlertActiveStatusActive;

  /// No description provided for @stopAlertActiveStatusAppOnly.
  ///
  /// In en, this message translates to:
  /// **'App only'**
  String get stopAlertActiveStatusAppOnly;

  /// No description provided for @stopAlertActiveDistanceMeasured.
  ///
  /// In en, this message translates to:
  /// **'Distance measured'**
  String get stopAlertActiveDistanceMeasured;

  /// No description provided for @stopAlertActiveByRoad.
  ///
  /// In en, this message translates to:
  /// **'By road'**
  String get stopAlertActiveByRoad;

  /// No description provided for @stopAlertActiveStraightLine.
  ///
  /// In en, this message translates to:
  /// **'Straight line'**
  String get stopAlertActiveStraightLine;

  /// No description provided for @stopAlertActiveEnding.
  ///
  /// In en, this message translates to:
  /// **'Ending...'**
  String get stopAlertActiveEnding;

  /// No description provided for @stopAlertActiveGetOffButton.
  ///
  /// In en, this message translates to:
  /// **'I am getting off here'**
  String get stopAlertActiveGetOffButton;

  /// No description provided for @stopAlertActiveCanLockPhone.
  ///
  /// In en, this message translates to:
  /// **'You can lock your phone. Amica will alarm before your stop.'**
  String get stopAlertActiveCanLockPhone;

  /// No description provided for @stopAlertActiveKeepScreenOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open so Amica can watch your stop.'**
  String get stopAlertActiveKeepScreenOpen;

  /// No description provided for @stopAlertActiveComingUp.
  ///
  /// In en, this message translates to:
  /// **'YOUR STOP IS COMING UP'**
  String get stopAlertActiveComingUp;

  /// No description provided for @stopAlertActiveDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE TO YOUR STOP'**
  String get stopAlertActiveDistanceLabel;

  /// No description provided for @stopAlertActiveGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready to get off at {name}.'**
  String stopAlertActiveGetReady(String name);

  /// No description provided for @stopAlertActiveWillAlarmAt.
  ///
  /// In en, this message translates to:
  /// **'Amica will alarm at {distance}.'**
  String stopAlertActiveWillAlarmAt(String distance);

  /// No description provided for @plateScanStartingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting camera...'**
  String get plateScanStartingCamera;

  /// No description provided for @plateScanAlignPrompt.
  ///
  /// In en, this message translates to:
  /// **'Align the plate in the frame and tap the shutter'**
  String get plateScanAlignPrompt;

  /// No description provided for @plateScanNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera was found on this device.'**
  String get plateScanNoCamera;

  /// No description provided for @plateScanPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan a plate. Enable it in system settings.'**
  String get plateScanPermissionRequired;

  /// No description provided for @plateScanCameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera.'**
  String get plateScanCameraStartFailed;

  /// No description provided for @plateScanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading plate...'**
  String get plateScanReading;

  /// No description provided for @plateScanDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected {plate}'**
  String plateScanDetected(String plate);

  /// No description provided for @plateScanNotDetected.
  ///
  /// In en, this message translates to:
  /// **'No plate detected. Align it inside the frame and try again.'**
  String get plateScanNotDetected;

  /// No description provided for @plateScanChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking {plate}...'**
  String plateScanChecking(String plate);

  /// No description provided for @plateScanGalleryNoPlate.
  ///
  /// In en, this message translates to:
  /// **'No single plate detected. Try another image or enter the plate.'**
  String get plateScanGalleryNoPlate;

  /// No description provided for @plateScanGalleryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not scan the plate. Please try again.'**
  String get plateScanGalleryFailed;

  /// No description provided for @plateScanEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter plate number'**
  String get plateScanEnterTitle;

  /// No description provided for @plateScanCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get plateScanCheckButton;

  /// No description provided for @plateScanInvalidPlate.
  ///
  /// In en, this message translates to:
  /// **'Enter a plate like CAB-1234, WP KA-1234 or 65-1234.'**
  String get plateScanInvalidPlate;

  /// No description provided for @plateScanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm plate number'**
  String get plateScanConfirmTitle;

  /// No description provided for @plateScanConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the plate we read and correct it if needed.'**
  String get plateScanConfirmMessage;

  /// No description provided for @plateScanUnreadMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the plate clearly. Type the number shown on the plate.'**
  String get plateScanUnreadMessage;

  /// No description provided for @plateScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan before you ride'**
  String get plateScanTitle;

  /// No description provided for @plateScanRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get plateScanRetry;

  /// No description provided for @plateScanChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery instead'**
  String get plateScanChooseGallery;

  /// No description provided for @plateResultDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveling in {plate}?'**
  String plateResultDialogTitle(String plate);

  /// No description provided for @plateResultDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Check the plate matches the vehicle. This sends a boarding SMS to your active emergency contacts. SIM charges may apply.'**
  String get plateResultDialogBody;

  /// No description provided for @plateResultConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm and notify'**
  String get plateResultConfirmButton;

  /// No description provided for @plateResultBoardingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load contacts. Check your connection and retry.'**
  String get plateResultBoardingFailed;

  /// No description provided for @plateResultStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get plateResultStatusSafe;

  /// No description provided for @plateResultStatusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get plateResultStatusReported;

  /// No description provided for @plateResultStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get plateResultStatusUnknown;

  /// No description provided for @plateResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status'**
  String get plateResultTitle;

  /// No description provided for @plateResultDemoPassengerRating.
  ///
  /// In en, this message translates to:
  /// **'Demo passenger rating'**
  String get plateResultDemoPassengerRating;

  /// No description provided for @plateResultPassengerRating.
  ///
  /// In en, this message translates to:
  /// **'Passenger rating'**
  String get plateResultPassengerRating;

  /// No description provided for @plateResultNotRated.
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get plateResultNotRated;

  /// No description provided for @plateResultRatingValue.
  ///
  /// In en, this message translates to:
  /// **'{average}/5 ({count})'**
  String plateResultRatingValue(String average, int count);

  /// No description provided for @plateResultUnverifiedChecks.
  ///
  /// In en, this message translates to:
  /// **'Unverified missed checks'**
  String get plateResultUnverifiedChecks;

  /// No description provided for @plateResultReportsOnFile.
  ///
  /// In en, this message translates to:
  /// **'Reports on file'**
  String get plateResultReportsOnFile;

  /// No description provided for @plateResultRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get plateResultRiskLevel;

  /// No description provided for @plateResultDbNote.
  ///
  /// In en, this message translates to:
  /// **'Vehicle checks use the shared Amica safety database. When in doubt, share your trip with a trusted contact before riding.'**
  String get plateResultDbNote;

  /// No description provided for @plateResultDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo data. These ratings are fictional.'**
  String get plateResultDemoNote;

  /// No description provided for @plateResultFeedbackNote.
  ///
  /// In en, this message translates to:
  /// **'Passenger feedback is associated with this plate, not a verified driver identity or safety guarantee.'**
  String get plateResultFeedbackNote;

  /// No description provided for @plateResultNotifying.
  ///
  /// In en, this message translates to:
  /// **'Notifying contacts...'**
  String get plateResultNotifying;

  /// No description provided for @plateResultTravelingButton.
  ///
  /// In en, this message translates to:
  /// **'I am traveling in this vehicle'**
  String get plateResultTravelingButton;

  /// No description provided for @plateResultScanAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Scan another plate'**
  String get plateResultScanAnotherButton;

  /// No description provided for @plateResultRateButton.
  ///
  /// In en, this message translates to:
  /// **'Rate a completed ride'**
  String get plateResultRateButton;

  /// No description provided for @vehicleRatingCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed vehicle rides'**
  String get vehicleRatingCompletedTitle;

  /// No description provided for @vehicleRatingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your rides. Please reconnect.'**
  String get vehicleRatingLoadError;

  /// No description provided for @vehicleRatingNoRides.
  ///
  /// In en, this message translates to:
  /// **'No completed rides for this vehicle yet.'**
  String get vehicleRatingNoRides;

  /// No description provided for @vehicleRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your journey'**
  String get vehicleRatingTitle;

  /// No description provided for @vehicleRatingPrompt.
  ///
  /// In en, this message translates to:
  /// **'How was your experience traveling in this vehicle?'**
  String get vehicleRatingPrompt;

  /// No description provided for @vehicleRatingStarsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String vehicleRatingStarsTooltip(int count);

  /// No description provided for @vehicleRatingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your rating. Please retry.'**
  String get vehicleRatingSaveFailed;

  /// No description provided for @vehicleRatingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted'**
  String get vehicleRatingSubmitted;

  /// No description provided for @vehicleRatingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get vehicleRatingSaving;

  /// No description provided for @vehicleRatingSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get vehicleRatingSubmitButton;

  /// No description provided for @vehicleRatingSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get vehicleRatingSkipButton;

  /// No description provided for @startJourneyFindingAddress.
  ///
  /// In en, this message translates to:
  /// **'Pinned. Finding the address...'**
  String get startJourneyFindingAddress;

  /// No description provided for @startJourneyAddressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pinned. No address found here, so type a name for this place.'**
  String get startJourneyAddressNotFound;

  /// No description provided for @startJourneyRouteLoading.
  ///
  /// In en, this message translates to:
  /// **'Finding a route...'**
  String get startJourneyRouteLoading;

  /// No description provided for @startJourneyRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'Suggested route: {distance} · about {minutes} min'**
  String startJourneyRouteSummary(String distance, int minutes);

  /// No description provided for @startJourneyRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a route. Using a straight-line estimate.'**
  String get startJourneyRouteUnavailable;

  /// No description provided for @journeyTimerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get journeyTimerPause;

  /// No description provided for @journeyTimerResumeNow.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get journeyTimerResumeNow;

  /// No description provided for @journeyTimerPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get journeyTimerPaused;

  /// No description provided for @journeyTimerResumesIn.
  ///
  /// In en, this message translates to:
  /// **'Resumes automatically in {time}'**
  String journeyTimerResumesIn(String time);

  /// No description provided for @journeyTimerPauseSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause the safety timer'**
  String get journeyTimerPauseSheetTitle;

  /// No description provided for @journeyTimerPauseSheetBody.
  ///
  /// In en, this message translates to:
  /// **'The countdown stops while paused. It starts again on its own when the pause ends, or you can resume it any time.'**
  String get journeyTimerPauseSheetBody;

  /// No description provided for @journeyTimerPauseMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String journeyTimerPauseMinutes(int minutes);

  /// No description provided for @journeyTimerPauseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pause for {minutes} min'**
  String journeyTimerPauseConfirm(int minutes);

  /// No description provided for @journeyTimerPausedFor.
  ///
  /// In en, this message translates to:
  /// **'Timer paused for {minutes} min'**
  String journeyTimerPausedFor(int minutes);

  /// No description provided for @journeyTimerResumed.
  ///
  /// In en, this message translates to:
  /// **'Timer resumed'**
  String get journeyTimerResumed;

  /// No description provided for @journeyTimerPauseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pause the timer. Please try again.'**
  String get journeyTimerPauseFailed;

  /// No description provided for @journeyTimerResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resume the timer. Please try again.'**
  String get journeyTimerResumeFailed;

  /// No description provided for @journeyTimerSuggestedRoute.
  ///
  /// In en, this message translates to:
  /// **'Suggested route'**
  String get journeyTimerSuggestedRoute;

  /// No description provided for @journeyTimerRouteInfo.
  ///
  /// In en, this message translates to:
  /// **'{distance} · about {minutes} min'**
  String journeyTimerRouteInfo(String distance, int minutes);

  /// No description provided for @journeyTimerNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No suggested route. Head towards the pink pin.'**
  String get journeyTimerNoRoute;

  /// No description provided for @journeyTimerOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Navigate in Google Maps'**
  String get journeyTimerOpenInMaps;

  /// No description provided for @zzzArbEnd.
  ///
  /// In en, this message translates to:
  /// **'do not translate; internal append anchor'**
  String get zzzArbEnd;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
