// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'Amica';

  @override
  String get checkingLoginStatus => 'உள்நுழைவு நிலையை சரிபார்க்கிறது';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navJourneys => 'பயணங்கள்';

  @override
  String get navCircle => 'வட்டம்';

  @override
  String get navYou => 'நீங்கள்';

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonBack => 'பின்செல்';

  @override
  String get commonContinue => 'தொடரவும்';

  @override
  String get commonEmail => 'மின்னஞ்சல்';

  @override
  String get commonPassword => 'கடவுச்சொல்';

  @override
  String get commonEnterValidEmail => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get commonYes => 'ஆம்';

  @override
  String get commonNo => 'இல்லை';

  @override
  String get commonEdit => 'திருத்து';

  @override
  String get commonDelete => 'நீக்கு';

  @override
  String get commonAdd => 'சேர்';

  @override
  String get commonRemove => 'அகற்று';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonTryAgain => 'மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginWelcomeBack => 'மீண்டும் வருக';

  @override
  String get loginSubtitle =>
      'உள்நுழையுங்கள், உங்கள் வட்டத்தினர் உங்களை மீண்டும் தொடர்பு கொள்ள முடியும்.';

  @override
  String get loginPasswordRequired => 'கடவுச்சொல் தேவை';

  @override
  String get loginForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginFailed =>
      'உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get googleSignInFailed =>
      'Google உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginButton => 'உள்நுழை';

  @override
  String get continueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get loginNewToAmica => 'Amica-வில் புதியவரா?';

  @override
  String get loginCreateAccount => 'கணக்கை உருவாக்கவும்';

  @override
  String get signupAppBarTitle => 'கணக்கை உருவாக்கவும்';

  @override
  String get signupJoinAmica => 'Amica-வில் இணையுங்கள்';

  @override
  String get signupSubtitle =>
      'பாதுகாப்பு எச்சரிக்கைகள் மற்றும் நம்பகமான தொடர்புகளுக்காக உங்கள் சுயவிவரத்தை உருவாக்கவும்.';

  @override
  String get signupNameLabel => 'பெயர்';

  @override
  String get signupPhoneLabel => 'தொலைபேசி எண்';

  @override
  String get signupSecretPhraseLabel => 'இரகசிய சொற்றொடர்';

  @override
  String get signupSecretPhraseHelper =>
      'மறைமுக SOS-ஐ இயக்க போலி அழைப்பின் போது இதைச் சொல்லுங்கள்.';

  @override
  String get signupConfirmPasswordLabel => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String fieldRequired(String field) {
    return '$field தேவை';
  }

  @override
  String get signupEmailInvalid => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get signupPasswordTooShort =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகளாவது இருக்க வேண்டும்';

  @override
  String get signupPasswordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get signupFailed => 'பதிவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get signupCreatingAccount => 'கணக்கை உருவாக்குகிறது...';

  @override
  String get signupCreateAccountButton => 'கணக்கை உருவாக்கவும்';

  @override
  String get connecting => 'இணைக்கிறது...';

  @override
  String get signupAlreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்';

  @override
  String get forgotPasswordAppBarTitle => 'கடவுச்சொல்லை மீட்டமைக்கவும்';

  @override
  String get forgotPasswordHeading => 'உங்கள் கடவுச்சொல்லை மறந்துவிட்டீர்களா?';

  @override
  String get forgotPasswordSubtitle =>
      'உங்கள் கணக்கு மின்னஞ்சலை உள்ளிடவும், Amica கடவுச்சொல் மீட்டமைப்பு இணைப்பை அனுப்பும்.';

  @override
  String get forgotPasswordEmailInvalid =>
      'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get forgotPasswordSuccess =>
      'கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பப்பட்டது. உங்கள் இன்பாக்ஸைச் சரிபார்த்து இணைப்பைப் பின்பற்றவும்.';

  @override
  String get forgotPasswordFailed =>
      'மீட்டமைப்பு மின்னஞ்சலை அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get forgotPasswordSending => 'அனுப்புகிறது...';

  @override
  String get forgotPasswordSendButton => 'மீட்டமைப்பு இணைப்பை அனுப்பவும்';

  @override
  String get forgotPasswordBackToLogin => 'உள்நுழைவுக்குத் திரும்பு';

  @override
  String get greetingMorning => 'காலை வணக்கம்';

  @override
  String get greetingAfternoon => 'மதிய வணக்கம்';

  @override
  String get greetingEvening => 'மாலை வணக்கம்';

  @override
  String get discreetModeTurnOff => 'மறைநிலைப் பயன்முறையை அணைக்கவும்';

  @override
  String get discreetModeTurnOn => 'மறைநிலைப் பயன்முறையை இயக்கவும்';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name.';
  }

  @override
  String homeGreetingNoName(String greeting) {
    return '$greeting.';
  }

  @override
  String get homeNoGuardiansSubline =>
      'இன்னும் யாரும் உங்களைக் கண்டுபிடிக்க முடியாது. Amica-வுக்கு தொடர்பு கொள்ள ஒருவரை உங்கள் வட்டத்தில் சேர்க்கவும்.';

  @override
  String homeGuardianCountSubline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'எல்லாம் அமைதி. உங்களுக்குத் தேவைப்பட்டால் $count பேர் விநாடிகளில் உங்களைக் கண்டுபிடிக்க முடியும்.',
      two:
          'எல்லாம் அமைதி. உங்களுக்குத் தேவைப்பட்டால் இருவர் விநாடிகளில் உங்களைக் கண்டுபிடிக்க முடியும்.',
      one:
          'எல்லாம் அமைதி. உங்களுக்குத் தேவைப்பட்டால் ஒருவர் விநாடிகளில் உங்களைக் கண்டுபிடிக்க முடியும்.',
    );
    return '$_temp0';
  }

  @override
  String get homeYouAreProtected => 'நீங்கள் பாதுகாக்கப்படுகிறீர்கள்';

  @override
  String get homeFinishSettingUp => 'அமைப்பை முடிக்கவும்';

  @override
  String homeProtectionReadySubline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'பாதுகாவலர்கள்',
      one: 'பாதுகாவலர்',
    );
    return 'இருப்பிடம் இயக்கத்தில் · குரல் சொல் இயக்கத்தில் · $count $_temp0';
  }

  @override
  String get homeAddGuardianPrompt =>
      'உங்கள் வட்டத்தில் குறைந்தது ஒரு பாதுகாவலரையாவது சேர்க்கவும்';

  @override
  String get homeSosHoldHint =>
      '2 விநாடிகள் அழுத்திப் பிடிக்கவும். உங்கள் வட்டத்திற்கு அறிவிக்கப்படுவதற்கு முன் ரத்து செய்ய மேலும் 5 விநாடிகள் உள்ளன.';

  @override
  String get homeSectionQuieterOptions => 'அமைதியான விருப்பங்கள்';

  @override
  String get homeTileWalkWithMe => 'என்னுடன்\nநடையுங்கள்';

  @override
  String get homeTileFakeCall => 'போலி\nஅழைப்பு';

  @override
  String get homeTileScanPlate => 'பலகையை\nஸ்கேன் செய்';

  @override
  String get homeTileStopAlert => 'நிறுத்த\nஎச்சரிக்கை';

  @override
  String get sosHoldSemanticLabel => 'SOS எச்சரிக்கையை அனுப்பவும்';

  @override
  String get sosHoldSemanticHint => 'இரண்டு விநாடிகள் அழுத்திப் பிடிக்கவும்';

  @override
  String get sosHoldLabel => 'பிடிக்கவும்';

  @override
  String get sosHoldReachingCircle => 'உங்கள் வட்டத்தை அடைகிறது…';

  @override
  String get sosHoldKeepHolding =>
      'தொடர்ந்து பிடியுங்கள். ரத்து செய்ய விடவும்.';

  @override
  String get sosHoldToSend => 'SOS அனுப்ப அழுத்திப் பிடிக்கவும்';

  @override
  String get profileAppBarTitle => 'நீங்கள்';

  @override
  String get profileLoadingYourProfile => 'உங்கள் சுயவிவரம் ஏற்றப்படுகிறது';

  @override
  String get profileVoicePhrase => 'குரல் சொல்';

  @override
  String profileVoicePhraseSet(String phrase) {
    return '“$phrase”';
  }

  @override
  String get profileVoicePhraseNotSet =>
      'அமைக்கப்படவில்லை — இதைச் சொன்னால் Amica அமைதியாக எச்சரிக்கை அனுப்பும்';

  @override
  String get profilePrivacyTitle => 'தனியுரிமை மற்றும் உங்கள் தரவு';

  @override
  String get profilePrivacySubtitle =>
      'பதிவுகள் மற்றும் இருப்பிடங்கள் சேமிக்கப்படும் இடம்';

  @override
  String get profileAllSettings => 'அனைத்து அமைப்புகளும்';

  @override
  String get profileYourProfile => 'உங்கள் சுயவிவரம்';

  @override
  String get profileSectionHowAmicaBehaves => 'Amica எவ்வாறு செயல்படுகிறது';

  @override
  String get profileSectionYourSafetySetup => 'உங்கள் பாதுகாப்பு அமைப்பு';

  @override
  String profileSetupDoneCount(int done, int total) {
    return '$total-இல் $done முடிந்தது';
  }

  @override
  String profileGuardiansInCircle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'உங்கள் வட்டத்தில் $count பாதுகாவலர்கள்',
      one: 'உங்கள் வட்டத்தில் $count பாதுகாவலர்',
    );
    return '$_temp0';
  }

  @override
  String get profileNoGuardiansYet => 'இன்னும் உங்கள் வட்டத்தில் யாரும் இல்லை';

  @override
  String get profileVoicePhraseRecorded => 'குரல் சொல் பதிவு செய்யப்பட்டது';

  @override
  String get profilePhoneConfirmed => 'தொலைபேசி எண் உறுதிப்படுத்தப்பட்டது';

  @override
  String get profileMedicalNotes => 'மீட்பாளர்களுக்கான மருத்துவக் குறிப்புகள்';

  @override
  String get profileDiscreetModeTitle => 'மறைநிலைப் பயன்முறை';

  @override
  String get profileDiscreetModeSubtitle =>
      'இருள், அமைதி, அறிவிப்புகளில் முன்னோட்டம் இல்லை';

  @override
  String get appearanceTitle => 'தோற்றம்';

  @override
  String get appearanceSubtitle =>
      'பகலில் ஒளி பயன்முறை படிக்க எளிது. இரவில் இருள் பயன்முறை மறைவாக இருக்கும்.';

  @override
  String get themeLight => 'ஒளி';

  @override
  String get themeDark => 'இருள்';

  @override
  String get themeSystem => 'சிஸ்டம்';

  @override
  String get mapRecenter => 'என் இருப்பிடத்திற்கு மையப்படுத்து';

  @override
  String get mapShowWholeRoute => 'முழு வழியைக் காட்டு';

  @override
  String get mapZoomIn => 'பெரிதாக்கு';

  @override
  String get mapZoomOut => 'சிறிதாக்கு';

  @override
  String get startJourneyYourLocation => 'உங்கள் இருப்பிடம்';

  @override
  String get profileEditTitle => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get profileEditSubtitle =>
      'Amica உங்களுக்கு விரைவாக உதவ இவற்றைப் புதுப்பித்து வைத்திருங்கள்.';

  @override
  String get profileNameLabel => 'உங்கள் பெயர்';

  @override
  String get profilePhoneLabel => 'தொலைபேசி எண்';

  @override
  String get profileMedicalNotesLabel =>
      'மருத்துவக் குறிப்புகள் (விருப்பத்தேர்வு)';

  @override
  String get profileMedicalNotesHint =>
      'ஒவ்வாமைகள், நோய் நிலைகள், மருந்துகள், இரத்த வகை…';

  @override
  String get profileNameRequired => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get profileSaved => 'சுயவிவரம் சேமிக்கப்பட்டது';

  @override
  String get profileSaveFailed =>
      'உங்கள் சுயவிவரத்தைச் சேமிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get homeSafetyTipTitle => 'இன்றைய பாதுகாப்பு குறிப்பு';

  @override
  String get homeSafetyTip1 =>
      'புறப்படுவதற்கு முன் உங்கள் பயணத்தை நம்பிக்கைக்குரிய ஒருவருடன் பகிருங்கள்.';

  @override
  String get homeSafetyTip2 =>
      'இரவில் பேருந்து மற்றும் ரயில்களில் ஓட்டுநர் அல்லது மற்ற பயணிகளுக்கு அருகில் அமருங்கள்.';

  @override
  String get homeSafetyTip3 =>
      'இரவில் வெளியே செல்லும் முன் உங்கள் தொலைபேசியில் 20%க்கு மேல் சார்ஜ் இருக்கட்டும்.';

  @override
  String get homeSafetyTip4 =>
      'உங்கள் உள்ளுணர்வை நம்புங்கள். ஒரு இடம் சரியில்லை எனத் தோன்றினால், வெளியேறி யாரிடமாவது சொல்லுங்கள்.';

  @override
  String get homeSafetyTip5 =>
      'டாக்ஸியில் ஏறும் முன் அதன் எண் பலகை உங்கள் முன்பதிவுடன் பொருந்துகிறதா எனச் சரிபாருங்கள்.';

  @override
  String get homeSafetyTip6 =>
      'தொலைபேசியைத் தொடாமலே உங்கள் வட்டத்தை எச்சரிக்க ஒரு ரகசிய குரல் சொற்றொடரை அமையுங்கள்.';

  @override
  String get phoneVerifyTitle => 'உங்கள் தொலைபேசி எண்ணைச் சரிபார்க்கவும்';

  @override
  String get phoneVerifySubtitle =>
      'இந்த எண் உங்களுடையது என்பதை உறுதிப்படுத்த 6 இலக்கக் குறியீட்டை SMS மூலம் அனுப்புவோம்.';

  @override
  String get phoneSendCode => 'குறியீட்டை அனுப்பு';

  @override
  String phoneCodeSentTo(String phone) {
    return '$phone எண்ணுக்குக் குறியீடு அனுப்பப்பட்டது';
  }

  @override
  String get phoneCodeLabel => '6 இலக்கக் குறியீடு';

  @override
  String get phoneVerifyButton => 'சரிபார்';

  @override
  String phoneResendIn(int seconds) {
    return '$seconds வி.யில் மீண்டும் அனுப்பு';
  }

  @override
  String get phoneResend => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get phoneChangeNumber => 'எண்ணை மாற்று';

  @override
  String get phoneVerified => 'தொலைபேசி எண் சரிபார்க்கப்பட்டது';

  @override
  String get phoneVerifiedBadge => 'சரிபார்க்கப்பட்டது';

  @override
  String get phoneNotVerified => 'இன்னும் சரிபார்க்கப்படவில்லை';

  @override
  String get phoneInvalidNumber =>
      'சரியான தொலைபேசி எண்ணை உள்ளிடவும், எ.கா. +94 77 123 4567';

  @override
  String get phoneErrInvalidCode =>
      'அந்தக் குறியீடு சரியில்லை. SMS-ஐச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get phoneErrExpired =>
      'இந்தக் குறியீடு காலாவதியாகிவிட்டது. புதியதை அனுப்பவும்.';

  @override
  String get phoneErrTooMany =>
      'அதிகமான முயற்சிகள். சிறிது நேரம் காத்திருந்து மீண்டும் முயலவும்.';

  @override
  String get phoneErrInUse =>
      'இந்த எண் ஏற்கனவே வேறொரு Amica கணக்குடன் இணைக்கப்பட்டுள்ளது.';

  @override
  String get phoneErrNotEnabled =>
      'இந்தச் செயலிக்குத் தொலைபேசி சரிபார்ப்பு இன்னும் இயக்கப்படவில்லை.';

  @override
  String get phoneErrAppNotAuthorized =>
      'இந்தச் செயலி பதிப்பு தொலைபேசி சரிபார்ப்புக்கு இன்னும் பதிவு செய்யப்படவில்லை.';

  @override
  String get phoneErrGeneric =>
      'உங்கள் எண்ணைச் சரிபார்க்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get phoneAddTitle => 'உங்கள் தொலைபேசி எண்ணைச் சேர்க்கவும்';

  @override
  String get phoneAddSubtitle =>
      'நீங்கள் தினமும் பயன்படுத்தும் எண்ணைச் சேமிக்கவும். SMS மூலம் சரிபார்ப்பு விரைவில் வரும்.';

  @override
  String get phoneSaved => 'தொலைபேசி எண் சேமிக்கப்பட்டது';

  @override
  String get profilePhoneAdded => 'தொலைபேசி எண் சேர்க்கப்பட்டது';

  @override
  String get profileAddPhone => 'உங்கள் தொலைபேசி எண்ணைச் சேர்க்கவும்';

  @override
  String get profileVerifyAction => 'சரிபார்';

  @override
  String get profilePhoneNotVerified =>
      'உங்கள் தொலைபேசி எண்ணை உறுதிப்படுத்தவும்';

  @override
  String profileSaveFailedWithCode(String code) {
    return 'உங்கள் சுயவிவரத்தைச் சேமிக்க முடியவில்லை ($code). இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';
  }

  @override
  String get profileLoadFailedTitle => 'உங்கள் சுயவிவரத்தை ஏற்ற முடியவில்லை';

  @override
  String get profileLoadFailedBody =>
      'உங்கள் விவரங்கள் பாதுகாப்பாக உள்ளன. இணைப்பைச் சரிபார்க்கவும் — மீண்டும் இணைந்ததும் இந்தப் பக்கம் தானாகவே புதுப்பிக்கப்படும்.';

  @override
  String get tripTitleBus => 'உங்கள் பேருந்துப் பயணம்';

  @override
  String get tripTitleTrain => 'உங்கள் ரயில் பயணம்';

  @override
  String get tripPlanning => 'உங்களுக்கு அருகிலுள்ள நிறுத்தங்களைத் தேடுகிறது…';

  @override
  String get tripTooClose =>
      'நடந்தே செல்லும் அளவுக்கு அருகில் உள்ளது — பேருந்து அல்லது ரயில் தேவையில்லை.';

  @override
  String get tripNoStops =>
      'அருகில் நிறுத்தங்களோ நிலையங்களோ கிடைக்கவில்லை. அதற்குப் பதிலாக Amica சாலை வழியைப் பயன்படுத்தும்.';

  @override
  String get tripOffline =>
      'இப்போது பயணத்தைத் திட்டமிட முடியவில்லை. அதற்குப் பதிலாக Amica சாலை வழியைப் பயன்படுத்தும்.';

  @override
  String tripWalkToStop(String distance, String stop) {
    return '$stop வரை $distance நடக்கவும்';
  }

  @override
  String tripGetOnAt(String stop) {
    return '$stop இல் ஏறவும்';
  }

  @override
  String tripGetOffAt(String stop) {
    return '$stop இல் இறங்கவும்';
  }

  @override
  String tripWalkToDestination(String distance) {
    return 'உங்கள் இலக்கு வரை $distance நடக்கவும்';
  }

  @override
  String tripRideSummary(String distance, int minutes) {
    return 'பயணம் $distance · சுமார் $minutes நிமி.';
  }

  @override
  String tripMinutes(int minutes) {
    return '$minutes நிமி.';
  }

  @override
  String tripBusLine(String line) {
    return 'பேருந்து $line';
  }

  @override
  String tripTrainLine(String line) {
    return 'ரயில்: $line';
  }

  @override
  String get tripEstimated =>
      'அருகிலுள்ள நிறுத்தங்களைக் கொண்டு மதிப்பிடப்பட்டது — நடத்துநரிடம் வழியை உறுதிசெய்யவும்.';

  @override
  String get tripChooseBoard => 'ஏறும் இடம்';

  @override
  String get tripChooseAlight => 'இறங்கும் இடம்';

  @override
  String tripStopAway(String distance) {
    return '$distance தொலைவில்';
  }

  @override
  String get stopAlertWhereGoing => 'நீங்கள் எங்கே செல்கிறீர்கள்?';

  @override
  String stopAlertWakeBefore(String stop) {
    return 'நீங்கள் இறங்க வேண்டிய $stop நிறுத்தத்திற்கு முன் Amica உங்களை எச்சரிக்கும்.';
  }

  @override
  String get sosSmsDefaultMessage => 'எனக்கு உதவி தேவை.';

  @override
  String sosSmsWithName(String name, String message, String link) {
    return '$name இடமிருந்து AMICA SOS: $message என் இருப்பிடம்: $link';
  }

  @override
  String sosSmsNoName(String message, String link) {
    return 'AMICA SOS: $message என் இருப்பிடம்: $link';
  }

  @override
  String get sosCircleSending => 'உங்கள் வட்டத்திற்குச் செய்தி அனுப்புகிறது…';

  @override
  String get sosCircleLoadFailed =>
      'உங்கள் வட்டத்தை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get sosCircleTryAgain => 'மீண்டும் முயல்க';

  @override
  String get sosCircleOpenSmsApp => 'SMS செயலியைத் திற';

  @override
  String sosCircleReachedCount(int reached, int total) {
    return '$total இல் $reached பேருக்குச் சென்றது';
  }

  @override
  String get sosCircleStatusSending => 'அனுப்புகிறது';

  @override
  String get sosCircleStatusSent => 'அனுப்பப்பட்டது';

  @override
  String get sosCircleStatusUnconfirmed => 'உறுதிசெய்யப்படவில்லை';

  @override
  String get sosCircleStatusFailed => 'தோல்வி';

  @override
  String get mapTypeTitle => 'வரைபட வகை';

  @override
  String get mapTypeDefault => 'இயல்புநிலை';

  @override
  String get mapTypeSatellite => 'செயற்கைக்கோள்';

  @override
  String get mapTypeTerrain => 'நிலப்பரப்பு';

  @override
  String get tripFeederBusHint => 'நிலையத்திற்கு நடக்க தூரம் அதிகம்';

  @override
  String get loginOr => 'அல்லது';

  @override
  String get loginShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get loginHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get signupSectionAboutYou => 'உங்களைப் பற்றி';

  @override
  String get signupSectionSafety => 'உங்கள் பாதுகாப்பு';

  @override
  String get signupSectionPassword => 'கடவுச்சொல்';

  @override
  String get signupStrengthWeak => 'பலவீனம்';

  @override
  String get signupStrengthFair => 'பரவாயில்லை';

  @override
  String get signupStrengthStrong => 'வலிமை';

  @override
  String tripRideToStation(String station) {
    return '$station வரை பேருந்து அல்லது ஆட்டோவில் செல்லவும்';
  }

  @override
  String get profileLogOut => 'வெளியேறு';

  @override
  String get profileLogOutConfirmTitle => 'Amica-விலிருந்து வெளியேறவா?';

  @override
  String get profileLogOutConfirmBody =>
      'நீங்கள் மீண்டும் உள்நுழையும் வரை உங்கள் வட்டத்தினர் Amica வழியாக உங்களைத் தொடர்பு கொள்ள முடியாது.';

  @override
  String get profileStayLoggedIn => 'உள்நுழைந்திரு';

  @override
  String get settingsAppBarTitle => 'அமைப்புகள்';

  @override
  String get settingsLoading => 'அமைப்புகள் ஏற்றப்படுகிறது';

  @override
  String get settingsCouldNotLoad => 'அமைப்புகளை ஏற்ற முடியவில்லை.';

  @override
  String get settingsSaved => 'அமைப்புகள் சேமிக்கப்பட்டன';

  @override
  String get settingsCouldNotSave =>
      'அமைப்புகளைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get settingsFakeCallSection => 'போலி அழைப்பு';

  @override
  String get settingsVolumeShortcutTitle => 'ஒலியளவு-அதிகரி குறுக்குவழி';

  @override
  String get settingsVolumeShortcutSubtitle =>
      'இயக்கப்பட்டால், Amica ஒரு பாதுகாப்பு குறுக்குவழி அறிவிப்பை இயங்க வைத்திருக்கும். அழைப்புத் திரையைத் திறக்க ஒலியளவு-அதிகரி பொத்தானை மூன்று முறை அழுத்தவும்.';

  @override
  String get settingsFakeCallerNameLabel => 'போலி அழைப்பாளர் பெயர்';

  @override
  String get settingsEnterCallerName => 'அழைப்பாளர் பெயரை உள்ளிடவும்.';

  @override
  String get settingsFakeCallerNumberLabel => 'போலி அழைப்பாளர் எண்';

  @override
  String get settingsEnterCallerNumber => 'அழைப்பாளர் எண்ணை உள்ளிடவும்.';

  @override
  String get settingsVoiceSosSection => 'மறைநிலை குரல் SOS';

  @override
  String get settingsEnableVoiceSos => 'குரல் SOS-ஐ இயக்கு';

  @override
  String get settingsListenForPhrase =>
      'செயலில் உள்ள போலி அழைப்பின் போது இரகசிய சொற்றொடருக்குக் காதுகொடுக்கும்.';

  @override
  String get settingsEnableSecretPhrase => 'இரகசிய சொற்றொடரை இயக்கு';

  @override
  String get settingsUsePhraseBelow =>
      'குரல் SOS-ஐ இயக்க கீழே உள்ள சொற்றொடரைப் பயன்படுத்தவும்.';

  @override
  String settingsSecretPhraseLabel(int number) {
    return 'இரகசிய சொற்றொடர் $number';
  }

  @override
  String get settingsEnterPhrase => 'ஒரு சொற்றொடரை உள்ளிடவும்.';

  @override
  String get settingsPhraseAlreadyListed =>
      'இந்த சொற்றொடர் ஏற்கனவே பட்டியலில் உள்ளது.';

  @override
  String get settingsRemovePhrase => 'சொற்றொடரை அகற்று';

  @override
  String get settingsAddPhrase => 'சொற்றொடரைச் சேர்';

  @override
  String get settingsSosMessageLabel => 'அவசரகால தொடர்புக்கான SOS செய்தி';

  @override
  String get settingsSosMessageHelper =>
      'சொற்றொடர் சொல்லப்படும்போது குரல் SOS எச்சரிக்கையுடன் சேமிக்கப்படும்.';

  @override
  String get settingsEnterMessage => 'அனுப்ப வேண்டிய செய்தியை உள்ளிடவும்.';

  @override
  String get settingsSaving => 'சேமிக்கிறது...';

  @override
  String get settingsSaveButton => 'அமைப்புகளைச் சேமி';

  @override
  String get settingsLanguageSection => 'மொழி';

  @override
  String get settingsLanguageSubtitle =>
      'Amica காட்டப்படும் மொழியைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get contactsAppBarTitle => 'உங்கள் வட்டம்';

  @override
  String get contactsLoading => 'அவசரகால தொடர்புகள் ஏற்றப்படுகிறது';

  @override
  String contactsLoadError(String error) {
    return 'அவசரகால தொடர்புகளை ஏற்ற முடியவில்லை.\n$error';
  }

  @override
  String get contactsEmptyTitle => 'இன்னும் யாரும் இல்லை';

  @override
  String get contactsEmptyMessage =>
      'நீங்கள் எச்சரிக்கை அனுப்பும் தருணத்தில் Amica தொடர்பு கொள்பவர்கள் உங்கள் வட்டத்தினர். நீங்கள் நம்பும் ஒருவரைச் சேர்க்கவும், பயன்பாடு செயல்படத் தொடங்கும்.';

  @override
  String get contactsAddFirstGuardian =>
      'உங்கள் முதல் பாதுகாவலரைச் சேர்க்கவும்';

  @override
  String get contactsAlertedTogetherNote =>
      'இங்கு இயக்கப்பட்டுள்ள அனைவரும் நீங்கள் எச்சரிக்கை அனுப்பும்போது ஒரே நேரத்தில் தொடர்பு கொள்ளப்படுவார்கள்.';

  @override
  String get contactsAddGuardianFab => 'பாதுகாவலரைச் சேர்க்கவும்';

  @override
  String get contactsDeleteConfirmTitle => 'தொடர்பை நீக்கவா?';

  @override
  String contactsDeleteConfirmBody(String name) {
    return 'அவசரகால தொடர்புகளிலிருந்து $name-ஐ அகற்றவா?';
  }

  @override
  String get contactsDeleted => 'தொடர்பு நீக்கப்பட்டது';

  @override
  String get contactsCouldNotDelete => 'தொடர்பை நீக்க முடியவில்லை';

  @override
  String get contactsCouldNotUpdate => 'தொடர்பைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get contactsAlertedOnSos =>
      'நீங்கள் SOS அனுப்பும்போது அறிவிக்கப்படுவார்';

  @override
  String get contactsMuted => 'முடக்கப்பட்டது — அறிவிக்கப்பட மாட்டார்';

  @override
  String contactsRemoveTooltip(String name) {
    return '$name-ஐ அகற்று';
  }

  @override
  String get addContactCouldNotSave =>
      'தொடர்பைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get addContactPermissionRequired =>
      'தொடர்பை இறக்குமதி செய்ய தொடர்புகள் அனுமதி தேவை.';

  @override
  String get addContactNoPhoneNumber =>
      'அந்த தொடர்பில் தொலைபேசி எண் சேமிக்கப்படவில்லை. ஒன்றை நேரடியாக உள்ளிடவும்.';

  @override
  String get addContactCouldNotImport =>
      'அந்த தொடர்பை இறக்குமதி செய்ய முடியவில்லை.';

  @override
  String get addContactPriorityInvalid =>
      'முன்னுரிமை ஒரு நேர்மறை எண்ணாக இருக்க வேண்டும்';

  @override
  String get addContactEditTitle => 'தொடர்பைத் திருத்து';

  @override
  String get addContactAddTitle => 'தொடர்பைச் சேர்';

  @override
  String get addContactOpeningContacts => 'தொடர்புகளைத் திறக்கிறது...';

  @override
  String get addContactImportFromPhone =>
      'மொபைல் தொடர்புகளிலிருந்து இறக்குமதி செய்';

  @override
  String get addContactNameLabel => 'பெயர்';

  @override
  String get addContactPhoneLabel => 'தொலைபேசி எண்';

  @override
  String get addContactRelationshipLabel => 'உறவு';

  @override
  String get addContactPriorityLabel => 'முன்னுரிமை';

  @override
  String get addContactPriorityHelper =>
      'குறைந்த எண்கள் முதலில் தொடர்பு கொள்ளப்படும்.';

  @override
  String get addContactSaving => 'சேமிக்கிறது...';

  @override
  String get addContactSaveButton => 'தொடர்பைச் சேமி';

  @override
  String get sosArmingSendingLabel => 'எச்சரிக்கை அனுப்பப்படுகிறது';

  @override
  String get sosArmingAlertingLabel => 'உங்கள் வட்டத்திற்கு அறிவிக்கிறது';

  @override
  String get sosArmingReachingNow => 'இப்போது அவர்களை அடைகிறது.';

  @override
  String get sosArmingCancelIfMeant => 'தவறுதலாக இருந்தால் ரத்து செய்யவும்.';

  @override
  String get sosArmingStaySafe =>
      'பாதுகாப்பாக இருந்தால் நீங்கள் இருக்கும் இடத்திலேயே இருங்கள்.';

  @override
  String get sosArmingStopNow =>
      'இப்போது நிறுத்தினால் எதுவும் அனுப்பப்படாது. நீங்கள் அழைக்க முயன்றதாக யாருக்கும் தெரிவிக்கப்படாது.';

  @override
  String get sosArmingSendFailed =>
      'உங்கள் எச்சரிக்கையை அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும் அல்லது நேரடியாக 119-ஐ அழைக்கவும்.';

  @override
  String get sosArmingWhenZero => 'எண்ணிக்கை பூஜ்ஜியத்தை அடையும்போது';

  @override
  String get sosArmingGuardianNone =>
      'உங்கள் வட்டத்திற்கு உங்கள் நேரடி இருப்பிடம் கிடைக்கும்';

  @override
  String sosArmingGuardianOne(String name) {
    return '$name-க்கு உங்கள் நேரடி இருப்பிடம் கிடைக்கும்';
  }

  @override
  String sosArmingGuardianTwo(String first, String second) {
    return '$first மற்றும் $second-க்கு உங்கள் நேரடி இருப்பிடம் கிடைக்கும்';
  }

  @override
  String sosArmingGuardianMany(String names, String last) {
    return '$names மற்றும் $last-க்கு உங்கள் நேரடி இருப்பிடம் கிடைக்கும்';
  }

  @override
  String get sosArmingRecordingAudio =>
      'உங்கள் தொலைபேசி ஒலியைப் பதிவு செய்யத் தொடங்கும்';

  @override
  String get sosArmingCallReady =>
      '119 ஏற்கனவே டயல் செய்யப்பட்டு, ஒரு தட்டுத் தொலைவில் உள்ளது';

  @override
  String get sosArmingCancelSendNothing =>
      'ரத்து செய் — எதுவும் அனுப்ப வேண்டாம்';

  @override
  String get sosArmingBackToHome => 'முகப்புக்குத் திரும்பு';

  @override
  String get sosActiveTriggerVoice => 'உங்கள் குரல் சொல்லால் இயக்கப்பட்டது';

  @override
  String get sosActiveTriggerTimer => 'உங்கள் பயண டைமர் முடிந்தது';

  @override
  String get sosActiveTriggerManual =>
      'நீங்கள் இந்த எச்சரிக்கையை அனுப்பினீர்கள்';

  @override
  String get sosActiveLive => 'எச்சரிக்கை நேரடியில்';

  @override
  String get sosActiveYourLocation => 'உங்கள் இருப்பிடம்';

  @override
  String get sosActiveUpdatingEvery10s =>
      'ஒவ்வொரு 10 விநாடிகளுக்கும் புதுப்பிக்கப்படுகிறது';

  @override
  String get sosActiveNoOneInCircle =>
      'உங்கள் வட்டத்தில் யாரும் இல்லை, எனவே அவசர சேவைகளால் மட்டுமே உதவ முடியும். 119-ஐ அழைக்கவும்.';

  @override
  String sosActiveCircleReachedHeader(int count) {
    return 'உங்கள் வட்டம் · $count பேர் அறிவிக்கப்பட்டனர்';
  }

  @override
  String get sosActiveNotified => 'அறிவிக்கப்பட்டது';

  @override
  String get sosActiveWhatAmicaIsDoing => 'Amica என்ன செய்கிறது';

  @override
  String get sosActiveSharingLocation =>
      'உங்கள் நேரடி இருப்பிடத்தைப் பகிர்கிறது';

  @override
  String get sosActiveRecordingAudio => 'ஒலியைப் பதிவு செய்கிறது';

  @override
  String get sosActiveSirenSounding => 'சைரன் — ஒலிக்கிறது';

  @override
  String get sosActiveSirenSilent => 'சைரன் — அமைதி, ஒலிக்க தட்டவும்';

  @override
  String get sosActiveOn => 'இயக்கத்தில்';

  @override
  String get sosActiveOff => 'நிறுத்தப்பட்டது';

  @override
  String get sosActiveImSafe => 'நான் பாதுகாப்பாக இருக்கிறேன் — நிறுத்து';

  @override
  String get sosActiveCall119 => '119-ஐ அழை';

  @override
  String get sosActiveStandDownNote =>
      'நிறுத்துவது நீங்கள் நலமாக இருப்பதாக உங்கள் வட்டத்திற்குத் தெரிவிக்கும். இது பதிவை நீக்காது.';

  @override
  String get sosActiveConfirmTitle =>
      'நீங்கள் பாதுகாப்பாக இருப்பதாக உங்கள் வட்டத்திற்குத் தெரிவிக்கவா?';

  @override
  String get sosActiveConfirmBody =>
      'அவர்கள் உங்கள் நேரடி இருப்பிடத்தைப் பார்ப்பதை நிறுத்துவார்கள், எச்சரிக்கை மூடப்படும்.';

  @override
  String get sosActiveKeepLive => 'நேரடியாக வைத்திரு';

  @override
  String get sosActiveYesImSafe => 'ஆம், நான் பாதுகாப்பாக இருக்கிறேன்';

  @override
  String get fakeCallPreparingCall => 'அழைப்பு தயாராகிறது';

  @override
  String get fakeCallAppBarTitle => 'போலி அழைப்பு';

  @override
  String get fakeCallHeroTitle =>
      'யாரோ உங்களை எதிர்பார்ப்பது போல் தோன்ற வையுங்கள்';

  @override
  String get fakeCallHeroSubtitle =>
      'இப்போது அழையுங்கள், அல்லது நீங்கள் ஒரு வாகனத்தில் ஏறும் தருணத்திற்கு ஒரு அழைப்பைத் திட்டமிடுங்கள். நீங்கள் பயன்பாட்டை மூடினாலும் அல்லது தொலைபேசியைப் பூட்டினாலும் Amica எண்ணிக்கையைத் தொடர்கிறது.';

  @override
  String get fakeCallRingNowInstead => 'அதற்குப் பதிலாக இப்போது அழை';

  @override
  String get fakeCallCancelScheduled => 'திட்டமிடப்பட்ட அழைப்பை ரத்து செய்';

  @override
  String get fakeCallScheduling => 'திட்டமிடுகிறது...';

  @override
  String fakeCallScheduleIn(String delay) {
    return '$delay-இல் திட்டமிடு';
  }

  @override
  String get fakeCallRingNow => 'இப்போது அழை';

  @override
  String get fakeCallDisclaimer =>
      'உண்மையான அழைப்பு எதுவும் வைக்கப்படவில்லை. அழைப்பின் போது, Amica உங்கள் இரகசிய சொற்றொடருக்குச் செவிசாய்த்து அமைதியான SOS-ஐ அனுப்பலாம்.';

  @override
  String get fakeCallEditCallerTooltip => 'அழைப்பாளரைத் திருத்து';

  @override
  String get fakeCallMeIn => 'என்னை அழை';

  @override
  String get fakeCallCallingIn => 'அழைக்கிறது';

  @override
  String get fakeCallKeepNotificationVisible =>
      '\"அழைப்பு திட்டமிடப்பட்டது\" அறிவிப்பைக் காணக்கூடியதாக வைத்திருங்கள். இப்போது Amica-வை மூடலாம்.';

  @override
  String fakeCallScheduledSnackbar(String name, String delay) {
    return '$name $delay-இல் அழைப்பார். நீங்கள் Amica-வை மூடலாம்.';
  }

  @override
  String get fakeCallCouldNotSchedule =>
      'இந்த சாதனத்தில் அழைப்பை திட்டமிட முடியவில்லை.';

  @override
  String get fakeCallScheduleCancelled =>
      'திட்டமிடப்பட்ட அழைப்பு ரத்து செய்யப்பட்டது';

  @override
  String get fakeCallCouldNotCancel =>
      'திட்டமிடப்பட்ட அழைப்பை ரத்து செய்ய முடியவில்லை.';

  @override
  String get fakeCallIncoming => 'வரும் அழைப்பு';

  @override
  String get fakeCallMobile => 'மொபைல்';

  @override
  String get fakeCallDecline => 'நிராகரி';

  @override
  String get fakeCallAccept => 'ஏற்றுக்கொள்';

  @override
  String get fakeCallActiveCouldNotCompleteVoiceSos =>
      'குரல் SOS-ஐ முடிக்க முடியவில்லை. தேவைப்பட்டால் கையேடு SOS-ஐப் பயன்படுத்தவும்.';

  @override
  String get fakeCallActiveConnected => 'அழைப்பு இணைக்கப்பட்டது';

  @override
  String get fakeCallActiveMute => 'முடக்கு';

  @override
  String get fakeCallActiveKeypad => 'கீபேட்';

  @override
  String get fakeCallActiveSpeaker => 'ஸ்பீக்கர்';

  @override
  String get fakeCallActiveAddCall => 'அழைப்பைச் சேர்';

  @override
  String get fakeCallActiveHold => 'வைத்திரு';

  @override
  String get fakeCallActiveBluetooth => 'புளூடூத்';

  @override
  String get journeysScreenCheckingJourneys =>
      'உங்கள் பயணங்களைச் சரிபார்க்கிறது';

  @override
  String get safetyCheckDefaultTrip => 'உங்கள் பயணம்';

  @override
  String get safetyCheckAreYouSafe => 'நீங்கள் பாதுகாப்பாக இருக்கிறீர்களா?';

  @override
  String safetyCheckTimerEnded(String destination) {
    return '$destination-க்கான உங்கள் பயண டைமர் முடிந்துவிட்டது.';
  }

  @override
  String get safetyCheckImSafe => 'நான் பாதுகாப்பாக இருக்கிறேன்';

  @override
  String get safetyCheckSendSosNow => 'இப்போது SOS அனுப்பு';

  @override
  String get safetyCheckSafeClosesNote =>
      '\"நான் பாதுகாப்பாக இருக்கிறேன்\" என்பதைத் தட்டுவது இந்த பயணத்தை மூடும். Amica கண்காணிப்பதை நிறுத்தும், யாரையும் தொடர்பு கொள்ளாது.';

  @override
  String get safetyCheckAnswerPrompt =>
      'உங்கள் அவசரகால தொடர்புக்கு அறிவிக்க வேண்டுமா என்று Amica அறிய பதிலளிக்கவும்.';

  @override
  String get safetyCheckContactAlerted =>
      'Amica உங்கள் அவசரகால தொடர்புக்கு அறிவித்துள்ளது';

  @override
  String get safetyCheckAutoAlertIn => 'தானியங்கு எச்சரிக்கை';

  @override
  String get safetyCheckEscalationExplain =>
      'நீங்கள் பதிலளிக்கவில்லை என்றால், Amica உங்கள் முதன்மை அவசரகால தொடர்புக்கு உங்கள் நேரடி இருப்பிடத்துடன் செய்தி அனுப்பி, பின்னர் அவர்களை அழைக்கும்.';

  @override
  String get safetyCheckAfterEscalationNote =>
      'நீங்கள் இன்னும் பாதுகாப்பாக இருப்பதை உறுதிப்படுத்தலாம், அல்லது உங்கள் நேரடி இருப்பிடத்துடன் முழு SOS-க்கு உயர்த்தலாம்.';

  @override
  String get startJourneyFindingOnMap => 'வரைபடத்தில் இலக்கைக் கண்டறிகிறது...';

  @override
  String get startJourneyDestinationFound =>
      'இலக்கு வரைபடத்தில் கண்டறியப்பட்டது.';

  @override
  String get startJourneyDestinationNotFound =>
      'இலக்கு கிடைக்கவில்லை. வரைபடத்தில் அதைக் குறிக்கவும்.';

  @override
  String get startJourneyCouldNotGetLocation =>
      'தற்போதைய இருப்பிடத்தைப் பெற முடியவில்லை.';

  @override
  String get startJourneyGetLocationFirst =>
      'முதலில் உங்கள் தற்போதைய இருப்பிடத்தைப் பெறவும்.';

  @override
  String get startJourneyChooseDestination =>
      'வரைபடத்தில் இலக்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get startJourneyCouldNotStart => 'பயணத்தைத் தொடங்க முடியவில்லை.';

  @override
  String get startJourneyDestinationPinSelected =>
      'இலக்கு பின் தேர்ந்தெடுக்கப்பட்டது.';

  @override
  String get startJourneyDestinationLabel => 'இலக்கு';

  @override
  String get startJourneyWalkWithMeTitle => 'என்னுடன் நடையுங்கள்';

  @override
  String get startJourneyRideWithMeTitle => 'என்னுடன் பயணியுங்கள்';

  @override
  String startJourneyVehicleLabel(String plate) {
    return 'வாகனம்: $plate';
  }

  @override
  String get startJourneyGettingLocation => 'இருப்பிடத்தைப் பெறுகிறது...';

  @override
  String get startJourneyGetCurrentLocation =>
      'தற்போதைய இருப்பிடத்தைப் பெறவும்';

  @override
  String get startJourneyCurrentLocationNotSelected =>
      'தற்போதைய இருப்பிடம்: இன்னும் தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String startJourneyCurrentLocationValue(String lat, String lng) {
    return 'தற்போதைய இருப்பிடம்: $lat, $lng';
  }

  @override
  String get startJourneyDestinationNameLabel => 'இலக்கு பெயர் அல்லது முகவரி';

  @override
  String get startJourneyMapStartMarker => 'பயண தொடக்கம்';

  @override
  String get startJourneyTapMapToPin =>
      'இலக்கைக் குறிக்க வரைபடத்தைத் தட்டவும்.';

  @override
  String startJourneyDestinationPinValue(String lat, String lng) {
    return 'இலக்கு பின்: $lat, $lng';
  }

  @override
  String get startJourneyTypeLabel => 'பயண வகை';

  @override
  String get startJourneyTypeWalk => 'நடை';

  @override
  String get startJourneyTypeTaxi => 'டாக்சி';

  @override
  String get startJourneyTypeBus => 'பேருந்து';

  @override
  String get startJourneyTypeTrain => 'ரயில்';

  @override
  String get startJourneyTypeOther => 'மற்றவை';

  @override
  String get startJourneyDurationLabel =>
      'மதிப்பிடப்பட்ட கால அளவு (நிமிடங்களில்)';

  @override
  String get startJourneyDurationInvalid => 'நேர்மறை கால அளவை உள்ளிடவும்';

  @override
  String startJourneySuggestedDuration(int minutes) {
    return 'பரிந்துரைக்கப்பட்ட கால அளவு: $minutes நிமிடங்கள் (தோராயமானது; போக்குவரத்து தரவு இல்லை)';
  }

  @override
  String get startJourneyStarting => 'தொடங்குகிறது...';

  @override
  String get startJourneyStartButton => 'பயணத்தைத் தொடங்கு';

  @override
  String get startJourneyStartVehicleButton => 'வாகனப் பயணத்தைத் தொடங்கு';

  @override
  String get journeyTimerMarkedSafe => 'பயணம் பாதுகாப்பானது என குறிக்கப்பட்டது';

  @override
  String get journeyTimerMarkSafeFailed =>
      'பயணத்தைப் பாதுகாப்பானது என குறிக்க முடியவில்லை';

  @override
  String get journeyTimerSendingSos => 'SOS எச்சரிக்கை அனுப்பப்படுகிறது...';

  @override
  String get journeyTimerSosCreateFailed =>
      'SOS எச்சரிக்கையை உருவாக்க முடியவில்லை';

  @override
  String get journeyTimerNoContactFound =>
      'செயலில் உள்ள அவசரகால தொடர்பு எதுவும் இல்லை.';

  @override
  String journeyTimerSmsSubmitted(int count) {
    return '$count தொடர்புகளுக்கு அவசரகால எஸ்எம்எஸ் அனுப்பப்பட்டது.';
  }

  @override
  String get journeyTimerMessagePrepFailed =>
      'அவசரகால செய்தியைத் தயார் செய்ய முடியவில்லை.';

  @override
  String get journeyTimerNoContactFoundCall =>
      'அழைப்புக்கான செயலில் உள்ள அவசரகால தொடர்பு இல்லை.';

  @override
  String journeyTimerCalling(String name) {
    return '$name அழைக்கப்படுகிறார்.';
  }

  @override
  String get journeyTimerCallOpenFailed =>
      'அவசரகால அழைப்பைத் திறக்க முடியவில்லை.';

  @override
  String get journeyTimerEmergencyLocationUnavailable =>
      'இருப்பிடம் கிடைக்கவில்லை.';

  @override
  String journeyTimerEmergencyLocationLine(String url) {
    return 'இருப்பிடம்: $url';
  }

  @override
  String get journeyTimerEmergencyAlertIntro =>
      'Amica பாதுகாப்பு எச்சரிக்கை: எனது பயண பாதுகாப்பு சரிபார்ப்புக்கு நான் பதிலளிக்கவில்லை.';

  @override
  String journeyTimerEmergencyVehicleLine(String plate) {
    return 'வாகனம்: $plate.';
  }

  @override
  String journeyTimerEmergencyDestinationLine(String name) {
    return 'இலக்கு: $name.';
  }

  @override
  String get journeyTimerTitle => 'பயணம்';

  @override
  String get journeyTimerLoading => 'பயணம் ஏற்றப்படுகிறது';

  @override
  String journeyTimerLoadError(String error) {
    return 'பயணத்தை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get journeyTimerNoActiveJourney => 'செயலில் உள்ள பயணம் எதுவும் இல்லை.';

  @override
  String get journeyTimerStatusActive => 'செயலில்';

  @override
  String get journeyTimerStatusSafe => 'பாதுகாப்பானது';

  @override
  String get journeyTimerStatusSos => 'SOS';

  @override
  String journeyTimerEstimatedDuration(int minutes) {
    return 'மதிப்பிடப்பட்ட கால அளவு: $minutes நிமிடங்கள்';
  }

  @override
  String get journeyTimerTimeRemaining => 'மீதமுள்ள நேரம்';

  @override
  String get journeyTimerMapMarkerTitle => 'பயண இருப்பிடம்';

  @override
  String get journeyTimerSaving => 'சேமிக்கிறது...';

  @override
  String get journeyTimerTriggerTestSos => 'சோதனை SOS ஐ இயக்கு';

  @override
  String get stopAlertSetupFindingStop =>
      'உங்கள் நிறுத்தத்தை வரைபடத்தில் தேடுகிறது...';

  @override
  String get stopAlertSetupStopFound =>
      'நிறுத்தம் வரைபடத்தில் கண்டறியப்பட்டது.';

  @override
  String get stopAlertSetupStopNotFound =>
      'நிறுத்தம் கிடைக்கவில்லை. அதைக் குறிக்க வரைபடத்தைத் தட்டவும்.';

  @override
  String get stopAlertSetupStopPinned =>
      'நிறுத்தம் வரைபடத்தில் குறிக்கப்பட்டது.';

  @override
  String get stopAlertSetupLocationError =>
      'உங்கள் தற்போதைய இருப்பிடத்தைப் பெற முடியவில்லை.';

  @override
  String get stopAlertSetupNeedLocation =>
      'முதலில் உங்கள் தற்போதைய இருப்பிடத்தைப் பெறவும்.';

  @override
  String get stopAlertSetupNeedStop =>
      'உங்கள் நிறுத்தத்தைத் தேடுங்கள் அல்லது அதைக் குறிக்க வரைபடத்தைத் தட்டவும்.';

  @override
  String get stopAlertSetupStartFailed =>
      'பேருந்து பயணத்தைத் தொடங்க முடியவில்லை.';

  @override
  String get stopAlertSetupValidateDropOff =>
      'எச்சரிக்கை நீங்கள் செல்லும் இடத்தைத் தெரிவிக்க உங்கள் நிறுத்தத்திற்கு பெயரிடவும்';

  @override
  String get stopAlertSetupTitle => 'பேருந்து நிறுத்த எச்சரிக்கை';

  @override
  String get stopAlertSetupHeadline =>
      'உங்கள் நிறுத்தத்தை ஒருபோதும் தவறவிடாதீர்கள்';

  @override
  String get stopAlertSetupIntro =>
      'நீங்கள் இறங்கும் இடத்தைத் தேர்ந்தெடுக்கவும். Amica தூரத்தைக் கண்காணித்து நீங்கள் சென்றடைவதற்கு முன் அலாரம் ஒலிக்கும், எனவே உங்கள் நிறுத்தத்தைத் தவறவிடாமல் பேருந்தில் ஓய்வெடுக்கலாம்.';

  @override
  String get stopAlertSetupGettingLocation => 'இருப்பிடம் பெறப்படுகிறது...';

  @override
  String get stopAlertSetupUpdateLocation =>
      'தற்போதைய இருப்பிடத்தைப் புதுப்பிக்கவும்';

  @override
  String get stopAlertSetupLocationUnavailable =>
      'தற்போதைய இருப்பிடம்: இன்னும் கிடைக்கவில்லை';

  @override
  String stopAlertSetupLocationKnown(String lat, String lng) {
    return 'தற்போதைய இருப்பிடம்: $lat, $lng';
  }

  @override
  String get stopAlertSetupDropOffLabel => 'நீங்கள் எங்கே இறங்குகிறீர்கள்?';

  @override
  String get stopAlertSetupYouAreHereMarker => 'நீங்கள் இங்கே இருக்கிறீர்கள்';

  @override
  String get stopAlertSetupYourStopDefault => 'உங்கள் நிறுத்தம்';

  @override
  String get stopAlertSetupTapToPin =>
      'உங்கள் நிறுத்தத்தைக் குறிக்க வரைபடத்தைத் தட்டவும்.';

  @override
  String stopAlertSetupStopPinnedAt(String lat, String lng) {
    return 'நிறுத்தம் $lat, $lng இல் குறிக்கப்பட்டது';
  }

  @override
  String get stopAlertSetupStartButton => 'பேருந்து பயணத்தைத் தொடங்கு';

  @override
  String get stopAlertSetupKeepNotificationNote =>
      'Amica கண்காணிப்பு அறிவிப்பைக் காணக்கூடியதாக வைத்திருங்கள். ஆப் மூடப்பட்டிருந்தாலும் திரை அணைந்திருந்தாலும் அலாரம் ஒலிக்கும்.';

  @override
  String get stopAlertSetupAlertDistanceLabel =>
      'நிறுத்தத்திலிருந்து இவ்வளவு தூரத்தில் எனக்குத் தெரிவிக்கவும்';

  @override
  String get stopAlertSetupCheckingRoadDistance =>
      'உங்கள் நிறுத்தத்திற்கான சாலை தூரம் சரிபார்க்கப்படுகிறது...';

  @override
  String stopAlertSetupDistanceStraightLine(String distance) {
    return 'உங்கள் நிறுத்தம் நேர்கோட்டில் $distance தொலைவில் உள்ளது.';
  }

  @override
  String stopAlertSetupDistanceByRoad(String distance) {
    return 'உங்கள் நிறுத்தம் சாலை வழியாக தோராயமாக $distance தொலைவில் உள்ளது.';
  }

  @override
  String stopAlertSetupTooClose(String alertDistance) {
    return 'நீங்கள் ஏற்கனவே இந்த நிறுத்தத்தின் $alertDistance தூரத்திற்குள் இருப்பதால், அலாரம் உடனடியாக ஒலிக்கும். குறுகிய எச்சரிக்கை தூரத்தைத் தேர்ந்தெடுக்கவும்.';
  }

  @override
  String get stopAlertActiveLocationPaused =>
      'நேரடி இருப்பிடம் இடைநிறுத்தப்பட்டது. Amica பின்னணியில் கண்காணிக்கிறது.';

  @override
  String get stopAlertActiveCloseFailed => 'பயணப் பதிவை மூட முடியவில்லை';

  @override
  String get stopAlertActiveLoading => 'உங்கள் பயணம் ஏற்றப்படுகிறது';

  @override
  String stopAlertActiveLoadError(String error) {
    return 'பயணத்தை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get stopAlertActiveNoRide => 'செயலில் உள்ள பேருந்து பயணம் இல்லை.';

  @override
  String get stopAlertActiveGettingOffAt => 'இறங்குமிடம்';

  @override
  String get stopAlertActiveAlertDistance => 'எச்சரிக்கை தூரம்';

  @override
  String get stopAlertActiveBackgroundAlarm => 'பின்னணி அலாரம்';

  @override
  String get stopAlertActiveStatusActive => 'செயலில்';

  @override
  String get stopAlertActiveStatusAppOnly => 'ஆப் மட்டும்';

  @override
  String get stopAlertActiveDistanceMeasured => 'அளக்கப்பட்ட தூரம்';

  @override
  String get stopAlertActiveByRoad => 'சாலை வழியாக';

  @override
  String get stopAlertActiveStraightLine => 'நேர்கோடு';

  @override
  String get stopAlertActiveEnding => 'முடிக்கிறது...';

  @override
  String get stopAlertActiveGetOffButton => 'நான் இங்கு இறங்குகிறேன்';

  @override
  String get stopAlertActiveCanLockPhone =>
      'உங்கள் தொலைபேசியைப் பூட்டலாம். உங்கள் நிறுத்தத்திற்கு முன் Amica அலாரம் அளிக்கும்.';

  @override
  String get stopAlertActiveKeepScreenOpen =>
      'Amica உங்கள் நிறுத்தத்தைக் கண்காணிக்க இந்தத் திரையைத் திறந்து வையுங்கள்.';

  @override
  String get stopAlertActiveComingUp => 'உங்கள் நிறுத்தம் நெருங்குகிறது';

  @override
  String get stopAlertActiveDistanceLabel => 'உங்கள் நிறுத்தத்திற்கான தூரம்';

  @override
  String stopAlertActiveGetReady(String name) {
    return '$name இல் இறங்க தயாராகுங்கள்.';
  }

  @override
  String stopAlertActiveWillAlarmAt(String distance) {
    return 'Amica $distance இல் அலாரம் அளிக்கும்.';
  }

  @override
  String get plateScanStartingCamera => 'கேமரா தொடங்கப்படுகிறது...';

  @override
  String get plateScanAlignPrompt =>
      'பலகையை சட்டகத்திற்குள் சீரமைத்து ஷட்டரைத் தட்டவும்';

  @override
  String get plateScanNoCamera => 'இந்த சாதனத்தில் கேமரா எதுவும் இல்லை.';

  @override
  String get plateScanPermissionRequired =>
      'பலகையை ஸ்கேன் செய்ய கேமரா அனுமதி தேவை. கணினி அமைப்புகளில் அதை இயக்கவும்.';

  @override
  String get plateScanCameraStartFailed => 'கேமராவைத் தொடங்க முடியவில்லை.';

  @override
  String get plateScanReading => 'பலகை படிக்கப்படுகிறது...';

  @override
  String plateScanDetected(String plate) {
    return 'கண்டறியப்பட்டது $plate';
  }

  @override
  String get plateScanNotDetected =>
      'பலகை கண்டறியப்படவில்லை. அதை சட்டகத்திற்குள் சீரமைத்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String plateScanChecking(String plate) {
    return '$plate சரிபார்க்கப்படுகிறது...';
  }

  @override
  String get plateScanGalleryNoPlate =>
      'ஒரு பலகை மட்டும் கண்டறியப்படவில்லை. வேறு படத்தை முயற்சிக்கவும் அல்லது பலகையை உள்ளிடவும்.';

  @override
  String get plateScanGalleryFailed =>
      'பலகையை ஸ்கேன் செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get plateScanEnterTitle => 'பலகை எண்ணை உள்ளிடவும்';

  @override
  String get plateScanCheckButton => 'சரிபார்';

  @override
  String get plateScanInvalidPlate =>
      'CAB-1234, WP KA-1234 அல்லது 65-1234 போன்ற எண்ணை உள்ளிடவும்.';

  @override
  String get plateScanEmptyPlate => 'முதலில் வாகன எண்ணை உள்ளிடவும்.';

  @override
  String get plateScanConfirmTitle => 'வாகன எண்ணை உறுதிப்படுத்தவும்';

  @override
  String get plateScanConfirmMessage =>
      'படித்த எண்ணைச் சரிபார்த்து, தேவைப்பட்டால் திருத்தவும்.';

  @override
  String get plateScanUnreadMessage =>
      'எண் பலகையைத் தெளிவாகப் படிக்க முடியவில்லை. பலகையில் உள்ள எண்ணை உள்ளிடவும்.';

  @override
  String get plateScanTitle => 'பயணிப்பதற்கு முன் ஸ்கேன் செய்யுங்கள்';

  @override
  String get plateScanRetry => 'மீண்டும் முயற்சி';

  @override
  String get plateScanChooseGallery =>
      'அதற்கு பதிலாக கேலரியிலிருந்து தேர்ந்தெடுக்கவும்';

  @override
  String plateResultDialogTitle(String plate) {
    return '$plate இல் பயணிக்கிறீர்களா?';
  }

  @override
  String get plateResultDialogBody =>
      'பலகை வாகனத்துடன் பொருந்துகிறதா எனச் சரிபார்க்கவும். இது உங்கள் செயலில் உள்ள அவசரகால தொடர்புகளுக்கு பயணம் தொடங்கியதை அறிவிக்கும் எஸ்எம்எஸ் அனுப்பும். சிம் கட்டணங்கள் விதிக்கப்படலாம்.';

  @override
  String get plateResultConfirmButton => 'உறுதிசெய்து அறிவிக்கவும்';

  @override
  String get plateResultBoardingFailed =>
      'தொடர்புகளை ஏற்ற முடியவில்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get plateResultStatusSafe => 'பாதுகாப்பானது';

  @override
  String get plateResultStatusReported => 'புகாரளிக்கப்பட்டது';

  @override
  String get plateResultStatusUnknown => 'தெரியவில்லை';

  @override
  String get plateResultTitle => 'வாகன நிலை';

  @override
  String get plateResultDemoPassengerRating => 'டெமோ பயணிகள் மதிப்பீடு';

  @override
  String get plateResultPassengerRating => 'பயணிகள் மதிப்பீடு';

  @override
  String get plateResultNotRated => 'மதிப்பிடப்படவில்லை';

  @override
  String plateResultRatingValue(String average, int count) {
    return '$average/5 ($count)';
  }

  @override
  String get plateResultUnverifiedChecks =>
      'சரிபார்க்கப்படாத தவறவிட்ட சரிபார்ப்புகள்';

  @override
  String get plateResultReportsOnFile => 'பதிவு செய்யப்பட்ட புகார்கள்';

  @override
  String get plateResultRiskLevel => 'ஆபத்து நிலை';

  @override
  String get plateResultDbNote =>
      'வாகன சோதனைகள் பகிரப்பட்ட Amica பாதுகாப்பு தரவுத்தளத்தைப் பயன்படுத்துகின்றன. சந்தேகம் இருந்தால், பயணிப்பதற்கு முன் நம்பகமான தொடர்புடன் உங்கள் பயணத்தைப் பகிரவும்.';

  @override
  String get plateResultPhotoTitle => 'இந்த வாகனம் இப்படித் தோன்றியது';

  @override
  String get plateResultPhotoCaption =>
      'இந்த எண்ணை முதலில் ஸ்கேன் செய்த Amica பயணி சேமித்தது. ஏறும் முன் உங்கள் முன் உள்ள வாகனம் இதுவா எனச் சரிபார்க்கவும்.';

  @override
  String get plateResultDemoNote => 'டெமோ தரவு. இந்த மதிப்பீடுகள் கற்பனையானவை.';

  @override
  String get plateResultFeedbackNote =>
      'பயணிகள் கருத்துக்கள் இந்த பலகையுடன் தொடர்புடையவை, சரிபார்க்கப்பட்ட ஓட்டுநர் அடையாளம் அல்லது பாதுகாப்பு உத்தரவாதம் அல்ல.';

  @override
  String get plateResultNotifying => 'தொடர்புகளுக்கு அறிவிக்கப்படுகிறது...';

  @override
  String get plateResultTravelingButton => 'நான் இந்த வாகனத்தில் பயணிக்கிறேன்';

  @override
  String get plateResultScanAnotherButton => 'மற்றொரு பலகையை ஸ்கேன் செய்யவும்';

  @override
  String get plateResultRateButton => 'முடிந்த பயணத்தை மதிப்பிடவும்';

  @override
  String get vehicleRatingCompletedTitle => 'முடிந்த வாகனப் பயணங்கள்';

  @override
  String get vehicleRatingLoadError =>
      'உங்கள் பயணங்களை ஏற்ற முடியவில்லை. மீண்டும் இணைக்கவும்.';

  @override
  String get vehicleRatingNoRides =>
      'இந்த வாகனத்திற்கு இன்னும் முடிந்த பயணங்கள் இல்லை.';

  @override
  String get vehicleRatingTitle => 'உங்கள் பயணத்தை மதிப்பிடவும்';

  @override
  String get vehicleRatingPrompt =>
      'இந்த வாகனத்தில் பயணித்த உங்கள் அனுபவம் எப்படி இருந்தது?';

  @override
  String vehicleRatingStarsTooltip(int count) {
    return '$count நட்சத்திரங்கள்';
  }

  @override
  String get vehicleRatingSaveFailed =>
      'உங்கள் மதிப்பீட்டைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get vehicleRatingSubmitted => 'மதிப்பீடு சமர்ப்பிக்கப்பட்டது';

  @override
  String get vehicleRatingSaving => 'சேமிக்கிறது...';

  @override
  String get vehicleRatingSubmitButton => 'மதிப்பீட்டைச் சமர்ப்பிக்கவும்';

  @override
  String get vehicleRatingSkipButton => 'தவிர்';

  @override
  String get vehicleRatingCommentLabel =>
      'கருத்தைச் சேர்க்கவும் (விருப்பத்திற்குரியது)';

  @override
  String get vehicleRatingCommentHint =>
      'இந்தப் பயணம் அல்லது ஓட்டுநர் பற்றி மற்றவர்கள் தெரிந்துகொள்ள வேண்டியது ஏதாவது உள்ளதா?';

  @override
  String get startJourneyFindingAddress =>
      'பின் செய்யப்பட்டது. முகவரியைத் தேடுகிறது...';

  @override
  String get startJourneyAddressNotFound =>
      'பின் செய்யப்பட்டது. இங்கு முகவரி கிடைக்கவில்லை, இந்த இடத்திற்கு ஒரு பெயரைத் தட்டச்சு செய்யவும்.';

  @override
  String get startJourneyRouteLoading => 'வழியைத் தேடுகிறது...';

  @override
  String startJourneyRouteSummary(String distance, int minutes) {
    return 'பரிந்துரைக்கப்பட்ட வழி: $distance · சுமார் $minutes நிமிடம்';
  }

  @override
  String get startJourneyRouteUnavailable =>
      'வழியைப் பெற முடியவில்லை. நேர்கோட்டு மதிப்பீடு பயன்படுத்தப்படுகிறது.';

  @override
  String get journeyTimerPause => 'இடைநிறுத்து';

  @override
  String get journeyTimerResumeNow => 'தொடரவும்';

  @override
  String get journeyTimerPaused => 'இடைநிறுத்தப்பட்டது';

  @override
  String journeyTimerResumesIn(String time) {
    return '$time இல் தானாகவே தொடரும்';
  }

  @override
  String get journeyTimerPauseSheetTitle => 'பாதுகாப்பு டைமரை இடைநிறுத்து';

  @override
  String get journeyTimerPauseSheetBody =>
      'இடைநிறுத்தத்தின் போது கவுண்ட்டவுன் நிற்கும். இடைநிறுத்தம் முடிந்ததும் அது தானாகவே மீண்டும் தொடங்கும், அல்லது எந்த நேரத்திலும் நீங்கள் தொடரலாம்.';

  @override
  String journeyTimerPauseMinutes(int minutes) {
    return '$minutes நிமிடம்';
  }

  @override
  String journeyTimerPauseConfirm(int minutes) {
    return '$minutes நிமிடம் இடைநிறுத்து';
  }

  @override
  String journeyTimerPausedFor(int minutes) {
    return 'டைமர் $minutes நிமிடம் இடைநிறுத்தப்பட்டது';
  }

  @override
  String get journeyTimerResumed => 'டைமர் தொடர்கிறது';

  @override
  String get journeyTimerPauseFailed =>
      'டைமரை இடைநிறுத்த முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get journeyTimerResumeFailed =>
      'டைமரைத் தொடர முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get journeyTimerSuggestedRoute => 'பரிந்துரைக்கப்பட்ட வழி';

  @override
  String journeyTimerRouteInfo(String distance, int minutes) {
    return '$distance · சுமார் $minutes நிமிடம்';
  }

  @override
  String get journeyTimerNoRoute =>
      'பரிந்துரைக்கப்பட்ட வழி இல்லை. இளஞ்சிவப்பு பின்னை நோக்கிச் செல்லவும்.';

  @override
  String get journeyTimerOpenInMaps => 'Google Maps இல் வழிசெலுத்து';

  @override
  String get liveShareToggleTitle => 'என் வட்டத்துடன் நேரலையில் பகிர்';

  @override
  String get liveShareToggleSubtitle =>
      'இந்தப் பயணத்தை வரைபடத்தில் பார்க்க உங்கள் தொடர்புகளுக்கு ஒரு இணைப்பு கிடைக்கும் — செயலி தேவையில்லை.';

  @override
  String get liveShareOnTitle => 'உங்கள் வட்டத்துடன் நேரலையில் பகிரப்படுகிறது';

  @override
  String get liveShareOnSubtitle =>
      'உங்கள் தொடர்புகள் இந்தப் பயணத்தை வரைபடத்தில் பார்க்கலாம்.';

  @override
  String get liveShareOffTitle => 'உங்கள் வட்டம் நேரலையில் பார்க்கட்டும்';

  @override
  String get liveShareOffSubtitle =>
      'நீங்கள் சென்றடையும் வரை நீங்கள் இருக்கும் இடத்தைக் காட்டும் இணைப்பை அனுப்பு.';

  @override
  String get liveShareSending => 'நேரலை இணைப்பை அனுப்புகிறது…';

  @override
  String liveShareSentSummary(int pushed, int texted) {
    return 'அனுப்பப்பட்டது: Amica அறிவிப்பு மூலம் $pushed, SMS மூலம் $texted.';
  }

  @override
  String liveShareSomeFailed(int count) {
    return '$count பேரை அடைய முடியவில்லை.';
  }

  @override
  String get liveShareShareNow => 'நேரலை இணைப்பைப் பகிர்';

  @override
  String get liveShareSendAgain => 'இணைப்பை மீண்டும் அனுப்பு';

  @override
  String get liveShareCopyLink => 'இணைப்பை நகலெடு';

  @override
  String get liveShareLinkCopied => 'நேரலை இணைப்பு நகலெடுக்கப்பட்டது.';

  @override
  String get liveShareCreateFailed =>
      'நேரலை இணைப்பை உருவாக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get liveShareContactsFailed =>
      'இணைப்பு தயார், ஆனால் அனுப்ப உங்கள் தொடர்புகளை ஏற்ற முடியவில்லை.';

  @override
  String liveShareSmsWithName(String name, String destination, String url) {
    return 'Amica: $name $destination நோக்கிச் செல்கிறார். அவரது பயணத்தை நேரலையில் பாருங்கள்: $url';
  }

  @override
  String liveShareSmsNoName(String destination, String url) {
    return 'Amica: நான் $destination நோக்கிச் செல்கிறேன். என் பயணத்தை நேரலையில் பாருங்கள்: $url';
  }

  @override
  String liveShareEmergencyLine(String url) {
    return 'நேரலை: $url';
  }

  @override
  String get liveShareTrackingTitle => 'உங்கள் நேரலை இருப்பிடம் பகிரப்படுகிறது';

  @override
  String get liveShareTrackingText =>
      'நீங்கள் சென்றடையும் வரை உங்கள் வட்டம் இந்தப் பயணத்தைப் பின்தொடரலாம்.';

  @override
  String get contactsConnectInAmica => 'உடனடி எச்சரிக்கைகளுக்கு Amica இல் இணை';

  @override
  String get contactsLinkedInAmica =>
      'Amica இல் உடனடி எச்சரிக்கைகள் பெறுகிறார்';

  @override
  String circleConnectTitle(String name) {
    return '$name ஐ Amica இல் இணை';
  }

  @override
  String circleConnectBody(String name) {
    return '$name இடம் Amica இருந்தால், உங்கள் SOS எச்சரிக்கைகளும் நேரலை பயணங்களும் உடனடி அறிவிப்புகளாக அவரைச் சேரும் — இலவசம், SMS ஐ விட வேகமானது. அவர் ஒரே தட்டலில் பதிலளிக்கலாம். அவரது செயலியில் உள்ளிட ஒரு குறியீட்டை SMS மூலம் அனுப்புவோம்.';
  }

  @override
  String circleConnectLinkedTitle(String name) {
    return '$name Amica இல் இணைக்கப்பட்டுள்ளார்';
  }

  @override
  String circleConnectLinkedBody(String name) {
    return '$name உங்கள் SOS எச்சரிக்கைகளையும் நேரலை பயணங்களையும் SMS உடன் உடனடி அறிவிப்புகளாகவும் பெறுகிறார்.';
  }

  @override
  String circleConnectSendCode(String name) {
    return '$name க்கு குறியீட்டை SMS செய்';
  }

  @override
  String get circleConnectCopyCode => 'குறியீட்டை நகலெடு';

  @override
  String circleConnectTexted(String name) {
    return '$name க்கு அனுப்பப்பட்டது. அவர் அதை Amica இல் நீங்கள் → ஒருவருக்கான எச்சரிக்கைகளைப் பெறு என்பதில் உள்ளிட வேண்டும். இது ஒரு முறை மட்டுமே செயல்படும், 7 நாட்களில் காலாவதியாகும்.';
  }

  @override
  String circleConnectTextFailed(String name) {
    return 'SMS அனுப்ப முடியவில்லை. இந்தக் குறியீட்டை வேறு வழியில் $name க்குக் கொடுங்கள் — இது ஒரு முறை மட்டுமே செயல்படும்.';
  }

  @override
  String get circleConnectDisconnect =>
      'இந்தத் தொடர்புக்கு Amica எச்சரிக்கைகளை நிறுத்து';

  @override
  String circleInviteSms(String name, String code) {
    return '$name உங்களை தனது Amica பாதுகாப்பு வட்டத்தில் சேர்த்துள்ளார். உங்களிடம் Amica இருந்தால், நீங்கள் → ஒருவருக்கான எச்சரிக்கைகளைப் பெறு என்பதற்குச் சென்று $code ஐ உள்ளிட்டு அவரது எச்சரிக்கைகளை உடனடியாகப் பெறுங்கள்.';
  }

  @override
  String circleInviteSmsNoName(String code) {
    return 'நீங்கள் ஒரு Amica பாதுகாப்பு வட்டத்தில் சேர்க்கப்பட்டுள்ளீர்கள். உங்களிடம் Amica இருந்தால், நீங்கள் → ஒருவருக்கான எச்சரிக்கைகளைப் பெறு என்பதற்குச் சென்று $code ஐ உள்ளிடுங்கள்.';
  }

  @override
  String get circleLinkTitle => 'ஒருவருக்கான எச்சரிக்கைகளைப் பெறு';

  @override
  String get circleLinkRowSubtitle => 'நண்பர் SMS செய்த குறியீட்டை உள்ளிடு';

  @override
  String get circleLinkIntro =>
      'யாராவது உங்களைத் தங்கள் வட்டத்தில் சேர்க்கும்போது, Amica உங்களுக்கு 6 எழுத்துக் குறியீட்டை SMS செய்யும். அதை இங்கே உள்ளிடுங்கள், அவர்களின் SOS எச்சரிக்கைகளும் நேரலை பயணங்களும் ஒரே தட்டலில் பதிலளிக்கக்கூடிய அறிவிப்புகளாக இந்தத் தொலைபேசிக்கு வரும்.';

  @override
  String get circleLinkCodeLabel => 'SMS இல் உள்ள குறியீடு';

  @override
  String get circleLinkButton => 'இணை';

  @override
  String get circleLinkCodeInvalid =>
      'குறியீடுகளில் 6 எழுத்துகளும் எண்களும் உள்ளன.';

  @override
  String circleLinkLinked(String name) {
    return 'இணைக்கப்பட்டது. இனி $name இன் எச்சரிக்கைகள் உங்களுக்கு வரும்.';
  }

  @override
  String get circleLinkErrorNotFound =>
      'அந்தக் குறியீடு எந்த அழைப்புடனும் பொருந்தவில்லை. SMS ஐச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get circleLinkErrorExpired =>
      'அந்தக் குறியீடு காலாவதியானது. புதியதைக் கேளுங்கள்.';

  @override
  String get circleLinkErrorUsed =>
      'அந்தக் குறியீடு ஏற்கனவே பயன்படுத்தப்பட்டது. புதியதைக் கேளுங்கள்.';

  @override
  String get circleLinkErrorOwn =>
      'அது உங்கள் சொந்த அழைப்பு — உங்கள் தொடர்பு தனது தொலைபேசியில் உள்ளிட வேண்டியது.';

  @override
  String get circleLinkGuardingTitle => 'நீங்கள் எச்சரிக்கைகள் பெறுவது';

  @override
  String get circleLinkGuardingEmpty => 'இதுவரை யாரும் இல்லை.';

  @override
  String get circleLinkGuardingSubtitle =>
      'SOS எச்சரிக்கைகளும் நேரலை பயணங்களும்';

  @override
  String get circleLinkLoadFailed =>
      'இந்தப் பட்டியலை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get circleLinkStop => 'நிறுத்து';

  @override
  String circleLinkStopTitle(String name) {
    return '$name இன் எச்சரிக்கைகளைப் பெறுவதை நிறுத்தவா?';
  }

  @override
  String circleLinkStopBody(String name) {
    return 'நீங்கள் அவரது வட்டத்தில் இருக்கும் வரை $name இன் SMS எச்சரிக்கைகள் இன்னும் வரும், ஆனால் Amica அறிவிப்புகள் வராது.';
  }

  @override
  String get circleLinkStopConfirm => 'எச்சரிக்கைகளை நிறுத்து';

  @override
  String get guardianAlertAppBar => 'வட்ட எச்சரிக்கை';

  @override
  String get guardianAlertJustNow => 'இப்போது';

  @override
  String guardianAlertMinutesAgo(int minutes) {
    return '$minutes நிமிடங்களுக்கு முன்';
  }

  @override
  String guardianAlertHerLocation(String name) {
    return '$name இன் இருப்பிடம்';
  }

  @override
  String get guardianAlertWatchLive => 'அவரது பயணத்தை நேரலையில் பார்';

  @override
  String get guardianAlertOpenMaps => 'Google Maps இல் திற';

  @override
  String get guardianAlertLetHerKnow =>
      'உதவி வருகிறது என்று அவருக்குத் தெரியப்படுத்து';

  @override
  String guardianAlertCallHer(String name) {
    return 'இப்போது $name ஐ அழை';
  }

  @override
  String guardianAlertCallingSent(String name) {
    return 'நீங்கள் அழைப்பது $name க்குத் தெரியும்';
  }

  @override
  String get guardianAlertAlertedSent =>
      'நீங்கள் மற்றவர்களுக்குத் தெரிவித்தது அவருக்குத் தெரியும்';

  @override
  String guardianAlertRepliesNote(String name) {
    return 'உங்கள் பதில்கள் உடனடியாக $name இன் திரையில் தோன்றும்.';
  }

  @override
  String get guardianReplyFailed =>
      'உங்கள் பதிலை அனுப்ப முடியவில்லை. அவரை நேரடியாக அழையுங்கள்.';

  @override
  String get pushSomeone => 'உங்கள் வட்டத்தில் ஒருவர்';

  @override
  String get pushYourContact => 'உங்கள் தொடர்பு';

  @override
  String get pushChannelSosName => 'உங்கள் வட்டத்திலிருந்து SOS';

  @override
  String get pushChannelSosDescription =>
      'உங்களைத் தங்கள் வட்டத்தில் சேர்த்த ஒருவருக்கு உதவி தேவைப்படும்போது.';

  @override
  String get pushChannelUpdatesName => 'வட்டப் புதுப்பிப்புகள்';

  @override
  String get pushChannelUpdatesDescription =>
      'நேரலை பயணங்கள், பாதுகாப்பான வருகைகள் மற்றும் உங்கள் எச்சரிக்கைகளுக்கான பதில்கள்.';

  @override
  String pushSosTitle(String name) {
    return '$name க்கு உதவி தேவை';
  }

  @override
  String get pushSosBody =>
      'Amica இலிருந்து SOS. அவர் எங்கே இருக்கிறார் என்று பார்த்து பதிலளிக்கத் தட்டவும்.';

  @override
  String get pushSosBodyNoLocation =>
      'Amica இலிருந்து SOS. பதிலளிக்கத் தட்டவும்.';

  @override
  String get pushActionCallingNow => 'இப்போது அழைக்கிறேன்';

  @override
  String get pushActionAlertedOthers => 'மற்றவர்களுக்குத் தெரிவித்தேன்';

  @override
  String get pushActionWatchLive => 'நேரலையில் பார்';

  @override
  String pushJourneyStartedTitle(String name) {
    return '$name தனது பயணத்தைப் பகிர்கிறார்';
  }

  @override
  String pushJourneyStartedBody(String destination) {
    return '$destination நோக்கிச் செல்கிறார். நேரலையில் பார்க்கத் தட்டவும்.';
  }

  @override
  String get pushJourneyStartedBodyNoDest => 'நேரலையில் பார்க்கத் தட்டவும்.';

  @override
  String pushArrivedTitle(String name) {
    return '$name பாதுகாப்பாகச் சென்றடைந்தார்';
  }

  @override
  String pushArrivedBody(String destination) {
    return '$destination நோக்கிய அவரது பயணம் முடிந்தது.';
  }

  @override
  String get pushArrivedBodyNoDest => 'அவரது பயணம் முடிந்தது.';

  @override
  String pushResponseCallingTitle(String name) {
    return '$name இப்போது உங்களை அழைக்கிறார்';
  }

  @override
  String get pushResponseCallingBody =>
      'உங்கள் தொலைபேசியை அருகில் வைத்திருங்கள்.';

  @override
  String pushResponseAlertedTitle(String name) {
    return '$name மற்றவர்களுக்குத் தெரிவித்தார்';
  }

  @override
  String get pushResponseAlertedBody =>
      'உங்களுக்கு உதவி தேவை என்பது மேலும் பலருக்குத் தெரியும்.';

  @override
  String pushLinkedTitle(String name) {
    return '$name Amica இல் இணைந்தார்';
  }

  @override
  String get pushLinkedBody =>
      'இனி உங்கள் எச்சரிக்கைகள் SMS உடன் அறிவிப்புகளாகவும் அவருக்கு வரும்.';

  @override
  String get pushResponseSentTitle => 'பதில் அனுப்பப்பட்டது';

  @override
  String pushResponseSentAlertedBody(String name) {
    return 'நீங்கள் மற்றவர்களுக்குத் தெரிவித்தது $name க்குத் தெரியும்.';
  }

  @override
  String get pushResponseFailedTitle => 'பதில் அனுப்பப்படவில்லை';

  @override
  String get pushResponseFailedBody =>
      'Amica ஐத் திறக்கவும் அல்லது அவரை நேரடியாக அழைக்கவும்.';

  @override
  String sosActivePushedCount(int count) {
    return 'உங்கள் வட்டத்தில் $count பேருக்கு Amica அறிவிப்பு சென்றது';
  }

  @override
  String get vehicleToldButton => 'எனக்கு என்ன சொன்னார்கள்?';

  @override
  String vehicleToldButtonSet(String description) {
    return 'எதிர்பார்ப்பது: $description';
  }

  @override
  String get vehicleToldSheetTitle => 'உங்களுக்கு என்ன சொன்னார்கள்?';

  @override
  String get vehicleToldSheetBody =>
      'சவாரி செயலிகள் வாகனத்தைக் காட்டும், எ.கா. \"வெள்ளை Toyota Axio, CAB-1234\". சொன்னதைத் தேர்ந்தெடுங்கள்; Amica அதைக் கேமரா பார்ப்பதுடன் ஒப்பிடும்.';

  @override
  String get vehicleToldTypeLabel => 'வாகன வகை';

  @override
  String get vehicleToldColourLabel => 'நிறம்';

  @override
  String get vehicleToldClear => 'அழி';

  @override
  String get vehicleToldDone => 'முடிந்தது';

  @override
  String get vehicleToldCardTitle => 'சரியான வாகனமா எனச் சரிபார்க்கவும்';

  @override
  String get vehicleToldCardBody =>
      'உங்கள் சவாரி செயலி காட்டிய வாகன வகையையும் நிறத்தையும் சேர்க்கவும்.';

  @override
  String get vehicleToldCardAdd => 'சேர்';

  @override
  String get vehicleToldCardSetTitle => 'உங்களுக்குச் சொல்லப்பட்டது';

  @override
  String get vehicleToldCardChange => 'மாற்று';

  @override
  String get vehicleToldPreviewEmpty =>
      'இன்னும் எதுவும் தேர்ந்தெடுக்கவில்லை. கீழே தேர்ந்தெடுக்கவும்.';

  @override
  String get vehicleKindCar => 'கார்';

  @override
  String get vehicleKindVan => 'வேன்';

  @override
  String get vehicleKindBus => 'பேருந்து';

  @override
  String get vehicleKindLorry => 'லாரி';

  @override
  String get vehicleKindMotorbike => 'மோட்டார் சைக்கிள்';

  @override
  String get vehicleKindThreeWheeler => 'முச்சக்கர வண்டி';

  @override
  String get vehicleColourWhite => 'வெள்ளை';

  @override
  String get vehicleColourSilver => 'வெள்ளி';

  @override
  String get vehicleColourGrey => 'சாம்பல்';

  @override
  String get vehicleColourBlack => 'கருப்பு';

  @override
  String get vehicleColourRed => 'சிவப்பு';

  @override
  String get vehicleColourMaroon => 'அடர் சிவப்பு';

  @override
  String get vehicleColourOrange => 'ஆரஞ்சு';

  @override
  String get vehicleColourYellow => 'மஞ்சள்';

  @override
  String get vehicleColourGreen => 'பச்சை';

  @override
  String get vehicleColourBlue => 'நீலம்';

  @override
  String get vehicleColourBrown => 'பழுப்பு';

  @override
  String vehicleDescription(String colour, String kind) {
    return '$colour $kind';
  }

  @override
  String get vehicleMatchTitleMatch => 'வாகனம் பொருந்துகிறது';

  @override
  String get vehicleMatchTitleMismatch => 'வாகனம் பொருந்தவில்லை';

  @override
  String get vehicleMatchTitleNotSure => 'வாகனத்தைச் சரிபார்க்க முடியவில்லை';

  @override
  String get vehicleMatchBodyMatch =>
      'கேமரா பார்த்தது எதிர்பார்த்ததுடன் பொருந்துகிறது.';

  @override
  String vehicleMatchMismatchTold(String expected, String seen) {
    return 'உங்களுக்குச் சொன்னது: $expected. கேமரா பார்ப்பது: $seen.';
  }

  @override
  String vehicleMatchMismatchCommunity(String expected, String seen) {
    return 'பிற Amica ஸ்கேன்களில் இந்த எண் வழக்கமாகக் காணப்பட்டது: $expected. கேமரா பார்ப்பது: $seen.';
  }

  @override
  String get vehicleMatchAdvice =>
      'ஏறும் முன் வாகனத்தையும் ஓட்டுநரையும் மீண்டும் சரிபாருங்கள். முடிவு உங்களுடையது.';

  @override
  String get vehicleMatchNotSureLowLight =>
      'நிறத்தை நம்பகமாகக் கணிக்க வெளிச்சம் போதவில்லை.';

  @override
  String get vehicleMatchNotSureColourCast =>
      'தெரு விளக்குகள் நிறங்களை மாற்றுவதால் நிறம் ஒப்பிடப்படவில்லை.';

  @override
  String get vehicleMatchNotSureNoVehicle =>
      'வாகனம் தெளிவாகத் தெரியவில்லை. வாகனம் அதிகமாகப் படத்தில் வர சற்றுப் பின்னால் செல்லுங்கள்.';

  @override
  String get vehicleMatchNotSureNothing =>
      'ஸ்கேன் செய்யும் முன், சவாரி செயலி காட்டியதுடன் ஒப்பிட \"எனக்கு என்ன சொன்னார்கள்?\" என்பதைத் தட்டுங்கள்.';

  @override
  String vehicleMatchSeen(String description) {
    return 'கேமரா பார்ப்பது: $description';
  }

  @override
  String get vehicleMatchSeenNothing =>
      'கேமராவால் வாகனத்தை அடையாளம் காண முடியவில்லை.';

  @override
  String vehicleMatchCommunity(String description, int count) {
    return 'வழக்கமாகப் பார்க்கப்படுவது: $description ($count ஸ்கேன்கள்)';
  }

  @override
  String get vehicleMatchPrivacy =>
      'வகையும் நிறமும் உங்கள் தொலைபேசியிலேயே சரிபார்க்கப்படும். புதிய வாகனத்தின் முதல் படம், வாகனம் மட்டும் தெரியும்படி வெட்டப்பட்டு, மற்ற பயணிகள் அடையாளம் காண சேமிக்கப்படும்.';

  @override
  String get zzzArbEnd => 'do not translate; internal append anchor';
}
