// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Amica';

  @override
  String get checkingLoginStatus => 'Checking login status';

  @override
  String get navHome => 'Home';

  @override
  String get navJourneys => 'Journeys';

  @override
  String get navCircle => 'Circle';

  @override
  String get navYou => 'You';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonOk => 'OK';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonEnterValidEmail => 'Enter a valid email';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonClose => 'Close';

  @override
  String get commonTryAgain => 'Please try again.';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in and your circle can reach you again.';

  @override
  String get loginPasswordRequired => 'Password is required';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get googleSignInFailed => 'Google sign-in failed. Please try again.';

  @override
  String get loginButton => 'Log in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get loginNewToAmica => 'New to Amica?';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get signupAppBarTitle => 'Create account';

  @override
  String get signupJoinAmica => 'Join Amica';

  @override
  String get signupSubtitle =>
      'Create your profile for safety alerts and trusted contacts.';

  @override
  String get signupNameLabel => 'Name';

  @override
  String get signupPhoneLabel => 'Phone';

  @override
  String get signupSecretPhraseLabel => 'Secret phrase';

  @override
  String get signupSecretPhraseHelper =>
      'Say this during a fake call to trigger stealth SOS.';

  @override
  String get signupConfirmPasswordLabel => 'Confirm password';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get signupEmailInvalid => 'Enter a valid email';

  @override
  String get signupPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get signupPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get signupFailed => 'Signup failed. Please try again.';

  @override
  String get signupCreatingAccount => 'Creating account...';

  @override
  String get signupCreateAccountButton => 'Create account';

  @override
  String get connecting => 'Connecting...';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get forgotPasswordAppBarTitle => 'Reset password';

  @override
  String get forgotPasswordHeading => 'Forgot your password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your account email and Amica will send a password reset link.';

  @override
  String get forgotPasswordEmailInvalid => 'Enter a valid email address';

  @override
  String get forgotPasswordSuccess =>
      'Password reset email sent. Check your inbox and follow the link.';

  @override
  String get forgotPasswordFailed =>
      'Could not send reset email. Please try again.';

  @override
  String get forgotPasswordSending => 'Sending...';

  @override
  String get forgotPasswordSendButton => 'Send reset link';

  @override
  String get forgotPasswordBackToLogin => 'Back to login';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get discreetModeTurnOff => 'Turn off discreet mode';

  @override
  String get discreetModeTurnOn => 'Turn on discreet mode';

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
      'No one can find you yet. Add someone to your circle so Amica has a person to reach.';

  @override
  String homeGuardianCountSubline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All calm. $count people can find you in seconds if you need them.',
      two: 'All calm. Two people can find you in seconds if you need them.',
      one: 'All calm. One person can find you in seconds if you need them.',
    );
    return '$_temp0';
  }

  @override
  String get homeYouAreProtected => 'You\'re protected';

  @override
  String get homeFinishSettingUp => 'Finish setting up';

  @override
  String homeProtectionReadySubline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'guardians',
      one: 'guardian',
    );
    return 'Location on · Voice phrase armed · $count $_temp0';
  }

  @override
  String get homeAddGuardianPrompt =>
      'Add at least one guardian to your circle';

  @override
  String get homeSosHoldHint =>
      'Hold 2 seconds. You get 5 more to cancel before your circle is alerted.';

  @override
  String get homeSectionQuieterOptions => 'Quieter options';

  @override
  String get homeTileWalkWithMe => 'Walk\nwith me';

  @override
  String get homeTileFakeCall => 'Fake\ncall';

  @override
  String get homeTileScanPlate => 'Scan\na plate';

  @override
  String get homeTileStopAlert => 'Stop\nalert';

  @override
  String get sosHoldSemanticLabel => 'Send an SOS alert';

  @override
  String get sosHoldSemanticHint => 'Press and hold for two seconds';

  @override
  String get sosHoldLabel => 'Hold';

  @override
  String get sosHoldReachingCircle => 'Reaching your circle…';

  @override
  String get sosHoldKeepHolding => 'Keep holding. Release to cancel.';

  @override
  String get sosHoldToSend => 'Hold to send an SOS';

  @override
  String get profileAppBarTitle => 'You';

  @override
  String get profileLoadingYourProfile => 'Loading your profile';

  @override
  String get profileVoicePhrase => 'Voice phrase';

  @override
  String profileVoicePhraseSet(String phrase) {
    return '“$phrase”';
  }

  @override
  String get profileVoicePhraseNotSet =>
      'Not set — say it and Amica alerts silently';

  @override
  String get profilePrivacyTitle => 'Privacy & your data';

  @override
  String get profilePrivacySubtitle =>
      'Where recordings and locations are kept';

  @override
  String get profileAllSettings => 'All settings';

  @override
  String get profileYourProfile => 'Your profile';

  @override
  String get profileSectionHowAmicaBehaves => 'How Amica behaves';

  @override
  String get profileSectionYourSafetySetup => 'Your safety setup';

  @override
  String profileSetupDoneCount(int done, int total) {
    return '$done of $total done';
  }

  @override
  String profileGuardiansInCircle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardians in your circle',
      one: '$count guardian in your circle',
    );
    return '$_temp0';
  }

  @override
  String get profileNoGuardiansYet => 'No one in your circle yet';

  @override
  String get profileVoicePhraseRecorded => 'Voice phrase recorded';

  @override
  String get profilePhoneConfirmed => 'Phone number confirmed';

  @override
  String get profileMedicalNotes => 'Medical notes for responders';

  @override
  String get profileDiscreetModeTitle => 'Discreet mode';

  @override
  String get profileDiscreetModeSubtitle =>
      'Dark, silent, no preview in notifications';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle =>
      'Light is easiest to read by day. Dark is discreet at night.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get mapRecenter => 'Centre on my location';

  @override
  String get mapShowWholeRoute => 'Show the whole route';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get startJourneyYourLocation => 'Your location';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditSubtitle =>
      'Keep these up to date so Amica can help you faster.';

  @override
  String get profileNameLabel => 'Your name';

  @override
  String get profilePhoneLabel => 'Phone number';

  @override
  String get profileMedicalNotesLabel => 'Medical notes (optional)';

  @override
  String get profileMedicalNotesHint =>
      'Allergies, conditions, medication, blood group…';

  @override
  String get profileNameRequired => 'Please enter your name';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save your profile. Check your connection and try again.';

  @override
  String get homeSafetyTipTitle => 'Safety tip of the day';

  @override
  String get homeSafetyTip1 =>
      'Share your journey with someone you trust before you set off.';

  @override
  String get homeSafetyTip2 =>
      'At night, sit near the driver or other passengers on buses and trains.';

  @override
  String get homeSafetyTip3 =>
      'Keep your phone charged above 20% before heading out late.';

  @override
  String get homeSafetyTip4 =>
      'Trust your instincts. If a place feels wrong, leave and tell someone.';

  @override
  String get homeSafetyTip5 =>
      'Check that the taxi\'s number plate matches your booking before you get in.';

  @override
  String get homeSafetyTip6 =>
      'Set a secret voice phrase so you can alert your circle without touching your phone.';

  @override
  String get phoneVerifyTitle => 'Verify your phone number';

  @override
  String get phoneVerifySubtitle =>
      'We\'ll text you a 6-digit code to confirm this number is yours.';

  @override
  String get phoneSendCode => 'Send code';

  @override
  String phoneCodeSentTo(String phone) {
    return 'We sent a code to $phone';
  }

  @override
  String get phoneCodeLabel => '6-digit code';

  @override
  String get phoneVerifyButton => 'Verify';

  @override
  String phoneResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get phoneResend => 'Resend code';

  @override
  String get phoneChangeNumber => 'Change number';

  @override
  String get phoneVerified => 'Phone number verified';

  @override
  String get phoneVerifiedBadge => 'Verified';

  @override
  String get phoneNotVerified => 'Not verified yet';

  @override
  String get phoneInvalidNumber =>
      'Enter a valid phone number, e.g. +94 77 123 4567';

  @override
  String get phoneErrInvalidCode =>
      'That code isn\'t right. Check the SMS and try again.';

  @override
  String get phoneErrExpired => 'This code has expired. Send a new one.';

  @override
  String get phoneErrTooMany =>
      'Too many attempts. Please wait a while and try again.';

  @override
  String get phoneErrInUse =>
      'This number is already linked to another Amica account.';

  @override
  String get phoneErrNotEnabled =>
      'Phone verification isn\'t turned on for this app yet.';

  @override
  String get phoneErrAppNotAuthorized =>
      'This app build isn\'t registered for phone verification yet.';

  @override
  String get phoneErrGeneric =>
      'Couldn\'t verify your number. Check your connection and try again.';

  @override
  String get phoneAddTitle => 'Add your phone number';

  @override
  String get phoneAddSubtitle =>
      'Save the number you use every day. SMS verification is coming soon.';

  @override
  String get phoneSaved => 'Phone number saved';

  @override
  String get profilePhoneAdded => 'Phone number added';

  @override
  String get profileAddPhone => 'Add your phone number';

  @override
  String get profileVerifyAction => 'Verify';

  @override
  String get profilePhoneNotVerified => 'Confirm your phone number';

  @override
  String profileSaveFailedWithCode(String code) {
    return 'Couldn\'t save your profile ($code). Check your connection and try again.';
  }

  @override
  String get profileLoadFailedTitle => 'Couldn\'t load your profile';

  @override
  String get profileLoadFailedBody =>
      'Your details are safe. Check your connection — this page updates by itself once you\'re back online.';

  @override
  String get tripTitleBus => 'Your bus trip';

  @override
  String get tripTitleTrain => 'Your train trip';

  @override
  String get tripPlanning => 'Finding stops near you…';

  @override
  String get tripTooClose =>
      'It\'s close enough to walk — no bus or train needed.';

  @override
  String get tripNoStops =>
      'No stops or stations found nearby. Amica will use the road route instead.';

  @override
  String get tripOffline =>
      'Couldn\'t plan the trip right now. Amica will use the road route instead.';

  @override
  String tripWalkToStop(String distance, String stop) {
    return 'Walk $distance to $stop';
  }

  @override
  String tripGetOnAt(String stop) {
    return 'Get on at $stop';
  }

  @override
  String tripGetOffAt(String stop) {
    return 'Get off at $stop';
  }

  @override
  String tripWalkToDestination(String distance) {
    return 'Walk $distance to your destination';
  }

  @override
  String tripRideSummary(String distance, int minutes) {
    return 'Ride $distance · about $minutes min';
  }

  @override
  String tripMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String tripBusLine(String line) {
    return 'Bus $line';
  }

  @override
  String tripTrainLine(String line) {
    return 'Train: $line';
  }

  @override
  String get tripEstimated =>
      'Estimated from the nearest stops — check the route with the conductor.';

  @override
  String get tripChooseBoard => 'Get on at';

  @override
  String get tripChooseAlight => 'Get off at';

  @override
  String tripStopAway(String distance) {
    return '$distance away';
  }

  @override
  String get stopAlertWhereGoing => 'Where are you going?';

  @override
  String stopAlertWakeBefore(String stop) {
    return 'Amica will alert you before $stop, the stop to get off at.';
  }

  @override
  String get sosSmsDefaultMessage => 'I need help.';

  @override
  String sosSmsWithName(String name, String message, String link) {
    return 'AMICA SOS from $name: $message My location: $link';
  }

  @override
  String sosSmsNoName(String message, String link) {
    return 'AMICA SOS: $message My location: $link';
  }

  @override
  String get sosCircleSending => 'Texting your circle…';

  @override
  String get sosCircleLoadFailed =>
      'Couldn\'t load your circle. Check your connection.';

  @override
  String get sosCircleTryAgain => 'Try again';

  @override
  String get sosCircleOpenSmsApp => 'Open SMS app';

  @override
  String sosCircleReachedCount(int reached, int total) {
    return '$reached of $total reached';
  }

  @override
  String get sosCircleStatusSending => 'Sending';

  @override
  String get sosCircleStatusSent => 'Sent';

  @override
  String get sosCircleStatusUnconfirmed => 'Not confirmed';

  @override
  String get sosCircleStatusFailed => 'Failed';

  @override
  String get mapTypeTitle => 'Map type';

  @override
  String get mapTypeDefault => 'Default';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeTerrain => 'Terrain';

  @override
  String get tripFeederBusHint => 'Too far to walk to the station';

  @override
  String get loginOr => 'or';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get signupSectionAboutYou => 'About you';

  @override
  String get signupSectionSafety => 'Your safety';

  @override
  String get signupSectionPassword => 'Password';

  @override
  String get signupStrengthWeak => 'Weak';

  @override
  String get signupStrengthFair => 'Fair';

  @override
  String get signupStrengthStrong => 'Strong';

  @override
  String tripRideToStation(String station) {
    return 'Take a bus or tuk-tuk to $station';
  }

  @override
  String get profileLogOut => 'Log out';

  @override
  String get profileLogOutConfirmTitle => 'Log out of Amica?';

  @override
  String get profileLogOutConfirmBody =>
      'Your circle will not be able to reach you through Amica until you log back in.';

  @override
  String get profileStayLoggedIn => 'Stay logged in';

  @override
  String get settingsAppBarTitle => 'Settings';

  @override
  String get settingsLoading => 'Loading settings';

  @override
  String get settingsCouldNotLoad => 'Could not load settings.';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsCouldNotSave =>
      'Could not save settings. Please try again.';

  @override
  String get settingsFakeCallSection => 'Fake Call';

  @override
  String get settingsVolumeShortcutTitle => 'Volume-up shortcut';

  @override
  String get settingsVolumeShortcutSubtitle =>
      'When enabled, Amica keeps a safety shortcut notification running. Press volume up three times to open the call screen.';

  @override
  String get settingsFakeCallerNameLabel => 'Fake caller name';

  @override
  String get settingsEnterCallerName => 'Enter a caller name.';

  @override
  String get settingsFakeCallerNumberLabel => 'Fake caller number';

  @override
  String get settingsEnterCallerNumber => 'Enter a caller number.';

  @override
  String get settingsVoiceSosSection => 'Stealth Voice SOS';

  @override
  String get settingsEnableVoiceSos => 'Enable voice SOS';

  @override
  String get settingsListenForPhrase =>
      'Listen for the secret phrase during an active fake call.';

  @override
  String get settingsSosEvidenceSection => 'SOS evidence';

  @override
  String get settingsRecordSosAudio => 'Record audio when an SOS fires';

  @override
  String get settingsRecordSosAudioHelper =>
      'Saves a 30-second clip from the moment Voice SOS or the SOS button fires. Only you can access it.';

  @override
  String get settingsMicrophoneNeeded =>
      'Allow microphone access so Amica can record during an SOS.';

  @override
  String get settingsEnableSecretPhrase => 'Enable secret phrase';

  @override
  String get settingsUsePhraseBelow =>
      'Use the phrase below to trigger Voice SOS.';

  @override
  String settingsSecretPhraseLabel(int number) {
    return 'Secret phrase $number';
  }

  @override
  String get settingsEnterPhrase => 'Enter a phrase.';

  @override
  String get settingsPhraseAlreadyListed =>
      'This phrase is already in the list.';

  @override
  String get settingsRemovePhrase => 'Remove phrase';

  @override
  String get settingsAddPhrase => 'Add phrase';

  @override
  String get settingsSosMessageLabel => 'SOS message for emergency contact';

  @override
  String get settingsSosMessageHelper =>
      'Saved with the Voice SOS alert when the phrase is spoken.';

  @override
  String get settingsEnterMessage => 'Enter the message to send.';

  @override
  String get settingsSaving => 'Saving...';

  @override
  String get settingsSaveButton => 'Save Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Choose the language Amica is shown in.';

  @override
  String get contactsAppBarTitle => 'Your circle';

  @override
  String get contactsLoading => 'Loading emergency contacts';

  @override
  String contactsLoadError(String error) {
    return 'Could not load emergency contacts.\n$error';
  }

  @override
  String get contactsEmptyTitle => 'No one yet';

  @override
  String get contactsEmptyMessage =>
      'Your circle are the people Amica reaches the moment you send an alert. Add one person you trust and the app starts working.';

  @override
  String get contactsAddFirstGuardian => 'Add your first guardian';

  @override
  String get contactsAlertedTogetherNote =>
      'Everyone switched on here is contacted at the same time when you send an alert.';

  @override
  String get contactsAddGuardianFab => 'Add guardian';

  @override
  String get contactsDeleteConfirmTitle => 'Delete contact?';

  @override
  String contactsDeleteConfirmBody(String name) {
    return 'Remove $name from emergency contacts?';
  }

  @override
  String get contactsDeleted => 'Contact deleted';

  @override
  String get contactsCouldNotDelete => 'Could not delete contact';

  @override
  String get contactsCouldNotUpdate => 'Could not update contact';

  @override
  String get contactsAlertedOnSos => 'Alerted when you send an SOS';

  @override
  String get contactsMuted => 'Muted — will not be alerted';

  @override
  String contactsRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String get addContactCouldNotSave =>
      'Could not save contact. Please try again.';

  @override
  String get addContactPermissionRequired =>
      'Contacts permission is required to import a contact.';

  @override
  String get addContactNoPhoneNumber =>
      'That contact has no phone number saved. Enter one manually.';

  @override
  String get addContactCouldNotImport => 'Could not import that contact.';

  @override
  String get addContactPriorityInvalid => 'Priority must be a positive number';

  @override
  String get addContactEditTitle => 'Edit contact';

  @override
  String get addContactAddTitle => 'Add contact';

  @override
  String get addContactOpeningContacts => 'Opening contacts...';

  @override
  String get addContactImportFromPhone => 'Import from phone contacts';

  @override
  String get addContactNameLabel => 'Name';

  @override
  String get addContactPhoneLabel => 'Phone number';

  @override
  String get addContactRelationshipLabel => 'Relationship';

  @override
  String get addContactPriorityLabel => 'Priority';

  @override
  String get addContactPriorityHelper => 'Lower numbers are contacted first.';

  @override
  String get addContactSaving => 'Saving...';

  @override
  String get addContactSaveButton => 'Save Contact';

  @override
  String get sosArmingSendingLabel => 'SENDING AN ALERT';

  @override
  String get sosArmingAlertingLabel => 'ALERTING YOUR CIRCLE';

  @override
  String get sosArmingReachingNow => 'Reaching them now.';

  @override
  String get sosArmingCancelIfMeant => 'Cancel if you meant to.';

  @override
  String get sosArmingStaySafe => 'Stay where you are if it is safe to.';

  @override
  String get sosArmingStopNow =>
      'Stop now and nothing is sent. No one is told you nearly called.';

  @override
  String get sosArmingSendFailed =>
      'Could not send your alert. Try again, or call 119 directly.';

  @override
  String get sosArmingWhenZero => 'WHEN THE COUNT REACHES ZERO';

  @override
  String get sosArmingGuardianNone => 'Your circle gets your live location';

  @override
  String sosArmingGuardianOne(String name) {
    return '$name gets your live location';
  }

  @override
  String sosArmingGuardianTwo(String first, String second) {
    return '$first and $second get your live location';
  }

  @override
  String sosArmingGuardianMany(String names, String last) {
    return '$names and $last get your live location';
  }

  @override
  String get sosArmingRecordingAudio => 'Your phone starts recording audio';

  @override
  String get sosArmingCallReady => '119 is one tap away, already dialled';

  @override
  String get sosArmingCancelSendNothing => 'Cancel — send nothing';

  @override
  String get sosArmingBackToHome => 'Back to home';

  @override
  String get sosActiveTriggerVoice => 'Triggered by your voice phrase';

  @override
  String get sosActiveTriggerTimer => 'Your journey timer ran out';

  @override
  String get sosActiveTriggerManual => 'You sent this alert';

  @override
  String get sosActiveLive => 'ALERT LIVE';

  @override
  String get sosActiveYourLocation => 'Your location';

  @override
  String get sosActiveUpdatingEvery10s => 'Updating every 10 seconds';

  @override
  String get sosActiveNoOneInCircle =>
      'No one is in your circle, so only emergency services can help. Call 119.';

  @override
  String sosActiveCircleReachedHeader(int count) {
    return 'Your circle · $count reached';
  }

  @override
  String get sosActiveNotified => 'Notified';

  @override
  String get sosActiveWhatAmicaIsDoing => 'What Amica is doing';

  @override
  String get sosActiveSharingLocation => 'Sharing your live location';

  @override
  String get sosActiveRecordingAudio => 'Recording audio';

  @override
  String get sosActiveAudioSaving => 'Saving the audio clip…';

  @override
  String get sosActiveAudioSaved => 'Audio clip saved securely';

  @override
  String get sosActiveAudioPending =>
      'Audio clip kept on phone, uploads when online';

  @override
  String get sosActiveAudioNoPermission =>
      'Not recording: microphone not allowed';

  @override
  String get sosActiveAudioOff => 'Audio recording is off in settings';

  @override
  String get sosActiveAudioFailed => 'Couldn\'t record audio';

  @override
  String get sosActiveAudioNotRecording => 'Not recording audio';

  @override
  String get sosActiveSirenSounding => 'Siren — sounding';

  @override
  String get sosActiveSirenSilent => 'Siren — silent, tap to sound';

  @override
  String get sosActiveOn => 'ON';

  @override
  String get sosActiveOff => 'OFF';

  @override
  String get sosActiveImSafe => 'I\'m safe — stand down';

  @override
  String get sosActiveCall119 => 'Call 119';

  @override
  String get sosActiveStandDownNote =>
      'Standing down tells your circle you are okay. It does not delete the recording.';

  @override
  String get sosActiveConfirmTitle => 'Tell your circle you are safe?';

  @override
  String get sosActiveConfirmBody =>
      'They will stop seeing your live location and the alert will close.';

  @override
  String get sosActiveKeepLive => 'Keep it live';

  @override
  String get sosActiveYesImSafe => 'Yes, I\'m safe';

  @override
  String get fakeCallPreparingCall => 'Preparing call';

  @override
  String get fakeCallAppBarTitle => 'Fake call';

  @override
  String get fakeCallHeroTitle => 'Make it look like someone is expecting you';

  @override
  String get fakeCallHeroSubtitle =>
      'Ring now, or schedule a call for the moment you get into a vehicle. Amica keeps the countdown running even if you close the app or lock your phone.';

  @override
  String get fakeCallRingNowInstead => 'Ring now instead';

  @override
  String get fakeCallCancelScheduled => 'Cancel scheduled call';

  @override
  String get fakeCallScheduling => 'Scheduling...';

  @override
  String fakeCallScheduleIn(String delay) {
    return 'Schedule in $delay';
  }

  @override
  String get fakeCallRingNow => 'Ring now';

  @override
  String get fakeCallDisclaimer =>
      'No real call is placed. During the call, Amica can listen for your secret phrase and send a silent SOS.';

  @override
  String get fakeCallEditCallerTooltip => 'Edit caller';

  @override
  String get fakeCallMeIn => 'Call me in';

  @override
  String get fakeCallCallingIn => 'CALLING IN';

  @override
  String get fakeCallKeepNotificationVisible =>
      'Keep the \"Call scheduled\" notification visible. You can close Amica now.';

  @override
  String fakeCallScheduledSnackbar(String name, String delay) {
    return '$name will call in $delay. You can close Amica.';
  }

  @override
  String get fakeCallCouldNotSchedule =>
      'Could not schedule the call on this device.';

  @override
  String get fakeCallScheduleCancelled => 'Scheduled call cancelled';

  @override
  String get fakeCallCouldNotCancel => 'Could not cancel the scheduled call.';

  @override
  String get fakeCallIncoming => 'Incoming call';

  @override
  String get fakeCallMobile => 'Mobile';

  @override
  String get fakeCallDecline => 'Decline';

  @override
  String get fakeCallAccept => 'Accept';

  @override
  String get fakeCallActiveCouldNotCompleteVoiceSos =>
      'Could not complete Voice SOS. Use manual SOS if needed.';

  @override
  String get fakeCallActiveConnected => 'Call connected';

  @override
  String get fakeCallActiveMute => 'Mute';

  @override
  String get fakeCallActiveKeypad => 'Keypad';

  @override
  String get fakeCallActiveSpeaker => 'Speaker';

  @override
  String get fakeCallActiveAddCall => 'Add call';

  @override
  String get fakeCallActiveHold => 'Hold';

  @override
  String get fakeCallActiveBluetooth => 'Bluetooth';

  @override
  String get journeysScreenCheckingJourneys => 'Checking your journeys';

  @override
  String get safetyCheckDefaultTrip => 'your trip';

  @override
  String get safetyCheckAreYouSafe => 'Are you safe?';

  @override
  String safetyCheckTimerEnded(String destination) {
    return 'Your journey timer for $destination has ended.';
  }

  @override
  String get safetyCheckImSafe => 'I am safe';

  @override
  String get safetyCheckSendSosNow => 'Send SOS now';

  @override
  String get safetyCheckSafeClosesNote =>
      'Tapping \"I am safe\" closes this journey. Amica will stop watching and will not contact anyone.';

  @override
  String get safetyCheckAnswerPrompt =>
      'Answer so Amica knows whether to alert your emergency contact.';

  @override
  String get safetyCheckContactAlerted =>
      'Amica has alerted your emergency contact';

  @override
  String get safetyCheckAutoAlertIn => 'Auto-alert in';

  @override
  String get safetyCheckEscalationExplain =>
      'If you do not answer, Amica messages your primary emergency contact with your live location, then calls them.';

  @override
  String get safetyCheckAfterEscalationNote =>
      'You can still confirm you are safe, or escalate to a full SOS with your live location.';

  @override
  String get startJourneyFindingOnMap => 'Finding destination on map...';

  @override
  String get startJourneyDestinationFound => 'Destination found on map.';

  @override
  String get startJourneyDestinationNotFound =>
      'Destination not found. Pin it on the map.';

  @override
  String get startJourneyCouldNotGetLocation =>
      'Could not get current location.';

  @override
  String get startJourneyGetLocationFirst => 'Get your current location first.';

  @override
  String get startJourneyChooseDestination =>
      'Choose the destination on the map.';

  @override
  String get startJourneyCouldNotStart => 'Could not start journey.';

  @override
  String get startJourneyDestinationPinSelected => 'Destination pin selected.';

  @override
  String get startJourneyDestinationLabel => 'Destination';

  @override
  String get startJourneyWalkWithMeTitle => 'Walk with me';

  @override
  String get startJourneyRideWithMeTitle => 'Ride with me';

  @override
  String startJourneyVehicleLabel(String plate) {
    return 'Vehicle: $plate';
  }

  @override
  String get startJourneyGettingLocation => 'Getting location...';

  @override
  String get startJourneyGetCurrentLocation => 'Get current location';

  @override
  String get startJourneyCurrentLocationNotSelected =>
      'Current location: not selected yet';

  @override
  String startJourneyCurrentLocationValue(String lat, String lng) {
    return 'Current location: $lat, $lng';
  }

  @override
  String get startJourneyDestinationNameLabel => 'Destination name or address';

  @override
  String get startJourneyMapStartMarker => 'Journey start';

  @override
  String get startJourneyTapMapToPin => 'Tap map to pin destination.';

  @override
  String startJourneyDestinationPinValue(String lat, String lng) {
    return 'Destination pin: $lat, $lng';
  }

  @override
  String get startJourneyTypeLabel => 'Journey type';

  @override
  String get startJourneyTypeWalk => 'Walk';

  @override
  String get startJourneyTypeTaxi => 'Taxi';

  @override
  String get startJourneyTypeBus => 'Bus';

  @override
  String get startJourneyTypeTrain => 'Train';

  @override
  String get startJourneyTypeOther => 'Other';

  @override
  String get startJourneyDurationLabel => 'Estimated duration in minutes';

  @override
  String get startJourneyDurationInvalid => 'Enter a positive duration';

  @override
  String startJourneySuggestedDuration(int minutes) {
    return 'Suggested duration: $minutes minutes (approximate; no traffic data)';
  }

  @override
  String get startJourneyStarting => 'Starting...';

  @override
  String get startJourneyStartButton => 'Start Journey';

  @override
  String get startJourneyStartVehicleButton => 'Start Vehicle Journey';

  @override
  String get journeyTimerMarkedSafe => 'Journey marked safe';

  @override
  String get journeyTimerMarkSafeFailed => 'Could not mark journey safe';

  @override
  String get journeyTimerSendingSos => 'Sending SOS alert...';

  @override
  String get journeyTimerSosCreateFailed => 'Could not create SOS alert';

  @override
  String get journeyTimerNoContactFound => 'No active emergency contact found.';

  @override
  String journeyTimerSmsSubmitted(int count) {
    return 'Emergency SMS submitted for $count contacts.';
  }

  @override
  String get journeyTimerMessagePrepFailed =>
      'Could not prepare emergency message.';

  @override
  String get journeyTimerNoContactFoundCall =>
      'No active emergency contact found for call.';

  @override
  String journeyTimerCalling(String name) {
    return 'Calling $name.';
  }

  @override
  String get journeyTimerCallOpenFailed => 'Could not open emergency call.';

  @override
  String get journeyTimerEmergencyLocationUnavailable =>
      'Location not available.';

  @override
  String journeyTimerEmergencyLocationLine(String url) {
    return 'Location: $url';
  }

  @override
  String get journeyTimerEmergencyAlertIntro =>
      'Amica safety alert: I did not respond to my journey safety check.';

  @override
  String journeyTimerEmergencyVehicleLine(String plate) {
    return 'Vehicle: $plate.';
  }

  @override
  String journeyTimerEmergencyDestinationLine(String name) {
    return 'Destination: $name.';
  }

  @override
  String get journeyTimerTitle => 'Journey';

  @override
  String get journeyTimerLoading => 'Loading journey';

  @override
  String journeyTimerLoadError(String error) {
    return 'Could not load journey: $error';
  }

  @override
  String get journeyTimerNoActiveJourney => 'No active journey found.';

  @override
  String get journeyTimerStatusActive => 'ACTIVE';

  @override
  String get journeyTimerStatusSafe => 'SAFE';

  @override
  String get journeyTimerStatusSos => 'SOS';

  @override
  String journeyTimerEstimatedDuration(int minutes) {
    return 'Estimated duration: $minutes minutes';
  }

  @override
  String get journeyTimerTimeRemaining => 'TIME REMAINING';

  @override
  String get journeyTimerMapMarkerTitle => 'Journey location';

  @override
  String get journeyTimerSaving => 'Saving...';

  @override
  String get journeyTimerTriggerTestSos => 'Trigger test SOS';

  @override
  String get stopAlertSetupFindingStop => 'Finding your stop on the map...';

  @override
  String get stopAlertSetupStopFound => 'Stop found on the map.';

  @override
  String get stopAlertSetupStopNotFound =>
      'Stop not found. Tap the map to pin it.';

  @override
  String get stopAlertSetupStopPinned => 'Stop pinned on the map.';

  @override
  String get stopAlertSetupLocationError =>
      'Could not get your current location.';

  @override
  String get stopAlertSetupNeedLocation => 'Get your current location first.';

  @override
  String get stopAlertSetupNeedStop =>
      'Search for your stop or tap the map to pin it.';

  @override
  String get stopAlertSetupStartFailed => 'Could not start the bus ride.';

  @override
  String get stopAlertSetupValidateDropOff =>
      'Name your stop so the alert can tell you where you are going';

  @override
  String get stopAlertSetupTitle => 'Bus stop alert';

  @override
  String get stopAlertSetupHeadline => 'Never miss your stop';

  @override
  String get stopAlertSetupIntro =>
      'Pick where you are getting off. Amica watches the distance and sounds an alarm before you arrive, so you can rest on the bus without missing your stop.';

  @override
  String get stopAlertSetupGettingLocation => 'Getting location...';

  @override
  String get stopAlertSetupUpdateLocation => 'Update current location';

  @override
  String get stopAlertSetupLocationUnavailable =>
      'Current location: not available yet';

  @override
  String stopAlertSetupLocationKnown(String lat, String lng) {
    return 'Current location: $lat, $lng';
  }

  @override
  String get stopAlertSetupDropOffLabel => 'Where are you getting off?';

  @override
  String get stopAlertSetupYouAreHereMarker => 'You are here';

  @override
  String get stopAlertSetupYourStopDefault => 'Your stop';

  @override
  String get stopAlertSetupTapToPin => 'Tap the map to pin your stop.';

  @override
  String stopAlertSetupStopPinnedAt(String lat, String lng) {
    return 'Stop pinned at $lat, $lng';
  }

  @override
  String get stopAlertSetupStartButton => 'Start bus ride';

  @override
  String get stopAlertSetupKeepNotificationNote =>
      'Keep the Amica tracking notification visible. The alarm still sounds with the app closed and the screen off.';

  @override
  String get stopAlertSetupAlertDistanceLabel =>
      'Alert me this far from the stop';

  @override
  String get stopAlertSetupCheckingRoadDistance =>
      'Checking the road distance to your stop...';

  @override
  String stopAlertSetupDistanceStraightLine(String distance) {
    return 'Your stop is $distance away in a straight line.';
  }

  @override
  String stopAlertSetupDistanceByRoad(String distance) {
    return 'Your stop is about $distance away by road.';
  }

  @override
  String stopAlertSetupTooClose(String alertDistance) {
    return 'You are already within $alertDistance of this stop, so the alarm would sound straight away. Pick a shorter alert distance.';
  }

  @override
  String get stopAlertActiveLocationPaused =>
      'Live location paused. Amica keeps watching in the background.';

  @override
  String get stopAlertActiveCloseFailed => 'Could not close the ride record';

  @override
  String get stopAlertActiveLoading => 'Loading your ride';

  @override
  String stopAlertActiveLoadError(String error) {
    return 'Could not load the ride: $error';
  }

  @override
  String get stopAlertActiveNoRide => 'No active bus ride found.';

  @override
  String get stopAlertActiveGettingOffAt => 'Getting off at';

  @override
  String get stopAlertActiveAlertDistance => 'Alert distance';

  @override
  String get stopAlertActiveBackgroundAlarm => 'Background alarm';

  @override
  String get stopAlertActiveStatusActive => 'Active';

  @override
  String get stopAlertActiveStatusAppOnly => 'App only';

  @override
  String get stopAlertActiveDistanceMeasured => 'Distance measured';

  @override
  String get stopAlertActiveByRoad => 'By road';

  @override
  String get stopAlertActiveStraightLine => 'Straight line';

  @override
  String get stopAlertActiveEnding => 'Ending...';

  @override
  String get stopAlertActiveGetOffButton => 'I am getting off here';

  @override
  String get stopAlertActiveCanLockPhone =>
      'You can lock your phone. Amica will alarm before your stop.';

  @override
  String get stopAlertActiveKeepScreenOpen =>
      'Keep this screen open so Amica can watch your stop.';

  @override
  String get stopAlertActiveComingUp => 'YOUR STOP IS COMING UP';

  @override
  String get stopAlertActiveDistanceLabel => 'DISTANCE TO YOUR STOP';

  @override
  String stopAlertActiveGetReady(String name) {
    return 'Get ready to get off at $name.';
  }

  @override
  String stopAlertActiveWillAlarmAt(String distance) {
    return 'Amica will alarm at $distance.';
  }

  @override
  String get plateScanStartingCamera => 'Starting camera...';

  @override
  String get plateScanAlignPrompt =>
      'Align the plate in the frame and tap the shutter';

  @override
  String get plateScanNoCamera => 'No camera was found on this device.';

  @override
  String get plateScanPermissionRequired =>
      'Camera permission is required to scan a plate. Enable it in system settings.';

  @override
  String get plateScanCameraStartFailed => 'Could not start the camera.';

  @override
  String get plateScanReading => 'Reading plate...';

  @override
  String plateScanDetected(String plate) {
    return 'Detected $plate';
  }

  @override
  String get plateScanNotDetected =>
      'No plate detected. Align it inside the frame and try again.';

  @override
  String plateScanChecking(String plate) {
    return 'Checking $plate...';
  }

  @override
  String get plateScanGalleryNoPlate =>
      'No single plate detected. Try another image or enter the plate.';

  @override
  String get plateScanGalleryFailed =>
      'Could not scan the plate. Please try again.';

  @override
  String get plateScanEnterTitle => 'Enter plate number';

  @override
  String get plateScanCheckButton => 'Check';

  @override
  String get plateScanInvalidPlate =>
      'Enter a plate like CAB-1234, WP KA-1234 or 65-1234.';

  @override
  String get plateScanEmptyPlate => 'Type the plate number first.';

  @override
  String get plateScanConfirmTitle => 'Confirm plate number';

  @override
  String get plateScanConfirmMessage =>
      'Check the plate we read and correct it if needed.';

  @override
  String get plateScanUnreadMessage =>
      'Couldn\'t read the plate clearly. Type the number shown on the plate.';

  @override
  String get plateScanTitle => 'Scan before you ride';

  @override
  String get plateScanRetry => 'Retry';

  @override
  String get plateScanChooseGallery => 'Choose from gallery instead';

  @override
  String plateResultDialogTitle(String plate) {
    return 'Traveling in $plate?';
  }

  @override
  String get plateResultDialogBody =>
      'Check the plate matches the vehicle. This sends a boarding SMS to your active emergency contacts. SIM charges may apply.';

  @override
  String get plateResultConfirmButton => 'Confirm and notify';

  @override
  String get plateResultBoardingFailed =>
      'Could not load contacts. Check your connection and retry.';

  @override
  String get plateResultStatusSafe => 'Safe';

  @override
  String get plateResultStatusReported => 'Reported';

  @override
  String get plateResultStatusUnknown => 'Unknown';

  @override
  String get plateResultTitle => 'Vehicle status';

  @override
  String get plateResultDemoPassengerRating => 'Demo passenger rating';

  @override
  String get plateResultPassengerRating => 'Passenger rating';

  @override
  String get plateResultNotRated => 'Not rated';

  @override
  String plateResultRatingValue(String average, int count) {
    return '$average/5 ($count)';
  }

  @override
  String get plateResultUnverifiedChecks => 'Unverified missed checks';

  @override
  String get plateResultReportsOnFile => 'Reports on file';

  @override
  String get plateResultRiskLevel => 'Risk level';

  @override
  String get plateResultDbNote =>
      'Vehicle checks use the shared Amica safety database. When in doubt, share your trip with a trusted contact before riding.';

  @override
  String get plateResultPhotoTitle => 'What this vehicle looked like';

  @override
  String get plateResultPhotoCaption =>
      'Saved by the first Amica rider who scanned this plate. Check the vehicle in front of you matches before you get in.';

  @override
  String get plateResultDemoNote => 'Demo data. These ratings are fictional.';

  @override
  String get plateResultFeedbackNote =>
      'Passenger feedback is associated with this plate, not a verified driver identity or safety guarantee.';

  @override
  String get plateResultNotifying => 'Notifying contacts...';

  @override
  String get plateResultTravelingButton => 'I am traveling in this vehicle';

  @override
  String get plateResultScanAnotherButton => 'Scan another plate';

  @override
  String get plateResultRateButton => 'Rate a completed ride';

  @override
  String get vehicleRatingCompletedTitle => 'Completed vehicle rides';

  @override
  String get vehicleRatingLoadError =>
      'Could not load your rides. Please reconnect.';

  @override
  String get vehicleRatingNoRides => 'No completed rides for this vehicle yet.';

  @override
  String get vehicleRatingTitle => 'Rate your journey';

  @override
  String get vehicleRatingPrompt =>
      'How was your experience traveling in this vehicle?';

  @override
  String vehicleRatingStarsTooltip(int count) {
    return '$count stars';
  }

  @override
  String get vehicleRatingSaveFailed =>
      'Could not save your rating. Please retry.';

  @override
  String get vehicleRatingSubmitted => 'Rating submitted';

  @override
  String get vehicleRatingSaving => 'Saving...';

  @override
  String get vehicleRatingSubmitButton => 'Submit rating';

  @override
  String get vehicleRatingSkipButton => 'Skip';

  @override
  String get vehicleRatingCommentLabel => 'Add a comment (optional)';

  @override
  String get vehicleRatingCommentHint =>
      'Anything others should know about this ride or driver?';

  @override
  String get startJourneyFindingAddress => 'Pinned. Finding the address...';

  @override
  String get startJourneyAddressNotFound =>
      'Pinned. No address found here, so type a name for this place.';

  @override
  String get startJourneyRouteLoading => 'Finding a route...';

  @override
  String startJourneyRouteSummary(String distance, int minutes) {
    return 'Suggested route: $distance · about $minutes min';
  }

  @override
  String get startJourneyRouteUnavailable =>
      'Couldn\'t get a route. Using a straight-line estimate.';

  @override
  String get journeyTimerPause => 'Pause';

  @override
  String get journeyTimerResumeNow => 'Resume';

  @override
  String get journeyTimerPaused => 'PAUSED';

  @override
  String journeyTimerResumesIn(String time) {
    return 'Resumes automatically in $time';
  }

  @override
  String get journeyTimerPauseSheetTitle => 'Pause the safety timer';

  @override
  String get journeyTimerPauseSheetBody =>
      'The countdown stops while paused. It starts again on its own when the pause ends, or you can resume it any time.';

  @override
  String journeyTimerPauseMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String journeyTimerPauseConfirm(int minutes) {
    return 'Pause for $minutes min';
  }

  @override
  String journeyTimerPausedFor(int minutes) {
    return 'Timer paused for $minutes min';
  }

  @override
  String get journeyTimerResumed => 'Timer resumed';

  @override
  String get journeyTimerPauseFailed =>
      'Could not pause the timer. Please try again.';

  @override
  String get journeyTimerResumeFailed =>
      'Could not resume the timer. Please try again.';

  @override
  String get journeyTimerSuggestedRoute => 'Suggested route';

  @override
  String journeyTimerRouteInfo(String distance, int minutes) {
    return '$distance · about $minutes min';
  }

  @override
  String get journeyTimerNoRoute =>
      'No suggested route. Head towards the pink pin.';

  @override
  String get journeyTimerOpenInMaps => 'Navigate in Google Maps';

  @override
  String get liveShareToggleTitle => 'Share live with my circle';

  @override
  String get liveShareToggleSubtitle =>
      'Your contacts get a link to watch this journey on a map — no app needed.';

  @override
  String get liveShareOnTitle => 'Sharing live with your circle';

  @override
  String get liveShareOnSubtitle =>
      'Your contacts can watch this journey on a map.';

  @override
  String get liveShareOffTitle => 'Let your circle watch live';

  @override
  String get liveShareOffSubtitle =>
      'Send a link that shows where you are until you arrive.';

  @override
  String get liveShareSending => 'Sending the live link…';

  @override
  String liveShareSentSummary(int pushed, int texted) {
    return 'Sent: $pushed by Amica notification, $texted by SMS.';
  }

  @override
  String liveShareSomeFailed(int count) {
    return '$count could not be reached.';
  }

  @override
  String get liveShareShareNow => 'Share live link';

  @override
  String get liveShareSendAgain => 'Send the link again';

  @override
  String get liveShareCopyLink => 'Copy link';

  @override
  String get liveShareLinkCopied => 'Live link copied.';

  @override
  String get liveShareCreateFailed =>
      'Couldn\'t create the live link. Check your connection and try again.';

  @override
  String get liveShareContactsFailed =>
      'Link ready, but your contacts couldn\'t be loaded to send it.';

  @override
  String liveShareSmsWithName(String name, String destination, String url) {
    return 'Amica: $name is on her way to $destination. Watch her journey live: $url';
  }

  @override
  String liveShareSmsNoName(String destination, String url) {
    return 'Amica: I\'m on my way to $destination. Watch my journey live: $url';
  }

  @override
  String liveShareEmergencyLine(String url) {
    return 'Live: $url';
  }

  @override
  String get liveShareTrackingTitle => 'Sharing your live location';

  @override
  String get liveShareTrackingText =>
      'Your circle can follow this journey until you arrive.';

  @override
  String get contactsConnectInAmica => 'Connect in Amica for instant alerts';

  @override
  String get contactsLinkedInAmica => 'Gets instant alerts in Amica';

  @override
  String circleConnectTitle(String name) {
    return 'Connect $name in Amica';
  }

  @override
  String circleConnectBody(String name) {
    return 'If $name has Amica, your SOS alerts and live journeys can reach them as instant notifications — free, and faster than SMS. They can reply with one tap. We\'ll text them a code to enter in their app.';
  }

  @override
  String circleConnectLinkedTitle(String name) {
    return '$name is connected in Amica';
  }

  @override
  String circleConnectLinkedBody(String name) {
    return '$name gets your SOS alerts and live journeys as instant notifications, as well as by SMS.';
  }

  @override
  String circleConnectSendCode(String name) {
    return 'Text $name a code';
  }

  @override
  String get circleConnectCopyCode => 'Copy code';

  @override
  String circleConnectTexted(String name) {
    return 'Sent to $name. They enter it in Amica under You → Get alerts for someone. It works once and expires in 7 days.';
  }

  @override
  String circleConnectTextFailed(String name) {
    return 'The SMS couldn\'t be sent. Give $name this code another way — it only works on their phone once.';
  }

  @override
  String get circleConnectDisconnect => 'Stop Amica alerts to this contact';

  @override
  String circleInviteSms(String name, String code) {
    return '$name added you to her Amica safety circle. If you have Amica, go to You → Get alerts for someone and enter $code to get her alerts instantly.';
  }

  @override
  String circleInviteSmsNoName(String code) {
    return 'You\'ve been added to an Amica safety circle. If you have Amica, go to You → Get alerts for someone and enter $code to get alerts instantly.';
  }

  @override
  String get circleLinkTitle => 'Get alerts for someone';

  @override
  String get circleLinkRowSubtitle => 'Enter a code a friend texted you';

  @override
  String get circleLinkIntro =>
      'When someone adds you to their circle, Amica texts you a 6-character code. Enter it here and their SOS alerts and live journeys will reach this phone as notifications you can answer with one tap.';

  @override
  String get circleLinkCodeLabel => 'Code from the SMS';

  @override
  String get circleLinkButton => 'Connect';

  @override
  String get circleLinkCodeInvalid => 'Codes have 6 letters and numbers.';

  @override
  String circleLinkLinked(String name) {
    return 'Connected. You\'ll now get $name\'s alerts.';
  }

  @override
  String get circleLinkErrorNotFound =>
      'That code doesn\'t match any invite. Check the SMS and try again.';

  @override
  String get circleLinkErrorExpired =>
      'That code has expired. Ask for a new one.';

  @override
  String get circleLinkErrorUsed =>
      'That code has already been used. Ask for a new one.';

  @override
  String get circleLinkErrorOwn =>
      'That\'s your own invite — it\'s for your contact to enter on their phone.';

  @override
  String get circleLinkGuardingTitle => 'You get alerts for';

  @override
  String get circleLinkGuardingEmpty => 'No one yet.';

  @override
  String get circleLinkGuardingSubtitle => 'SOS alerts and live journeys';

  @override
  String get circleLinkLoadFailed =>
      'Couldn\'t load this list. Check your connection.';

  @override
  String get circleLinkStop => 'Stop';

  @override
  String circleLinkStopTitle(String name) {
    return 'Stop getting $name\'s alerts?';
  }

  @override
  String circleLinkStopBody(String name) {
    return 'You\'ll still get $name\'s SMS alerts while you\'re in her circle, but not Amica notifications.';
  }

  @override
  String get circleLinkStopConfirm => 'Stop alerts';

  @override
  String get guardianAlertAppBar => 'Circle alert';

  @override
  String get guardianAlertJustNow => 'Just now';

  @override
  String guardianAlertMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String guardianAlertHerLocation(String name) {
    return '$name\'s location';
  }

  @override
  String get guardianAlertWatchLive => 'Watch her journey live';

  @override
  String get guardianAlertOpenMaps => 'Open in Google Maps';

  @override
  String get guardianAlertLetHerKnow => 'Let her know help is coming';

  @override
  String guardianAlertCallHer(String name) {
    return 'Call $name now';
  }

  @override
  String guardianAlertCallingSent(String name) {
    return '$name knows you\'re calling';
  }

  @override
  String get guardianAlertAlertedSent => 'She knows you\'ve alerted others';

  @override
  String guardianAlertRepliesNote(String name) {
    return 'Your replies appear on $name\'s screen straight away.';
  }

  @override
  String get guardianReplyFailed =>
      'Couldn\'t send your reply. Call her directly.';

  @override
  String get pushSomeone => 'Someone in your circle';

  @override
  String get pushYourContact => 'Your contact';

  @override
  String get pushChannelSosName => 'SOS from your circle';

  @override
  String get pushChannelSosDescription =>
      'When someone who added you to their circle needs help.';

  @override
  String get pushChannelUpdatesName => 'Circle updates';

  @override
  String get pushChannelUpdatesDescription =>
      'Live journeys, safe arrivals and replies to your alerts.';

  @override
  String pushSosTitle(String name) {
    return '$name needs help';
  }

  @override
  String get pushSosBody =>
      'SOS from Amica. Tap to see where she is and reply.';

  @override
  String get pushSosBodyNoLocation => 'SOS from Amica. Tap to reply.';

  @override
  String get pushActionCallingNow => 'Calling now';

  @override
  String get pushActionAlertedOthers => 'I\'ve alerted others';

  @override
  String get pushActionWatchLive => 'Watch live';

  @override
  String pushJourneyStartedTitle(String name) {
    return '$name is sharing her journey';
  }

  @override
  String pushJourneyStartedBody(String destination) {
    return 'Heading to $destination. Tap to watch live.';
  }

  @override
  String get pushJourneyStartedBodyNoDest => 'Tap to watch live.';

  @override
  String pushArrivedTitle(String name) {
    return '$name arrived safely';
  }

  @override
  String pushArrivedBody(String destination) {
    return 'Her journey to $destination has ended.';
  }

  @override
  String get pushArrivedBodyNoDest => 'Her journey has ended.';

  @override
  String pushResponseCallingTitle(String name) {
    return '$name is calling you now';
  }

  @override
  String get pushResponseCallingBody => 'Keep your phone close.';

  @override
  String pushResponseAlertedTitle(String name) {
    return '$name has alerted others';
  }

  @override
  String get pushResponseAlertedBody => 'More people know you need help.';

  @override
  String pushLinkedTitle(String name) {
    return '$name is connected in Amica';
  }

  @override
  String get pushLinkedBody =>
      'They\'ll now get your alerts as notifications as well as texts.';

  @override
  String get pushResponseSentTitle => 'Reply sent';

  @override
  String pushResponseSentAlertedBody(String name) {
    return '$name knows you\'ve alerted others.';
  }

  @override
  String get pushResponseFailedTitle => 'Reply not sent';

  @override
  String get pushResponseFailedBody => 'Open Amica or call her directly.';

  @override
  String sosActivePushedCount(int count) {
    return 'Amica notification delivered to $count in your circle';
  }

  @override
  String get vehicleToldButton => 'What was I told?';

  @override
  String vehicleToldButtonSet(String description) {
    return 'Expecting $description';
  }

  @override
  String get vehicleToldSheetTitle => 'What were you told?';

  @override
  String get vehicleToldSheetBody =>
      'Ride apps show the vehicle, for example \"White Toyota Axio, CAB-1234\". Pick what you were told and Amica compares it with what the camera sees.';

  @override
  String get vehicleToldTypeLabel => 'Vehicle type';

  @override
  String get vehicleToldColourLabel => 'Colour';

  @override
  String get vehicleToldClear => 'Clear';

  @override
  String get vehicleToldDone => 'Done';

  @override
  String get vehicleToldCardTitle => 'Check it\'s the right vehicle';

  @override
  String get vehicleToldCardBody =>
      'Add the type and colour your ride app showed you.';

  @override
  String get vehicleToldCardAdd => 'Add';

  @override
  String get vehicleToldCardSetTitle => 'You were told';

  @override
  String get vehicleToldCardChange => 'Change';

  @override
  String get vehicleToldPreviewEmpty => 'Nothing picked yet. Choose below.';

  @override
  String get vehicleKindCar => 'car';

  @override
  String get vehicleKindVan => 'van';

  @override
  String get vehicleKindBus => 'bus';

  @override
  String get vehicleKindLorry => 'lorry';

  @override
  String get vehicleKindMotorbike => 'motorbike';

  @override
  String get vehicleKindThreeWheeler => 'three-wheeler';

  @override
  String get vehicleColourWhite => 'white';

  @override
  String get vehicleColourSilver => 'silver';

  @override
  String get vehicleColourGrey => 'grey';

  @override
  String get vehicleColourBlack => 'black';

  @override
  String get vehicleColourRed => 'red';

  @override
  String get vehicleColourMaroon => 'maroon';

  @override
  String get vehicleColourOrange => 'orange';

  @override
  String get vehicleColourYellow => 'yellow';

  @override
  String get vehicleColourGreen => 'green';

  @override
  String get vehicleColourBlue => 'blue';

  @override
  String get vehicleColourBrown => 'brown';

  @override
  String vehicleDescription(String colour, String kind) {
    return '$colour $kind';
  }

  @override
  String get vehicleMatchTitleMatch => 'Vehicle matches';

  @override
  String get vehicleMatchTitleMismatch => 'Vehicle doesn\'t match';

  @override
  String get vehicleMatchTitleNotSure => 'Couldn\'t check the vehicle';

  @override
  String get vehicleMatchBodyMatch =>
      'What the camera could see fits what was expected.';

  @override
  String vehicleMatchMismatchTold(String expected, String seen) {
    return 'You were told: $expected. The camera sees: $seen.';
  }

  @override
  String vehicleMatchMismatchCommunity(String expected, String seen) {
    return 'Other Amica scans usually saw this plate as: $expected. The camera sees: $seen.';
  }

  @override
  String get vehicleMatchAdvice =>
      'Double-check the vehicle and driver before you get in. The choice is yours.';

  @override
  String get vehicleMatchNotSureLowLight =>
      'Too dark to judge colour reliably.';

  @override
  String get vehicleMatchNotSureColourCast =>
      'Street lighting is changing colours, so colour was not compared.';

  @override
  String get vehicleMatchNotSureNoVehicle =>
      'No vehicle was clearly in view. Step back so more of it is in the photo.';

  @override
  String get vehicleMatchNotSureNothing =>
      'Before scanning, tap \"What was I told?\" to compare the vehicle with what the ride app showed.';

  @override
  String vehicleMatchSeen(String description) {
    return 'Camera sees: $description';
  }

  @override
  String get vehicleMatchSeenNothing =>
      'The camera couldn\'t make out the vehicle.';

  @override
  String vehicleMatchCommunity(String description, int count) {
    return 'Usually seen as: $description ($count scans)';
  }

  @override
  String get vehicleMatchPrivacy =>
      'Type and colour are checked on your phone. The first photo of a new vehicle is saved, cropped to the vehicle, so other riders can recognise it.';

  @override
  String get zzzArbEnd => 'do not translate; internal append anchor';
}
