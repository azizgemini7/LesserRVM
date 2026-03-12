import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart'; // for EagerGestureRecognizer
import 'package:html_unescape/html_unescape.dart';
import 'package:universal_io/io.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_options.dart';
import 'lcsystem.dart';
import 'uisystem.dart';
import 'package:get/get.dart';

// Only import dart:html if running ____
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences to load the saved language
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // String savedLanguage =
  //     prefs.getString('language') ?? 'en'; // Default to English

  if (await FirebaseMessaging.instance.isSupported()) {
    // Request permission to display notifications
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get any initial message that opened the app from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Handle the notification payload
      }
    });
  }

  // Disable App Check on all platforms
  // FirebaseAppCheck.instance.activate(
  //   webProvider: null, // No reCAPTCHA for web
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  runApp(MyApp());
}

String userRole = 'user'; // default

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Application language _____

String targetLanguage = 'en';

Map<String, String> languageNames = {
  'ar': 'Arabic',
  'en': 'English',
  // 'ja': 'Japanese',
  // 'fr': 'French',
  // 'es': 'Spanish',
  // 'de': 'German',
  // Add more language codes and names as needed
};

// Application Theme _____

AppThemeMode targetThemeMode = AppThemeMode.light;

Map<AppThemeMode, String> themeModeNames = {
  AppThemeMode.light: '☀️ Light',
  AppThemeMode.dark: '🌙 Dark',
  AppThemeMode.colorful: '🎨 Colorful',
};

// The App _____

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  // Method to set locale dynamically
  // static void setLocale(BuildContext context, Locale newLocale) {
  //   _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
  //   state?.setLocale(newLocale);
  // }
}

class _MyAppState extends State<MyApp> {
  static const String _title = 'Lesser';

  @override
  void initState() {
    super.initState();
  }

  // void setLocale(Locale locale) {
  //   setState(() {
  //     _locale = locale;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ApplicationColors.primary,
        ),
        scaffoldBackgroundColor: ApplicationColors.background, // ✅ Here!
      ),
      // locale: _locale,
      navigatorKey: navigatorKey,
      // supportedLocales: const [
      //   Locale('en'), // English
      //   Locale('ar'), // Arabic
      // ],
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => NavBarWidget(),
        '/contactus': (context) => ContactusPage(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        // Check for dynamic post routes
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'posts') {
          final postId = uri.pathSegments[1]; // Extract the post ID
          return MaterialPageRoute(
            builder: (context) => PostDetailsScreen(postId: postId),
            settings: settings,
          );
        }

        // Check for dynamic product routes
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'products') {
          final productId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: productId),
            settings: settings,
          );
        }

        return null; // For undefined routes
      },
    );
  }
}

// ________________________________________________
// NavBar Section
// HomePage Section || Widget 0
// ________________________________________________

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({super.key});

  @override
  State<NavBarWidget> createState() => _NavBarWidgetState();
}

class _NavBarWidgetState extends State<NavBarWidget>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setUpFirebaseMessaging();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkVersionAndForceUpdate(context);
    });
    fetchUserRole();
  }

  int _selectedIndex = 2;

  late TabController _tabController;

  List<Widget> get _widgetOptions {
    return [
      LeaderboardWidget(),
      NetPageWidget(),
      HomePageWidget(),
      userRole == 'business' ? PickupMap() : EnvPageWidget(),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Notifications setup functionality _____________________

  void _setUpFirebaseMessaging() async {
    if (!await FirebaseMessaging.instance.isSupported()) {
      return;
    }

    if (kIsWeb) {
      // Retrieve token for web
      FirebaseMessaging.instance
          .getToken(
              vapidKey:
                  'BHs5vx3SfvrutsAEfxexXs7v49X4Y1KIKHIPNSQDazE6ydg1iziNd7DBNdpfhvXthEqxpk3VAgBus84baqzSU0o')
          .then(
            (token) => print('Web FCM Token: $token'),
          );

      // Listen for messages from the service worker
      // html.window.onMessage.listen((event) {
      //   final data = event.data;
      //   if (data != null) {
      //     print('Message received from service worker: $data');
      //     _handleNotificationNavigation(
      //         Map<String, dynamic>.from(data)); // Pass data to navigation
      //   } else {
      //     print('No data received from service worker.');
      //   }
      // });
    } else {
      // Retrieve token for mobile
      FirebaseMessaging.instance.getToken().then((token) {
        if (token != null) {
          print("Mobile FCM Token: $token");
        } else {
          print("Failed to retrieve FCM token.");
        }
      });
    }

    // Handle foreground notifications (commented for now)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Uncomment this block in the future to handle foreground notifications
      /*
    print('Received a message in the foreground: ${message.messageId}');
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'No Title'),
        content: Text(message.notification?.body ?? 'No Body'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNotificationNavigation(
                  message.data); // Unified navigation logic
            },
            child: Text("Ok"),
          ),
        ],
      ),
    );
    */
    });

    // Handle notifications when the app is opened via a notification (after click the push notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked with data: ${message.data}');
      _handleNotificationNavigation(message.data); // Unified navigation logic
    });

    // Handle notifications received while the app was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened via notification: ${initialMessage.messageId}');
      _handleNotificationNavigation(
          initialMessage.data); // Unified navigation logic
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.containsKey('screen')) {
      // Navigate to Message Screen for message notifications
      if (data['screen'] == 'MessageScreen') {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => MessageScreen(),
          ),
        );
      }
      // Navigate to Bill Screen for bill notifications
      else if (data['screen'] == 'WalletScreen') {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => WalletScreen(),
          ),
        );
      }
    } else if (data.containsKey('route')) {
      // Navigate to specific post/product for posts or products
      Navigator.pushNamed(
        navigatorKey.currentContext!,
        data['route']!,
      );
    } else {
      print("Unknown notification data: $data");
    }
  }

  // Version checking functionality _____________________

  Future<void> checkVersionAndForceUpdate(BuildContext context) async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? Duration.zero // always fetch fresh in debug
          : Duration(hours: 1), // cache for users in production
    ));

    await remoteConfig.fetchAndActivate();

    final platform = Theme.of(context).platform == TargetPlatform.android
        ? 'android'
        : 'ios';

    final requiredVersion = platform == 'android'
        ? remoteConfig.getString('required_version_android')
        : remoteConfig.getString('required_version_ios');

    print("📌 Remote Config requiredVersion = $requiredVersion");

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    print("📌 Current app version = $currentVersion");

    if (_isVersionOutdated(currentVersion, requiredVersion)) {
      print("⚠️ Outdated → showing update dialog...");
      _showForceUpdateDialog(context);
    } else {
      print("✅ Up-to-date → continue");
    }
  }

  Future<void> checkVersionAndForceUpdate1(BuildContext context) async {
    const requiredVersion =
        '1.0.17'; // 🔁 Change this when you publish a new version

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (_isVersionOutdated(currentVersion, requiredVersion)) {
      _showForceUpdateDialog(context);
    }
  }

  bool _isVersionOutdated(String current, String required) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> r = required.split('.').map(int.parse).toList();

    for (int i = 0; i < r.length; i++) {
      if (i >= c.length || c[i] < r[i]) return true;
      if (c[i] > r[i]) return false;
    }
    return false;
  }

  void _showForceUpdateDialog(BuildContext context) {
    final platform = Theme.of(context).platform == TargetPlatform.android
        ? 'android'
        : 'ios';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🔄 Update Required"),
        content: const Text(
          "A newer version of Lesser is available. Please update the app to continue using it.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = platform == 'android'
                  ? 'https://play.google.com/store/apps/details?id=com.lesser.androidapp&hl=ar&pli=1'
                  : 'https://apps.apple.com/sa/app/lesser/id6670465462';
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  // User role checking functionalioty ________
  Future<void> fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        userRole = data['role'] ?? 'user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: translate('leaderboard', targetLanguage),
            backgroundColor: ApplicationColors.background,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.mail),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return const SizedBox();

                    bool hasUnread = snapshot.data!.docs.any((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      if (!data.containsKey('lastReadTimestamps')) return false;
                      if (!data['lastReadTimestamps']
                          .containsKey(currentUserId)) return false;

                      final lastRead =
                          data['lastReadTimestamps'][currentUserId];
                      final lastMessage = data['lastMessageTimestamp'];

                      if (lastRead == null || lastMessage == null) return false;

                      return lastMessage.toDate().isAfter(lastRead.toDate());
                    });

                    return hasUnread
                        ? Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : const SizedBox();
                  },
                ),
              ],
            ),
            label: translate('discover', targetLanguage),
            backgroundColor: ApplicationColors.background,
          ),
          BottomNavigationBarItem(
            icon: Image(
              image: AssetImage("assets/images/lesserlogo.png"),
              width: 25,
            ),
            label: translate('home', targetLanguage),
            backgroundColor: ApplicationColors.background,
          ),
          if (userRole != 'driver')
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.location_on),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, authSnapshot) {
                      if (!authSnapshot.hasData) return const SizedBox();

                      final currentUserId = authSnapshot.data!.uid;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bill_rooms')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }

                          final hasUnread = snapshot.data!.docs.any((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            if (!data.containsKey('lastReadTimestamps'))
                              return false;
                            if (!data['lastReadTimestamps']
                                .containsKey(currentUserId)) {
                              return false;
                            }

                            final lastRead =
                                data['lastReadTimestamps'][currentUserId];
                            final lastBill = data['lastBillTimestamp'];

                            if (lastRead == null || lastBill == null)
                              return false;

                            return lastBill.toDate().isAfter(lastRead.toDate());
                          });

                          return hasUnread
                              ? Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    height: 8,
                                    width: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        },
                      );
                    },
                  ),
                ],
              ),
              label: translate('recycle', targetLanguage),
              backgroundColor: ApplicationColors.background,
            ),
        ],
        // backgroundColor: ApplicationColors.background,
        currentIndex: _selectedIndex,
        fixedColor: ApplicationColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  @override
  void initState() {
    super.initState();
    fetchUserPremiumStatus(); // 🔁
    _updateTotalUsedFolders();
    fetchSubfiles(); // Fetch top-level folders initially
  }

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('required_signing', targetLanguage)),
        content: Text(translate('required_signing2', targetLanguage)),
      ),
    );
  }

  Future<void> _saveFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in. Cannot save FCM token.");
      return;
    }

    try {
      // ✅ Request notification permission first
      final settings = await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print(
            "❌ Notification permission not granted: ${settings.authorizationStatus}");
        return; // Stop here, don't try to get token
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': fcmToken});
        print("✅ FCM Token saved: $fcmToken");
      } else {
        print("⚠️ Failed to retrieve FCM token.");
      }
    } catch (e) {
      print("⚠️ FCM token saving error: $e");
      // 🔇 Don't show this to user, just log it
    }
  }

  // Authentications Functions and vars __________

  bool _isExpanded = false;

  void _openProfile() {
    final _formKey = GlobalKey<FormState>();
    final FocusNode f1 = FocusNode();
    final FocusNode f2 = FocusNode();

    final TextEditingController _inputController = TextEditingController();
    TextEditingController _phoneController = TextEditingController();
    TextEditingController _emailController = TextEditingController();
    TextEditingController _userNameController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();
    TextEditingController _fullNameController = TextEditingController();

    String _enteredPhone = '';
    String _selectedCountryCode = '+966'; // Default country code
    String _enteredEmail = '';
    String _enteredUserName = '';
    String _enteredPassword = '';
    String _enteredFullName = '';

    String? _selectedDistrict = null;
    String? _selectedAgeGroup = null;
    String _selectedGender = '';

    List<String> districts = [
      'Riyadh',
      'Jeddah',
      'Dammam',
      'Khobar',
      'Makkah',
      'Madina'
    ];
    List<String> ageGroups = [
      '12-18',
      '19-25',
      '26-35',
      '36-45',
      '46-59',
      '60+'
    ];
    List<String> genders = ['Male', 'Female'];

    bool isIconTrue = true;
    bool isChecked = false;
    bool? checkBoxValue = false;
    bool _isPhoneInput = false;

    int? _resendToken;
    bool _isSignIn = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              const String otpBaseUrl =
                  "https://otpbridge-42656840839.europe-west8.run.app";

              Future<void> _editProfile() async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    print("No user logged in");
                    return;
                  }

                  final userId = user.uid;
                  final TextEditingController usernameController =
                      TextEditingController();
                  final TextEditingController fullNameController =
                      TextEditingController();
                  String errorMessage = '';
                  bool isSaving = false;

                  print("Opening loading dialog...");

                  // Show loading dialog immediately
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevent accidental closure
                    builder: (BuildContext loadingContext) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("Loading profile..."),
                          ],
                        ),
                      );
                    },
                  );

                  print("Fetching user data...");

                  // Fetch user data from Firestore
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();
                  if (userDoc.exists) {
                    final data =
                        userDoc.data() ?? {}; // Ensure data is not null
                    usernameController.text =
                        data.containsKey('username') ? data['username'] : '';
                    fullNameController.text =
                        data.containsKey('full_name') ? data['full_name'] : '';
                  } else {
                    print("User document not found in Firestore.");
                  }

                  print("User data fetched. Closing loading dialog...");

                  // Close loading dialog before opening the edit form
                  if (mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                  }

                  print("Opening edit profile dialog...");

                  // Now open the actual edit profile dialog
                  await showDialog(
                    context: context,
                    barrierDismissible: false, // Prevent accidental closure
                    builder: (BuildContext dialogContext) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Edit Profile'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Static Profile Image
                                  ClipOval(
                                    child: Image.asset(
                                      'assets/images/nonuser.png', // Static profile image
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Username Input Field
                                  TextFormField(
                                    controller: usernameController,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Username (no spaces or dashes)',
                                      prefixIcon: Icon(Icons.account_circle),
                                    ),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      } else if (value.contains(' ') ||
                                          value.contains('-')) {
                                        return 'Username cannot contain spaces or dashes';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Full Name Input Field
                                  TextFormField(
                                    controller: fullNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      return null;
                                    },
                                  ),

                                  if (errorMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        errorMessage,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 14),
                                      ),
                                    ),

                                  const SizedBox(height: 10),

                                  // Save Button with Validation & Loading Indicator
                                  ElevatedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            String newUsername =
                                                usernameController.text.trim();
                                            String newFullName =
                                                fullNameController.text.trim();

                                            // Validate username format
                                            if (newUsername.isEmpty) {
                                              setState(() {
                                                errorMessage =
                                                    'Please enter your username';
                                              });
                                              return;
                                            } else if (newUsername
                                                    .contains(' ') ||
                                                newUsername.contains('-')) {
                                              setState(() {
                                                errorMessage =
                                                    'Username cannot contain spaces or dashes';
                                              });
                                              return;
                                            }

                                            // Validate full name format
                                            if (newFullName.isEmpty) {
                                              setState(() {
                                                errorMessage =
                                                    'Please enter your full name';
                                              });
                                              return;
                                            }

                                            setState(() {
                                              isSaving = true;
                                              errorMessage =
                                                  ''; // Reset error message
                                            });

                                            print(
                                                "Checking username availability...");

                                            final querySnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .where('username',
                                                        isEqualTo: newUsername)
                                                    .get();

                                            bool usernameExists = querySnapshot
                                                .docs
                                                .any((doc) => doc.id != userId);

                                            if (usernameExists) {
                                              print("Username already taken.");
                                              setState(() {
                                                errorMessage =
                                                    'This username is already taken. Try another one.';
                                                isSaving = false;
                                              });
                                            } else {
                                              print("Updating user data...");

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(userId)
                                                  .update({
                                                'username': newUsername,
                                                'full_name': newFullName,
                                              });

                                              print(
                                                  "User data updated successfully.");

                                              if (mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                            }
                                          },
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Save Changes'),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (!isSaving && mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  print("Edit profile dialog closed.");
                } catch (e) {
                  print("Error opening edit profile dialog: $e");
                }
              }

              Future<void> _showResetPasswordDialog(
                  BuildContext context) async {
                final TextEditingController emailController =
                    TextEditingController();
                String? errorMessage;

                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text('Reset Password'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Enter your email',
                                  hintText: 'example@example.com',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              if (errorMessage != null) ...[
                                SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  setState(() {
                                    errorMessage = 'Email cannot be empty';
                                  });
                                  return;
                                }

                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => Dialog(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          (ApplicationSpacing.large)),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Sending reset email..."),
                                          const SizedBox(height: 10),
                                          CircularProgressIndicator(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                try {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(email: email);
                                  Navigator.of(context)
                                      .pop(); // Close loading dialog
                                  Navigator.of(context)
                                      .pop(); // Close reset password dialog

                                  // Show success dialog
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Success'),
                                        content: Text(
                                            'Password reset email sent! Check your inbox.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  setState(() {
                                    errorMessage =
                                        'Please enter a valid email address, such as example@example.com.';
                                  });
                                  print(e);
                                }
                              },
                              child: Text('Reset Password'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }

              Future<void> _saveUserData(User user) async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'uid': user.uid,
                  'email': _enteredEmail,
                  'full_name': _enteredFullName,
                  'username': _enteredUserName,
                  'phone_number': _enteredPhone,
                  'district': _selectedDistrict,
                  'age_group': _selectedAgeGroup,
                  'gender': _selectedGender,
                  'points': 20,
                  'bottles': 0,
                  'cans': 0,
                  'waste': 0,
                  'role': 'user',
                });
              }

              void _detectInputType(String input) {
                setState(() {
                  if (input.contains("@")) {
                    _isPhoneInput = false;
                    _enteredEmail = input;
                  } else if (RegExp(r'^[0-9]+').hasMatch(input)) {
                    _isPhoneInput = true;
                    _enteredPhone = input;
                  } else {
                    _isPhoneInput = false;
                    _enteredUserName = input;
                  }
                });
              }

              Future<void> _submit() async {
                _formKey.currentState!.save();
                try {
                  if (_isSignIn) {
                    if (_isPhoneInput) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                (ApplicationSpacing.large)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Signing in..."),
                                const SizedBox(height: 10),
                                CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                      );

                      var querySnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .where('phone_number', isEqualTo: _enteredPhone)
                          .limit(1)
                          .get();

                      Navigator.pop(context); // Close loading indicator

                      if (querySnapshot.docs.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Phone Number Not Registered"),
                            content: Text(
                                "The phone number you entered is not associated with any account."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      // ✅ 1) Send OTP using Cloud Run (Twilio)
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.large),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text("Sending OTP..."),
                                SizedBox(height: 10),
                                CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                      );

                      try {
                        final startRes = await http.post(
                          Uri.parse("$otpBaseUrl/otp/start"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({"phone": _enteredPhone}),
                        );

                        Navigator.pop(context); // Close "Sending OTP..."

                        if (startRes.statusCode != 200) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("OTP Failed"),
                              content: Text(
                                "Failed to send OTP. (${startRes.statusCode})\n${startRes.body}",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        // ✅ 2) OTP Input Dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            String smsCode = "";
                            bool isLoading = false;

                            return StatefulBuilder(
                              builder: (context, setState) {
                                Future<void> resendOtp() async {
                                  setState(() => isLoading = true);
                                  try {
                                    final resendRes = await http.post(
                                      Uri.parse("$otpBaseUrl/otp/start"),
                                      headers: {
                                        "Content-Type": "application/json"
                                      },
                                      body:
                                          jsonEncode({"phone": _enteredPhone}),
                                    );

                                    if (resendRes.statusCode == 200) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "OTP resent successfully.")),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Resend Failed"),
                                          content: Text(
                                            "(${resendRes.statusCode})\n${resendRes.body}",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Resend Failed"),
                                        content: Text(e.toString()),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } finally {
                                    setState(() => isLoading = false);
                                  }
                                }

                                Future<void> verifyOtpAndSignIn() async {
                                  if (smsCode.trim().length != 6) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Invalid OTP"),
                                        content: const Text(
                                            "Please enter a valid 6-digit OTP."),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            ApplicationSpacing.large),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text("Verifying OTP..."),
                                            SizedBox(height: 10),
                                            CircularProgressIndicator(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  try {
                                    final checkRes = await http.post(
                                      Uri.parse("$otpBaseUrl/otp/check"),
                                      headers: {
                                        "Content-Type": "application/json"
                                      },
                                      body: jsonEncode({
                                        "phone": _enteredPhone,
                                        "code": smsCode.trim(),
                                      }),
                                    );

                                    Navigator.pop(
                                        context); // Close "Verifying OTP..."

                                    if (checkRes.statusCode != 200) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Invalid OTP"),
                                          content: Text(
                                            "OTP verification failed.\n(${checkRes.statusCode})\n${checkRes.body}",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    final data = jsonDecode(checkRes.body)
                                        as Map<String, dynamic>;
                                    final token =
                                        (data["firebaseCustomToken"] ?? "")
                                            .toString();

                                    if (token.isEmpty) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Error"),
                                          content: const Text(
                                              "Missing firebaseCustomToken from server."),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ Firebase Sign In using Custom Token
                                    await FirebaseAuth.instance
                                        .signInWithCustomToken(token);

                                    await _saveFCMToken();

                                    // Close OTP dialog
                                    Navigator.pop(context);

                                    // Success dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Success"),
                                        content: const Text(
                                            "You have signed in successfully!"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.of(context)
                                                  .pushNamedAndRemoveUntil(
                                                      '/', (route) => false);
                                            },
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    // Close "Verifying OTP..." if needed
                                    try {
                                      Navigator.pop(context);
                                    } catch (_) {}

                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: Text(e.toString()),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }

                                return AlertDialog(
                                  title:
                                      Text("Enter OTP sent to $_enteredPhone"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            hintText: "Enter OTP"),
                                        onChanged: (value) => smsCode = value,
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed:
                                              isLoading ? null : resendOtp,
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 14,
                                                  width: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                )
                                              : const Text("Resend OTP"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: verifyOtpAndSignIn,
                                      child: const Text("Verify"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      } catch (e) {
                        // Close "Sending OTP..." if still open
                        try {
                          Navigator.pop(context);
                        } catch (_) {}

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("OTP Failed"),
                            content: Text(e.toString()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                (ApplicationSpacing.large)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Signing in..."),
                                const SizedBox(height: 10),
                                CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                      );

                      String email = _enteredEmail;
                      if (!_enteredEmail.contains("@")) {
                        String? fetchedEmail = await FirebaseFirestore.instance
                            .collection('users')
                            .where('username', isEqualTo: _enteredUserName)
                            .limit(1)
                            .get()
                            .then((query) => query.docs.isNotEmpty
                                ? query.docs.first['email']
                                : null);

                        Navigator.pop(context); // Close the loading indicator

                        if (fetchedEmail != null) {
                          email = fetchedEmail;
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Username Not Found"),
                              content: Text(
                                  "No account found with this username. Please try again."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      } else {
                        // Check if email exists in Firestore
                        String? fetchedEmail = await FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: _enteredEmail)
                            .limit(1)
                            .get()
                            .then((query) => query.docs.isNotEmpty
                                ? query.docs.first['email']
                                : null);

                        Navigator.pop(context); // Close the loading indicator

                        if (fetchedEmail == null) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Email Not Found"),
                              content: Text(
                                  "No account found with this email. Please try again."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      }

                      _passwordController.clear();

                      // Show password input dialog if email/username exists
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Enter Password"),
                            content: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                  hintText: "Enter your password"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  _enteredPassword =
                                      _passwordController.text.trim();

                                  if (_enteredPassword.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Invalid Password"),
                                        content: Text(
                                            "Password field cannot be empty."),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  // Navigator.pop(context); // Close the password dialog

                                  // Show signing in loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            (ApplicationSpacing.large)),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("Signing in..."),
                                            const SizedBox(height: 10),
                                            CircularProgressIndicator(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  try {
                                    print(
                                        "Attempting to sign in with email: $email and password: $_enteredPassword");

                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                            email: email,
                                            password: _enteredPassword);
                                    await _saveFCMToken();

                                    Navigator.pop(
                                        context); // Close the loading indicator

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        title: Text("Success"),
                                        content: Text(
                                            "You have signed in successfully!"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);

                                              Navigator.of(context)
                                                  .pushNamedAndRemoveUntil(
                                                      '/', (route) => false);
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    Navigator.pop(
                                        context); // Close the loading indicator
                                    print(
                                        "FirebaseAuthException: ${e.code} - ${e.message}");

                                    String errorMessage =
                                        "An error occurred. Please try again.";
                                    if (e.code == 'wrong-password' ||
                                        e.code == 'invalid-credential') {
                                      errorMessage =
                                          "The password you entered is incorrect. Please try again.";
                                    } else if (e.code == 'user-not-found') {
                                      errorMessage =
                                          "No user found with this email. Please check and try again.";
                                    } else if (e.code == 'too-many-requests') {
                                      errorMessage =
                                          "Too many unsuccessful attempts. Please try again later.";
                                    } else if (e.code == 'invalid-email') {
                                      errorMessage =
                                          "The email address is not valid. Please check and try again.";
                                    }

                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Sign-in Failed"),
                                        content: Text(errorMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    Navigator.pop(
                                        context); // Close loading indicator
                                    print("General Exception: ${e.toString()}");
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Error"),
                                        content: Text(
                                            "An unexpected error occurred. Please try again."),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                child: Text("Sign in"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } else {
                    // SIGN UP using Twilio OTP + Firebase Custom Token

                    // 1️⃣ Check if phone exists in Firestore
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(ApplicationSpacing.large),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text("Signing up..."),
                              SizedBox(height: 10),
                              CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      ),
                    );

                    final existing = await FirebaseFirestore.instance
                        .collection('users')
                        .where('phone_number', isEqualTo: _enteredPhone)
                        .limit(1)
                        .get();

                    Navigator.pop(context);

                    if (existing.docs.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Phone Already Registered"),
                          content: const Text("Please sign in instead."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"))
                          ],
                        ),
                      );
                      return;
                    }

                    // 2️⃣ Start OTP
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(ApplicationSpacing.large),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text("Sending OTP..."),
                              SizedBox(height: 10),
                              CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      ),
                    );

                    final startRes = await http.post(
                      Uri.parse("$otpBaseUrl/otp/start"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({"phone": _enteredPhone}),
                    );

                    Navigator.pop(context);

                    if (startRes.statusCode != 200) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("OTP Failed"),
                          content: Text(startRes.body),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"))
                          ],
                        ),
                      );
                      return;
                    }

                    // 3️⃣ Show OTP Dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        String smsCode = "";

                        return AlertDialog(
                          title: Text("Enter OTP sent to $_enteredPhone"),
                          content: TextField(
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: "Enter OTP"),
                            onChanged: (v) => smsCode = v,
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel")),
                            TextButton(
                              child: const Text("Verify"),
                              onPressed: () async {
                                if (smsCode.length != 6) return;

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => Dialog(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          ApplicationSpacing.large),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text("Verifying OTP..."),
                                          SizedBox(height: 10),
                                          CircularProgressIndicator(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                final checkRes = await http.post(
                                  Uri.parse("$otpBaseUrl/otp/check"),
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    "phone": _enteredPhone,
                                    "code": smsCode
                                  }),
                                );

                                Navigator.pop(context);

                                if (checkRes.statusCode != 200) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Invalid OTP"),
                                      content: Text(checkRes.body),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"))
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final data = jsonDecode(checkRes.body)
                                    as Map<String, dynamic>;
                                final token = data["firebaseCustomToken"];

                                final userCred = await FirebaseAuth.instance
                                    .signInWithCustomToken(token);

                                // Link email + password
                                await userCred.user!.linkWithCredential(
                                  EmailAuthProvider.credential(
                                    email: _enteredEmail,
                                    password: _enteredPassword,
                                  ),
                                );

                                await _saveFCMToken();
                                await _saveUserData(userCred.user!);

                                Navigator.pop(context);

                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/', (route) => false);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                } on FirebaseAuthException catch (error) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(error.message ?? 'Authentication Failed!')),
                  );
                }
              }

              void _showError(String message) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              }

              Widget _buildSignUpForm() {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Changing signing __________
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sign up',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: AppTextColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2),
                          Switch(
                            activeColor: ApplicationColors.primary,
                            value: _isSignIn,
                            onChanged: (value) {
                              setState(() {
                                _isSignIn = value;
                              });
                            },
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Sign in',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: AppTextColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      //Image(
                      //image: AssetImage(nonuser),
                      //width: MediaQuery.of(context).size.width * 0.30,
                      //),
                      Text(
                        'Sign up to Your Account',
                        style: AppTypo.heading2.copyWith(
                          color: AppTextColors.primary,
                        ),
                      ),
                      // Phone number ______________
                      SizedBox(height: 20),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone), // Show phone icon
                          hintText: "Phone Number",
                        ),
                        initialCountryCode: 'SA', // Default country
                        showDropdownIcon:
                            true, // Keep dropdown icon for selection
                        showCountryFlag:
                            false, // Hides the flag in the input field
                        onChanged: (phone) {
                          setState(() {
                            _enteredPhone = phone.completeNumber;
                            _selectedCountryCode = phone.countryCode;
                          });
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      // Email _______
                      SizedBox(height: 10),
                      TextFormField(
                        focusNode: f1,
                        onFieldSubmitted: (v) {
                          f1.unfocus();
                          FocusScope.of(context).requestFocus(f2);
                        },
                        validator: (k) {
                          if (!k!.contains('@')) {
                            return 'Please enter the correct email';
                          }
                          return null;
                        },
                        controller: _emailController,
                        onChanged: (value) {
                          setState(() {
                            _formKey.currentState!.validate();
                          });
                        },
                        onSaved: (k) {
                          _enteredEmail = k!;
                        },
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.mail_rounded),
                            hintText: "Email"),
                      ),
                      // User name _______________
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.account_circle),
                          hintText: "Username (no spaces or dashes)",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your username';
                          } else if (value.contains(' ') ||
                              value.contains('-')) {
                            return 'Username cannot contain spaces or dashes';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredUserName = value!;
                        },
                        onChanged: (value) {
                          setState(() {
                            _formKey.currentState!.validate();
                          });
                        },
                      ),
                      // Password ____________
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: isIconTrue,
                        focusNode: f2,
                        validator: (value) {
                          return Validate.validate(value!);
                        },
                        onFieldSubmitted: (v) {
                          f2.unfocus();
                          if (_formKey.currentState!.validate()) {
                            //
                          }
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          hintText: "Password",
                          suffixIcon: Theme(
                            data: ThemeData(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent),
                            child: IconButton(
                              highlightColor: Colors.transparent,
                              onPressed: () {
                                setState(() {
                                  isIconTrue = !isIconTrue;
                                });
                              },
                              icon: Icon(
                                (isIconTrue)
                                    ? Icons.visibility_off
                                    : Icons.visibility_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formKey.currentState!.validate();
                          });
                        },
                      ),
                      // Full name __________
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          hintText: "Full Name",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredFullName = value!;
                        },
                        onChanged: (value) {
                          setState(() {
                            _formKey.currentState!.validate();
                          });
                        },
                      ),
                      // District ___________
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value:
                            _selectedDistrict, // Assuming you have a selected district variable
                        hint: Text('Select City'),
                        items: districts
                            .map((district) => DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value!;
                            _formKey.currentState!.validate();
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a city' : null,
                      ),
                      // Age Group ________________
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedAgeGroup,
                        hint: Text('Select Age Group'),
                        items: ageGroups
                            .map((ageGroup) => DropdownMenuItem(
                                  value: ageGroup,
                                  child: Text(ageGroup),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAgeGroup = value!;
                            _formKey.currentState!.validate();
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select an age group' : null,
                      ),
                      // Gender _____________
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Gender:',
                            style: ApplicationTextStyles.textPrimary,
                          ),
                          Spacer(),
                          Radio(
                            value: 'male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value as String;
                              });
                            },
                          ),
                          Text('Male',
                              style: AppTypo.body.copyWith(
                                color: AppTextColors.primary,
                              )),
                          SizedBox(width: 10),
                          Radio(
                            value: 'female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value as String;
                              });
                            },
                          ),
                          Text('Female',
                              style: AppTypo.body.copyWith(
                                color: AppTextColors.primary,
                              )),
                        ],
                      ),
                      // Submitting ________________
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submit();
                          }
                        },
                        style: ApplicationButtons.button0(),
                        child: Text('Sign Up'),
                      ),
                      // Forgot password ___________
                      SizedBox(height: 4),
                    ],
                  ),
                );
              }

              Widget _buildSignInForm() {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sign up',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: AppTextColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2),
                          Switch(
                            activeColor: ApplicationColors.primary,
                            value: _isSignIn,
                            onChanged: (value) {
                              setState(() {
                                _isSignIn = value;
                              });
                            },
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              'Sign in',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: AppTextColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      //Image(
                      //image: AssetImage(nonuser),
                      //width: MediaQuery.of(context).size.width * 0.30,
                      //),
                      Text(
                        'Sign in to Your Account',
                        style: AppTypo.heading2.copyWith(
                          color: AppTextColors.primary,
                        ),
                      ),
                      // Email/Phone/Username _______
                      SizedBox(height: 20),
                      if (_isPhoneInput)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isPhoneInput = false;
                              });
                            },
                            child: Text(
                              'Use email or username instead',
                              style: AppTypo.bodyBold.copyWith(
                                color: AppTextColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      _isPhoneInput
                          ? IntlPhoneField(
                              showDropdownIcon:
                                  true, // Keep dropdown icon for selection
                              showCountryFlag: false,
                              decoration: InputDecoration(
                                  hintText: "Enter Phone Number"),
                              initialCountryCode: 'SA',
                              onChanged: (phone) =>
                                  _enteredPhone = phone.completeNumber,
                            )
                          : TextFormField(
                              controller: _inputController,
                              keyboardType: TextInputType.text,
                              decoration:
                                  ApplicationInputFields.input1().copyWith(
                                hintText: "Enter email/username/phone",
                              ),
                              onChanged: (value) => _detectInputType(value),
                            ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _submit();
                            await _saveFCMToken();
                          }
                        },
                        style: ApplicationButtons.button0(),
                        child: Text(
                          'Sign In',
                          style: AppTypo.bodyBold.copyWith(
                            color: AppTextColors.inverse,
                          ),
                        ),
                      ),

                      SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _showResetPasswordDialog(context),
                        child: Text('Forgot the password ?',
                            style: AppTypo.bodyBold.copyWith(
                              color: AppTextColors.secondary,
                            )),
                      ),
                    ],
                  ),
                );
              }

              Widget _buildProfileUI() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar ______________________
                    ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child: Image(
                        image: AssetImage(nonuser),
                        width: MediaQuery.of(context).size.width * 0.30,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Settings button ________________
                    SizedBox(height: 8),
                    InkWell(
                      onTap: _editProfile,
                      child: SizedBox(
                        height: 24,
                        child: Image.asset('assets/images/editprofile.png'),
                      ),
                    ),
                    // Name and Welcoming __________
                    SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get()
                          .then((snapshot) =>
                              snapshot.data()!['full_name'].toString()),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            "Error: ${snapshot.error}", // Handle errors
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white),
                          );
                        }
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return Text(
                              "Loading...",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white),
                            );
                          default:
                            return Text(
                              "${snapshot.data!}",
                              style: AppTypo.heading2
                                  .copyWith(color: AppTextColors.primary),
                            );
                        }
                      },
                    ),
                    // User Subscription Status ____________
                    Padding(
                      padding:
                          const EdgeInsets.all((ApplicationSpacing.medium)),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subscription status ___________
                            userRole == 'business'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: ApplicationSpacing.medium,
                                      vertical: ApplicationSpacing.small,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "You are a Business User",
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // TextButton(
                                        //   onPressed: () {
                                        //     showDialog(
                                        //       context: context,
                                        //       builder: (context) => AlertDialog(
                                        //         title: Text("Account Info"),
                                        //         content: Text(
                                        //             "You are already a Business user.\nThank you!"),
                                        //         actions: [
                                        //           TextButton(
                                        //             onPressed: () => Navigator.pop(context),
                                        //             child: Text("Close"),
                                        //           ),
                                        //         ],
                                        //       ),
                                        //     );
                                        //   },
                                        //   child: Text("Manage"),
                                        // ),
                                      ],
                                    ),
                                  )
                                : userRole == 'driver'
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: Colors.blue),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "You are a Driver",
                                              style: TextStyle(
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        WalletScreen(),
                                                  ),
                                                );
                                              },
                                              child: Text("Open Orders"),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: Colors.orange),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Individual User",
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            // TextButton(
                                            //   onPressed: () {
                                            //     final user =
                                            //         FirebaseAuth.instance.currentUser;
                                            //     if (user == null) {
                                            //       _notSignedIn();
                                            //     } else {
                                            //       upgradePremium();
                                            //     }
                                            //   },
                                            //   child: Text("Upgrade"),
                                            // ),
                                          ],
                                        ),
                                      ),
                          ],
                        ),
                      ),
                    ),
                    // Logout __________________
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirm Logout'),
                            content: Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await FirebaseAuth.instance.signOut();

                          setState(() {
                            userRole = 'user';
                          });

                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          vertical: ApplicationSpacing.medium,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(45)),
                          color: ApplicationColors.primary,
                        ),
                        child: Text(
                          'Logout',
                          style: AppTypo.bodyBold.copyWith(
                            color: AppTextColors.inverse,
                          ),
                        ),
                      ),
                    ),
                    // Delete account ______________
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        // Show the confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Account'),
                              content: Text(
                                  'Are you sure you want to delete this account?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Dismiss the dialog if the user cancels
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context)
                                        .pop(); // Dismiss confirmation dialog

                                    try {
                                      // Delete the user account after confirmation
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();

                                      // Log the user out after deleting the account
                                      await FirebaseAuth.instance.signOut();

                                      // Show success dialog
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Success'),
                                            content: Text(
                                                'Account deleted successfully.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Dismiss success dialog

                                                  // Refresh the current widget or page
                                                  setState(() {
                                                    // This will trigger the widget to rebuild
                                                  });
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage =
                                          'Unknown error occurred.';

                                      if (e.code == 'requires-recent-login') {
                                        errorMessage =
                                            'Re-authentication required to delete account.';
                                      } else if (e.message != null) {
                                        errorMessage = e.message!;
                                      }

                                      // Show error dialog
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Error'),
                                            content: Text(errorMessage),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Dismiss error dialog
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        'Delete this account?',
                        style: AppTypo.bodyBold.copyWith(
                          color: AppTextColors.red,
                        ),
                      ),
                    )
                  ],
                );
              }

              return Scaffold(
                backgroundColor: ApplicationColors.background,
                appBar: AppBar(
                  backgroundColor: ApplicationColors.background,
                  iconTheme: IconThemeData(
                    color: ApplicationColors.secondary,
                  ),
                  title: Text('My Profile',
                      style: AppTypo.heading3.copyWith(
                        color: AppTextColors.primary,
                      )),
                ),
                body: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.all(ApplicationSpacing.medium),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ApplicationColors.background,
                            ),
                            child: StreamBuilder(
                              stream: FirebaseAuth.instance.authStateChanges(),
                              builder: (ctx, snapshot) {
                                if (snapshot.hasData) {
                                  return _buildProfileUI();
                                }
                                return _isSignIn
                                    ? _buildSignInForm()
                                    : _buildSignUpForm();
                              },
                            ),
                          ),
                        ),
                        Card(
                          margin:
                              const EdgeInsets.all(ApplicationSpacing.medium),
                          child: Container(
                            decoration: ApplicationContainers.container2,
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.small),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: ApplicationSpacing.medium,
                                    vertical: ApplicationSpacing.small,
                                  ),
                                  title: Text(
                                    'Contact us on WhatsApp',
                                    style: AppTypo.bodyBold.copyWith(
                                      color: ApplicationColors.secondary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: ApplicationColors.secondary,
                                  ),
                                  onTap: () async {
                                    // Replace with your WhatsApp number (include country code without +)
                                    final Uri uri =
                                        Uri.parse('https://wa.me/966566013374');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                                Divider(height: 8),
                                // Privacy Policy
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: ApplicationSpacing.medium,
                                    vertical: ApplicationSpacing.small,
                                  ),
                                  title: Text(
                                    'Privacy Policy',
                                    style: AppTypo.bodyBold.copyWith(
                                      color: AppTextColors.primary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: ApplicationColors.secondary,
                                  ),
                                  onTap: () async {
                                    final Uri uri = Uri.parse(
                                        'https://www.lesserapp.com/policy');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                                Divider(height: 8),
                                // Terms of Service
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: ApplicationSpacing.medium,
                                    vertical: ApplicationSpacing.small,
                                  ),
                                  title: Text(
                                    'Terms of Service',
                                    style: AppTypo.bodyBold.copyWith(
                                      color: AppTextColors.primary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: ApplicationColors.secondary,
                                  ),
                                  onTap: () async {
                                    final Uri uri = Uri.parse(
                                        'https://www.lesserapp.com/terms-conditions');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Choose language and social accounts (Temporary) _________________
                        SizedBox(height: 15),
                        Card(
                          margin:
                              const EdgeInsets.all(ApplicationSpacing.medium),
                          child: Container(
                            height: 200,
                            decoration: ApplicationContainers.container2,
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.large),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dropdown 3: Choosing language (Temporary will be deleted later)
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          decoration:
                                              ApplicationDropdowns.dropdown1,
                                          value: targetLanguage,
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                targetLanguage = newValue;

                                                // Update application to apply the language
                                                Navigator.of(context)
                                                    .pushNamedAndRemoveUntil(
                                                        '/', (route) => false);
                                              });
                                              // _saveLanguage(
                                              //     newValue); // Save the selected language
                                            }
                                          },
                                          items: languageNames.keys
                                              .map<DropdownMenuItem<String>>(
                                                  (String code) {
                                            return DropdownMenuItem<String>(
                                              value: code,
                                              child: Text(languageNames[code]!),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: ApplicationSpacing.medium),
                                      Expanded(
                                        child: DropdownButtonFormField<
                                            AppThemeMode>(
                                          decoration:
                                              ApplicationDropdowns.dropdown1,
                                          value: targetThemeMode,
                                          onChanged: (AppThemeMode? newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                targetThemeMode = newValue;
                                                // 🔁 Restart app like language
                                                Navigator.of(context)
                                                    .pushNamedAndRemoveUntil(
                                                        '/', (route) => false);
                                              });
                                            }
                                          },
                                          items: themeModeNames.entries
                                              .map((entry) {
                                            return DropdownMenuItem<
                                                AppThemeMode>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider
                                Divider(height: 16),
                                // Content with Navigation and Display
                                Expanded(
                                  child: Row(
                                    children: [
                                      // Content Area ___________
                                      Expanded(
                                        child: Container(
                                          //  padding: EdgeInsets.only(left: 12.0),
                                          child: Center(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    ApplicationSpacing.medium,
                                                vertical:
                                                    ApplicationSpacing.small,
                                              ),
                                              child: Row(
                                                children:
                                                    socialData.map((item) {
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      final url = Uri.parse(
                                                          item['url']);
                                                      if (await canLaunchUrl(
                                                          url)) {
                                                        await launchUrl(url,
                                                            mode: LaunchMode
                                                                .externalApplication);
                                                      }
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal:
                                                            ApplicationSpacing
                                                                .small,
                                                      ),
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundImage:
                                                            AssetImage(
                                                                item['avatar']),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Social channels and translation (Temporary) ___________

  List<Map<String, dynamic>> socialData = [
    {
      'platform': 'Website',
      'avatar': 'assets/images/00.png',
      'url': 'https://www.lesserapp.com',
    },
    {
      'platform': 'LinkedIn',
      'avatar': 'assets/images/01.png',
      'url':
          'https://www.linkedin.com/company/lesser-for-sustainability-solutions/',
    },
    {
      'platform': 'X',
      'avatar': 'assets/images/03.png',
      'url': 'https://x.com/lesserappksa',
    },
    {
      'platform': 'Instagram',
      'avatar': 'assets/images/04.png',
      'url': 'https://www.instagram.com/lesserapp/',
    },
  ];

  // CALENDAR AND DATA CHARTS FUNCTIONS ___________________

  MeetingDataSource _getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];
    final DateTime today = DateTime.now();
    appointments.add(Appointment(
      startTime: DateTime(today.year, today.month, today.day, 0, 0, 0),
      endTime: DateTime(today.year, today.month, today.day, 8, 0, 0),
      subject: 'First pickup',
      color: Colors.black,
    ));
    appointments.add(Appointment(
      startTime: DateTime(today.year, today.month, today.day, 8, 0, 0),
      endTime: DateTime(today.year, today.month, today.day, 12, 0, 0),
      subject: 'Second pickup',
      color: Colors.red,
    ));
    appointments.add(Appointment(
      startTime: DateTime(today.year, today.month, today.day, 12, 0, 0),
      endTime: DateTime(today.year, today.month, today.day, 16, 0, 0),
      subject: 'Third pickup',
      color: Colors.blue,
    ));
    appointments.add(Appointment(
      startTime: DateTime(today.year, today.month, today.day, 16, 0, 0),
      endTime: DateTime(today.year, today.month, today.day, 20, 0, 0),
      subject: 'Fourth pickup',
      color: Colors.green,
    ));
    appointments.add(Appointment(
      startTime: DateTime(today.year, today.month, today.day, 20, 0, 0),
      endTime: DateTime(today.year, today.month, today.day, 24, 0, 0),
      subject: 'Fifth pickup',
      color: Colors.yellow,
    ));
    return MeetingDataSource(appointments);
  }

  // FILES STORAGE FUNCTIONS AND VARS _______________________

  num get maxFolders {
    switch (userRole) {
      case 'business':
        return double.infinity;
      case 'premium':
        return 10;
      default:
        return 1;
    }
  }

  int get usedFolders => folderDocs.length;
  int _totalUsedFolders = 0;

  List<DocumentSnapshot> folderDocs = [];

  String? currentOwnerUid;

  // Track current path: ['mainLocationId', 'subfileId', ...]
  List<String> currentFirestorePath = [];
  // Map folder IDs to names for breadcrumb display
  Map<String, String> folderNames = {};

  String searchText = ''; // Text for search bar
  final TextEditingController searchController = TextEditingController();
  String sortBy = 'Date'; // Default sorting option
  String filterCategory = ''; // Default category (empty means no filter)

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Local state for filter options
            String selectedSort = 'Date'; // Default sort option
            String selectedCategory = ''; // Selected category
            List<String> categories = []; // Categories fetched dynamically

            // Fetch categories dynamically (Example)
            if (categories.isEmpty) {
              FirebaseFirestore.instance
                  .collection('posts')
                  .get()
                  .then((querySnapshot) {
                final uniqueCategories = querySnapshot.docs
                    .map((doc) => doc['category'] as String?)
                    .where(
                        (category) => category != null && category.isNotEmpty)
                    .toSet()
                    .toList();
                setState(() {
                  //  categories = uniqueCategories;
                });
              });
            }

            return AlertDialog(
              title: Text('Filter Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Filter
                  Text('Sort By:'),
                  DropdownButton<String>(
                    value: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                    items: ['Date', 'Price', 'Most Liked'].map((sortOption) {
                      return DropdownMenuItem<String>(
                        value: sortOption,
                        child: Text(sortOption),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  Text('Category:'),
                  DropdownButton<String>(
                    value:
                        selectedCategory.isNotEmpty ? selectedCategory : null,
                    hint: Text('Select a Category'),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog without applying
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Apply filters
                    setState(() {
                      // Store the selected sort and category for filtering
                      sortBy = selectedSort;
                      filterCategory = selectedCategory;
                    });
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTotalUsedFolders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Count root folders
    final rootSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('locations')
        .get();

    int total = rootSnapshot.docs.length;

    for (final doc in rootSnapshot.docs) {
      final subPath = 'users/$uid/locations/${doc.id}';
      total += await _countAllFoldersRecursively(subPath);
    }

    setState(() {
      _totalUsedFolders = total;
    });
  }

  Future<int> _countAllFoldersRecursively(String parentPath) async {
    int total = 0;

    final subfilesSnapshot = await FirebaseFirestore.instance
        .collection('$parentPath/subfiles')
        .get();

    total += subfilesSnapshot.docs.length;

    for (final doc in subfilesSnapshot.docs) {
      final subPath = '$parentPath/subfiles/${doc.id}';
      total += await _countAllFoldersRecursively(subPath); // recursion
    }

    return total;
  }

  Future<void> fetchUserFolders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('locations')
          .get();

      folderDocs = snapshot.docs;

      // Optionally update maxFolders if user is premium
      // e.g., if you fetch user profile data later and set isPremium = true;
      // maxFolders = isPremium ? double.infinity.toInt() : 1;

      setState(() {});
    } catch (e) {
      print("Error fetching folders: $e");
      folderDocs = [];
      setState(() {});
    }
  }

  Future<void> fetchSubfiles() async {
    try {
      // Are we at root? (My Branches)
      if (currentFirestorePath.isEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        // 🔹 1. Fetch owned folders
        final ownedSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('locations')
            .get();
        final ownedDocs = ownedSnap.docs;

        // 🔹 2. Fetch shared folders
        final sharedDocs = await _fetchSharedRootFiles();

        // 🔹 3. Merge and deduplicate by Firestore path
        final seenPaths = <String>{};
        final allDocs = <DocumentSnapshot>[];

        for (final doc in [...ownedDocs, ...sharedDocs]) {
          if (seenPaths.add(doc.reference.path)) {
            allDocs.add(doc);
          }
        }

        setState(() {
          folderDocs = allDocs;
          currentOwnerUid = uid; // root starts from me
        });
      } else {
        // 🔹 Normal subfile fetch
        final ref = getCurrentSubfileCollectionRef();
        final snapshot = await ref.get();
        setState(() {
          folderDocs = snapshot.docs;
        });
      }
    } catch (e) {
      print("Error fetching subfiles: $e");
      setState(() {
        folderDocs = [];
      });
    }
  }

  CollectionReference getCurrentSubfileCollectionRef() {
    final uid = currentOwnerUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("UID is null");

    CollectionReference ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('locations');

    for (String id in currentFirestorePath) {
      ref = ref.doc(id).collection('subfiles');
    }

    return ref;
  }

  Future<List<DocumentSnapshot>> _fetchSharedRootFiles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final membersSnap = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();

      final List<DocumentSnapshot> sharedFiles = [];
      final Set<String> seenPaths = {};

      for (final memberDoc in membersSnap.docs) {
        final membersColl = memberDoc.reference.parent;
        final allTimeDoc = membersColl.parent;
        if (allTimeDoc == null || allTimeDoc.id != 'all_time') continue;

        final timeframesColl = allTimeDoc.parent;
        if (timeframesColl == null) continue;

        final fileDocRef = timeframesColl.parent;
        if (fileDocRef == null) continue;

        final fileDoc = await fileDocRef.get();
        if (!fileDoc.exists) continue;

        if (seenPaths.add(fileDoc.reference.path)) {
          sharedFiles.add(fileDoc);
        }
      }

      return sharedFiles;
    } catch (e) {
      print("Error fetching shared files: $e");
      return [];
    }
  }

  Future<void> _manageFile({
    DocumentReference? fileRef,
    Map<String, dynamic>? existingData,
  }) async {
    final _formKey = GlobalKey<FormState>();

    final _nameController =
        TextEditingController(text: existingData?['name'] ?? '');
    final _detailsController =
        TextEditingController(text: existingData?['details'] ?? '');
    final _latController = TextEditingController(
        text: existingData?['latitude']?.toString() ?? '');
    final _lngController = TextEditingController(
        text: existingData?['longitude']?.toString() ?? '');
    final _notesController =
        TextEditingController(text: existingData?['notes'] ?? '');

    final _inviteController = TextEditingController();
    List<Map<String, dynamic>> _suggestions = [];
    List<Map<String, dynamic>> _invitedUsers = [];
    List<Map<String, dynamic>> _members = [];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              // Saving file function ___
              Future<void> _save() async {
                if (!_formKey.currentState!.validate()) return;

                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;

                final name = _nameController.text.trim();
                final details = _detailsController.text.trim(); // ✅ NEW
                final lat = double.tryParse(_latController.text.trim());
                final lng = double.tryParse(_lngController.text.trim());
                final notes = _notesController.text.trim();

                final dataToSave = {
                  'name': name,
                  'details': details, // ✅ NEW
                  'notes': notes,
                  'latitude': lat,
                  'longitude': lng,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                try {
                  if (fileRef == null) {
                    final collection = getCurrentSubfileCollectionRef();

                    final newDocRef =
                        collection.doc(); // Create doc ref manually to get ID

                    await newDocRef.set({
                      ...dataToSave,
                      'createdBy': uid, // always set on create
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    final parentDocRef = collection.parent;

                    // Skip group creation if under `/users/{uid}/locations`
                    if (parentDocRef != null &&
                        parentDocRef.parent?.id != 'users') {
                      await parentDocRef
                          .collection('timeframes')
                          .doc('all_time')
                          .collection('groups')
                          .doc(newDocRef.id)
                          .set({
                        'uid': newDocRef.id,
                        'username': dataToSave['name'] ?? 'Untitled',
                        'score': 0,
                        'trophies': 0,
                        'joinedAt': FieldValue.serverTimestamp(),
                      });
                    }
                  } else {
                    await fileRef.update(dataToSave);
                  }

                  Navigator.pop(context);
                  fetchSubfiles(); // Refresh
                } catch (e) {
                  print("Error saving file: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save file')),
                  );
                }
              }

              // Inviting users function ___
              Future<void> _inviteUser(String username) async {
                if (username.trim().isEmpty) return;

                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                if (currentUid == null) return;

                final ref = fileRef;
                if (ref == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Please save the file before inviting")),
                  );
                  return;
                }

                final docSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: username)
                    .limit(1)
                    .get();

                if (docSnapshot.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User not found")),
                  );
                  return;
                }

                final userDoc = docSnapshot.docs.first;
                final invitedUid = userDoc.id;
                final invitedUsername = userDoc['username'] ?? 'unknown';

                final memberRef = ref
                    .collection('timeframes')
                    .doc('all_time')
                    .collection('members')
                    .doc(invitedUid);

                final existing = await memberRef.get();
                if (existing.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User is already a member")),
                  );
                  return;
                }

                if (invitedUid == currentUid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("You cannot invite yourself")),
                  );
                  return;
                }

                await memberRef.set({
                  'uid':
                      invitedUid, // ✅ Add this line to fix collectionGroup query
                  'joinedAt': FieldValue.serverTimestamp(),
                  'score': 0,
                  'username': invitedUsername,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User invited successfully")),
                );
              }

              Future<void> _fetchMembers() async {
                if (fileRef == null) return;

                final snapshot = await fileRef
                    .collection('timeframes')
                    .doc('all_time')
                    .collection('members')
                    .get();

                List<Map<String, dynamic>> updatedMembers = [];

                for (final doc in snapshot.docs) {
                  final uid = doc.id;
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get();
                  final username = userDoc.exists
                      ? userDoc['username'] ?? 'unknown'
                      : 'unknown';

                  updatedMembers.add({
                    'uid': uid,
                    'username': username,
                    'score': doc['score'] ?? 0,
                  });
                }

                setState(() {
                  _members = updatedMembers;
                });
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchMembers();
              });

              return Scaffold(
                appBar: AppBar(
                  title:
                      Text(fileRef == null ? 'Create New File' : 'Edit File'),
                  actions: [
                    TextButton(
                      onPressed: _save,
                      child:
                          Text('Save', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // 🔹 1. Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter a name'
                              : null,
                        ),
                        TextFormField(
                          controller: _detailsController,
                          decoration: InputDecoration(
                            labelText: 'Details (e.g., house number)',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Details are required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // 🔹 2. Location
                        Text('Location:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 250,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                double.tryParse(_latController.text) ?? 24.7136,
                                double.tryParse(_lngController.text) ?? 46.6753,
                              ),
                              zoom: 14,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              setState(() {}); // Just refresh state
                            },
                            markers: {
                              Marker(
                                markerId: MarkerId('picked'),
                                position: LatLng(
                                  double.tryParse(_latController.text) ??
                                      24.7136,
                                  double.tryParse(_lngController.text) ??
                                      46.6753,
                                ),
                                draggable: true,
                                onDragEnd: (LatLng newPosition) {
                                  _latController.text =
                                      newPosition.latitude.toStringAsFixed(6);
                                  _lngController.text =
                                      newPosition.longitude.toStringAsFixed(6);
                                  setState(() {});
                                },
                              ),
                            },
                            onTap: (LatLng tapped) {
                              _latController.text =
                                  tapped.latitude.toStringAsFixed(6);
                              _lngController.text =
                                  tapped.longitude.toStringAsFixed(6);
                              setState(() {});
                            },
                            // ✅ This is what fixes the pinch zoom issue
                            gestureRecognizers: <
                                Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                          ),
                        ),
                        SizedBox(height: 20),

                        // 🔹 3. Relation Section – Invite Members (Autocomplete only for now)
                        Text('Relation:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _inviteController,
                          decoration: InputDecoration(
                            labelText: 'Invite by username',
                            suffixIcon: Icon(Icons.search),
                          ),
                          onChanged: (text) async {
                            if (text.length < 2) {
                              setState(() {
                                _suggestions = [];
                              });
                              return;
                            }

                            final snapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .where('username', isGreaterThanOrEqualTo: text)
                                .where('username', isLessThan: text + '\uf8ff')
                                .limit(5)
                                .get();

                            setState(() {
                              _suggestions = snapshot.docs
                                  .map((doc) => {
                                        'uid': doc.id,
                                        'username':
                                            doc['username'] ?? 'unknown',
                                      })
                                  .toList();
                            });
                          },
                        ),
                        SizedBox(height: 4),

                        if (_suggestions.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Column(
                              children: _suggestions.map((user) {
                                return ListTile(
                                  title: Text(user['username']),
                                  onTap: () {
                                    setState(() {
                                      _inviteController.clear();
                                      _suggestions = [];
                                      _invitedUsers
                                          .add(user); // Add to invited list
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        SizedBox(height: 12),

                        if (_invitedUsers.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _invitedUsers.map((user) {
                              return Chip(
                                label: Text(user['username']),
                                deleteIcon: Icon(Icons.close),
                                onDeleted: () {
                                  setState(() {
                                    _invitedUsers.removeWhere(
                                        (u) => u['uid'] == user['uid']);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.send),
                            label: Text('Send Invites'),
                            onPressed: () async {
                              for (final user in _invitedUsers) {
                                await _inviteUser(user['username']);
                              }

                              setState(() {
                                _invitedUsers.clear();
                              });

                              _fetchMembers(); // 🔁 Refresh members after inviting
                            }, // call your function here
                          ),
                        ),
                        if (_members.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('No members yet',
                                style: AppTypo.body.copyWith(
                                  color: AppTextColors.disabled,
                                )),
                          )
                        else
                          Column(
                            children: _members.map((member) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      member['username'].toString().isNotEmpty
                                          ? member['username'][0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(member['username']),
                                  subtitle: Text('Score: ${member['score']}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final ref = fileRef;
                                      if (ref != null) {
                                        await ref
                                            .collection('timeframes')
                                            .doc('all_time')
                                            .collection('members')
                                            .doc(member['uid'])
                                            .delete();
                                        await _fetchMembers(); // Refresh
                                      }
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        SizedBox(height: 20),

                        // 🔹 4. Notes
                        Text('Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: null,
                          minLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Write your notes here...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool isPremium = false;

  Future<void> fetchUserPremiumStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['isPremium'] == true) {
      setState(() {
        isPremium = true;
      });
    } else {
      setState(() {
        isPremium = false;
      });
    }
  }

  void upgradePremium() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Upgrade Plan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upgrade to Premium",
                style: AppTypo.heading3.copyWith(
                  color: AppTextColors.primary,
                )),
            SizedBox(height: 8),
            Text(
                "Enjoy unlimited access to Smart Cardboards and unlock the full power of your recycling experience:",
                style: AppTypo.body.copyWith(
                  color: AppTextColors.secondary,
                )),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      "Create unlimited Smart Cardboards linked to locations."),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      "Organize and track your recycling files with no limits."),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      "Support our mission and help build a cleaner future."),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Only 5 SAR/month — cancel anytime.",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                // Optional: Show a loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      Center(child: CircularProgressIndicator()),
                );

                try {
                  final response = await http.post(
                    Uri.parse(
                        'https://createmoyasarpayment-42656840839.europe-west8.run.app'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'uid': uid}),
                  );

                  // if (!mounted)
                  //   return; // 🔒 prevent using context after disposal
                  // Navigator.pop(context); // Close loading spinner

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final paymentUrl = data['url'];

                    if (await canLaunchUrl(Uri.parse(paymentUrl))) {
                      await launchUrl(Uri.parse(paymentUrl),
                          mode: LaunchMode.externalApplication);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: Text("Payment Started"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Finish your payment in the next page and get back here to see the update.",
                              ),
                              SizedBox(height: 20),
                              CircularProgressIndicator(), // 🌀 Loading spinner
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/', (route) => false);
                              },
                              child: Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      throw Exception('Could not launch payment page');
                    }
                  } else {
                    throw Exception('Failed to initiate payment');
                  }
                } catch (e) {
                  print('Payment error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Error starting payment. Please try again.")),
                  );
                }
                // Navigator.pop(context); // Close dialog
              }
            },
            child: Text("Upgrade Now"),
          ),
        ],
      ),
    );
  }

  Widget _pageBody() {
    return Center(
      child: Column(
        children: [
          // The main Logo and slogan ____________________
          SizedBox(height: 16),
          // Chart visualizations Section __________________
          userRole == 'user'
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Section 1 (Calendar) __________________
                      // Container(
                      //   padding: const EdgeInsets.all(20.0),
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(10.0),
                      //     color: Colors.white,
                      //   ),
                      //   child: SfCalendar(
                      //     view: CalendarView.week,
                      //     showNavigationArrow: true,
                      //     showCurrentTimeIndicator: true,
                      //     showWeekNumber: true,
                      //     showDatePickerButton: true,
                      //     showTodayButton: true,
                      //     allowViewNavigation: true,
                      //     allowDragAndDrop: true,
                      //     allowAppointmentResize: true,
                      //     allowedViews: <CalendarView>[
                      //       CalendarView.day,
                      //       CalendarView.week,
                      //       CalendarView.month,
                      //     ],
                      //     dataSource: _getCalendarDataSource(),
                      //   ),
                      // ),
                      // Section 2 ______

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate('points', targetLanguage),
                            style: AppTypo.heading3.copyWith(
                              color: AppTextColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.large),
                            decoration: ApplicationContainers.container4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<String?>(
                                          future: FirebaseAuth.instance
                                                      .currentUser?.uid !=
                                                  null
                                              ? FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(FirebaseAuth.instance
                                                      .currentUser!.uid)
                                                  .get()
                                                  .then(
                                                    (snapshot) => snapshot
                                                        .data()!['points']
                                                        .toString(),
                                                  )
                                              : Future.value(null),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return Text(
                                                'Error',
                                                style:
                                                    AppTypo.heading2.copyWith(
                                                  color: AppTextColors.inverse,
                                                ),
                                              );
                                            }

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Text(
                                                '...',
                                                style:
                                                    AppTypo.heading2.copyWith(
                                                  color: AppTextColors.inverse,
                                                ),
                                              );
                                            }

                                            return Text(
                                              snapshot.data ?? '0',
                                              style: AppTypo.heading2.copyWith(
                                                color: AppTextColors.inverse,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          translate(
                                              'total_points', targetLanguage),
                                          style: AppTypo.body.copyWith(
                                            color: AppTextColors.inverse,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  WalletScreen(),
                                            ),
                                          );
                                        } else {
                                          _notSignedIn();
                                        }
                                      },
                                      style: ApplicationButtons.button2(),
                                      child: Text(
                                        translate('wallet', targetLanguage),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ApplicationSpacing.xLarge),
                      // Section 3 ______
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate('impact', targetLanguage),
                            style: AppTypo.heading3.copyWith(
                              color: AppTextColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      ApplicationSpacing.large),
                                  decoration: ApplicationContainers.container1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/bottles-2.png'),
                                        width: 62,
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder<String?>(
                                        future: FirebaseAuth.instance
                                                    .currentUser?.uid !=
                                                null
                                            ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .get()
                                                .then(
                                                  (snapshot) => snapshot
                                                      .data()!['bottles']
                                                      .toString(),
                                                )
                                            : Future.value(null),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return Text(
                                                '...',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: AppTextColors.primary,
                                                ),
                                              );
                                            default:
                                              return Text(
                                                snapshot.data ?? '0',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: AppTextColors.primary,
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translate('bottles', targetLanguage),
                                        style: AppTypo.body.copyWith(
                                          color: ApplicationColors.secondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      ApplicationSpacing.large),
                                  decoration: ApplicationContainers.container1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/cans-2.png'),
                                        width: 62,
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder<String?>(
                                        future: FirebaseAuth.instance
                                                    .currentUser?.uid !=
                                                null
                                            ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .get()
                                                .then(
                                                  (snapshot) => snapshot
                                                      .data()!['cans']
                                                      .toString(),
                                                )
                                            : Future.value(null),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return Text(
                                                '...',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: AppTextColors.primary,
                                                ),
                                              );
                                            default:
                                              return Text(
                                                snapshot.data ?? '0',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: AppTextColors.primary,
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translate('cans', targetLanguage),
                                        style: AppTypo.body.copyWith(
                                          color: ApplicationColors.secondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      ApplicationSpacing.large),
                                  decoration: ApplicationContainers.container1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/co2-2.png'),
                                        width: 62,
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder<String?>(
                                        future: FirebaseAuth.instance
                                                    .currentUser?.uid !=
                                                null
                                            ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .get()
                                                .then(
                                                  (snapshot) => snapshot
                                                      .data()!['bottles']
                                                      .toString(),
                                                )
                                            : Future.value(null),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return Text(
                                                '...',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color:
                                                      ApplicationColors.primary,
                                                ),
                                              );
                                            default:
                                              final data = snapshot.data ?? '0';
                                              final numberOfBottles =
                                                  int.tryParse(data) ?? 0;
                                              final totalCO2 =
                                                  numberOfBottles * 0.015;
                                              return Text(
                                                totalCO2.toStringAsFixed(3),
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: ApplicationColors
                                                      .secondary,
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translate(
                                            'co2_emissions', targetLanguage),
                                        style: AppTypo.body.copyWith(
                                          color: ApplicationColors.secondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      ApplicationSpacing.large),
                                  decoration: ApplicationContainers.container1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/waste-2.png'),
                                        width: 62,
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder<String?>(
                                        future: FirebaseAuth.instance
                                                    .currentUser?.uid !=
                                                null
                                            ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .get()
                                                .then(
                                                  (snapshot) => snapshot
                                                      .data()!['waste']
                                                      .toString(),
                                                )
                                            : Future.value(null),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          switch (snapshot.connectionState) {
                                            case ConnectionState.waiting:
                                              return Text(
                                                '...',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: AppTextColors.primary,
                                                ),
                                              );
                                            default:
                                              return Text(
                                                snapshot.data ?? '0',
                                                style:
                                                    AppTypo.heading3.copyWith(
                                                  color: ApplicationColors
                                                      .secondary,
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        translate('kg_waste', targetLanguage),
                                        style: AppTypo.body.copyWith(
                                          color: ApplicationColors.secondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Container(),
          // Driver orders ____
          userRole == 'driver'
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "You are a Driver",
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalletScreen(),
                            ),
                          );
                        },
                        child: Text("Open Orders"),
                      ),
                    ],
                  ),
                )
              : Container(),
          // Folders/Files Section __________________
          userRole == 'business'
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(ApplicationSpacing.medium),
                    child: Container(
                      decoration: ApplicationContainers.container1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress Bar ____________
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.medium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "$_totalUsedFolders of ${maxFolders == double.infinity ? '∞' : maxFolders} Cardboards used",
                                    style: AppTypo.body.copyWith(
                                      color: AppTextColors.primary,
                                    )),
                                SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: maxFolders == double.infinity
                                      ? 1.0
                                      : (_totalUsedFolders / maxFolders)
                                          .clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    maxFolders != double.infinity &&
                                            _totalUsedFolders >= maxFolders
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // File tools manager with search and filtering _____________
                          Center(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.create_new_folder),
                              label:
                                  Text(translate('new_branch', targetLanguage)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ApplicationColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 24),
                                textStyle:
                                    TextStyle(fontWeight: FontWeight.w800),
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  _manageFile(); // ✅ use your unified function
                                } else {
                                  _notSignedIn();
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.medium),
                            child: TextField(
                              controller: searchController,
                              decoration:
                                  ApplicationInputFields.input1().copyWith(
                                labelText: 'Search',
                                prefixIcon: Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.filter_list),
                                  onPressed: () {
                                    _showFilterDialog(context);
                                  },
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchText = value
                                      .trim()
                                      .toLowerCase(); // Normalize the search query
                                });
                              },
                            ),
                          ),
                          const Divider(thickness: 1.0),
                          // Files/Folders Navigation _____________
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.medium),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      currentFirestorePath.clear();
                                      folderNames.clear();
                                      currentOwnerUid = FirebaseAuth
                                          .instance.currentUser?.uid;
                                    });
                                    fetchSubfiles();
                                  },
                                  child: Text("My Branches"),
                                ),
                                const Icon(Icons.chevron_right),
                                for (int i = 0;
                                    i < currentFirestorePath.length;
                                    i++)
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            currentFirestorePath =
                                                currentFirestorePath.sublist(
                                                    0, i + 1);
                                          });
                                          fetchSubfiles();
                                        },
                                        child: Text(
                                          folderNames[
                                                  currentFirestorePath[i]] ??
                                              currentFirestorePath[i],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          // Folder/Subfile Listing _________________
                          folderDocs.isNotEmpty
                              ? ListView.builder(
                                  itemCount: folderDocs.length,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    final doc = folderDocs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    return ListTile(
                                      leading: IconButton(
                                        icon: Icon(Icons.apartment),
                                        tooltip: "Open File Info",
                                        onPressed: () {
                                          final folderData = doc.data()
                                              as Map<String, dynamic>;
                                          _manageFile(
                                            fileRef: doc.reference,
                                            existingData: folderData,
                                          );
                                        },
                                      ),
                                      title: Text(
                                          data['name'] ?? 'Unnamed Location'),
                                      subtitle: FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(data['createdBy'])
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Text("Created by: ...");
                                          }
                                          final userData = snapshot.data!.data()
                                              as Map<String, dynamic>?;
                                          final username =
                                              userData?['username'] ??
                                                  'Unknown';
                                          return Text("Created by: $username");
                                        },
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.folder_open),
                                            tooltip: "Open Folder",
                                            onPressed: () {
                                              final createdBy =
                                                  (data['createdBy'] as String?)
                                                      ?.trim();
                                              if (currentFirestorePath
                                                      .isEmpty &&
                                                  createdBy != null) {
                                                // ✅ Entering root-level folder: set branch owner
                                                currentOwnerUid = createdBy;
                                              }

                                              setState(() {
                                                currentFirestorePath.add(doc
                                                    .id); // Add to navigation path
                                                folderNames[doc.id] = data[
                                                        'name'] ??
                                                    doc.id; // Save name for breadcrumb
                                              });
                                              fetchSubfiles();
                                            },
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert),
                                            tooltip: "More Options",
                                            onSelected: (value) async {
                                              if (value == 'delete') {
                                                final confirmed =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                        "Confirm Deletion"),
                                                    content: Text(
                                                        "Are you sure you want to delete this file?"),
                                                    actions: [
                                                      TextButton(
                                                        child: Text("Cancel"),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                      ),
                                                      ElevatedButton(
                                                        child: Text("Delete"),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmed == true) {
                                                  try {
                                                    await doc.reference
                                                        .delete();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              "File deleted")),
                                                    );
                                                    fetchSubfiles(); // Refresh list
                                                  } catch (e) {
                                                    print("Delete error: $e");
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              "Error deleting file")),
                                                    );
                                                  }
                                                }
                                              } else if (value == 'move') {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "Move not implemented yet")),
                                                );
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              // PopupMenuItem(
                                              //   value: 'move',
                                              //   child: Text("Move"),
                                              // ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 200,
                                  child: Text("This folder is empty",
                                      style: AppTypo.body.copyWith(
                                        color: AppTextColors.disabled,
                                      )),
                                ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ApplicationColors.background,
          // Qr Code ____
          leading: Padding(
            padding: const EdgeInsets.only(
                left:
                    16.0), // Optional: spacing // Optional: to match icon padding
            child: CircleAvatar(
              backgroundColor:
                  ApplicationColors.primary, // ✅ Background color for QR
              child: IconButton(
                icon: Icon(Icons.qr_code, color: Colors.white),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: Text("QR Code")),
                          body: Center(
                            child: QrImageView(
                              data: user.uid,
                              version: QrVersions.auto,
                              size: 250.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    _notSignedIn();
                  }
                },
              ),
            ),
          ),
          // Profile screen _____
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // Optional: spacing
              child: CircleAvatar(
                backgroundColor:
                    ApplicationColors.primary, // ✅ Background color for profile
                child: IconButton(
                  icon: Icon(Icons.account_circle, color: Colors.white),
                  onPressed: () {
                    _openProfile();
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => Scaffold(
                    //       appBar: AppBar(
                    //         title: Text('My Profile'),
                    //       ),
                    //       body: SingleChildScrollView(
                    //         child: Center(
                    //           child: Padding(
                    //             padding: const EdgeInsets.all(16.0),
                    //             child: Container(
                    //               width:
                    //                   MediaQuery.of(context).size.width * 0.85,
                    //               padding: EdgeInsets.all(12),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 border: Border.all(color: Colors.black),
                    //                 borderRadius: BorderRadius.circular(15),
                    //                 boxShadow: [
                    //                   BoxShadow(
                    //                     color: Colors.grey.withOpacity(0.5),
                    //                     spreadRadius: 1,
                    //                     blurRadius: 3,
                    //                     offset: Offset(0, 2),
                    //                   ),
                    //                 ],
                    //               ),
                    //               child: StreamBuilder(
                    //                 stream: FirebaseAuth.instance
                    //                     .authStateChanges(),
                    //                 builder: (ctx, snapshot) {
                    //                   if (snapshot.hasData) {
                    //                     return _buildProfileUI(); // ✅ your existing function
                    //                   }
                    //                   return _isSignIn
                    //                       ? _buildSignInForm() // ✅ your existing function
                    //                       : _buildSignUpForm(); // ✅ your existing function
                    //                 },
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // );
                  },
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            //  constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
              color: ApplicationColors.background,
              // image: DecorationImage(
              //   image: AssetImage('assets/images/background.png'),
              //   fit: BoxFit.cover,
              // ),
            ),
            child: width <= 800
                ? _pageBody()
                : Padding(
                    padding: const EdgeInsets.only(
                      left: 200,
                      right: 200,
                    ),
                    child: _pageBody(),
                  ),
          ),
        ),
      ),
    );
  }
}

class ZoomImageScreen extends StatefulWidget {
  final List<String>? galleryImages;
  final int index;

  ZoomImageScreen({required this.galleryImages, required this.index});

  @override
  _ZoomImageScreenState createState() => _ZoomImageScreenState();
}

class _ZoomImageScreenState extends State<ZoomImageScreen> {
  bool showAppBar = false;

  @override
  void initState() {
    super.initState();
    _setStatusBarColor();
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _resetStatusBarColor();
  }

  void _resetStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: (Theme.of(context).brightness == Brightness.dark)
          ? Colors.black87
          : Colors.black,
    ));
  }

  Widget placeHolderWidget() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("Gallery",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          elevation: 0.0,
        ),
        body: PhotoViewGallery.builder(
          scrollPhysics: BouncingScrollPhysics(),
          enableRotation: false,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: widget.index),
          builder: (BuildContext context, int index) {
            print('🔍 Opening image URL: ${widget.galleryImages![index]}');
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.galleryImages![index]),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              errorBuilder: (context, error, stackTrace) => placeHolderWidget(),
              heroAttributes:
                  PhotoViewHeroAttributes(tag: widget.galleryImages![index]),
            );
          },
          itemCount: widget.galleryImages!.length,
          loadingBuilder: (context, event) =>
              Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class Validate {
  static validate(String value) {
    if (value.length < 8) {
      return 'password must be more than 8 character';
    } else if (value.length > 16) {
      return 'password must be  less than 16 character';
    } else if (value.isEmpty) {
      return 'Please enter password';
    }
  }
}

class ChartData {
  final num
      x; // Replace with the actual data type for x-axis (e.g., int, double)
  final String
      y; // Replace with the actual data type for y-axis (e.g., String for pie charts)

  ChartData(this.x, this.y);
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class ContactusPage extends StatefulWidget {
  const ContactusPage({Key? key}) : super(key: key);

  @override
  State<ContactusPage> createState() => _ContactusPageState();
}

class _ContactusPageState extends State<ContactusPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  double _opacity = 0;

  // bool? checkBoxValue = false;

  // Services and projects Functions ____

  //  final CarouselController _controller = CarouselController();
  int _serviceCurrent = 0;
  int _projectCurrent = 0;
  int _partnerCurrent = 0;

  Color _green = Color(0xff263F6B);

  final List<String> ourprojectslogo = [
    'assets/images/product1.png',
    'assets/images/product2.png',
    'assets/images/product3.png',
    'assets/images/product4.png',
    'assets/images/product5.png',
  ];

  final List<String> ourprojectstitle = [
    'Abrat Mashahir',
    'LSI SILDERMA',
    'Hestia',
    'White rose',
    'Tranacix'
  ];

  final List<String> ourpartnerslogo = [
    'assets/images/partner1.png',
    'assets/images/partner2.png',
    'assets/images/partner3.png'
  ];

  final List<String> ourpartnerstitle = ['LSI', 'Dr. Oracle', 'GTG Medical'];

  final List<String> _servicesImages = [
    'assets/images/service2.png',
    'assets/images/service3.png',
    'assets/images/service1.png',
  ];

  final List<String> ourservices = [
    'Excellence',
    'Education',
    'Transparency',
  ];

  final List _isHovering = [false, false, false, false, false, false, false];
  final List _isSelected = [true, false, false, false, false, false, false];

  List<Widget> generateImageTiles(screenSize) {
    return _servicesImages
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesProj(screenSize) {
    return ourprojectslogo
        .map(
          (image) => Padding(
            padding: EdgeInsets.only(top: screenSize.height / 50),
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: screenSize.width / 2.4,
                      width: screenSize.width / 1.8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          image,
                          //  fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: screenSize.height / 70,
                      ),
                      child: Text(
                        ourprojectstitle[_projectCurrent],
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: screenSize.width / 15),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesProj2(screenSize) {
    return ourprojectslogo
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesPartners(screenSize) {
    return ourpartnerslogo
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List isHovering = [false, false, false];

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  // Contact us functions ______________

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _sendEmail() async {
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String message = _messageController.text;

    // Construct the request body
    Map<String, String> formData = {
      'name': name,
      'email': email,
      'message': message,
    };

    // Send POST request to the endpoint
    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/care@lesserapp.com'),
        body: formData,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Show alert after sending
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Message Sent'),
            content: Text('Thank you for your message!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to send message. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // background image
                      Image(
                        image: AssetImage('assets/background11.png'),
                        fit: BoxFit.cover,
                      ),
                      Center(
                        child: Column(
                          children: [
                            // The main Logo and slogan ____________________
                            SizedBox(height: 50),
                            Image(
                              image: AssetImage("assets/images/lesserlogo.png"),
                              width: MediaQuery.of(context).size.width * 0.30,
                            ),
                            Text(
                              'LESSER',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        // Sign in/up Section __________________
                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width * 0.65,
                        //   child: Container(
                        //     padding: EdgeInsets.all(2),
                        //     decoration: BoxDecoration(
                        //       border: Border.all(color: Colors.black),
                        //       borderRadius: BorderRadius.circular(15),
                        //     ),
                        //     child: StreamBuilder(
                        //       stream: FirebaseAuth.instance.authStateChanges(),
                        //       builder: (ctx, snapshot) {
                        //         // if (snapshot.connectionState ==
                        //         //     ConnectionState.waiting) {
                        //         //   return Text(
                        //         //     'Loading...',
                        //         //     style: TextStyle(fontSize: 15),
                        //         //   );
                        //         // }
                        //         if (snapshot.hasData) {
                        //           return Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             mainAxisAlignment: MainAxisAlignment.start,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.center,
                        //             children: [
                        //               Image(
                        //                 image: AssetImage(nonuser),
                        //                 width:
                        //                     MediaQuery.of(context).size.width *
                        //                         0.30,
                        //               ),
                        //               InkWell(
                        //                   onTap: () {},
                        //                   child: SizedBox(
                        //                       height: 24,
                        //                       child: Image.asset(
                        //                           Appcontent.addpostst))),
                        //               Text(
                        //                 'Welcome! You Logged in!',
                        //                 style: TextStyle(fontSize: 15),
                        //               ),
                        //               SizedBox(height: 8),
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   FirebaseAuth.instance.signOut();
                        //                 },
                        //                 child: Container(
                        //                   alignment: Alignment.center,
                        //                   padding: EdgeInsets.symmetric(
                        //                       vertical: 16),
                        //                   decoration: BoxDecoration(
                        //                     borderRadius: BorderRadius.all(
                        //                         Radius.circular(45)),
                        //                     color: Colors.black,
                        //                   ),
                        //                   child: Text(
                        //                     'Logout',
                        //                     style: TextStyle(
                        //                         color: Colors.white,
                        //                         fontSize: 15),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 4),
                        //             ],
                        //           );
                        //         }
                        //         return Form(
                        //           key: _formKey,
                        //           child: Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             mainAxisAlignment: MainAxisAlignment.start,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.center,
                        //             children: [
                        //               Image(
                        //                 image: AssetImage(nonuser),
                        //                 width:
                        //                     MediaQuery.of(context).size.width *
                        //                         0.30,
                        //               ),
                        //               Text(
                        //                 'SignIn/up Your Account',
                        //                 style: TextStyle(fontSize: 15),
                        //               ),
                        //               SizedBox(height: 20),
                        //               TextFormField(
                        //                 focusNode: f1,
                        //                 onFieldSubmitted: (v) {
                        //                   f1.unfocus();
                        //                   FocusScope.of(context)
                        //                       .requestFocus(f2);
                        //                 },
                        //                 validator: (k) {
                        //                   if (!k!.contains('@')) {
                        //                     return 'Please enter the correct email';
                        //                   }
                        //                   return null;
                        //                 },
                        //                 controller: _emailController,
                        //                 onSaved: (k) {
                        //                   _enteredEmail = k!;
                        //                 },
                        //                 decoration: InputDecoration(
                        //                     prefixIcon:
                        //                         Icon(Icons.mail_rounded),
                        //                     hintText: "Email"),
                        //               ),
                        //               SizedBox(height: 20),
                        //               TextFormField(
                        //                 controller: _passwordController,
                        //                 obscureText: isIconTrue,
                        //                 focusNode: f2,
                        //                 validator: (value) {
                        //                   return Validate.validate(value!);
                        //                 },
                        //                 onFieldSubmitted: (v) {
                        //                   f2.unfocus();
                        //                   if (_formKey.currentState!
                        //                       .validate()) {
                        //                     //
                        //                   }
                        //                 },
                        //                 onSaved: (value) {
                        //                   _enteredPassword = value!;
                        //                 },
                        //                 decoration: InputDecoration(
                        //                   prefixIcon: Icon(Icons.lock),
                        //                   hintText: "Password",
                        //                   suffixIcon: Theme(
                        //                     data: ThemeData(
                        //                         splashColor: Colors.transparent,
                        //                         highlightColor:
                        //                             Colors.transparent),
                        //                     child: IconButton(
                        //                       highlightColor:
                        //                           Colors.transparent,
                        //                       onPressed: () {
                        //                         setState(() {
                        //                           isIconTrue = !isIconTrue;
                        //                         });
                        //                       },
                        //                       icon: Icon(
                        //                         (isIconTrue)
                        //                             ? Icons.visibility_rounded
                        //                             : Icons.visibility_off,
                        //                         size: 16,
                        //                         color: Colors.grey,
                        //                       ),
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 8),
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   if (_formKey.currentState!
                        //                       .validate()) {
                        //                     _submit();
                        //                   }
                        //                 },
                        //                 child: Container(
                        //                   alignment: Alignment.center,
                        //                   padding: EdgeInsets.symmetric(
                        //                       vertical: 16),
                        //                   decoration: BoxDecoration(
                        //                     borderRadius: BorderRadius.all(
                        //                         Radius.circular(45)),
                        //                     color: Colors.black,
                        //                   ),
                        //                   child: Text(
                        //                     _isSignIn ? 'Sign In' : 'Sign Up',
                        //                     style: TextStyle(
                        //                         color: Colors.white,
                        //                         fontSize: 15),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 4),
                        //               Row(
                        //                 children: [
                        //                   Expanded(
                        //                     child: Text(
                        //                       'Sign up',
                        //                       textAlign: TextAlign.center,
                        //                       style: TextStyle(
                        //                           color: Colors.black,
                        //                           fontSize: 15,
                        //                           fontWeight: FontWeight.w600),
                        //                     ),
                        //                   ),
                        //                   SizedBox(width: 2),
                        //                   Switch(
                        //                     value: _isSignIn,
                        //                     onChanged: (value) {
                        //                       setState(() {
                        //                         _isSignIn = value;
                        //                       });
                        //                     },
                        //                   ),
                        //                   SizedBox(width: 2),
                        //                   Expanded(
                        //                     child: Text(
                        //                       'Sign in',
                        //                       textAlign: TextAlign.center,
                        //                       style: TextStyle(
                        //                           color: Colors.black,
                        //                           fontSize: 15,
                        //                           fontWeight: FontWeight.w600),
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //               SizedBox(height: 4),
                        //               TextButton(
                        //                 onPressed: () {},
                        //                 child: Text('Forgot the password ?',
                        //                     style: TextStyle(
                        //                         fontWeight: FontWeight.bold)),
                        //               ),
                        //             ],
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //   ),
                        // ),
                        // Identity Section ____________________
                        // SizedBox(height: 5),
                        // Padding(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 6,
                        //     right: MediaQuery.of(context).size.width / 6,
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       Column(
                        //         children: [
                        //           Text(
                        //             'About us',
                        //             style: TextStyle(
                        //               fontSize: 36,
                        //               color: _green,
                        //               fontFamily: 'Raleway',
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //           SizedBox(height: 5),
                        //           Text(
                        //             'Diamond beauty is a company that distributes unique product lines for the beauty and hair care industries.\nOur primary business activity is the distribution and delivery of high-quality medicinal and cosmetic products.',
                        //             //  textAlign: TextAlign.end,
                        //           ),
                        //         ],
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.history,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Mission',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To provide the most up to date technologies and innovation in the medical & Aesthetic field',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.science,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Vision',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To meet the needs of dermatologists and aestheticians and always be on the top of recent advances',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.people,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Goals',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To reach our customers satisfaction and to be able to fulfil the gaps in the market',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Services and activities Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Activities',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Our specializations and locations',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Image(
                        //   image: AssetImage('assets/images/services1.png'),
                        //   fit: BoxFit.cover,
                        // ),
                        // SizedBox(height: 5),
                        // // Project and products Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Products',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We provide products at the highest quality ',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesProj2(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (projectsIndex, context) {
                        //           setState(() {
                        //             _projectCurrent = projectsIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesProj2(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (projectsIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourprojectstitle[_projectCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Partners Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Partners',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We are proud to partner with:',
                        //         //  textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesPartners(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (partnersIndex, context) {
                        //           setState(() {
                        //             _partnerCurrent = partnersIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesPartners(
                        //                             screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (partnersIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourpartnerstitle[_partnerCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Team/Structure Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Team',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Organizational Chart',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Image(
                        //   image: AssetImage('assets/images/team1.png'),
                        //   fit: BoxFit.cover,
                        // ),
                        // SizedBox(height: 5),
                        // // Values Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Values',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'our values = our sustainability',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Stack(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTiles(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (servicesIndex, context) {
                        //           setState(() {
                        //             _serviceCurrent = servicesIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTiles(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (servicesIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     AspectRatio(
                        //       aspectRatio: 18 / 8,
                        //       child: Center(
                        //         child: Text(
                        //           ourservices[_serviceCurrent],
                        //           style: TextStyle(
                        //             fontFamily: 'Montserrat',
                        //             fontSize: screenSize.width / 20,
                        //             fontWeight: FontWeight.bold,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // Contact us Section ______________________
                        Container(
                          padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width / 15,
                            right: MediaQuery.of(context).size.width / 15,
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: _green,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'We will be happy to contact you!',
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _messageController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: 'Message',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your message';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState != null &&
                                      _formKey.currentState!.validate()) {
                                    _sendEmail();
                                  }
                                },
                                child: Text('Send'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // background image
                      Center(
                        child: Container(
                          width: MediaQuery.of(context)
                              .size
                              .width, // Set container width to screen width
                          child: Image(
                            image: AssetImage('assets/background11.png'),
                            fit: BoxFit
                                .cover, // Ensure the image covers the entire container
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            // The main Logo and slogan ____________________
                            SizedBox(height: 100),
                            Image(
                              image: AssetImage("assets/images/lesserlogo.png"),
                              width: MediaQuery.of(context).size.width * 0.30,
                            ),
                            Text(
                              'LESSER',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        // Identity Section ____________________
                        // SizedBox(height: 5),
                        // Padding(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 6,
                        //     right: MediaQuery.of(context).size.width / 6,
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       Column(
                        //         children: [
                        //           Text(
                        //             'About us',
                        //             style: TextStyle(
                        //               fontSize: 36,
                        //               color: _green,
                        //               fontFamily: 'Raleway',
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //           SizedBox(height: 5),
                        //           Text(
                        //             'Diamond beauty is a company that distributes unique product lines for the beauty and hair care industries.\nOur primary business activity is the distribution and delivery of high-quality medicinal and cosmetic products.',
                        //             //  textAlign: TextAlign.end,
                        //           ),
                        //         ],
                        //       ),
                        //       Row(
                        //         children: [
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.history,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Mission',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To provide the most up to date technologies and innovation in the medical & Aesthetic field',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.science,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Vision',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To meet the needs of dermatologists and aestheticians and always be on the top of recent advances',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.people,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Goals',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To reach our customers satisfaction and to be able to fulfil the gaps in the market',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Services and activities Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Activities',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Our specializations and locations',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Container(
                        //   width: MediaQuery.of(context)
                        //       .size
                        //       .width, // Set container width to screen width
                        //   child: Image(
                        //     image: AssetImage('assets/images/services1.png'),
                        //     fit: BoxFit
                        //         .cover, // Ensure the image covers the entire container
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Project and products Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Products',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We provide products at the highest quality ',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesProj2(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (projectsIndex, context) {
                        //           setState(() {
                        //             _projectCurrent = projectsIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesProj2(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (projectsIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourprojectstitle[_projectCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Partners Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Partners',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We are proud to partner with:',
                        //         //  textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesPartners(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (partnersIndex, context) {
                        //           setState(() {
                        //             _partnerCurrent = partnersIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesPartners(
                        //                             screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (partnersIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourpartnerstitle[_partnerCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Team/Structure Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Team',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Organizational Chart',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Container(
                        //   width: MediaQuery.of(context)
                        //       .size
                        //       .width, // Set container width to screen width
                        //   child: Image(
                        //     image: AssetImage('assets/images/team1.png'),
                        //     fit: BoxFit
                        //         .cover, // Ensure the image covers the entire container
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Values Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Values',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'our values = our sustainability',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Stack(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTiles(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (servicesIndex, context) {
                        //           setState(() {
                        //             _serviceCurrent = servicesIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTiles(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (servicesIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     AspectRatio(
                        //       aspectRatio: 18 / 8,
                        //       child: Center(
                        //         child: Text(
                        //           ourservices[_serviceCurrent],
                        //           style: TextStyle(
                        //             fontFamily: 'Montserrat',
                        //             fontSize: screenSize.width / 20,
                        //             fontWeight: FontWeight.bold,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // Contact us Section ______________________
                        Container(
                          padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width / 15,
                            right: MediaQuery.of(context).size.width / 15,
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: _green,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'We will be happy to contact you!',
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 200,
                            right: 200,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Message',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your message';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState != null &&
                                        _formKey.currentState!.validate()) {
                                      _sendEmail();
                                    }
                                  },
                                  child: Text('Send'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  double _opacity = 0;

  // bool? checkBoxValue = false;

  // Services and projects Functions ____

  //  final CarouselController _controller = CarouselController();
  int _serviceCurrent = 0;
  int _projectCurrent = 0;
  int _partnerCurrent = 0;

  Color _green = Color(0xff263F6B);

  final List<String> ourprojectslogo = [
    'assets/images/product1.png',
    'assets/images/product2.png',
    'assets/images/product3.png',
    'assets/images/product4.png',
    'assets/images/product5.png',
  ];

  final List<String> ourprojectstitle = [
    'Abrat Mashahir',
    'LSI SILDERMA',
    'Hestia',
    'White rose',
    'Tranacix'
  ];

  final List<String> ourpartnerslogo = [
    'assets/images/partner1.png',
    'assets/images/partner2.png',
    'assets/images/partner3.png'
  ];

  final List<String> ourpartnerstitle = ['LSI', 'Dr. Oracle', 'GTG Medical'];

  final List<String> _servicesImages = [
    'assets/images/service2.png',
    'assets/images/service3.png',
    'assets/images/service1.png',
  ];

  final List<String> ourservices = [
    'Excellence',
    'Education',
    'Transparency',
  ];

  final List _isHovering = [false, false, false, false, false, false, false];
  final List _isSelected = [true, false, false, false, false, false, false];

  List<Widget> generateImageTiles(screenSize) {
    return _servicesImages
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesProj(screenSize) {
    return ourprojectslogo
        .map(
          (image) => Padding(
            padding: EdgeInsets.only(top: screenSize.height / 50),
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: screenSize.width / 2.4,
                      width: screenSize.width / 1.8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          image,
                          //  fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: screenSize.height / 70,
                      ),
                      child: Text(
                        ourprojectstitle[_projectCurrent],
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: screenSize.width / 15),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesProj2(screenSize) {
    return ourprojectslogo
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List<Widget> generateImageTilesPartners(screenSize) {
    return ourpartnerslogo
        .map(
          (image) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        )
        .toList();
  }

  List isHovering = [false, false, false];

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  // Contact us functions ______________

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _sendEmail() async {
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String message = _messageController.text;

    // Construct the request body
    Map<String, String> formData = {
      'name': name,
      'email': email,
      'message': message,
    };

    // Send POST request to the endpoint
    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/care@lesserapp.com'),
        body: formData,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Show alert after sending
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Message Sent'),
            content: Text('Thank you for your message!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to send message. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      body: width <= 800
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // background image
                      Image(
                        image: AssetImage('assets/background11.png'),
                        fit: BoxFit.cover,
                      ),
                      Center(
                        child: Column(
                          children: [
                            // The main Logo and slogan ____________________
                            SizedBox(height: 50),
                            Image(
                              image: AssetImage("assets/images/lesserlogo.png"),
                              width: MediaQuery.of(context).size.width * 0.30,
                            ),
                            Text(
                              'LESSER',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        // Sign in/up Section __________________
                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width * 0.65,
                        //   child: Container(
                        //     padding: EdgeInsets.all(2),
                        //     decoration: BoxDecoration(
                        //       border: Border.all(color: Colors.black),
                        //       borderRadius: BorderRadius.circular(15),
                        //     ),
                        //     child: StreamBuilder(
                        //       stream: FirebaseAuth.instance.authStateChanges(),
                        //       builder: (ctx, snapshot) {
                        //         // if (snapshot.connectionState ==
                        //         //     ConnectionState.waiting) {
                        //         //   return Text(
                        //         //     'Loading...',
                        //         //     style: TextStyle(fontSize: 15),
                        //         //   );
                        //         // }
                        //         if (snapshot.hasData) {
                        //           return Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             mainAxisAlignment: MainAxisAlignment.start,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.center,
                        //             children: [
                        //               Image(
                        //                 image: AssetImage(nonuser),
                        //                 width:
                        //                     MediaQuery.of(context).size.width *
                        //                         0.30,
                        //               ),
                        //               InkWell(
                        //                   onTap: () {},
                        //                   child: SizedBox(
                        //                       height: 24,
                        //                       child: Image.asset(
                        //                           Appcontent.addpostst))),
                        //               Text(
                        //                 'Welcome! You Logged in!',
                        //                 style: TextStyle(fontSize: 15),
                        //               ),
                        //               SizedBox(height: 8),
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   FirebaseAuth.instance.signOut();
                        //                 },
                        //                 child: Container(
                        //                   alignment: Alignment.center,
                        //                   padding: EdgeInsets.symmetric(
                        //                       vertical: 16),
                        //                   decoration: BoxDecoration(
                        //                     borderRadius: BorderRadius.all(
                        //                         Radius.circular(45)),
                        //                     color: Colors.black,
                        //                   ),
                        //                   child: Text(
                        //                     'Logout',
                        //                     style: TextStyle(
                        //                         color: Colors.white,
                        //                         fontSize: 15),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 4),
                        //             ],
                        //           );
                        //         }
                        //         return Form(
                        //           key: _formKey,
                        //           child: Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             mainAxisAlignment: MainAxisAlignment.start,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.center,
                        //             children: [
                        //               Image(
                        //                 image: AssetImage(nonuser),
                        //                 width:
                        //                     MediaQuery.of(context).size.width *
                        //                         0.30,
                        //               ),
                        //               Text(
                        //                 'SignIn/up Your Account',
                        //                 style: TextStyle(fontSize: 15),
                        //               ),
                        //               SizedBox(height: 20),
                        //               TextFormField(
                        //                 focusNode: f1,
                        //                 onFieldSubmitted: (v) {
                        //                   f1.unfocus();
                        //                   FocusScope.of(context)
                        //                       .requestFocus(f2);
                        //                 },
                        //                 validator: (k) {
                        //                   if (!k!.contains('@')) {
                        //                     return 'Please enter the correct email';
                        //                   }
                        //                   return null;
                        //                 },
                        //                 controller: _emailController,
                        //                 onSaved: (k) {
                        //                   _enteredEmail = k!;
                        //                 },
                        //                 decoration: InputDecoration(
                        //                     prefixIcon:
                        //                         Icon(Icons.mail_rounded),
                        //                     hintText: "Email"),
                        //               ),
                        //               SizedBox(height: 20),
                        //               TextFormField(
                        //                 controller: _passwordController,
                        //                 obscureText: isIconTrue,
                        //                 focusNode: f2,
                        //                 validator: (value) {
                        //                   return Validate.validate(value!);
                        //                 },
                        //                 onFieldSubmitted: (v) {
                        //                   f2.unfocus();
                        //                   if (_formKey.currentState!
                        //                       .validate()) {
                        //                     //
                        //                   }
                        //                 },
                        //                 onSaved: (value) {
                        //                   _enteredPassword = value!;
                        //                 },
                        //                 decoration: InputDecoration(
                        //                   prefixIcon: Icon(Icons.lock),
                        //                   hintText: "Password",
                        //                   suffixIcon: Theme(
                        //                     data: ThemeData(
                        //                         splashColor: Colors.transparent,
                        //                         highlightColor:
                        //                             Colors.transparent),
                        //                     child: IconButton(
                        //                       highlightColor:
                        //                           Colors.transparent,
                        //                       onPressed: () {
                        //                         setState(() {
                        //                           isIconTrue = !isIconTrue;
                        //                         });
                        //                       },
                        //                       icon: Icon(
                        //                         (isIconTrue)
                        //                             ? Icons.visibility_rounded
                        //                             : Icons.visibility_off,
                        //                         size: 16,
                        //                         color: Colors.grey,
                        //                       ),
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 8),
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   if (_formKey.currentState!
                        //                       .validate()) {
                        //                     _submit();
                        //                   }
                        //                 },
                        //                 child: Container(
                        //                   alignment: Alignment.center,
                        //                   padding: EdgeInsets.symmetric(
                        //                       vertical: 16),
                        //                   decoration: BoxDecoration(
                        //                     borderRadius: BorderRadius.all(
                        //                         Radius.circular(45)),
                        //                     color: Colors.black,
                        //                   ),
                        //                   child: Text(
                        //                     _isSignIn ? 'Sign In' : 'Sign Up',
                        //                     style: TextStyle(
                        //                         color: Colors.white,
                        //                         fontSize: 15),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 4),
                        //               Row(
                        //                 children: [
                        //                   Expanded(
                        //                     child: Text(
                        //                       'Sign up',
                        //                       textAlign: TextAlign.center,
                        //                       style: TextStyle(
                        //                           color: Colors.black,
                        //                           fontSize: 15,
                        //                           fontWeight: FontWeight.w600),
                        //                     ),
                        //                   ),
                        //                   SizedBox(width: 2),
                        //                   Switch(
                        //                     value: _isSignIn,
                        //                     onChanged: (value) {
                        //                       setState(() {
                        //                         _isSignIn = value;
                        //                       });
                        //                     },
                        //                   ),
                        //                   SizedBox(width: 2),
                        //                   Expanded(
                        //                     child: Text(
                        //                       'Sign in',
                        //                       textAlign: TextAlign.center,
                        //                       style: TextStyle(
                        //                           color: Colors.black,
                        //                           fontSize: 15,
                        //                           fontWeight: FontWeight.w600),
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //               SizedBox(height: 4),
                        //               TextButton(
                        //                 onPressed: () {},
                        //                 child: Text('Forgot the password ?',
                        //                     style: TextStyle(
                        //                         fontWeight: FontWeight.bold)),
                        //               ),
                        //             ],
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //   ),
                        // ),
                        // Identity Section ____________________
                        // SizedBox(height: 5),
                        // Padding(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 6,
                        //     right: MediaQuery.of(context).size.width / 6,
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       Column(
                        //         children: [
                        //           Text(
                        //             'About us',
                        //             style: TextStyle(
                        //               fontSize: 36,
                        //               color: _green,
                        //               fontFamily: 'Raleway',
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //           SizedBox(height: 5),
                        //           Text(
                        //             'Diamond beauty is a company that distributes unique product lines for the beauty and hair care industries.\nOur primary business activity is the distribution and delivery of high-quality medicinal and cosmetic products.',
                        //             //  textAlign: TextAlign.end,
                        //           ),
                        //         ],
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.history,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Mission',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To provide the most up to date technologies and innovation in the medical & Aesthetic field',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.science,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Vision',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To meet the needs of dermatologists and aestheticians and always be on the top of recent advances',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //       Card(
                        //         elevation: 5,
                        //         child: Padding(
                        //           padding: EdgeInsets.only(
                        //             top:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             bottom:
                        //                 MediaQuery.of(context).size.height / 45,
                        //             left:
                        //                 MediaQuery.of(context).size.height / 40,
                        //             right:
                        //                 MediaQuery.of(context).size.height / 40,
                        //           ),
                        //           child: Column(
                        //             children: [
                        //               Container(
                        //                 height: 50,
                        //                 child: FloatingActionButton(
                        //                   onPressed: () {},
                        //                   backgroundColor: _green,
                        //                   child: Icon(
                        //                     Icons.people,
                        //                     color: Color(0xffffffff),
                        //                   ),
                        //                 ),
                        //               ),
                        //               SizedBox(height: 5),
                        //               Text(
                        //                 'Goals',
                        //                 style: TextStyle(
                        //                     fontSize: 20,
                        //                     color: Color(0xff000000),
                        //                     fontFamily: 'Raleway',
                        //                     fontWeight: FontWeight.bold),
                        //               ),
                        //               SizedBox(
                        //                 height:
                        //                     MediaQuery.of(context).size.height /
                        //                         50,
                        //               ),
                        //               Directionality(
                        //                 textDirection: TextDirection.ltr,
                        //                 child: Text(
                        //                   'To reach our customers satisfaction and to be able to fulfil the gaps in the market',
                        //                   style: TextStyle(
                        //                     color: Colors.blueGrey[900],
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Services and activities Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Activities',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Our specializations and locations',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Image(
                        //   image: AssetImage('assets/images/services1.png'),
                        //   fit: BoxFit.cover,
                        // ),
                        // SizedBox(height: 5),
                        // // Project and products Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Products',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We provide products at the highest quality ',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesProj2(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (projectsIndex, context) {
                        //           setState(() {
                        //             _projectCurrent = projectsIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesProj2(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (projectsIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourprojectstitle[_projectCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Partners Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Partners',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We are proud to partner with:',
                        //         //  textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesPartners(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (partnersIndex, context) {
                        //           setState(() {
                        //             _partnerCurrent = partnersIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesPartners(
                        //                             screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (partnersIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourpartnerstitle[_partnerCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Team/Structure Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Team',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Organizational Chart',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Image(
                        //   image: AssetImage('assets/images/team1.png'),
                        //   fit: BoxFit.cover,
                        // ),
                        // SizedBox(height: 5),
                        // // Values Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Values',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'our values = our sustainability',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Stack(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTiles(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (servicesIndex, context) {
                        //           setState(() {
                        //             _serviceCurrent = servicesIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTiles(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (servicesIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     AspectRatio(
                        //       aspectRatio: 18 / 8,
                        //       child: Center(
                        //         child: Text(
                        //           ourservices[_serviceCurrent],
                        //           style: TextStyle(
                        //             fontFamily: 'Montserrat',
                        //             fontSize: screenSize.width / 20,
                        //             fontWeight: FontWeight.bold,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // Contact us Section ______________________
                        Container(
                          padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width / 15,
                            right: MediaQuery.of(context).size.width / 15,
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: _green,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'We will be happy to contact you!',
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _messageController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: 'Message',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your message';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState != null &&
                                      _formKey.currentState!.validate()) {
                                    _sendEmail();
                                  }
                                },
                                child: Text('Send'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // background image
                      Center(
                        child: Container(
                          width: MediaQuery.of(context)
                              .size
                              .width, // Set container width to screen width
                          child: Image(
                            image: AssetImage('assets/background11.png'),
                            fit: BoxFit
                                .cover, // Ensure the image covers the entire container
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            // The main Logo and slogan ____________________
                            SizedBox(height: 100),
                            Image(
                              image: AssetImage("assets/images/lesserlogo.png"),
                              width: MediaQuery.of(context).size.width * 0.30,
                            ),
                            Text(
                              'LESSER',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        // Identity Section ____________________
                        // SizedBox(height: 5),
                        // Padding(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 6,
                        //     right: MediaQuery.of(context).size.width / 6,
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       Column(
                        //         children: [
                        //           Text(
                        //             'About us',
                        //             style: TextStyle(
                        //               fontSize: 36,
                        //               color: _green,
                        //               fontFamily: 'Raleway',
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //           SizedBox(height: 5),
                        //           Text(
                        //             'Diamond beauty is a company that distributes unique product lines for the beauty and hair care industries.\nOur primary business activity is the distribution and delivery of high-quality medicinal and cosmetic products.',
                        //             //  textAlign: TextAlign.end,
                        //           ),
                        //         ],
                        //       ),
                        //       Row(
                        //         children: [
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.history,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Mission',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To provide the most up to date technologies and innovation in the medical & Aesthetic field',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.science,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Vision',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To meet the needs of dermatologists and aestheticians and always be on the top of recent advances',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //           Expanded(
                        //             child: Card(
                        //               elevation: 5,
                        //               child: Padding(
                        //                 padding: EdgeInsets.only(
                        //                   top: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   bottom: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       45,
                        //                   left: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                   right: MediaQuery.of(context)
                        //                           .size
                        //                           .height /
                        //                       40,
                        //                 ),
                        //                 child: Column(
                        //                   children: [
                        //                     Container(
                        //                       height: 50,
                        //                       child: FloatingActionButton(
                        //                         onPressed: () {},
                        //                         backgroundColor: _green,
                        //                         child: Icon(
                        //                           Icons.people,
                        //                           color: Color(0xffffffff),
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     SizedBox(height: 5),
                        //                     Text(
                        //                       'Goals',
                        //                       style: TextStyle(
                        //                           fontSize: 20,
                        //                           color: Color(0xff000000),
                        //                           fontFamily: 'Raleway',
                        //                           fontWeight: FontWeight.bold),
                        //                     ),
                        //                     SizedBox(
                        //                       height: MediaQuery.of(context)
                        //                               .size
                        //                               .height /
                        //                           50,
                        //                     ),
                        //                     Directionality(
                        //                       textDirection: TextDirection.ltr,
                        //                       child: Text(
                        //                         'To reach our customers satisfaction and to be able to fulfil the gaps in the market',
                        //                         style: TextStyle(
                        //                           color: Colors.blueGrey[900],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Services and activities Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Activities',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Our specializations and locations',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Container(
                        //   width: MediaQuery.of(context)
                        //       .size
                        //       .width, // Set container width to screen width
                        //   child: Image(
                        //     image: AssetImage('assets/images/services1.png'),
                        //     fit: BoxFit
                        //         .cover, // Ensure the image covers the entire container
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Project and products Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Products',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We provide products at the highest quality ',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesProj2(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (projectsIndex, context) {
                        //           setState(() {
                        //             _projectCurrent = projectsIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesProj2(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (projectsIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourprojectstitle[_projectCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Partners Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Partners',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'We are proud to partner with:',
                        //         //  textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTilesPartners(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (partnersIndex, context) {
                        //           setState(() {
                        //             _partnerCurrent = partnersIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTilesPartners(
                        //                             screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (partnersIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     SizedBox(height: 10),
                        //     Center(
                        //       child: Text(
                        //         ourpartnerstitle[_partnerCurrent],
                        //         style: TextStyle(
                        //           fontFamily: 'Montserrat',
                        //           fontSize: screenSize.width / 20,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.black,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // // Team/Structure Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Team',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'Organizational Chart',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Container(
                        //   width: MediaQuery.of(context)
                        //       .size
                        //       .width, // Set container width to screen width
                        //   child: Image(
                        //     image: AssetImage('assets/images/team1.png'),
                        //     fit: BoxFit
                        //         .cover, // Ensure the image covers the entire container
                        //   ),
                        // ),
                        // SizedBox(height: 5),
                        // // Values Section ______________________
                        // Container(
                        //   padding: EdgeInsets.only(
                        //     left: MediaQuery.of(context).size.width / 15,
                        //     right: MediaQuery.of(context).size.width / 15,
                        //   ),
                        //   width: MediaQuery.of(context).size.width,
                        //   child: Column(
                        //     children: [
                        //       Text(
                        //         'Values',
                        //         style: TextStyle(
                        //           fontSize: 36,
                        //           color: _green,
                        //           fontFamily: 'Raleway',
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //       SizedBox(height: 5),
                        //       Text(
                        //         'our values = our sustainability',
                        //         textAlign: TextAlign.end,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // Stack(
                        //   children: [
                        //     CarouselSlider(
                        //       items: generateImageTiles(screenSize),
                        //       carouselController: _controller,
                        //       options: CarouselOptions(
                        //         enlargeCenterPage: true,
                        //         aspectRatio: 18 / 8,
                        //         autoPlay: true,
                        //         onPageChanged: (servicesIndex, context) {
                        //           setState(() {
                        //             _serviceCurrent = servicesIndex;
                        //             for (int i = 0;
                        //                 i <
                        //                     generateImageTiles(screenSize)
                        //                         .length;
                        //                 i++) {
                        //               if (servicesIndex == i) {
                        //                 _isSelected[i] = true;
                        //               } else {
                        //                 _isSelected[i] = false;
                        //               }
                        //             }
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     AspectRatio(
                        //       aspectRatio: 18 / 8,
                        //       child: Center(
                        //         child: Text(
                        //           ourservices[_serviceCurrent],
                        //           style: TextStyle(
                        //             fontFamily: 'Montserrat',
                        //             fontSize: screenSize.width / 20,
                        //             fontWeight: FontWeight.bold,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 5),
                        // Contact us Section ______________________
                        Container(
                          padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width / 15,
                            right: MediaQuery.of(context).size.width / 15,
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: _green,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'We will be happy to contact you!',
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 200,
                            right: 200,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Message',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your message';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState != null &&
                                        _formKey.currentState!.validate()) {
                                      _sendEmail();
                                    }
                                  },
                                  child: Text('Send'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ________________________________________________
// EnvPage Section || Widget 1
// ________________________________________________

class EnvPageWidget extends StatefulWidget {
  const EnvPageWidget({Key? key}) : super(key: key);

  @override
  State<EnvPageWidget> createState() => _EnvPageWidgetState();
}

class _EnvPageWidgetState extends State<EnvPageWidget> {
  // List<String> list = <String>['All', 'Home', 'Street', 'Store', 'Space'];

  @override
  void initState() {
    super.initState();
    _addCurrentLocationMarker();
    _initMarkers();
    _loadLocationsFromFirestore();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // Maps, locations and logistics functions and vars ____________________

  LatLng _center =
      LatLng(24.710574024024353, 46.67343704478749); // Initial center
  Marker? _centerMarker; // Marker that stays at the center

  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  LatLng? _currentLocation; // For tracking current location
  Marker? _tempMarker; // Temporary marker for the location to be added
  bool _addingLocation = false; // Toggle when in add location mode

  TabController? tabController;
  PageController pageController1 = PageController(viewportFraction: 1);

  final Set<Marker> _markers = {};
  final Set<Marker> _dropOffMarkers = {};
  List<String> list = <String>[
    //  'Current Location',
    'Add Location',
  ];

  Future<Position> _determinePosition() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _addCurrentLocationMarker() async {
    Position position = await _determinePosition();
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    final int markerSize = kIsWeb ? 32 : 100;

    // BitmapDescriptor markerIcon = await _createCustomMarkerImage(
    //  'assets/images/urhere1.png',
    // size: markerSize);

    // setState(() {
    // _markers.add(
    //   Marker(
    //     markerId: MarkerId('current_location'),
    //     position: currentLocation,
    //     icon: markerIcon,
    //     consumeTapEvents: true,
    //     onTap: () {
    //       showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //           title: Text('Current Location'),
    //           content: Text('You are here'),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.pop(context),
    //               child: Text('OK'),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   ),
    // );

    // _dropOffMarkers.add(
    // Marker(
    // markerId: MarkerId('current_location'),
    // position: currentLocation,
    // icon: markerIcon,
    // consumeTapEvents: true,
    // onTap: () {
    // showDialog(
    // context: context,
    // builder: (_) => AlertDialog(
    // title: Text('Current Location'),
    // content: Text('You are here'),
    // actions: [
    //              TextButton(
    // onPressed: () => Navigator.pop(context),
    // child: Text('OK'),
    // ),
    // ],
    // ),
    // );
    // },
    // ),
    // );
    // });
  }

  void _loadLocationsFromFirestore() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .get();

    // Extract the saved locations
    List<String> savedLocations =
        snapshot.docs.map((doc) => doc['name'].toString()).toList();

    Set<Marker> newMarkers = {};

    // Iterate over each saved location and create markers
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      LatLng position = LatLng(data['latitude'], data['longitude']);
      String locationName = data['name'];

      Marker locationMarker = Marker(
        markerId: MarkerId(locationName),
        position: position,
        consumeTapEvents: true,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(locationName),
              content: Text('This is a saved location.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
      );

      newMarkers.add(locationMarker);
    }

    setState(() {
      // Update the list for the dropdown
      list = ['Current Location', 'Add Location', ...savedLocations];

      // Update the markers set to include both new and existing markers
      _markers.addAll(newMarkers);
    });
  }

  Future<void> _initMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .where('type', isEqualTo: 'dropoff')
        .get();

    final int markerSize = kIsWeb ? 32 : 100;

    BitmapDescriptor markerIcon1 = await _createCustomMarkerImage(
        'assets/images/3drvm.png',
        size: markerSize);

    final markers = snapshot.docs.map((doc) {
      final data = doc.data();
      final name = data['name'];
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(latitude, longitude),
        icon: markerIcon1,
        consumeTapEvents: true,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(name),
              content: Text('Open this location in Google Maps?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open Google Maps.')),
                      );
                    }
                  },
                  child: Text('Open'),
                ),
              ],
            ),
          );
        },
      );
    }).toSet();

    setState(() {
      _dropOffMarkers.clear();
      _dropOffMarkers.addAll(markers);
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerImage(String assetPath,
      {int size = 64}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List imageData = data.buffer.asUint8List();

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: size,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      final ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

      return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Error decoding image for marker: $e");
      }
      // fallback for web if needed
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Functions and product area vars ____________________

  String dropdownValue = 'All Offers'; // Default dropdown value
  String searchText = ''; // Text for search bar
  final TextEditingController searchControllerOfProducts =
      TextEditingController();
  String sortBy = 'Date'; // Default sorting option
  String filterCategory = ''; // Default category (empty means no filter)

  void _showFilterDialogOfProducts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Local state for filter options
            String selectedSort = 'Date'; // Default sort option
            String selectedCategory = ''; // Selected category
            List<String> categories = []; // Categories fetched dynamically

            // Fetch categories dynamically (Example)
            if (categories.isEmpty) {
              FirebaseFirestore.instance
                  .collection('posts')
                  .get()
                  .then((querySnapshot) {
                final uniqueCategories = querySnapshot.docs
                    .map((doc) => doc['category'] as String?)
                    .where(
                        (category) => category != null && category.isNotEmpty)
                    .toSet()
                    .toList();
                setState(() {
                  //  categories = uniqueCategories;
                });
              });
            }

            return AlertDialog(
              title: Text('Filter Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Filter
                  Text('Sort By:'),
                  DropdownButton<String>(
                    value: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                    items: ['Date', 'Price', 'Most Liked'].map((sortOption) {
                      return DropdownMenuItem<String>(
                        value: sortOption,
                        child: Text(sortOption),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  Text('Category:'),
                  DropdownButton<String>(
                    value:
                        selectedCategory.isNotEmpty ? selectedCategory : null,
                    hint: Text('Select a Category'),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog without applying
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Apply filters
                    setState(() {
                      // Store the selected sort and category for filtering
                      sortBy = selectedSort;
                      filterCategory = selectedCategory;
                    });
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void toggleProductLike(String productId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userLikesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('productLikes')
        .doc(productId);

    final productRef =
        FirebaseFirestore.instance.collection('products').doc(productId);

    final isLiked = (await userLikesRef.get()).exists;

    if (isLiked) {
      // Remove the like
      await userLikesRef.delete();
      await productRef.update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      // Add the like
      await userLikesRef.set({'likedAt': Timestamp.now()});
      await productRef.update({
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> _addProductOrLocation() async {
    // Show the alert dialog with fields for product name, price, and images
    final productNameController = TextEditingController();
    final priceController = TextEditingController();
    final productDiscController = TextEditingController();
    final productImages = <String>[]; // List to store product image URLs

    // Use the latest file_picker version
    final filePicker = await FilePicker.platform;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Product/Location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: productNameController,
                      decoration:
                          const InputDecoration(hintText: 'Product Name'),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Price'),
                    ),
                    TextField(
                      controller: productDiscController,
                      decoration: const InputDecoration(
                          hintText: 'Product Description'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () async {
                        final result = await filePicker.pickFiles(
                          allowMultiple: true,
                          type: FileType.image,
                        );
                        if (result != null) {
                          for (final pickedFile in result.files) {
                            final file = kIsWeb
                                ? File.fromRawPath(pickedFile.bytes!)
                                : File(pickedFile.path!);

                            String contentType;
                            if (!kIsWeb) {
                              if (pickedFile.path!
                                      .toLowerCase()
                                      .endsWith('.jpg') ||
                                  pickedFile.path!
                                      .toLowerCase()
                                      .endsWith('.jpeg')) {
                                contentType = 'image/jpeg';
                              } else if (pickedFile.path!
                                  .toLowerCase()
                                  .endsWith('.png')) {
                                contentType = 'image/png';
                              } else {
                                contentType = 'application/octet-stream';
                              }
                            } else {
                              final bytes = pickedFile.bytes!;
                              if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
                                contentType = 'image/jpeg';
                              } else if (bytes[0] == 0x89 && bytes[1] == 0x50) {
                                contentType = 'image/png';
                              } else {
                                contentType = 'application/octet-stream';
                              }
                            }

                            final imageRef = FirebaseStorage.instance.ref().child(
                                'product_images/${DateTime.now().millisecondsSinceEpoch}.png');
                            final uploadTask = kIsWeb
                                ? imageRef.putData(
                                    pickedFile.bytes!,
                                    SettableMetadata(contentType: contentType),
                                  )
                                : imageRef.putFile(
                                    file,
                                    SettableMetadata(contentType: contentType),
                                  );

                            final url =
                                await (await uploadTask).ref.getDownloadURL();

                            productImages.add(url);
                            setState(() {});
                          }
                        }
                      },
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: productImages.length,
                      itemBuilder: (context, index) {
                        final imageUrl = productImages[index];
                        return Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              height: 50,
                              width: 50,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    productImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  color: Colors.red,
                                  child: Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Send the product data to Firestore
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add({
                      'productName': productNameController.text,
                      'price': double.parse(priceController.text),
                      'productDisc': productDiscController.text,
                      'productImages': productImages,
                      'userId': FirebaseAuth.instance.currentUser!.uid,
                      'userEmail':
                          FirebaseAuth.instance.currentUser!.email.toString(),
                      'timeStamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please Sign In or Sign Up'),
        content: const Text('You need to be signed in to perform this action.'),
      ),
    );
  }

  void _payNow(
      String receiverUid, String documentId, Map<String, dynamic> data) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    try {
      // Fetch user role directly from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      String userRole = userDoc['role'] ?? '';

      if (userRole != 'driver') {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show access denied dialog if the user is not a driver
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Access Denied'),
            content: Text('Only drivers can confirm orders.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Build the billRoomId dynamically based on the admin and receiver UIDs
      List<String> ids = [
        receiverUid,
        '7DHsNu3hGYfEiKA0CCKezD6VQ0N2' // Assuming '7DHsNu3hGYfEiKA0CCKezD6VQ0N2' is the admin UID
      ];
      ids.sort();
      String billRoomId = ids.join("_");

      // Update order and receiver's points
      await FirebaseFirestore.instance
          .collection('bill_rooms')
          .doc(billRoomId)
          .collection('bills')
          .doc(documentId)
          .update({
        'completed': true,
        'status': FieldValue.arrayUnion([
          {
            'statustext': 'Order Confirmed',
            'statustime': Timestamp.now(),
          },
        ]),
      });

      int points = data['bill'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverUid)
          .update({
        'points': FieldValue.increment(points),
      });

      // Close loading dialog before showing success
      Navigator.of(context).pop();

      // Show success confirmation dialog after updates
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Confirmed'),
          content: Text('Order confirmed and points transferred!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog if something goes wrong
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to confirm order. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _buyProduct(String productId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    print("Button pressed. Starting _buyProduct for productId: $productId");

    // 1. Get product details
    Map<String, dynamic>? productData;
    try {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      // Check if product exists before accessing data
      if (productSnapshot.exists) {
        productData = productSnapshot.data() as Map<String, dynamic>;
        print("Product data retrieved: $productData");

        if (productData == null) {
          // Handle product not found error
          print("Product data is null");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        // Extract relevant product details (assuming fields exist)
        int price = productData['price'] ?? 0; // Handle missing field
        List<dynamic>? stockDynamic =
            productData['stock'] as List<dynamic>?; // Handle missing field

        // Ensure stock is a List<String>
        List<String> stock =
            stockDynamic != null ? List<String>.from(stockDynamic) : [];

        // Extract seller ID from product data
        String sellerId = productData['userId'] ?? ''; // Handle missing field

        print("Product price: $price, stock: $stock, sellerId: $sellerId");

        // 2. Get user details (replace with your logic to retrieve user ID)
        String userId = FirebaseAuth.instance.currentUser!.uid;
        print("User ID: $userId");

        DocumentSnapshot userSnapshot;
        try {
          print("Attempting to retrieve user data...");
          userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          print("User data retrieved: ${userSnapshot.data()}");
        } catch (e) {
          print("Error getting user details: $e");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        // Check if user exists before accessing data
        if (!userSnapshot.exists) {
          // Handle user not found error (unlikely, but good practice)
          print("User not found");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Extract user points (assuming field exists)
        int userPoints = userData['points'] ?? 0; // Handle missing field
        print("User points: $userPoints");

        // 3. Perform security checks and data validation
        if (userPoints < price) {
          // Handle insufficient points error (show a dialog)
          print("Insufficient points");
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Insufficient Points'),
                content: const Text(
                    'You don\'t have enough points to purchase this product.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Exit the function if points are insufficient
        }

        if (stock.isEmpty) {
          // Handle out-of-stock error (show a dialog)
          print("Out of stock");
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Out of Stock'),
                content: const Text('This product is currently out of stock.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Exit the function if product is out of stock
        }

        // 4. Update user and seller points within a transaction
        print("Starting transaction to update points");
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            print("Transaction: Getting user and seller references");
            DocumentReference userRef =
                FirebaseFirestore.instance.collection('users').doc(userId);
            DocumentReference sellerRef =
                FirebaseFirestore.instance.collection('users').doc(sellerId);

            // Read both user and seller documents first
            DocumentSnapshot userSnapshot = await transaction.get(userRef);
            DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);

            // Check if documents exist
            if (!userSnapshot.exists) {
              throw Exception("User document does not exist in transaction");
            }
            if (!sellerSnapshot.exists) {
              throw Exception("Seller document does not exist in transaction");
            }

            // Update user points
            Map<String, dynamic> updatedUserData =
                userSnapshot.data()! as Map<String, dynamic>;
            updatedUserData['points'] = userPoints - price;
            print("Transaction: Updating user points");
            transaction.update(userRef, updatedUserData);

            // Update seller points
            Map<String, dynamic> updatedSellerData =
                sellerSnapshot.data()! as Map<String, dynamic>;
            updatedSellerData['points'] =
                (updatedSellerData['points'] ?? 0) + price;
            print("Transaction: Updating seller points");
            transaction.update(sellerRef, updatedSellerData);
          });
          print("Transaction to update points completed");

          // 5. Capture stock item (without removing from stock)
          String stockItem =
              stock.first; // Get the first element (without removing)
          print("Stock item captured: $stockItem");

          // 6. Build and store bill room data
          List<String> ids = [sellerId, userId];
          ids.sort();
          String billRoomId = ids.join("_");
          print("Bill room ID: $billRoomId");

          CollectionReference billCollectionRef = FirebaseFirestore.instance
              .collection('bill_rooms')
              .doc(billRoomId)
              .collection('bills');
          DocumentReference billDocRef =
              billCollectionRef.doc(); // Generate a new document ID

          // Consider using a dedicated model class for bill data if needed for clarity and consistency
          Map<String, dynamic> newBillData = {
            'completed': true, // Adjust as needed
            'sending': true, // Adjust as needed
            'senderId': userId,
            'senderEmail': FirebaseAuth.instance.currentUser!.email
                .toString(), // Replace with your logic
            'receiverId': sellerId,
            'bill': price, // Use retrieved product price
            'message':
                '${productData['productName']}\n(Stock/Code Item: $stockItem)', // Update message with stock item
            'status': [], // Handle potential absence of 'status'
            'timestamp': FieldValue.serverTimestamp(),
          };

          await billDocRef.set(newBillData);
          print("Bill room data stored");

          // 7. Update product stock (uncommented)
          print("Starting transaction to update product stock");
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentReference productRef = FirebaseFirestore.instance
                .collection('products')
                .doc(productId);
            DocumentSnapshot productSnapshot =
                await transaction.get(productRef);
            if (!productSnapshot.exists) {
              throw Exception("Product document does not exist in transaction");
            }
            Map<String, dynamic> updatedProductData =
                productSnapshot.data()! as Map<String, dynamic>;
            List<String> remainingStock = List.from(stock); // Create a copy
            remainingStock
                .removeAt(0); // Remove the first element (purchased item)
            updatedProductData['stock'] =
                remainingStock; // Update stock with the modified list
            print("Transaction: Updating product stock");
            transaction.update(productRef, updatedProductData);
          });
          print("Product stock updated");

          // 8. Handle purchase success (optional: show confirmation message)
          print('Product purchased successfully!');
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Purchased successfully!'),
                content: const Text(
                    'Check the wallet transaction to view your purchase.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } catch (e, stackTrace) {
          print("Transaction failed: ${e.toString()}");
          print(stackTrace.toString());
          Navigator.of(context).pop(); // Close the loading dialog
        }
      } else {
        // Handle product not found error (e.g., show a dialog)
        print("Product not found");
        Navigator.of(context).pop(); // Close the loading dialog
        return;
      }
    } catch (e) {
      // Handle product not found error
      print("Error getting product details: $e");
      Navigator.of(context).pop(); // Close the loading dialog
      return;
    }
  }

  Widget _pageBody() {
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // Invoices, Billing and Carts __________________
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Navigate to Wallet Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WalletScreen(),
                                ),
                              );
                            } else {
                              // User is not signed in, show a dialog
                              _notSignedIn();
                            }
                          },
                          style: ApplicationButtons.button2(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: Colors.black,
                                    ),
                                  ),
                                  StreamBuilder<User?>(
                                    stream: FirebaseAuth.instance
                                        .authStateChanges(),
                                    builder: (context, authSnapshot) {
                                      if (authSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(); // Avoid errors during loading
                                      }

                                      if (!authSnapshot.hasData ||
                                          authSnapshot.data == null) {
                                        return const SizedBox(); // No unread indicator if not logged in
                                      }

                                      String currentUserId =
                                          authSnapshot.data!.uid;

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('bill_rooms')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return const SizedBox();
                                          }

                                          // Check if there are unread bills
                                          bool hasUnread =
                                              snapshot.data!.docs.any((doc) {
                                            Map<String, dynamic> data = doc
                                                .data() as Map<String, dynamic>;

                                            if (!data.containsKey(
                                                'lastReadTimestamps'))
                                              return false;
                                            if (!data['lastReadTimestamps']
                                                .containsKey(currentUserId))
                                              return false;

                                            Timestamp? lastReadTimestamp =
                                                data['lastReadTimestamps']
                                                    [currentUserId];
                                            Timestamp? lastBillTimestamp =
                                                data['lastBillTimestamp'];

                                            if (lastBillTimestamp == null ||
                                                lastReadTimestamp == null)
                                              return false;

                                            return lastBillTimestamp
                                                .toDate()
                                                .isAfter(
                                                    lastReadTimestamp.toDate());
                                          });

                                          return hasUnread
                                              ? Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    height: 10,
                                                    width: 10,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(width: 4.toDouble()),
                              Text('Wallet transaction',
                                  style: primaryTextStyle(color: black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Locations, Spaces and Sites _____________________
            Padding(
              padding: const EdgeInsets.all(ApplicationSpacing.large),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      'Choose recycling method',
                      style: AppTypo.heading2.copyWith(
                        color: AppTextColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Pickup Option
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PickupMap()),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      color: ApplicationColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.xLarge),
                            child: Center(
                              child: Image.asset(
                                'assets/images/pickup.png',
                                height: 140, // controls image size only
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.medium),
                            child: Text(
                              'Pick up',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: AppTextColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Dropoff Option
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  'Drop off Map',
                                  style: AppTypo.heading3.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                                backgroundColor: ApplicationColors.surface,
                              ),
                              body: Stack(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: GoogleMap(
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled:
                                            true, // default recenter button
                                        initialCameraPosition: CameraPosition(
                                          target:
                                              _center, // Start at initial location
                                          zoom: 4,
                                        ),
                                        markers: _dropOffMarkers.union(
                                          _centerMarker != null &&
                                                  _addingLocation
                                              ? {_centerMarker!}
                                              : {},
                                        ),
                                        // onCameraMove:
                                        //     _onCameraMove, // Update marker as the map moves
                                        onMapCreated:
                                            (GoogleMapController controller) {
                                          if (!_mapController.isCompleted) {
                                            _mapController.complete(controller);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top:
                                        10.0, // Adjust this to move the AppButton vertically
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              showGeneralDialog(
                                                context: context,
                                                barrierLabel:
                                                    "Drop Off Instructions",
                                                barrierDismissible:
                                                    false, // Prevent accidental dismiss
                                                barrierColor:
                                                    Colors.black.withAlpha(20),
                                                pageBuilder:
                                                    (context, anim1, anim2) {
                                                  return Center(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.9,
                                                        constraints:
                                                            BoxConstraints(
                                                          maxHeight:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.8,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              ApplicationColors
                                                                  .surface,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Column(
                                                            children: [
                                                              // Image
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          20),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          20),
                                                                ),
                                                                child:
                                                                    Image.asset(
                                                                  'assets/images/dropoff_instructions.png', // Replace with your image path
                                                                  height: 150,
                                                                  width: double
                                                                      .infinity,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              // Title
                                                              Text(
                                                                  'Drop off instructions',
                                                                  style: AppTypo
                                                                      .heading3
                                                                      .copyWith(
                                                                          color:
                                                                              Colors.teal)),
                                                              const SizedBox(
                                                                  height: 16),
                                                              // Instructions
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        ApplicationSpacing
                                                                            .large),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      '1. Find the nearest Recycling Station on the map.',
                                                                      style: AppTypo
                                                                          .body
                                                                          .copyWith(
                                                                              color: AppTextColors.primary),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      '2. Collect clean and empty plastic bottles and cans.',
                                                                      style: AppTypo
                                                                          .body
                                                                          .copyWith(
                                                                              color: AppTextColors.primary),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      '3. Scan your QR code shown on Lesser app using the RVM QR code reader.',
                                                                      style: AppTypo
                                                                          .body
                                                                          .copyWith(
                                                                              color: AppTextColors.primary),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      '4. Insert empty bottles or cans one by one.',
                                                                      style: AppTypo
                                                                          .body
                                                                          .copyWith(
                                                                              color: AppTextColors.primary),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      '5. Enjoy your Points and let’s see you again!',
                                                                      style: AppTypo
                                                                          .body
                                                                          .copyWith(
                                                                              color: AppTextColors.primary),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              // Buttons
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      ApplicationSpacing
                                                                          .large,
                                                                  vertical:
                                                                      ApplicationSpacing
                                                                          .medium,
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          'Dismiss'),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          'Understood'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ApplicationButtons.button2(),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 24,
                                                  child: Icon(
                                                    Icons.help,
                                                    color: ApplicationColors
                                                        .primary,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Text('How to drop off?',
                                                    style: AppTypo.body.copyWith(
                                                        color: ApplicationColors
                                                            .primary)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      color: ApplicationColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.xLarge),
                            child: Center(
                              child: Image.asset(
                                'assets/images/dropoff.png',
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.medium),
                            child: Text(
                              'Drop off',
                              textAlign: TextAlign.center,
                              style: AppTypo.heading3.copyWith(
                                color: ApplicationColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            // Products Area & adding products/locations ____________
            // Column(
            //   children: [
            //     // Dropdown Menu
            //     Padding(
            //       padding: const EdgeInsets.symmetric(
            //           horizontal: 16, vertical: 8),
            //       child: DropdownButton<String>(
            //         value: dropdownValue,
            //         isExpanded: true,
            //         onChanged: (String? newValue) {
            //           setState(() {
            //             dropdownValue = newValue!;
            //           });
            //         },
            //         items: <String>['All Offers', 'Likes']
            //             .map<DropdownMenuItem<String>>((String value) {
            //           return DropdownMenuItem<String>(
            //             value: value,
            //             child: Text(value),
            //           );
            //         }).toList(),
            //       ),
            //     ),
            //     // Search Bar
            //     Padding(
            //       padding: const EdgeInsets.symmetric(
            //           horizontal: 16, vertical: 4),
            //       child: TextField(
            //         controller: searchControllerOfProducts,
            //         decoration: InputDecoration(
            //           labelText: 'Search',
            //           prefixIcon: Icon(Icons.search),
            //           suffixIcon: IconButton(
            //             icon: Icon(Icons.filter_list),
            //             onPressed: () {
            //               _showFilterDialogOfProducts(context);
            //             },
            //           ),
            //           border: OutlineInputBorder(),
            //         ),
            //         onChanged: (value) {
            //           setState(() {
            //             searchText = value
            //                 .trim()
            //                 .toLowerCase(); // Normalize the search query
            //           });
            //         },
            //       ),
            //     ),
            //     // Products List
            //     StreamBuilder<QuerySnapshot>(
            //       stream: dropdownValue == 'Likes'
            //           ? FirebaseFirestore.instance
            //               .collection('users')
            //               .doc(FirebaseAuth.instance.currentUser?.uid)
            //               .collection('productLikes')
            //               .snapshots()
            //           : FirebaseFirestore.instance
            //               .collection('products')
            //               .orderBy('timeStamp', descending: true)
            //               .snapshots(),
            //       builder: (context, snapshot) {
            //         if (snapshot.connectionState ==
            //             ConnectionState.waiting) {
            //           return Center(child: CircularProgressIndicator());
            //         }
            //         if (!snapshot.hasData ||
            //             snapshot.data!.docs.isEmpty) {
            //           return Center(
            //             child: Text(
            //               dropdownValue == 'All Offers'
            //                   ? "No products yet..."
            //                   : "No liked products yet...",
            //               style: TextStyle(color: Colors.grey),
            //             ),
            //           );
            //         }

            //         // Fetch product data
            //         final products = dropdownValue == 'Likes'
            //             ? snapshot.data!.docs
            //                 .map((doc) => doc.id)
            //                 .toList()
            //             : snapshot.data!.docs;

            //         return ListView.builder(
            //           shrinkWrap: true,
            //           physics: NeverScrollableScrollPhysics(),
            //           itemCount: products.length,
            //           itemBuilder: (context, index) {
            //             final Future<DocumentSnapshot<Object?>>
            //                 productFuture = dropdownValue == 'Likes'
            //                     ? FirebaseFirestore.instance
            //                         .collection('products')
            //                         .doc(products[index] as String)
            //                         .get()
            //                     : Future.value(products[index]
            //                         as DocumentSnapshot<Object?>);

            //             return FutureBuilder<DocumentSnapshot<Object?>>(
            //               future: productFuture,
            //               builder: (context, productSnapshot) {
            //                 if (!productSnapshot.hasData ||
            //                     !productSnapshot.data!.exists) {
            //                   return SizedBox(); // Product not found
            //                 }

            //                 final productData = productSnapshot.data!;
            //                 final productId = productData.id;

            //                 return GestureDetector(
            //                   onTap: () {
            //                     Navigator.pushNamed(
            //                         context, '/products/$productId');
            //                   },
            //                   child: Column(
            //                     children: [
            //                       const SizedBox(height: 10),
            //                       Container(
            //                         alignment: Alignment.topCenter,
            //                         width: MediaQuery.of(context)
            //                             .size
            //                             .width,
            //                         decoration: BoxDecoration(
            //                           color: Colors.white,
            //                           borderRadius:
            //                               BorderRadius.circular(15),
            //                         ),
            //                         child: Row(
            //                           crossAxisAlignment:
            //                               CrossAxisAlignment.start,
            //                           children: [
            //                             Container(
            //                               padding: EdgeInsets.all(10),
            //                               decoration: BoxDecoration(
            //                                 color:
            //                                     primaryColor.shade300,
            //                                 borderRadius:
            //                                     BorderRadius.circular(
            //                                         15),
            //                               ),
            //                               child: Image.network(
            //                                 productData['productImages']
            //                                     [0],
            //                                 height: 140,
            //                                 width:
            //                                     MediaQuery.of(context)
            //                                             .size
            //                                             .width /
            //                                         2.2,
            //                               ),
            //                             ),
            //                             Expanded(
            //                               child: Column(
            //                                 crossAxisAlignment:
            //                                     CrossAxisAlignment
            //                                         .center,
            //                                 children: [
            //                                   // Product Name _______
            //                                   SizedBox(height: 10),
            //                                   Text(
            //                                     productData[
            //                                         'productName'],
            //                                     style: boldTextStyle(),
            //                                     overflow: TextOverflow
            //                                         .ellipsis,
            //                                     maxLines: 2,
            //                                   ).paddingOnly(left: 8),
            //                                   SizedBox(height: 10),
            //                                   // Product price ______
            //                                   Text(
            //                                     "${productData['price']} Point",
            //                                     style: boldTextStyle(),
            //                                   ).paddingOnly(left: 8),
            //                                   SizedBox(height: 8),
            //                                   // Product Engaging Section ______
            //                                   Row(
            //                                     children: [
            //                                       const SizedBox(
            //                                           width: 20),
            //                                       // Like Button
            //                                       StreamBuilder<
            //                                           DocumentSnapshot>(
            //                                         stream: FirebaseFirestore
            //                                             .instance
            //                                             .collection(
            //                                                 'users')
            //                                             .doc(FirebaseAuth
            //                                                 .instance
            //                                                 .currentUser
            //                                                 ?.uid)
            //                                             .collection(
            //                                                 'productLikes')
            //                                             .doc(productId)
            //                                             .snapshots(),
            //                                         builder: (context,
            //                                             likeSnapshot) {
            //                                           bool isLiked =
            //                                               false;

            //                                           if (likeSnapshot
            //                                                   .hasData &&
            //                                               likeSnapshot
            //                                                   .data!
            //                                                   .exists) {
            //                                             isLiked = true;
            //                                           }

            //                                           return Column(
            //                                             children: [
            //                                               GestureDetector(
            //                                                 onTap: () {
            //                                                   if (FirebaseAuth
            //                                                           .instance
            //                                                           .currentUser ==
            //                                                       null) {
            //                                                     showDialog(
            //                                                       context:
            //                                                           context,
            //                                                       builder: (context) =>
            //                                                           AlertDialog(
            //                                                         title:
            //                                                             Text("Login Required"),
            //                                                         content:
            //                                                             Text("You need to log in to like products."),
            //                                                         actions: [
            //                                                           TextButton(
            //                                                             onPressed: () => Navigator.pop(context),
            //                                                             child: Text("Close"),
            //                                                           ),
            //                                                         ],
            //                                                       ),
            //                                                     );
            //                                                   } else {
            //                                                     toggleProductLike(
            //                                                         productId);
            //                                                   }
            //                                                 },
            //                                                 child:
            //                                                     Container(
            //                                                   height:
            //                                                       36,
            //                                                   width: 36,
            //                                                   decoration:
            //                                                       BoxDecoration(
            //                                                     border:
            //                                                         Border.all(
            //                                                       color: isLiked
            //                                                           ? Colors.red
            //                                                           : Colors.grey.shade200,
            //                                                     ),
            //                                                     borderRadius:
            //                                                         BorderRadius.circular(100),
            //                                                   ),
            //                                                   child:
            //                                                       Center(
            //                                                     child: Image
            //                                                         .asset(
            //                                                       isLiked
            //                                                           ? 'assets/images/heart2.png'
            //                                                           : 'assets/images/hearts.png',
            //                                                       height:
            //                                                           16,
            //                                                       width:
            //                                                           16,
            //                                                     ),
            //                                                   ),
            //                                                 ),
            //                                               ),
            //                                               const SizedBox(
            //                                                   height:
            //                                                       4),
            //                                               Text(
            //                                                 '${productData['likesCount'] ?? 0} likes',
            //                                                 style:
            //                                                     TextStyle(
            //                                                   fontSize:
            //                                                       12,
            //                                                   color: Colors
            //                                                       .grey,
            //                                                 ),
            //                                               ),
            //                                             ],
            //                                           );
            //                                         },
            //                                       ),
            //                                       const SizedBox(
            //                                           width: 10),
            //                                       // Share Button
            //                                       Column(
            //                                         children: [
            //                                           GestureDetector(
            //                                             onTap:
            //                                                 () async {
            //                                               try {
            //                                                 // Show loading dialog
            //                                                 showDialog(
            //                                                   context:
            //                                                       context,
            //                                                   barrierDismissible:
            //                                                       false,
            //                                                   builder:
            //                                                       (context) =>
            //                                                           Dialog(
            //                                                     child:
            //                                                         Padding(
            //                                                       padding:
            //                                                           const EdgeInsets.all(20.0),
            //                                                       child:
            //                                                           Column(
            //                                                         mainAxisSize:
            //                                                             MainAxisSize.min,
            //                                                         children: [
            //                                                           Text("Processing..."),
            //                                                           const SizedBox(height: 10),
            //                                                           CircularProgressIndicator(),
            //                                                         ],
            //                                                       ),
            //                                                     ),
            //                                                   ),
            //                                                 );

            //                                                 final productLink =
            //                                                     'https://lessernaqaa.web.app/#/products/$productId';

            //                                                 // Copy to clipboard
            //                                                 await Clipboard.setData(
            //                                                     ClipboardData(
            //                                                         text:
            //                                                             productLink));

            //                                                 // Update share count in Firestore
            //                                                 await FirebaseFirestore
            //                                                     .instance
            //                                                     .collection(
            //                                                         'products')
            //                                                     .doc(
            //                                                         productId)
            //                                                     .update({
            //                                                   'shareCount':
            //                                                       FieldValue.increment(
            //                                                           1),
            //                                                 });

            //                                                 Navigator.pop(
            //                                                     context); // Close loading

            //                                                 // Show confirmation dialog
            //                                                 showDialog(
            //                                                   context:
            //                                                       context,
            //                                                   builder:
            //                                                       (context) =>
            //                                                           AlertDialog(
            //                                                     title: Text(
            //                                                         "Link Copied"),
            //                                                     content:
            //                                                         Text("The product link has been copied to your clipboard."),
            //                                                     actions: [
            //                                                       TextButton(
            //                                                         onPressed: () =>
            //                                                             Navigator.pop(context),
            //                                                         child:
            //                                                             Text("Close"),
            //                                                       ),
            //                                                     ],
            //                                                   ),
            //                                                 );
            //                                               } catch (e) {
            //                                                 Navigator.pop(
            //                                                     context); // Close loading
            //                                                 print(
            //                                                     "Error copying product link: $e");

            //                                                 showDialog(
            //                                                   context:
            //                                                       context,
            //                                                   builder:
            //                                                       (context) =>
            //                                                           AlertDialog(
            //                                                     title: Text(
            //                                                         "Error"),
            //                                                     content:
            //                                                         Text("Something went wrong while copying the link."),
            //                                                     actions: [
            //                                                       TextButton(
            //                                                         onPressed: () =>
            //                                                             Navigator.pop(context),
            //                                                         child:
            //                                                             Text("Close"),
            //                                                       ),
            //                                                     ],
            //                                                   ),
            //                                                 );
            //                                               }
            //                                             },
            //                                             child:
            //                                                 Container(
            //                                               height: 36,
            //                                               width: 36,
            //                                               decoration:
            //                                                   BoxDecoration(
            //                                                 border: Border.all(
            //                                                     color: Colors
            //                                                         .grey
            //                                                         .shade200),
            //                                                 borderRadius:
            //                                                     BorderRadius.circular(
            //                                                         100),
            //                                               ),
            //                                               child: Center(
            //                                                 child: Image
            //                                                     .asset(
            //                                                   'assets/images/send.png',
            //                                                   height:
            //                                                       16,
            //                                                   width: 16,
            //                                                 ),
            //                                               ),
            //                                             ),
            //                                           ),
            //                                           const SizedBox(
            //                                               height: 4),
            //                                           StreamBuilder<
            //                                               DocumentSnapshot>(
            //                                             stream: FirebaseFirestore
            //                                                 .instance
            //                                                 .collection(
            //                                                     'products')
            //                                                 .doc(
            //                                                     productId)
            //                                                 .snapshots(),
            //                                             builder: (context,
            //                                                 snapshot) {
            //                                               if (!snapshot
            //                                                       .hasData ||
            //                                                   !snapshot
            //                                                       .data!
            //                                                       .exists) {
            //                                                 return Text(
            //                                                   '0 shares',
            //                                                   style:
            //                                                       TextStyle(
            //                                                     fontSize:
            //                                                         12,
            //                                                     color: Colors
            //                                                         .grey,
            //                                                   ),
            //                                                 );
            //                                               }

            //                                               final shareCount =
            //                                                   snapshot.data![
            //                                                           'shareCount'] ??
            //                                                       0;

            //                                               return Text(
            //                                                 '$shareCount shares',
            //                                                 style:
            //                                                     TextStyle(
            //                                                   fontSize:
            //                                                       12,
            //                                                   color: Colors
            //                                                       .grey,
            //                                                 ),
            //                                               );
            //                                             },
            //                                           ),
            //                                         ],
            //                                       ),
            //                                     ],
            //                                   ),
            //                                   SizedBox(height: 10),
            //                                 ],
            //                               ),
            //                             ),
            //                           ],
            //                         ),
            //                       ),
            //                       const SizedBox(height: 10),
            //                       Divider(
            //                           height: 10,
            //                           thickness: 1,
            //                           color: Colors.grey),
            //                     ],
            //                   ),
            //                 );
            //               },
            //             );
            //           },
            //         );
            //       },
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? _pageBody()
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 200,
                  right: 200,
                ),
                child: _pageBody(),
              ),
            ),
    );
  }
}

class PickupMap extends StatefulWidget {
  const PickupMap({Key? key}) : super(key: key);

  @override
  State<PickupMap> createState() => _PickupMapState();
}

class _PickupMapState extends State<PickupMap> {
  LatLng _center =
      LatLng(24.710574024024353, 46.67343704478749); // Initial center
  Marker? _centerMarker; // Marker that stays at the center

  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  BitmapDescriptor? _addLocationIcon;

  LatLng? _currentLocation; // For tracking current location
  bool _addingLocation = false; // Toggle when in add location mode

  TabController? tabController;
  PageController pageController1 = PageController(viewportFraction: 1);

  @override
  void initState() {
    super.initState();
    // _startAddingLocation();
    // _moveToCurrentLocation();
    _addCurrentLocationMarker();
    // _initMarkers();
    _loadLocationsFromFirestore();
    loadZoneBoxesFromFirestore();
    init();
  }

  void init() async {
    //
  }

  // Maps ____________________

  Set<Marker> _markers = {};
  Map<String, dynamic>? selectedLocation;
  final Set<Marker> _dropOffMarkers = {};
  List<String> list = <String>[
    //  'Current Location',
    'Add Location',
  ];
  List<Map<String, dynamic>> locationOptions = [
    {
      'title': 'Add Location',
      'type': 'add',
    }
  ];

  Future<Position> _determinePosition() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getCurrentLocation() async {
    Position position =
        await _determinePosition(); // Fetch the current position
    setState(() {
      _currentLocation = LatLng(
          position.latitude, position.longitude); // Assign to _currentLocation
    });
  }

  Future<void> _addCurrentLocationMarker() async {
    Position position = await _determinePosition();
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    final int markerSize = kIsWeb ? 32 : 100;

    //BitmapDescriptor markerIcon = await _createCustomMarkerImage(
    //  'assets/images/urhere1.png',
    //size: markerSize);

    //setState(() {
    //_markers.add(
    //Marker(
    //markerId: MarkerId('current_location'),
    //position: currentLocation,
    //zIndexInt: 0,
    //icon: markerIcon,
    //consumeTapEvents: true,
    //onTap: () {
    //showDialog(
    //context: context,
    //builder: (_) => AlertDialog(
    //title: Text('Current Location'),
    //content: Text('You are here'),
    //actions: [
    //TextButton(
    //onPressed: () => Navigator.pop(context),
    //child: Text('OK'),
    //),
    //],
    //),
    //);
    //},
    //),
    //);

    // _dropOffMarkers.add(
    //   Marker(
    //     markerId: MarkerId('current_location'),
    //     position: currentLocation,
    //     icon: markerIcon,
    //     consumeTapEvents: true,
    //     onTap: () {
    //       showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //           title: Text('Current Location'),
    //           content: Text('You are here'),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.pop(context),
    //               child: Text('OK'),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   ),
    // );
    //});
  }

  void _moveToCurrentLocation() async {
    Position position = await _determinePosition();
    LatLng currentLocation = LatLng(position.latitude, position.longitude);
    double zoomLevel = 15.0;

    GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
          currentLocation, zoomLevel), // Move to location and zoom in
    );
  }

  void _startAddingLocation() async {
    print('🔥 startAddingLocation triggered');

    final int markerSize = kIsWeb ? 80 : 180;

    BitmapDescriptor markerIcon = await _createCustomMarkerImage(
        'assets/images/addlocation2.png',
        size: markerSize);

    setState(() {
      _addingLocation = true;
      _addLocationIcon = markerIcon; // Save it for use in markers
    });
  }

  void _onCameraMove(CameraPosition position) async {
    setState(() {
      _center = position.target; // Update the center based on map movement
    });
  }

  void _showLocationNameDialog() async {
    String? locationName;
    String? locationDetails;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController detailsController = TextEditingController();
        final _formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text("Name this location"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: "Enter location name"),
                  validator: (value) => value == null || value.isEmpty
                      ? "Name is required"
                      : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: detailsController,
                  decoration:
                      InputDecoration(hintText: "Enter house number/details"),
                  validator: (value) => value == null || value.isEmpty
                      ? "Details are required"
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  locationName = nameController.text;
                  locationDetails = detailsController.text;
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );

    // If filled properly, save
    if (locationName != null && locationDetails != null) {
      _saveLocationToFirestore(_center, locationName!, locationDetails!);
      setState(() {
        _addingLocation = false;
        _centerMarker = null;
      });
    }
  }

  void _saveLocationToFirestore(
      LatLng position, String locationName, String details) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .add({
      'name': locationName,
      'details': details,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'createdBy': userId, // always set on create
      'createdAt': FieldValue.serverTimestamp(),
    });

    _loadLocationsFromFirestore();
  }

  void _loadLocationsFromFirestore1() async {
    // String? userId = FirebaseAuth.instance.currentUser?.uid;
    // QuerySnapshot snapshot = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(userId)
    //     .collection('locations')
    //     .get();

    // // Extract the saved locations
    // List<String> savedLocations =
    //     snapshot.docs.map((doc) => doc['name'].toString()).toList();

    // Set<Marker> newMarkers = {};

    // // Iterate over each saved location and create markers
    // for (var doc in snapshot.docs) {
    //   var data = doc.data() as Map<String, dynamic>;
    //   LatLng position = LatLng(data['latitude'], data['longitude']);
    //   String locationName = data['name'];

    //   Marker locationMarker = Marker(
    //     markerId: MarkerId(locationName),
    //     position: position,
    //     zIndexInt: 2,
    //     consumeTapEvents: true,
    //     onTap: () {
    //       showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //           title: Text(locationName),
    //           content: Text('This is a saved location.'),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.pop(context),
    //               child: Text('OK'),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   );

    //   newMarkers.add(locationMarker);
    // }

    // setState(() {
    //   if (savedLocations.isEmpty) {
    //     // No saved locations → show only Add Location
    //     list = ['Add Location'];
    //     selectedLocation = 'Add Location';
    //     _startAddingLocation(); // Automatically trigger add mode
    //     _moveToCurrentLocation();
    //   } else {
    //     // Saved locations exist → show them first, then Add Location
    //     list = [...savedLocations, 'Add Location'];
    //     selectedLocation = savedLocations.first;
    //     _moveToSavedLocation(
    //         savedLocations.first); // Automatically move to the first saved
    //   }

    //   // Update the markers
    //   _markers.addAll(newMarkers);
    // });
  }

  Future<void> _loadLocationsFromFirestore() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> loadedOptions = [];
    Set<Marker> newMarkers = {};

    // 🔁 Recursive Subfiles
    Future<void> addSubfilesRecursively(
        String parentPath, String idPrefix) async {
      final subfilesSnapshot =
          await firestore.collection('$parentPath/subfiles').get();

      for (final subDoc in subfilesSnapshot.docs) {
        final subfileData = subDoc.data();
        final subfilePath = '$parentPath/subfiles/${subDoc.id}';

        final lat = subfileData['latitude'];
        final lng = subfileData['longitude'];

        if (lat != null && lng != null) {
          loadedOptions.add({
            'title': subfileData['name'] ?? subDoc.id,
            'latitude': lat,
            'longitude': lng,
            'path': subfilePath,
            'type': 'subfile',
          });

          newMarkers.add(
            Marker(
              markerId: MarkerId(subfileData['name'] ?? subDoc.id),
              position: LatLng(
                  double.parse(lat.toString()), double.parse(lng.toString())),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(subfileData['name'] ?? subDoc.id),
                    content: Text('This is a saved location.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await addSubfilesRecursively(subfilePath, '${idPrefix}__${subDoc.id}');
      }
    }

    // 🔹 Owned Locations
    final ownedSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('locations')
        .get();

    for (final doc in ownedSnapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat != null && lng != null) {
        loadedOptions.add({
          'title': data['name'] ?? doc.id,
          'latitude': lat,
          'longitude': lng,
          'path': '/users/$uid/locations/${doc.id}',
          'type': 'owned',
        });

        newMarkers.add(
          Marker(
            markerId: MarkerId(data['name'] ?? doc.id),
            position: LatLng(
                double.parse(lat.toString()), double.parse(lng.toString())),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(data['name'] ?? doc.id),
                  content: Text('This is a saved location.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      await addSubfilesRecursively('/users/$uid/locations/${doc.id}', doc.id);
    }

    // 🔹 Shared Files/Subfiles
    final sharedMembersSnap = await firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    final Set<String> seenPaths = {};

    for (final memberDoc in sharedMembersSnap.docs) {
      final membersColl = memberDoc.reference.parent;
      final allTimeDoc = membersColl.parent;
      if (allTimeDoc == null || allTimeDoc.id != 'all_time') continue;

      final timeframesColl = allTimeDoc.parent;
      if (timeframesColl == null) continue;

      final fileDocRef = timeframesColl.parent;
      if (fileDocRef == null) continue;

      if (!seenPaths.add(fileDocRef.path)) continue;

      final fileDoc = await fileDocRef.get();
      if (!fileDoc.exists) continue;

      final data = fileDoc.data() as Map<String, dynamic>?;
      final lat = data?['latitude'];
      final lng = data?['longitude'];

      if (lat != null && lng != null) {
        loadedOptions.add({
          'title': data?['name'] ?? fileDoc.id,
          'latitude': lat,
          'longitude': lng,
          'path': fileDocRef.path,
          'type': 'shared',
        });

        newMarkers.add(
          Marker(
            markerId: MarkerId(data?['name'] ?? fileDoc.id),
            position: LatLng(
                double.parse(lat.toString()), double.parse(lng.toString())),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(data?['name'] ?? fileDoc.id),
                  content: Text('This is a saved location.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      await addSubfilesRecursively(fileDocRef.path, fileDoc.id);
    }

    // ✅ Final Dropdown + Behavior Logic
    setState(() {
      final addLocationOption = {'title': 'Add Location', 'type': 'add'};
      final finalList = [...loadedOptions, addLocationOption];
      locationOptions = finalList;

      if (loadedOptions.isEmpty) {
        // Only "Add Location" exists → auto-trigger add mode + move
        selectedLocation = addLocationOption;
        _startAddingLocation();
        _moveToCurrentLocation();
      } else {
        // Select first real location and move to it
        selectedLocation = loadedOptions.first;

        final lat = selectedLocation?['latitude'];
        final lng = selectedLocation?['longitude'];
        if (lat != null && lng != null) {
          _moveToPosition(LatLng(
            double.parse(lat.toString()),
            double.parse(lng.toString()),
          ));
        }
      }

      _markers.addAll(newMarkers);
    });
  }

  Future<void> _moveToPosition(LatLng position, {double zoom = 15.0}) async {
    try {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
    } catch (e) {
      print('Error moving to position: $e');
    }
  }

  void _moveToSavedLocation(String? locationName) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('name', isEqualTo: locationName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var locationData = snapshot.docs.first.data() as Map<String, dynamic>;
      double latitude = locationData?['latitude'] ?? 0.0;
      double longitude = locationData?['longitude'] ?? 0.0;

      if (latitude != 0.0 && longitude != 0.0) {
        LatLng savedLocation = LatLng(latitude, longitude);
        double zoomLevel = 15.0;

        GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
              savedLocation, zoomLevel), // Move to location and zoom in
        );
      } else {
        print('Location data is missing or invalid.');
      }
    } else {
      print('No saved locations found.');
    }
  }

  void _deleteLocation(BuildContext context, String locationName) {
    // Show confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Location"),
          content: Text("Are you sure you want to delete $locationName?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                String userId = FirebaseAuth.instance.currentUser!.uid;

                // Find and delete the document with the matching name
                QuerySnapshot snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('locations')
                    .where('name', isEqualTo: locationName)
                    .get();

                if (snapshot.docs.isNotEmpty) {
                  var docId = snapshot.docs.first.id;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('locations')
                      .doc(docId)
                      .delete();

                  // Remove the marker from the map
                  setState(() {
                    _markers.removeWhere(
                        (marker) => marker.markerId.value == locationName);

                    // Remove the location from the dropdown list
                    list.remove(locationName);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initMarkers() async {
    BitmapDescriptor markerIcon1 =
        await _createCustomMarkerImage('assets/images/3drvm.png');

    setState(() {
      _dropOffMarkers.add(
        Marker(
          markerId: MarkerId('marker1'),
          position: LatLng(26.33560408318569, 50.12094857116385),
          icon: markerIcon1,
          consumeTapEvents: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('King Abdulaziz Center for World Culture - Ithra'),
                content: Text('Open this location in Google Maps?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=26.33560408318569,50.12094857116385');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Could not open Google Maps.')),
                        );
                      }
                    },
                    child: Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      _dropOffMarkers.add(
        Marker(
          markerId: MarkerId('marker2'),
          position: LatLng(24.676978861097144, 46.687885371163865),
          icon: markerIcon1,
          consumeTapEvents: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Bank Albilad - HQ'),
                content: Text('Open this location in Google Maps?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=24.676978861097144,46.687885371163865');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Could not open Google Maps.')),
                        );
                      }
                    },
                    child: Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      _dropOffMarkers.add(
        Marker(
          markerId: MarkerId('marker3'),
          position: LatLng(24.736308349016127, 46.70131017116385),
          icon: markerIcon1,
          consumeTapEvents: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Jahez - PSU'),
                content: Text('Open this location in Google Maps?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=24.736308349016127,46.70131017116385');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Could not open Google Maps.')),
                        );
                      }
                    },
                    child: Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      _dropOffMarkers.add(
        Marker(
          markerId: MarkerId('marker4'),
          position: LatLng(24.929247334770505, 46.71729711608818),
          icon: markerIcon1,
          consumeTapEvents: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Riyadh Air'),
                content: Text('Open this location in Google Maps?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=24.929247334770505,46.71729711608818');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Could not open Google Maps.')),
                        );
                      }
                    },
                    child: Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerImage(String assetPath,
      {int size = 64}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List imageData = data.buffer.asUint8List();

    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: size,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      final ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

      return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Error decoding image for marker: $e");
      }
      // fallback for web if needed
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Products/Offers (pickup) _____________________

  Future<void> _addProductOrLocation() async {
    _getCurrentLocation();
    LatLng? selectedLocationCoords;
    String selectedLocationName = '';
    String selectedLocationDetails = '';
    final _formKey = GlobalKey<FormState>();
    final timeController = TextEditingController();
    final plasticBagController = TextEditingController(text: "0");
    final sodaCanBagController = TextEditingController(text: "0");
    final paperBagController = TextEditingController(text: "0");
    final cartonBeverageBagController = TextEditingController(text: "0");
    final cosmeticsBagController = TextEditingController(text: "0");

    Future<List<Map<String, dynamic>>> fetchZoneTimeSlots(
        String zoneName) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('name', isEqualTo: zoneName)
          .where('type', isEqualTo: 'pickup_zone')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final data = snapshot.docs.first.data();
      final List<dynamic> slots = data['timeSlots'] ?? [];
      return slots.cast<Map<String, dynamic>>();
    }

    List<Map<String, dynamic>> _savedLocations = [];
    String uid = FirebaseAuth.instance.currentUser!.uid;

    Future<List<Map<String, dynamic>>> fetchSavedAndSharedLocations() async {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final firestore = FirebaseFirestore.instance;
      List<Map<String, dynamic>> options = [];

      Future<void> addSubfilesRecursively(String parentPath) async {
        final subfilesSnapshot =
            await firestore.collection('$parentPath/subfiles').get();

        for (final subDoc in subfilesSnapshot.docs) {
          final subData = subDoc.data();
          final lat = subData['latitude'];
          final lng = subData['longitude'];

          if (lat != null && lng != null) {
            options.add({
              'title': subData['name'] ?? subDoc.id,
              'latitude': lat,
              'longitude': lng,
              'path': '$parentPath/subfiles/${subDoc.id}',
              'type': 'subfile',
              'details': subData['details'], // ✅ added line
            });
          }

          await addSubfilesRecursively('$parentPath/subfiles/${subDoc.id}');
        }
      }

      // ✅ Owned
      final ownedSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .get();

      for (final doc in ownedSnapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];

        if (lat != null && lng != null) {
          options.add({
            'title': data['name'] ?? doc.id,
            'latitude': lat,
            'longitude': lng,
            'path': '/users/$uid/locations/${doc.id}',
            'type': 'owned',
            'details': data['details'], // ✅ added line
          });
        }

        await addSubfilesRecursively('/users/$uid/locations/${doc.id}');
      }

      // ✅ Shared
      final sharedMembersSnap = await firestore
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();

      final Set<String> seenPaths = {};

      for (final memberDoc in sharedMembersSnap.docs) {
        final membersColl = memberDoc.reference.parent;
        final allTimeDoc = membersColl.parent;
        if (allTimeDoc == null || allTimeDoc.id != 'all_time') continue;

        final timeframesColl = allTimeDoc.parent;
        if (timeframesColl == null) continue;

        final fileDocRef = timeframesColl.parent;
        if (fileDocRef == null) continue;

        if (!seenPaths.add(fileDocRef.path)) continue;

        final fileDoc = await fileDocRef.get();
        if (!fileDoc.exists) continue;

        final data = fileDoc.data() as Map<String, dynamic>?;
        final lat = data?['latitude'];
        final lng = data?['longitude'];

        if (lat != null && lng != null) {
          options.add({
            'title': data?['name'] ?? fileDoc.id,
            'latitude': lat,
            'longitude': lng,
            'path': fileDocRef.path,
            'type': 'shared',
            'details': data?['details'], // ✅ added line
          });
        }

        await addSubfilesRecursively(fileDocRef.path);
      }

      return options;
    }

    // Before Navigator.push
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final allLocations = await fetchSavedAndSharedLocations();

    Navigator.pop(context); // Remove the loading dialog

    _savedLocations = allLocations
        .map((loc) => {
              'name': loc['title'],
              'latitude': loc['latitude'],
              'longitude': loc['longitude'],
              'details': loc['details'], // ✅ ADD THIS LINE
            })
        .toList();

    String? selectedValue;
    DateTimeRange? selectedTimeSlot;

    List<Map<String, dynamic>> _zoneSlots = [];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              int plasticBags = int.parse(plasticBagController.text);
              int sodaCansBags = int.parse(sodaCanBagController.text);
              int paperBags = int.parse(paperBagController.text);
              int cartonBeverageBags =
                  int.parse(cartonBeverageBagController.text);
              int cosmeticsBags = int.parse(cosmeticsBagController.text);
              int totalBags = plasticBags +
                  paperBags +
                  sodaCansBags +
                  cartonBeverageBags +
                  cosmeticsBags;
              int points = totalBags * 100;

              void _updatePoints() {
                totalBags = plasticBags +
                    sodaCansBags +
                    paperBags +
                    cartonBeverageBags +
                    cosmeticsBags;
                points = totalBags * 100;
              }

              return Scaffold(
                appBar: AppBar(title: Text('Pick up from your location!')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Select location ______
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              hintText: "Select Location"),
                          value: selectedValue,
                          isExpanded: true,
                          onChanged: (String? value) async {
                            setState(() {
                              selectedValue = value;
                              if (value == 'Current Location') {
                                selectedLocationCoords = _currentLocation;
                                selectedLocationName = 'Current Location';
                              } else {
                                final selectedLocation =
                                    _savedLocations.firstWhere(
                                  (location) => location['name'] == value,
                                );
                                selectedLocationCoords = LatLng(
                                  selectedLocation['latitude'],
                                  selectedLocation['longitude'],
                                );
                                selectedLocationName = selectedLocation['name'];
                                selectedLocationDetails =
                                    selectedLocation['details'] ?? '';
                              }
                            });

                            // determine zone and fetch slots
                            final String zone = determineZone(
                              selectedLocationCoords?.latitude ?? 0.0,
                              selectedLocationCoords?.longitude ?? 0.0,
                            );

                            final slots = await fetchZoneTimeSlots(zone);
                            setState(() {
                              _zoneSlots = slots;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a location';
                            }
                            String zone = determineZone(
                              selectedLocationCoords?.latitude ?? 0.0,
                              selectedLocationCoords?.longitude ?? 0.0,
                            );
                            if (zone == "Out of Zones") {
                              return "This location not in our supported zones.";
                            }
                            return null;
                          },
                          items: [
                            // DropdownMenuItem<String>(
                            //   value: 'Current Location',
                            //   child: Text('Current Location'),
                            // ),
                            ..._savedLocations
                                .map<DropdownMenuItem<String>>((location) {
                              return DropdownMenuItem<String>(
                                value: location['name'],
                                child: Text(location['name']),
                              );
                            }).toList(),
                          ],
                        ),
                        // Select date and time ________
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            // read-only result
                            TextFormField(
                              controller: timeController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: 'Selected Date & Time Slot',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date and time slot';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            CalendarDatePicker(
                              initialDate: _getInitialDate(_zoneSlots),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              selectableDayPredicate: (date) {
                                if (_zoneSlots.isEmpty)
                                  return true; // allow all until zone chosen
                                final weekdayName = intl.DateFormat('EEEE')
                                    .format(date)
                                    .toLowerCase();
                                final allowedDays =
                                    _zoneSlots.map((s) => s['day']).toSet();
                                return allowedDays.contains(weekdayName);
                              },
                              onDateChanged: (pickedDate) async {
                                print("📅 User picked date: $pickedDate");
                                // Show loading spinner
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );

                                String selectedDate =
                                    pickedDate.toIso8601String().split('T')[0];

                                // figure out zone of selected location
                                final String zone = determineZone(
                                  selectedLocationCoords?.latitude ?? 0.0,
                                  selectedLocationCoords?.longitude ?? 0.0,
                                );

                                // fetch slots for this zone
                                final zoneSlots =
                                    await fetchZoneTimeSlots(zone);

                                // filter by weekday
                                final weekdayName = intl.DateFormat('EEEE')
                                    .format(pickedDate)
                                    .toLowerCase();
                                final todaysSlots = zoneSlots
                                    .where((s) => s['day'] == weekdayName)
                                    .toList();

                                print("🔎 weekdayName = $weekdayName");
                                print("🔎 todaysSlots = $todaysSlots");

                                // check availability
                                Map<String, int> slotAvailability = {};

                                try {
                                  slotAvailability =
                                      await _checkTimeSlotAvailability(
                                          selectedDate, zone, context);
                                  print(
                                      "📊 slotAvailability: $slotAvailability");
                                } catch (e) {
                                  print(
                                      "❌ Error while checking slot availability: $e");
                                }

                                setState(() {
                                  timeController.text = ''; // clear previous
                                });

                                // Hide loading spinner
                                Navigator.pop(context);

                                print("📌 Attempting to open dialog...");

                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Select Time Slot for $selectedDate'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: todaysSlots.map((slot) {
                                          String slotText =
                                              "${slot['start']} - ${slot['end']}";
                                          int currentCount =
                                              slotAvailability[slotText] ?? 0;
                                          int maxOrders =
                                              slot['maxOrders'] ?? 999;

                                          return ListTile(
                                            title: Text(slotText),
                                            trailing: currentCount >= maxOrders
                                                ? const Text('Full',
                                                    style: TextStyle(
                                                        color: Colors.red))
                                                : null,
                                            enabled: currentCount < maxOrders,
                                            onTap: () {
                                              selectedTimeSlot = DateTimeRange(
                                                start: DateTime.parse(
                                                    "$selectedDate ${slot['start']}"),
                                                end: DateTime.parse(
                                                    "$selectedDate ${slot['end']}"),
                                              );
                                              timeController.text =
                                                  '$selectedDate - $slotText';
                                              Navigator.pop(context);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                );
                                print("✅ Slot dialog closed");
                              },
                            ),
                          ],
                        ),
                        // Plastic Bags field with number control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/plastic_bottle.png', // your image path
                                  width: 40, // customize width
                                  height: 40, // customize height
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Plastic Bottles',
                                  style: AppTypo.bodyBold.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (plasticBags > 0) {
                                        plasticBags--;
                                        plasticBagController.text =
                                            plasticBags.toString();
                                        _updatePoints();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: plasticBagController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    validator: (value) {
                                      int count =
                                          int.tryParse(value ?? '') ?? 0;
                                      if (count < 0) {
                                        return 'Invalid count';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      plasticBags++;
                                      plasticBagController.text =
                                          plasticBags.toString();
                                      _updatePoints();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Soda Cans Bags OR aluminum field with number control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/aluminum_can.png', // your image path
                                  width: 40, // customize width
                                  height: 40, // customize height
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Aluminum Cans',
                                  style: AppTypo.bodyBold.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (sodaCansBags > 0) {
                                        sodaCansBags--;
                                        sodaCanBagController.text =
                                            sodaCansBags.toString();
                                        _updatePoints();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: sodaCanBagController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    validator: (value) {
                                      int count =
                                          int.tryParse(value ?? '') ?? 0;
                                      if (count < 0) {
                                        return 'Invalid count';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      sodaCansBags++;
                                      sodaCanBagController.text =
                                          sodaCansBags.toString();
                                      _updatePoints();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Paper Bags field with number control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/cardboard.png', // your image path
                                  width: 40, // customize width
                                  height: 40, // customize height
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Paper and Cardboard',
                                  style: AppTypo.bodyBold.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (paperBags > 0) {
                                        paperBags--;
                                        paperBagController.text =
                                            paperBags.toString();
                                        _updatePoints();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: paperBagController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    validator: (value) {
                                      int count =
                                          int.tryParse(value ?? '') ?? 0;
                                      if (count < 0) {
                                        return 'Invalid count';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      paperBags++;
                                      paperBagController.text =
                                          paperBags.toString();
                                      _updatePoints();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // carton Beverage Bags field with number control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/carton_beverage.png', // your image path
                                  width: 40, // customize width
                                  height: 40, // customize height
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Carton Beverage',
                                  style: AppTypo.bodyBold.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (cartonBeverageBags > 0) {
                                        cartonBeverageBags--;
                                        cartonBeverageBagController.text =
                                            cartonBeverageBags.toString();
                                        _updatePoints();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: cartonBeverageBagController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    validator: (value) {
                                      int count =
                                          int.tryParse(value ?? '') ?? 0;
                                      if (count < 0) {
                                        return 'Invalid count';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      cartonBeverageBags++;
                                      cartonBeverageBagController.text =
                                          cartonBeverageBags.toString();
                                      _updatePoints();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // cosmetics Bags field with number control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/cosmetic_item.png', // your image path
                                  width: 40, // customize width
                                  height: 40, // customize height
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cosmetics Items',
                                  style: AppTypo.bodyBold.copyWith(
                                    color: AppTextColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (cosmeticsBags > 0) {
                                        cosmeticsBags--;
                                        cosmeticsBagController.text =
                                            cosmeticsBags.toString();
                                        _updatePoints();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: cosmeticsBagController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    validator: (value) {
                                      int count =
                                          int.tryParse(value ?? '') ?? 0;
                                      if (count < 0) {
                                        return 'Invalid count';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      cosmeticsBags++;
                                      cosmeticsBagController.text =
                                          cosmeticsBags.toString();
                                      _updatePoints();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Hidden field for total bags validation
                        TextFormField(
                          validator: (value) {
                            if (totalBags < 3) {
                              return 'You need to add at least 3 bags.';
                            }
                            return null;
                          },
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          enabled:
                              false, // Hidden field, so no interaction required
                        ),
                        // Display for total bags
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(totalBags.toString(),
                                    style: AppTypo.heading2.copyWith(
                                        color: AppTextColors.primary)),
                                const Text(
                                  "Total Bags",
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.grey),
                                ),
                              ],
                            ),
                            Icon(Icons.shopping_bag,
                                size: 32.0, color: Colors.brown),
                          ],
                        ),
                        // Points display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(points.toString(),
                                    style: AppTypo.heading2.copyWith(
                                        color: AppTextColors.primary)),
                                const Text(
                                  "Total Points",
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.grey),
                                ),
                              ],
                            ),
                            Icon(Icons.star, size: 32.0, color: Colors.yellow),
                          ],
                        ),
                        // Submission button ______
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Dialog(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text("Submitting request..."),
                                        SizedBox(height: 10),
                                        CircularProgressIndicator(),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              try {
                                // ⏳ The whole Firestore logic here...
                                int totalBags = plasticBags +
                                    paperBags +
                                    sodaCansBags +
                                    cartonBeverageBags +
                                    cosmeticsBags;
                                if (selectedLocationCoords != null &&
                                    selectedLocationName.isNotEmpty &&
                                    selectedTimeSlot != null) {
                                  // Prepare the message content
                                  String formattedStartDate =
                                      intl.DateFormat('yyyy-MM-dd HH:mm')
                                          .format(selectedTimeSlot!.start);
                                  String formattedEndDate =
                                      intl.DateFormat('HH:mm')
                                          .format(selectedTimeSlot!.end);

                                  String messageContent =
                                      'Items: (Plastic Bags: $plasticBags, Paper Bags: $paperBags, Soda Cans Bags: $sodaCansBags, Total Bags: $totalBags, Total KG: ${totalBags}kg )\n'
                                      'Time Slot: $formattedStartDate - $formattedEndDate';

                                  // Save the pickup data to Firestore
                                  // 1. Get user info and items/bags details
                                  final String currentUserId =
                                      FirebaseAuth.instance.currentUser!.uid;
                                  final String currentUserEmail = FirebaseAuth
                                      .instance.currentUser!.email
                                      .toString();
                                  final Timestamp timestamp = Timestamp.now();

                                  // 2. Assigning the seller/driver _____
                                  final String zone = determineZone(
                                    selectedLocationCoords?.latitude ?? 0.0,
                                    selectedLocationCoords?.longitude ?? 0.0,
                                  );
                                  final driverQuery = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .where('role', isEqualTo: 'driver')
                                      .where('zone', isEqualTo: zone)
                                      .get();

                                  if (driverQuery.docs.isEmpty) {
                                    throw Exception(
                                        "No drivers available in zone: $zone");
                                  }

                                  final driverDoc = driverQuery.docs[Random()
                                      .nextInt(driverQuery.docs.length)];
                                  final String sellerId = driverDoc.id;
                                  final String sellerEmail = driverDoc['email'];

                                  // 3. Build chat room id (bill room id)
                                  List<String> ids = [
                                    currentUserId,
                                    sellerId, // Replace with the actual receiver's ID
                                  ];
                                  ids.sort();
                                  String billRoomId = ids.join("_");

                                  // 4. Reference to the bill room document
                                  DocumentReference billRoomRef =
                                      FirebaseFirestore.instance
                                          .collection('bill_rooms')
                                          .doc(billRoomId);

                                  // Current timestamp
                                  Timestamp currentTimestamp = Timestamp.now();

                                  // 5. Check if the bill room document exists
                                  DocumentSnapshot billRoomSnapshot =
                                      await billRoomRef.get();

                                  if (billRoomSnapshot.exists) {
                                    // If the document exists, update only the lastBillTimestamp
                                    await billRoomRef.update({
                                      'lastBillTimestamp': currentTimestamp,
                                    });
                                    print('Bill room updated successfully.');
                                  } else {
                                    // If the document does not exist, initialize it
                                    await billRoomRef.set({
                                      'lastBillTimestamp': currentTimestamp,
                                      'lastReadTimestamps': {
                                        currentUserId:
                                            null, // Sender has not read yet
                                        '7DHsNu3hGYfEiKA0CCKezD6VQ0N2':
                                            null, // Receiver has not read yet
                                      },
                                    });
                                    print(
                                        'Bill room initialized successfully.');
                                  }

                                  // 📌 Extract location metadata for scoring gamification ___
                                  final selectedLocationFull =
                                      allLocations.firstWhere(
                                    (loc) => loc['title'] == selectedValue,
                                    orElse: () => {},
                                  );

                                  final String? fullPath =
                                      selectedLocationFull['path'];
                                  final List<String> pathParts =
                                      fullPath?.split('/') ?? [];

                                  String? locationOwner;
                                  String? locationId;
                                  String? subfileId;

                                  if (pathParts.contains('users') &&
                                      pathParts.contains('locations')) {
                                    locationOwner = pathParts[
                                        pathParts.indexOf('users') + 1];
                                    locationId = pathParts[
                                        pathParts.indexOf('locations') + 1];
                                    if (pathParts.contains('subfiles')) {
                                      subfileId = pathParts[
                                          pathParts.indexOf('subfiles') + 1];
                                    }
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('bill_rooms')
                                      .doc(billRoomId)
                                      .collection('bills')
                                      .add({
                                    'completed': false,
                                    'sending': false,
                                    'senderId': sellerId,
                                    'senderEmail': sellerEmail,
                                    'receiverId': currentUserId,
                                    'bill': points,
                                    'message': messageContent,
                                    'status': [
                                      {
                                        'statustext':
                                            'Pending', // Initial status
                                        'statustime': Timestamp
                                            .now(), // Current time as the timestamp
                                      },
                                    ],
                                    'timestamp': timestamp,
                                    'locationName': selectedLocationName,
                                    'locationDetails':
                                        selectedLocationDetails, // ✅ NEW LINE
                                    'latitude':
                                        selectedLocationCoords!.latitude,
                                    'longitude':
                                        selectedLocationCoords!.longitude,
                                    'timeSlot': {
                                      'start': selectedTimeSlot!.start
                                          .toIso8601String(),
                                      'end': selectedTimeSlot!.end
                                          .toIso8601String(),
                                    },
                                    'plasticBags': plasticBags,
                                    'paperBags': paperBags,
                                    'sodaCansBags': sodaCansBags,
                                    'totalBags': totalBags,
                                    'totalKgs': totalBags,
                                    'type': 'pickup', // Tag the bill type
                                    'zone': selectedLocationCoords != null
                                        ? determineZone(
                                            selectedLocationCoords?.latitude ??
                                                0.0,
                                            selectedLocationCoords?.longitude ??
                                                0.0,
                                          )
                                        : 'Unknown',
                                    // For scoring ___
                                    'locationOwner': locationOwner,
                                    'locationId': locationId,
                                    'subfileId': subfileId,
                                  });

                                  Navigator.pop(
                                      context); // Close loading dialog
                                  Navigator.pop(context); // Close form dialog

                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: const Text('Order submitted!'),
                                      content: const Text(
                                          "Your pickup order has been successfully submitted."),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    WalletScreen(),
                                              ),
                                            );
                                          },
                                          child:
                                              const Text('Go to transactions'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context); // Close loading dialog
                                print("❌ Submission error: $e");
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Error"),
                                    content: const Text(
                                        "Failed to submit your request. Please try again."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          child: Text("Pick up!"),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _zoneBoxList = [];

  Future<void> loadZoneBoxesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .where('type', isEqualTo: 'pickup_zone')
        .get();

    _zoneBoxList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String name = data['name'];
      final List<dynamic> polygonData = data['polygon'];

      final List<LatLng> polygonPoints = polygonData
          .map<LatLng>(
              (point) => LatLng(point['lat'] as double, point['lng'] as double))
          .toList();

      _zoneBoxList.add({
        'name': name,
        'polygon': polygonPoints,
      });
    }

    // 👇 Draw polygons on the map
    _drawZonePolygons();
  }

  Set<Polygon> _zonePolygons = {};

  void _drawZonePolygons() {
    Set<Polygon> polygons = {};

    for (final zone in _zoneBoxList) {
      final String name = zone['name'];
      final List<LatLng> polygonPoints = zone['polygon'];

      polygons.add(
        Polygon(
          polygonId: PolygonId(name),
          points: polygonPoints,
          strokeColor: Colors.green,
          strokeWidth: 2,
          fillColor: Colors.green.withOpacity(0.2),
        ),
      );
    }

    setState(() {
      _zonePolygons = polygons;
    });
  }

  String determineZone(double latitude, double longitude) {
    final LatLng point = LatLng(latitude, longitude);

    bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
      int intersectCount = 0;

      for (int j = 0; j < polygon.length; j++) {
        LatLng vertex1 = polygon[j];
        LatLng vertex2 = polygon[(j + 1) % polygon.length];

        if (((vertex1.longitude > point.longitude) !=
                (vertex2.longitude > point.longitude)) &&
            (point.latitude <
                (vertex2.latitude - vertex1.latitude) *
                        (point.longitude - vertex1.longitude) /
                        (vertex2.longitude - vertex1.longitude) +
                    vertex1.latitude)) {
          intersectCount++;
        }
      }

      return (intersectCount % 2) == 1;
    }

    for (final zone in _zoneBoxList) {
      final String name = zone['name'];
      final List<LatLng> polygonPoints = zone['polygon'];

      if (isPointInPolygon(point, polygonPoints)) {
        return name;
      }
    }

    return "Out of Zones";
  }

  DateTime getNextSunday() {
    DateTime today = DateTime.now();
    int daysUntilSunday = (DateTime.sunday - today.weekday) % 7;
    return today
        .add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  DateTime _getInitialDate(List<Map<String, dynamic>> slots) {
    if (slots.isEmpty) return DateTime.now();

    final allowedDays = slots.map((s) => s['day']).toSet();

    DateTime date = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final weekdayName = intl.DateFormat('EEEE').format(date).toLowerCase();
      if (allowedDays.contains(weekdayName)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return DateTime.now();
  }

  Future<Map<String, int>> _checkTimeSlotAvailability(
      String date, String zone, BuildContext context) async {
    Map<String, int> slotAvailability = {};

    // build correct range strings
    final startRange = "${date}T00:00:00.000";
    final endRange = "${date}T23:59:59.999";

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collectionGroup('bills')
        .where('zone', isEqualTo: zone)
        .where('timeSlot.start',
            isGreaterThanOrEqualTo: startRange, isLessThanOrEqualTo: endRange)
        .get();

    for (var doc in snapshot.docs) {
      String startIso = doc['timeSlot']['start'];
      String endIso = doc['timeSlot']['end'];

      // extract HH:mm from the ISO strings
      final startTime = startIso.split('T').last.substring(0, 5); // "07:00"
      final endTime = endIso.split('T').last.substring(0, 5); // "11:00"

      String formattedSlot = "$startTime - $endTime";
      slotAvailability[formattedSlot] =
          (slotAvailability[formattedSlot] ?? 0) + 1;
    }

    return slotAvailability;
  }

  String _formatTimeRange(DateTimeRange range, BuildContext context) {
    final start = TimeOfDay.fromDateTime(range.start);
    final end = TimeOfDay.fromDateTime(range.end);
    return '${start.format(context)} - ${end.format(context)}';
  }

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please Sign In or Sign Up'),
        content: const Text('You need to be signed in to perform this action.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Pick up Map',
          style: AppTypo.heading3.copyWith(
            color: AppTextColors.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map and locations _______
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true, // default recenter button
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 4,
                ),
                markers: {
                  ..._markers,
                  if (_addingLocation && _addLocationIcon != null)
                    Marker(
                      markerId: MarkerId('center_marker'),
                      position: _center, // this moves with the camera
                      icon: _addLocationIcon!,
                      zIndexInt: 9,
                      consumeTapEvents: true,
                      onTap: _showLocationNameDialog,
                    ),
                },
                polygons: _zonePolygons,
                onCameraMove: _onCameraMove,
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                },
              ),
            ),
          ),
          // Upper button Instructions _______
          Positioned(
            top: 10.0, // Adjust this to move the AppButton vertically
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: "Pick up Instructions",
                        barrierColor: Colors.black.withOpacity(0.5),
                        pageBuilder: (context, anim1, anim2) {
                          int currentPage = 0;
                          final PageController pageController =
                              PageController();

                          return StatefulBuilder(
                            builder: (context, setState) {
                              final double dialogHeight =
                                  MediaQuery.of(context).size.height * 0.8;

                              return Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: dialogHeight,
                                    decoration: BoxDecoration(
                                      color: ApplicationColors.surface,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      children: [
                                        /// =========================
                                        /// IMAGE SLIDER (EDGE TO EDGE)
                                        /// =========================
                                        SizedBox(
                                          height: dialogHeight * 0.35,
                                          child: PageView(
                                            controller: pageController,
                                            onPageChanged: (index) {
                                              setState(
                                                  () => currentPage = index);
                                            },
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(24),
                                                  topRight: Radius.circular(24),
                                                ),
                                                child: Image.asset(
                                                  'assets/images/pickup_instruction.png',
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              // ClipRRect(
                                              //   borderRadius:
                                              //       const BorderRadius.only(
                                              //     topLeft: Radius.circular(24),
                                              //     topRight: Radius.circular(24),
                                              //   ),
                                              //   child: Image.asset(
                                              //     'assets/images/pickup_instruction.png',
                                              //     width: double.infinity,
                                              //     fit: BoxFit.cover,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        /// =========================
                                        /// DOTS
                                        /// =========================
                                        // Row(
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.center,
                                        //   children: List.generate(2, (index) {
                                        //     return AnimatedContainer(
                                        //       duration: const Duration(
                                        //           milliseconds: 200),
                                        //       margin:
                                        //           const EdgeInsets.symmetric(
                                        //               horizontal: 4),
                                        //       width:
                                        //           currentPage == index ? 12 : 8,
                                        //       height:
                                        //           currentPage == index ? 12 : 8,
                                        //       decoration: BoxDecoration(
                                        //         shape: BoxShape.circle,
                                        //         color: currentPage == index
                                        //             ? Colors.blue
                                        //             : Colors.grey,
                                        //       ),
                                        //     );
                                        //   }),
                                        // ),

                                        const SizedBox(height: 12),

                                        /// =========================
                                        /// SCROLLABLE TEXT
                                        /// =========================
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: currentPage == 0
                                                    ? [
                                                        Text(
                                                          'Pick up Service',
                                                          style: AppTypo
                                                              .heading2
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Text(
                                                          '1. Collect the highest amount of cardboard, paper, empty bottles, and cans before requesting pick up service.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '2. Each bag has to contain only one type of waste.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '3. Choose a suitable time available for you.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '4. Our delivery captain will contact you when he arrives.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                      ]
                                                    : [
                                                        const Text(
                                                          'Pick up Service',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Text(
                                                          '3. Choose a suitable time available for you.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '4. Our delivery captain will contact you when he arrives.',
                                                          style: AppTypo.body
                                                              .copyWith(
                                                            color: AppTextColors
                                                                .primary,
                                                          ),
                                                        ),
                                                      ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        /// =========================
                                        /// BUTTONS
                                        /// =========================
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Dismiss'),
                                              ),
                                              // ElevatedButton(
                                              //   onPressed: () {
                                              //     if (currentPage == 0) {
                                              //       pageController.nextPage(
                                              //         duration: const Duration(
                                              //             milliseconds: 300),
                                              //         curve: Curves.easeInOut,
                                              //       );
                                              //     } else {
                                              //       Navigator.pop(context);
                                              //     }
                                              //   },
                                              //   child: Text(
                                              //     currentPage == 0
                                              //         ? 'Next'
                                              //         : 'Understood',
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    style: ApplicationButtons.button2(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Icon(Icons.help,
                              color: ApplicationColors.primary),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'How to pick up?',
                          style: AppTypo.body
                              .copyWith(color: ApplicationColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List and buttons ________
          Positioned(
            bottom: 30.0, // Adjust this value as needed
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Properties and locations Squares _______
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white, // white background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.settings, color: Colors.grey),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            // ✅ Filter only owned or subfile locations
                            List<Map<String, dynamic>> userLocations =
                                locationOptions
                                    .where((location) =>
                                        location['type'] == 'owned' ||
                                        location['type'] == 'subfile')
                                    .toList();

                            return AlertDialog(
                              title: Text('Manage Locations'),
                              content: userLocations.isEmpty
                                  ? Center(child: Text('No locations added.'))
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: userLocations.map((location) {
                                        final title =
                                            location['title'] ?? 'Unnamed';
                                        return ListTile(
                                          title: Text(title),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // Close dialog
                                              _deleteLocation(context,
                                                  title); // Pass only name
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              actions: [
                                TextButton(
                                  child: Text("Close"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownMenu<Map<String, dynamic>>(
                        initialSelection: selectedLocation,
                        onSelected: (Map<String, dynamic>? value) {
                          if (value == null) return;

                          setState(() {
                            selectedLocation = value;
                          });

                          if (value['type'] == 'add') {
                            _startAddingLocation();

                            if (locationOptions.length == 1) {
                              _moveToCurrentLocation();
                            }

                            setState(() {
                              _addingLocation = true;
                              _centerMarker = null;
                            });
                          } else {
                            final pos = LatLng(
                              double.parse(value['latitude'].toString()),
                              double.parse(value['longitude'].toString()),
                            );
                            _moveToPosition(pos);
                            setState(() {
                              _addingLocation = false;
                              _centerMarker = null;
                            });
                          }
                        },
                        dropdownMenuEntries: locationOptions
                            .map<DropdownMenuEntry<Map<String, dynamic>>>(
                                (entry) {
                          return DropdownMenuEntry<Map<String, dynamic>>(
                            value: entry,
                            label: entry['title'],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Add product/location _______
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // User is signed in, proceed with the function
                        _addProductOrLocation();
                      } else {
                        // User is not signed in, show a dialog
                        _notSignedIn();
                      }
                    },
                    style: ApplicationButtons.button1(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: 24,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                            )),
                        SizedBox(width: 4),
                        Text('Pick up!',
                            style: AppTypo.bodyBold.copyWith(
                              color: AppTextColors.inverse,
                            )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  PageController pageController1 = PageController(viewportFraction: 1);

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please Sign In or Sign Up'),
        content: const Text('You need to be signed in to perform this action.'),
      ),
    );
  }

  void _payNow(
      String receiverUid, String documentId, Map<String, dynamic> data) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    try {
      // Fetch user role directly from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      String userRole = userDoc['role'] ?? '';

      if (userRole != 'driver') {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show access denied dialog if the user is not a driver
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Access Denied'),
            content: Text('Only drivers can confirm orders.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Build the billRoomId dynamically based on the admin and receiver UIDs
      List<String> ids = [
        receiverUid,
        '7DHsNu3hGYfEiKA0CCKezD6VQ0N2' // Assuming '7DHsNu3hGYfEiKA0CCKezD6VQ0N2' is the admin UID
      ];
      ids.sort();
      String billRoomId = ids.join("_");

      // Update order and receiver's points
      await FirebaseFirestore.instance
          .collection('bill_rooms')
          .doc(billRoomId)
          .collection('bills')
          .doc(documentId)
          .update({
        'completed': true,
        'status': FieldValue.arrayUnion([
          {
            'statustext': 'Order Confirmed',
            'statustime': Timestamp.now(),
          },
        ]),
      });

      int points = data['bill'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverUid)
          .update({
        'points': FieldValue.increment(points),
      });

      // Close loading dialog before showing success
      Navigator.of(context).pop();

      // Show success confirmation dialog after updates
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Confirmed'),
          content: Text('Order confirmed and points transferred!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog if something goes wrong
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to confirm order. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _buyProduct(String productId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        );
      },
    );

    print("Button pressed. Starting _buyProduct for productId: $productId");

    // 1. Get product details
    Map<String, dynamic>? productData;
    try {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      // Check if product exists before accessing data
      if (productSnapshot.exists) {
        productData = productSnapshot.data() as Map<String, dynamic>;
        print("Product data retrieved: $productData");

        if (productData == null) {
          // Handle product not found error
          print("Product data is null");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        // Extract relevant product details (assuming fields exist)
        int price = productData['price'] ?? 0; // Handle missing field
        List<dynamic>? stockDynamic =
            productData['stock'] as List<dynamic>?; // Handle missing field

        // Ensure stock is a List<String>
        List<String> stock =
            stockDynamic != null ? List<String>.from(stockDynamic) : [];

        // Extract seller ID from product data
        String sellerId = productData['userId'] ?? ''; // Handle missing field

        print("Product price: $price, stock: $stock, sellerId: $sellerId");

        // 2. Get user details (replace with your logic to retrieve user ID)
        String userId = FirebaseAuth.instance.currentUser!.uid;
        print("User ID: $userId");

        DocumentSnapshot userSnapshot;
        try {
          print("Attempting to retrieve user data...");
          userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          print("User data retrieved: ${userSnapshot.data()}");
        } catch (e) {
          print("Error getting user details: $e");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        // Check if user exists before accessing data
        if (!userSnapshot.exists) {
          // Handle user not found error (unlikely, but good practice)
          print("User not found");
          Navigator.of(context).pop(); // Close the loading dialog
          return;
        }

        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Extract user points (assuming field exists)
        int userPoints = userData['points'] ?? 0; // Handle missing field
        print("User points: $userPoints");

        // 3. Perform security checks and data validation
        if (userPoints < price) {
          // Handle insufficient points error (show a dialog)
          print("Insufficient points");
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Insufficient Points'),
                content: const Text(
                    'You don\'t have enough points to purchase this product.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Exit the function if points are insufficient
        }

        if (stock.isEmpty) {
          // Handle out-of-stock error (show a dialog)
          print("Out of stock");
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Out of Stock'),
                content: const Text('This product is currently out of stock.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Exit the function if product is out of stock
        }

        // 4. Update user and seller points within a transaction
        print("Starting transaction to update points");
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            print("Transaction: Getting user and seller references");
            DocumentReference userRef =
                FirebaseFirestore.instance.collection('users').doc(userId);
            DocumentReference sellerRef =
                FirebaseFirestore.instance.collection('users').doc(sellerId);

            // Read both user and seller documents first
            DocumentSnapshot userSnapshot = await transaction.get(userRef);
            DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);

            // Check if documents exist
            if (!userSnapshot.exists) {
              throw Exception("User document does not exist in transaction");
            }
            if (!sellerSnapshot.exists) {
              throw Exception("Seller document does not exist in transaction");
            }

            // Update user points
            Map<String, dynamic> updatedUserData =
                userSnapshot.data()! as Map<String, dynamic>;
            updatedUserData['points'] = userPoints - price;
            print("Transaction: Updating user points");
            transaction.update(userRef, updatedUserData);

            // Update seller points
            Map<String, dynamic> updatedSellerData =
                sellerSnapshot.data()! as Map<String, dynamic>;
            updatedSellerData['points'] =
                (updatedSellerData['points'] ?? 0) + price;
            print("Transaction: Updating seller points");
            transaction.update(sellerRef, updatedSellerData);
          });
          print("Transaction to update points completed");

          // 5. Capture stock item (without removing from stock)
          String stockItem =
              stock.first; // Get the first element (without removing)
          print("Stock item captured: $stockItem");

          // 6. Build and store bill room data
          List<String> ids = [sellerId, userId];
          ids.sort();
          String billRoomId = ids.join("_"); // Ensure consistent bill room ID
          print("Bill room ID: $billRoomId");

          // Reference to bill room and bills subcollection
          CollectionReference billCollectionRef = FirebaseFirestore.instance
              .collection('bill_rooms')
              .doc(billRoomId)
              .collection('bills');
          DocumentReference billDocRef =
              billCollectionRef.doc(); // Generate unique ID for bill

          // Bill data with required fields
          Map<String, dynamic> newBillData = {
            'completed': true, // Adjust as needed
            'sending': true, // Adjust as needed
            'senderId': userId,
            'senderEmail': FirebaseAuth.instance.currentUser!.email
                .toString(), // Sender's email
            'receiverId': sellerId,
            'bill': price, // Retrieved product price
            'message':
                '${productData['productName']}\n(Stock/Code Item: $stockItem)', // Detailed message
            'timestamp':
                FieldValue.serverTimestamp(), // Timestamp when bill is created
            'type': 'reward', // Add type field with value "reward"
            'status': FieldValue.arrayUnion([
              {
                'statustext': 'Order Confirmed',
                'statustime': Timestamp.now(),
              },
            ]), // Initial status update
          };

          // Add the new bill data to the 'bills' subcollection
          await billDocRef.set(newBillData);
          print("Bill data created successfully!");

          // Reference to the bill room document
          DocumentReference billRoomRef = FirebaseFirestore.instance
              .collection('bill_rooms')
              .doc(billRoomId);

          // Current timestamp
          Timestamp currentTimestamp = Timestamp.now();

          // Check if the bill room document exists
          DocumentSnapshot billRoomSnapshot = await billRoomRef.get();

          if (billRoomSnapshot.exists) {
            // If the document exists, update the lastBillTimestamp and lastReadTimestamps for the current user only
            await billRoomRef.update({
              'lastBillTimestamp': currentTimestamp,
            });
            print('Bill room updated successfully.');
          } else {
            // If the document does not exist, initialize it
            await billRoomRef.set({
              'lastBillTimestamp': currentTimestamp,
              'lastReadTimestamps': {
                FirebaseAuth.instance.currentUser!.uid:
                    null, // Sender has read it
                sellerId: null, // Receiver has not read yet
              },
            });
            print('Bill room initialized successfully.');
          }

          // 7. Update product stock (uncommented)
          print("Starting transaction to update product stock");
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            DocumentReference productRef = FirebaseFirestore.instance
                .collection('products')
                .doc(productId);
            DocumentSnapshot productSnapshot =
                await transaction.get(productRef);
            if (!productSnapshot.exists) {
              throw Exception("Product document does not exist in transaction");
            }
            Map<String, dynamic> updatedProductData =
                productSnapshot.data()! as Map<String, dynamic>;
            List<String> remainingStock = List.from(stock); // Create a copy
            remainingStock
                .removeAt(0); // Remove the first element (purchased item)
            updatedProductData['stock'] =
                remainingStock; // Update stock with the modified list
            print("Transaction: Updating product stock");
            transaction.update(productRef, updatedProductData);
          });
          print("Product stock updated");

          // 8. Handle purchase success (optional: show confirmation message)
          print('Product purchased successfully!');
          Navigator.of(context).pop(); // Close the loading dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Purchased successfully!'),
                content: const Text(
                    'Check the wallet transaction to view your purchase.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WalletScreen()),
                      );
                    },
                    child: const Text('Go to transactions'),
                  ),
                ],
              );
            },
          );
        } catch (e, stackTrace) {
          print("Transaction failed: ${e.toString()}");
          print(stackTrace.toString());
          Navigator.of(context).pop(); // Close the loading dialog
        }
      } else {
        // Handle product not found error (e.g., show a dialog)
        print("Product not found");
        Navigator.of(context).pop(); // Close the loading dialog
        return;
      }
    } catch (e) {
      // Handle product not found error
      print("Error getting product details: $e");
      Navigator.of(context).pop(); // Close the loading dialog
      return;
    }
  }

  Widget _pageBody() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.favorite_border_rounded,
        //         size: 20, color: Colors.black),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final product = snapshot.data!;
            return SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller Information ________________________________
                    // ListTile(
                    //   contentPadding:
                    //       EdgeInsets.only(
                    //           left: 16),
                    //   leading: Image(
                    //       image: AssetImage(
                    //           zatyatlogo),
                    //       height:
                    //           50,
                    //       width:
                    //           50),
                    //   title: Text(
                    //       "Zatyat Management",
                    //       style:
                    //           boldTextStyle()),
                    //   subtitle: Text(
                    //       "Official Accont of Zatyat ✔",
                    //       style:
                    //           secondaryTextStyle()),
                    //   trailing:
                    //       SingleChildScrollView(
                    //     scrollDirection:
                    //         Axis.horizontal,
                    //     child:
                    //         Row(
                    //       mainAxisAlignment:
                    //           MainAxisAlignment.end,
                    //       crossAxisAlignment:
                    //           CrossAxisAlignment.end,
                    //       children: [
                    //         IconButton(
                    //           onPressed: () {
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(builder: (context) => RegistrationScreen()),
                    //             );
                    //           },
                    //           icon: Icon(Icons.message_rounded, size: 20),
                    //         ),
                    //         IconButton(
                    //           onPressed: () {
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(builder: (context) => RegistrationScreen()),
                    //             );
                    //           },
                    //           icon: Icon(Icons.call, size: 20),
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    SizedBox(height: 8),
                    // Product/Service Images ____________________________
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 0.65,
                      child: PageView.builder(
                        controller: pageController1,
                        itemCount: product['productImages'].length,
                        itemBuilder: (context, index) => Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width * 0.55,
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.all(5),
                          alignment: Alignment.center,
                          child: Image.network(product['productImages'][index],
                              alignment: Alignment.topCenter),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SmoothPageIndicator(
                        controller: pageController1,
                        count: product['productImages'].length,
                        effect: CustomizableEffect(
                          activeDotDecoration: DotDecoration(
                            height: 8,
                            width: 8,
                            color: primaryBlackColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          dotDecoration: DotDecoration(
                            height: 8,
                            width: 8,
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        itemCount: product['productImages'].length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              final List<String> images =
                                  List<String>.from(product['productImages']);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ZoomImageScreen(
                                    galleryImages: images,
                                    index: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: gray.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(4),
                              child: Image(
                                  image: NetworkImage(
                                      product['productImages'][index]),
                                  height: 50,
                                  width: 50),
                            ),
                          );
                        },
                      ),
                    ),
                    // Product/Service Name ____________________________________
                    SizedBox(height: 15),
                    Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(product['productName'],
                            style: boldTextStyle(size: 20))),
                    // Price and buying button _______________________
                    SizedBox(height: MediaQuery.of(context).size.width * 0.015),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text("Price", style: boldTextStyle())),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("${product['price']} Point",
                              style: boldTextStyle(size: 18)),
                          SizedBox(width: 50),
                          GestureDetector(
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                // User is signed in, proceed with the function
                                _buyProduct(widget.productId);
                              } else {
                                // User is not signed in, show a dialog
                                _notSignedIn();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 42),
                              margin: EdgeInsets.all(8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(35),
                              ),
                              child: Text('Get this offer!',
                                  style: boldTextStyle(color: white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Product/Service Description and bio _________________________________________
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text('Description', style: boldTextStyle())),
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        style: secondaryTextStyle(),
                        text: product['productDisc'],
                        // children: [
                        //   TextSpan(
                        //       text: ' view more ...',
                        //       style: primaryTextStyle()),
                        // ],
                      ),
                    ).paddingOnly(right: 16, left: 16),
                    // Comments & Product/Service Ratings _____________
                    const SizedBox(
                      height: 20,
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('ٌReviews',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Urbanist-semibold'),
                                textAlign: TextAlign.center),
                            // trailing: InkWell(
                            //   onTap: () => Navigator.pop(context),
                            //   child: const Icon(
                            //     Icons.close,
                            //     color: Colors.black,
                            //   ),
                            // ),
                          ),
                          // Padding(
                          //   padding:
                          //       EdgeInsets.only(left: 16),
                          //   child:
                          //       Row(
                          //     children: [
                          //       Container(
                          //         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          //         decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
                          //         child: Text("Used", style: TextStyle(color: Colors.black, fontSize: 12)),
                          //       ),
                          //       SizedBox(width: 8),
                          //       Icon(Icons.star_half_rounded, color: Colors.black),
                          //       SizedBox(width: 8),
                          //       Text('4.9 (86 reviews)', style: secondaryTextStyle()),
                          //       SizedBox(width: 8),
                          //     ],
                          //   ),
                          // ),
                          // ListView
                          //     .builder(
                          //   physics:
                          //       const NeverScrollableScrollPhysics(),
                          //   shrinkWrap:
                          //       true,
                          //   scrollDirection:
                          //       Axis.vertical,
                          //   itemCount:
                          //       instastory1.length,
                          //   itemBuilder:
                          //       (context, index) {
                          //     return Column(
                          //       children: [
                          //         ListTile(
                          //           leading: Image.asset(
                          //             instastory1[index],
                          //             height: 30,
                          //             width: 30,
                          //           ),
                          //           title: Text(
                          //             text1[index],
                          //             style: const TextStyle(fontFamily: 'Urbanist-semibold', fontSize: 15),
                          //           ),
                          //           subtitle: Text(
                          //             subtitle[index],
                          //             style: const TextStyle(fontFamily: "Urbanist-medium"),
                          //           ),
                          //           trailing: Text(
                          //             time[index],
                          //             style: TextStyle(fontFamily: "Urbanist-medium", fontSize: 12, color: Colors.grey.shade400),
                          //           ),
                          //         ),
                          //         Padding(
                          //           padding: const EdgeInsets.only(left: 20),
                          //           child: Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               InkWell(
                          //                   onTap: () {
                          //                     changeValue(value: index);
                          //                   },
                          //                   child: Image.asset(
                          //                     selectIndex.contains(index) ? 'assets/images/heart2.png' : 'assets/images/hearts.png',
                          //                     height: 15,
                          //                     width: 15,
                          //                   )),
                          //               const SizedBox(
                          //                 width: 10,
                          //               ),
                          //               Image.asset(
                          //                 'assets/images/comment.png',
                          //                 height: 15,
                          //                 width: 15,
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          //         const SizedBox(
                          //           height: 10,
                          //         ),
                          //       ],
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(child: Text('Product not found.'));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? _pageBody()
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 200, right: 200),
                child: _pageBody(),
              ),
            ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    init();
    // walletDataList();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _openSearchAndFilterPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          String searchText = '';
          final TextEditingController searchController =
              TextEditingController();
          String sortBy = 'Date: New → Old'; // ✅ default
          List<String> selectedCategories = [];

          Future<List<QueryDocumentSnapshot>> _loadAllBillsFromUserRooms(
              List<String> billRoomIds) async {
            List<QueryDocumentSnapshot> allBills = [];
            for (final roomId in billRoomIds) {
              final snapshot = await FirebaseFirestore.instance
                  .collection('bill_rooms')
                  .doc(roomId)
                  .collection('bills')
                  .orderBy('timestamp', descending: true)
                  .get();
              allBills.addAll(snapshot.docs);
            }
            return allBills;
          }

          void _showFilterDialog(
            BuildContext context,
            void Function(void Function()) parentSetState,
          ) {
            List<String> localSelected = List.from(selectedCategories);
            String selectedSort = sortBy;

            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Filter Options'),
                      content: Container(
                        width: double.maxFinite,
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('bill_rooms')
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            String currentUserId =
                                FirebaseAuth.instance.currentUser!.uid;

                            // Get all bill rooms relevant to this user
                            List<DocumentSnapshot> relevantRooms = snapshot
                                .data!.docs
                                .where((doc) =>
                                    doc.id.split('_').contains(currentUserId))
                                .toList();

                            // Load all bills from all relevant rooms
                            return FutureBuilder<List<QuerySnapshot>>(
                              future: Future.wait(
                                relevantRooms.map((roomDoc) async {
                                  return await FirebaseFirestore.instance
                                      .collection('bill_rooms')
                                      .doc(roomDoc.id)
                                      .collection('bills')
                                      .orderBy('timestamp', descending: true)
                                      .get();
                                }),
                              ),
                              builder: (context, billSnapshot) {
                                if (!billSnapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                // Flatten all bills into one list
                                final allBills = billSnapshot.data!
                                    .expand((roomBills) => roomBills.docs)
                                    .toList();

                                // Build categories dynamically
                                Set<String> categorySet = {};
                                for (var billDoc in allBills) {
                                  final bill =
                                      billDoc.data() as Map<String, dynamic>;

                                  if (bill['type'] != null &&
                                      bill['type'] is String) {
                                    categorySet.add(bill['type']);
                                  }

                                  if (bill['completed'] == true) {
                                    categorySet.add('completed');
                                  } else if (bill['cancelled'] == true) {
                                    categorySet.add('cancelled');
                                  } else {
                                    categorySet.add('in progress');
                                  }
                                }

                                List<String> categories = categorySet.toList();

                                return ListView(
                                  shrinkWrap: true,
                                  children: [
                                    const Text('Sort By:'),
                                    DropdownButton<String>(
                                      value: selectedSort,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedSort = value!;
                                        });
                                      },
                                      items: [
                                        'Date: New → Old',
                                        'Date: Old → New',
                                      ].map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Category:'),
                                    if (categories.isEmpty)
                                      const Text('No categories found.')
                                    else
                                      ...categories.map(
                                        (cat) => CheckboxListTile(
                                          title: Text(cat),
                                          value: localSelected.contains(cat),
                                          onChanged: (checked) {
                                            setState(() {
                                              if (checked == true) {
                                                localSelected.add(cat);
                                              } else {
                                                localSelected.remove(cat);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            parentSetState(() {
                              selectedCategories = List.from(localSelected);
                              sortBy = selectedSort;
                              print(
                                  'APPLY PRESSED – selectedCategories: $selectedCategories');
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }

          return StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(title: Text('Search and Filtering')),
                backgroundColor: ApplicationColors.background,
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.filter_list),
                            onPressed: () =>
                                _showFilterDialog(context, setState),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText = value.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('bill_rooms')
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return Center(child: CircularProgressIndicator());

                        String currentUserId =
                            FirebaseAuth.instance.currentUser!.uid;

                        List<String> userBillRoomIds = snapshot.data!.docs
                            .where((doc) =>
                                doc.id.split('_').contains(currentUserId))
                            .map((doc) => doc.id)
                            .toList();

                        if (userBillRoomIds.isEmpty) {
                          return Center(child: Text('No transactions found.'));
                        }

                        return FutureBuilder<List<QueryDocumentSnapshot>>(
                          future: _loadAllBillsFromUserRooms(userBillRoomIds),
                          builder: (context, billsSnapshot) {
                            if (!billsSnapshot.hasData)
                              return Center(child: CircularProgressIndicator());

                            var bills = billsSnapshot.data!;

                            // Search
                            if (searchText.isNotEmpty) {
                              bills = bills.where((billDoc) {
                                final bill =
                                    billDoc.data() as Map<String, dynamic>;
                                return bill['message']
                                        ?.toString()
                                        .toLowerCase()
                                        .contains(searchText) ??
                                    false;
                              }).toList();
                            }

                            // Filter
                            if (selectedCategories.isNotEmpty) {
                              bills = bills.where((billDoc) {
                                final bill =
                                    billDoc.data() as Map<String, dynamic>;
                                final type = bill['type'] ?? '';
                                String status;
                                if (bill['completed'] == true) {
                                  status = 'completed';
                                } else if (bill['cancelled'] == true) {
                                  status = 'cancelled';
                                } else {
                                  status = 'in progress';
                                }

                                return selectedCategories.contains(type) ||
                                    selectedCategories.contains(status);
                              }).toList();
                            }

                            // Sort
                            if (sortBy == 'Date: New → Old') {
                              bills.sort((a, b) {
                                Timestamp t1 = (a.data()
                                        as Map<String, dynamic>)['timestamp'] ??
                                    Timestamp(0, 0);
                                Timestamp t2 = (b.data()
                                        as Map<String, dynamic>)['timestamp'] ??
                                    Timestamp(0, 0);
                                return t2.compareTo(t1); // Newest first
                              });
                            } else if (sortBy == 'Date: Old → New') {
                              bills.sort((a, b) {
                                Timestamp t1 = (a.data()
                                        as Map<String, dynamic>)['timestamp'] ??
                                    Timestamp(0, 0);
                                Timestamp t2 = (b.data()
                                        as Map<String, dynamic>)['timestamp'] ??
                                    Timestamp(0, 0);
                                return t1.compareTo(t2); // Oldest first
                              });
                            }

                            if (bills.isEmpty) {
                              return Center(child: Text('No matching bills.'));
                            }

                            return Expanded(
                              child: ListView.builder(
                                itemCount: bills.length,
                                itemBuilder: (context, index) {
                                  final bill = bills[index].data()
                                      as Map<String, dynamic>;
                                  final billId = bills[index].id;

                                  final currentUserId =
                                      FirebaseAuth.instance.currentUser!.uid;
                                  final senderId = bill['senderId'];
                                  final receiverId = bill['receiverId'];

                                  // Get the other user id
                                  final receiverUserID =
                                      currentUserId == senderId
                                          ? receiverId
                                          : senderId;

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(receiverUserID)
                                        .get(),
                                    builder: (context, userSnapshot) {
                                      String otherUserName = "Unknown";
                                      if (userSnapshot.hasData &&
                                          userSnapshot.data!.exists) {
                                        final userData = userSnapshot.data!
                                            .data() as Map<String, dynamic>;
                                        otherUserName =
                                            userData['username'] ?? 'Unknown';
                                      }

                                      return Container(
                                        decoration:
                                            ApplicationContainers.container1,
                                        child: ListTile(
                                          title: Text(
                                              bill['message'] ?? 'No message'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(bill['type'] ??
                                                  'Unknown type'),
                                              Text("With: $otherUserName"),
                                            ],
                                          ),
                                          trailing: Text(
                                            bill['cancelled'] == true
                                                ? '❌'
                                                : bill['completed'] == true
                                                    ? '✅'
                                                    : '🕒',
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BillScreen(
                                                  receiverUserID:
                                                      receiverUserID,
                                                  receiverUserName:
                                                      otherUserName, // ✅ always correct username
                                                  highlightedBillId: billId,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pageBody() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ApplicationColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Wallet',
          style: TextStyle(
              fontSize: 18,
              fontFamily: 'Urbanist-semibold',
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
      ),
      backgroundColor: ApplicationColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wallet/Balance/Card details ___________
            Container(
              margin: EdgeInsets.only(left: 16, right: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24), // Apply the radius
                    clipBehavior:
                        Clip.antiAliasWithSaveLayer, // Ensures smooth clipping
                    child: Image.asset(
                      "assets/card2.jpeg",
                      fit: BoxFit.cover,
                      height: 195,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get()
                            .then((snapshot) =>
                                snapshot.data()!['full_name'].toString()),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              "Error: ${snapshot.error}", // Handle errors
                              style: boldTextStyle(color: white, size: 18),
                            );
                          }
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return Text(
                                "Loading...",
                                style: boldTextStyle(color: white, size: 18),
                              );
                            default:
                              return Text(
                                "${snapshot.data!}",
                                style: boldTextStyle(color: white, size: 18),
                              );
                          }
                        },
                      ),
                      FutureBuilder<String>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get()
                            .then((snapshot) =>
                                snapshot.data()!['username'].toString()),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              "Error: ${snapshot.error}", // Handle errors
                              style: boldTextStyle(color: white),
                            );
                          }
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return Text(
                                "Loading...",
                                style: boldTextStyle(color: white),
                              );
                            default:
                              return Text(
                                "@${snapshot.data!}",
                                style: boldTextStyle(color: white),
                              );
                          }
                        },
                      ),
                      SizedBox(height: 32.toDouble()),
                      Text("Your points",
                          style: boldTextStyle(color: white.withOpacity(0.7))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<String>(
                            future: FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .get()
                                .then((snapshot) =>
                                    snapshot.data()!['points'].toString()),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  "Error: ${snapshot.error}", // Handle errors
                                  style: boldTextStyle(color: white, size: 28),
                                );
                              }

                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Text(
                                    "Loading...",
                                    style:
                                        boldTextStyle(color: white, size: 28),
                                  );
                                default:
                                  return Text(
                                    "${snapshot.data!} Point",
                                    style:
                                        boldTextStyle(color: white, size: 28),
                                  );
                              }
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConversionScreen(),
                                  ));
                            },
                            style: ApplicationButtons.button2(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.money, size: 18, color: black),
                                SizedBox(width: 4.toDouble()),
                                Text('Convert',
                                    style: primaryTextStyle(color: black)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).paddingAll(24),
                  SizedBox(height: 10.toDouble()),
                ],
              ),
            ),
            // Transactions Section ____________
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ApplicationSpacing.medium,
                  vertical: ApplicationSpacing.small),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions History',
                    style: AppTypo.heading3.copyWith(
                      color: AppTextColors.primary,
                    ),
                  ),
                  Text(
                    '_',
                    style: boldTextStyle(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ApplicationSpacing.small,
                  vertical: ApplicationSpacing.xSmall),
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () {
                      _openSearchAndFilterPage(
                          context); // 👈 this is your function
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
                onTap: () {
                  _openSearchAndFilterPage(context); // 👈 this is your function
                },
              ),
            ),

            // Showing only Transactions opened! _____________________
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bill_rooms')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No relevant bill rooms found.');
                }

                String currentUserId = FirebaseAuth.instance.currentUser!.uid;
                List<DocumentSnapshot> filteredDocs =
                    snapshot.data!.docs.where((doc) {
                  List<String> ids = doc.id.split('_');
                  return ids.contains(currentUserId);
                }).toList();

                // ✅ Sort by lastBillTimestamp descending
                filteredDocs.sort((a, b) {
                  Timestamp? t1 =
                      (a.data() as Map<String, dynamic>)['lastBillTimestamp'];
                  Timestamp? t2 =
                      (b.data() as Map<String, dynamic>)['lastBillTimestamp'];
                  return (t2?.compareTo(t1 ?? Timestamp(0, 0)) ?? 0);
                });

                if (filteredDocs.isEmpty) {
                  return Text('No relevant bill rooms found.');
                }

                return ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding:
                      EdgeInsets.only(left: 16, bottom: 16, right: 16, top: 8),
                  children: filteredDocs.map((doc) {
                    List<String> ids = doc.id.split('_');
                    String otherUserId =
                        ids.firstWhere((id) => id != currentUserId);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData)
                          return Text('Loading user info...');
                        Map<String, dynamic> userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        Map<String, dynamic> billRoomData =
                            doc.data() as Map<String, dynamic>;

                        // Check for unread bills
                        Timestamp? lastReadTimestamp =
                            billRoomData['lastReadTimestamps']?[currentUserId];
                        Timestamp? lastBillTimestamp =
                            billRoomData['lastBillTimestamp'];

                        bool hasUnread = lastBillTimestamp != null &&
                            (lastReadTimestamp == null ||
                                lastBillTimestamp
                                    .toDate()
                                    .isAfter(lastReadTimestamp.toDate()));

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BillScreen(
                                  receiverUserName:
                                      userData['username'] ?? 'Unknown',
                                  receiverUserID: otherUserId,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(nonuser,
                                  height: 40, width: 40, fit: BoxFit.cover),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('@${userData['username'] ?? 'Unknown'}',
                                      style: boldTextStyle()),
                                  SizedBox(height: 8),
                                  Text('Press here to open transactions!',
                                      style: secondaryTextStyle()),
                                ],
                              ),
                              if (hasUnread)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red, // Unread indicator
                                  ),
                                ),
                            ],
                          ).paddingSymmetric(vertical: 8),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) {
      //           return Scaffold(
      //             appBar: AppBar(title: Text('New Transaction')),
      //             body: SingleChildScrollView(
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Padding(
      //                     padding:
      //                         const EdgeInsets.symmetric(horizontal: 10),
      //                     child: General(text: 'Search'),
      //                   ),
      //                   StreamBuilder<QuerySnapshot>(
      //                     stream: FirebaseFirestore.instance
      //                         .collection('users')
      //                         .snapshots(),
      //                     builder: (context, snapshot) {
      //                       if (snapshot.hasError) {
      //                         return Text('Error Occured!');
      //                       }
      //                       if (snapshot.connectionState ==
      //                           ConnectionState.waiting) {
      //                         return Text('Loading!...');
      //                       }
      //                       return ListView(
      //                         physics:
      //                             const NeverScrollableScrollPhysics(),
      //                         shrinkWrap: true,
      //                         padding: EdgeInsets.only(
      //                             left: 16,
      //                             bottom: 16,
      //                             right: 16,
      //                             top: 8),
      //                         scrollDirection: Axis.vertical,
      //                         children: snapshot.data!.docs.map<Widget>(
      //                             (DocumentSnapshot document) {
      //                           Map<String, dynamic> data = document
      //                               .data()! as Map<String, dynamic>;
      //                           return InkWell(
      //                             onTap: () {
      //                               Navigator.push(
      //                                   context,
      //                                   MaterialPageRoute(
      //                                     builder: (context) =>
      //                                         BillScreen(
      //                                       receiverUserName:
      //                                           data['username'],
      //                                       receiverUserID: data['uid'],
      //                                     ),
      //                                   ));
      //                             },
      //                             child: Row(
      //                               crossAxisAlignment:
      //                                   CrossAxisAlignment.start,
      //                               children: [
      //                                 Image.asset(nonuser,
      //                                     height: 40,
      //                                     width: 40,
      //                                     // color: Colors.black,
      //                                     fit: BoxFit.cover),
      //                                 16.width,
      //                                 Column(
      //                                   crossAxisAlignment:
      //                                       CrossAxisAlignment.start,
      //                                   children: [
      //                                     Text('@${data['username']}',
      //                                         style: boldTextStyle()),
      //                                     8.height,
      //                                     Text('Status: ___',
      //                                         style:
      //                                             secondaryTextStyle()),
      //                                   ],
      //                                 ).expand(),
      //                                 Column(
      //                                   children: [
      //                                     Text('()point',
      //                                         style: boldTextStyle()),
      //                                     4.height,
      //                                     Row(
      //                                       children: [
      //                                         Text('Send',
      //                                             style:
      //                                                 secondaryTextStyle()),
      //                                         4.width,
      //                                         Container(
      //                                           padding:
      //                                               EdgeInsets.all(2),
      //                                           decoration:
      //                                               boxDecorationWithRoundedCorners(
      //                                             borderRadius:
      //                                                 BorderRadius.all(
      //                                                     Radius.circular(
      //                                                         2)),
      //                                             backgroundColor:
      //                                                 Colors.red,
      //                                           ),
      //                                           child: Icon(
      //                                               Icons.call_missed,
      //                                               color: white,
      //                                               size: 10),
      //                                         ),
      //                                       ],
      //                                     ),
      //                                   ],
      //                                 ),
      //                               ],
      //                             ).paddingSymmetric(vertical: 8),
      //                           );
      //                         }).toList(),
      //                       );
      //                     },
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           );
      //         },
      //       ),
      //     );
      //   },
      //   child: Icon(Icons.receipt_long),
      //   backgroundColor: Colors.blue,
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 800
        ? _pageBody()
        : Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 200,
                right: 200,
              ),
              child: _pageBody(),
            ),
          );
  }
}

class ConversionScreen extends StatefulWidget {
  @override
  _ConversionScreenState createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  TextEditingController priceController = TextEditingController();

  double walaaOneResult = 0.0;
  double stcPayResult = 0.0;
  double mobilyPayResult = 0.0;

  @override
  void initState() {
    super.initState();
    priceController.addListener(updateConversionResults);
  }

  @override
  void dispose() {
    priceController.removeListener(updateConversionResults);
    priceController.dispose();
    super.dispose();
  }

  void updateConversionResults() {
    setState(() {
      double inputPoints = double.tryParse(priceController.text) ?? 0.0;

      double riyals = inputPoints / 1500; // New: first get SAR from our points
      walaaOneResult = riyals * 500; // Then get WalaaOne points
      stcPayResult = riyals; // Same SAR value
      mobilyPayResult = riyals; // Same SAR value
    });
  }

  void _walaaOneApi() async {
    // Step 1: Validate Points Input
    if (priceController.text.isEmpty ||
        double.tryParse(priceController.text)! <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Invalid Input"),
          content: Text("Please enter a valid number of points to convert."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("OK"))
          ],
        ),
      );
      return;
    }

    double pointsToConvert = double.parse(priceController.text);
    int pointsToConvertInt = pointsToConvert.round(); // or .toInt()

    double riyals = pointsToConvert / 1500;
    double walaaOnePoints = riyals * 500;

    // ❌ Reject if WalaaOne points < 1 OR Riyals < 0.1 (required by API)
    if (walaaOnePoints < 1 || riyals < 0.1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Conversion Error"),
          content: Text("You need at least 150 points to convert to Walaaone."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("OK"))
          ],
        ),
      );
      return;
    }

    // Step 2: Retrieve User Details
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot userSnapshot;
    try {
      userSnapshot = await userRef.get();
    } catch (e) {
      print("❌ Error retrieving user data: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to retrieve user data. Please try again."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("OK"))
          ],
        ),
      );
      return;
    }

    if (!userSnapshot.exists) {
      print("❌ User not found in Firestore.");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("User account not found. Please try again."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("OK"))
          ],
        ),
      );
      return;
    }

    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    int userPoints = userData['points'] ?? 0;

    if (userPoints < pointsToConvert) {
      print("❌ Insufficient points.");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Insufficient Points"),
          content:
              Text("You don't have enough points to complete this conversion."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("OK"))
          ],
        ),
      );
      return;
    }

    // Step 3: Ask User for Phone Number
    TextEditingController phoneController = TextEditingController();
    bool proceed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter WalaaOne registered phone number:"),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: "966XXXXXXXXX"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              if (phoneController.text.isEmpty ||
                  !RegExp(r'^966\d{9}$').hasMatch(phoneController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "Please enter a valid Saudi phone number (966XXXXXXXXX).")),
                );
                return;
              }
              proceed = true;
              Navigator.pop(context);
            },
            child: Text("Proceed"),
          ),
        ],
      ),
    );

    if (!proceed) return; // Stop if user cancels input

    String phoneNumber = phoneController.text;
    String referenceID = DateTime.now().millisecondsSinceEpoch.toString();

    // Step 4: Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Processing..."),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Please wait...")
          ],
        ),
      ),
    );

    try {
      // Step 5: Send Request to API
      var response = await http.post(
        Uri.parse(
            "https://walaaoneapi-42656840839.europe-west8.run.app/send-points"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phoneNumber,
          "amount": double.parse(riyals.toStringAsFixed(2)),
        }),
      );

      Navigator.pop(context); // Close loading dialog

      var responseData = jsonDecode(response.body);
      print("API Response: ${response.body}");

      if (response.statusCode == 200 && responseData["code"] == 0) {
        // Step 6: Deduct Points & Store Transaction
        String adminId = "7DHsNu3hGYfEiKA0CCKezD6VQ0N2"; // ✅ Correct admin ID
        String billRoomId =
            [adminId, userId].join("_"); // ✅ Consistent bill room ID

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot freshUserSnapshot = await transaction.get(userRef);
          if (!freshUserSnapshot.exists) {
            throw Exception("User document does not exist.");
          }

          int updatedPoints =
              (freshUserSnapshot["points"] ?? 0) - pointsToConvertInt;
          transaction.update(userRef, {"points": updatedPoints});

          // Step 7: Store Bill Room Transaction
          DocumentReference billRoomRef = FirebaseFirestore.instance
              .collection('bill_rooms')
              .doc(billRoomId);
          CollectionReference billCollectionRef =
              billRoomRef.collection('bills');
          DocumentReference billDocRef = billCollectionRef.doc();

          Map<String, dynamic> newBillData = {
            'completed': true,
            'sending': true,
            'senderId': userId,
            'receiverId': adminId,
            'bill': pointsToConvertInt,
            'message': 'Converted $pointsToConvertInt points to WalaaOne.',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'conversion',
            'status': FieldValue.arrayUnion([
              {
                'statustext': 'Conversion Successful',
                'statustime': Timestamp.now(),
              },
            ]),
          };

          transaction.set(billDocRef, newBillData);

          await billRoomRef.set({
            'lastBillTimestamp': FieldValue.serverTimestamp(),
            'lastReadTimestamps': {
              userId: null,
              adminId: null,
            },
          }, SetOptions(merge: true));
        });

        // Step 8: Show Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Success!"),
            content: Text(
                "You have successfully converted $pointsToConvert points to $walaaOnePoints WalaaOne points."),
            actions: [
              TextButton(
                onPressed: () {
                  print("✅ User pressed OK");
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
              TextButton(
                onPressed: () {
                  print("✅ User pressed Go to Transactions");
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WalletScreen()),
                  );
                },
                child: Text("Go to Transactions"),
              ),
            ],
          ),
        );
      } else {
        // Step 9: Handle User Not Found in WalaaOne
        String errorMessage = "An error occurred.";
        if (responseData.containsKey("error") &&
            responseData["error"].containsKey("message")) {
          errorMessage = responseData["error"]["message"];

          if (errorMessage.contains("User is not found")) {
            errorMessage =
                "This phone number is not registered in WalaaOne system.";
          }
        } else if (responseData.containsKey("msg")) {
          errorMessage = responseData["msg"];
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Conversion Failed"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text("OK"))
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: editTextBgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ApplicationColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Convert point/cash',
          style: TextStyle(
              fontSize: 18,
              fontFamily: 'Urbanist-semibold',
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
      ),
      backgroundColor: ApplicationColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Avaliable points:",
                  style:
                      AppTypo.heading3.copyWith(color: AppTextColors.primary)),
              FutureBuilder<String>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get()
                    .then((snapshot) => snapshot.data()!['points'].toString()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      "Error: ${snapshot.error}", // Handle errors
                      style: boldTextStyle(size: 28),
                    );
                  }

                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Text(
                        "Loading...",
                        style: boldTextStyle(size: 28),
                      );
                    default:
                      return Text(
                        "${snapshot.data!} Point",
                        style: AppTypo.heading1
                            .copyWith(color: AppTextColors.primary),
                      );
                  }
                },
              ),
            ],
          ).paddingAll(16),
          Text(
            'Enter the amount of points you want to convert.',
            style: AppTypo.body.copyWith(color: AppTextColors.secondary),
          ).paddingOnly(
            left: 16,
            bottom: 4,
          ),
          TextFormField(
            controller: priceController,
            style: boldTextStyle(size: 26),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 20),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: black, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: black, width: 1.0),
              ),
            ),
          ).paddingAll(16),
          SizedBox(height: 12.toDouble()),
          Text(
            'Select the payment method you want to use.',
            style: AppTypo.body.copyWith(color: AppTextColors.secondary),
          ).paddingOnly(left: 16, bottom: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                        vertical: ApplicationSpacing.small,
                        horizontal: ApplicationSpacing.medium),
                    padding: EdgeInsets.all(ApplicationSpacing.medium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            spreadRadius: 2),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/walaaone.png',
                                height: 40, width: 40, fit: BoxFit.cover),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Walaa One',
                                    style: AppTypo.heading3.copyWith(
                                        color: AppTextColors.primary)),
                                SizedBox(height: 4),
                                SizedBox(
                                  width:
                                      150, // Adjust width to control text space
                                  child: Text(
                                    "You'll get: ${walaaOneResult.toStringAsFixed(2)} Point",
                                    style: AppTypo.body.copyWith(
                                        color: AppTextColors.secondary),
                                    overflow: TextOverflow
                                        .ellipsis, // Truncate with "..."
                                    maxLines:
                                        1, // Ensures text stays on one line
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _walaaOneApi,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: ApplicationSpacing.small,
                                horizontal: ApplicationSpacing.medium),
                            decoration: BoxDecoration(
                              color: ApplicationColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("Convert",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Container(
                  //   margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                  //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //           color: Colors.grey.shade200,
                  //           blurRadius: 5,
                  //           spreadRadius: 2),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Image.asset('assets/stcpaypic.jpg',
                  //               height: 40, width: 40, fit: BoxFit.cover),
                  //           SizedBox(width: 16),
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text('STC pay', style: boldTextStyle()),
                  //               SizedBox(height: 4),
                  //               SizedBox(
                  //                 width:
                  //                     150, // Adjust width to control text space
                  //                 child: Text(
                  //                   "You get: ${stcPayResult.toStringAsFixed(2)} SAR",
                  //                   style: secondaryTextStyle(
                  //                       size: 14, color: Colors.grey),
                  //                   overflow: TextOverflow
                  //                       .ellipsis, // Truncate with "..."
                  //                   maxLines:
                  //                       1, // Ensures text stays on one line
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //       GestureDetector(
                  //         onTap: () {},
                  //         child: Container(
                  //           padding: EdgeInsets.symmetric(
                  //               vertical: 8, horizontal: 12),
                  //           decoration: BoxDecoration(
                  //             color: Colors.black,
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           child: Text("Convert",
                  //               style: TextStyle(
                  //                   color: Colors.white, fontSize: 14)),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Container(
                  //   margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                  //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //           color: Colors.grey.shade200,
                  //           blurRadius: 5,
                  //           spreadRadius: 2),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Image.asset('assets/mpay2.png',
                  //               height: 40, width: 40, fit: BoxFit.cover),
                  //           SizedBox(width: 16),
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text('Mobily pay', style: boldTextStyle()),
                  //               SizedBox(height: 4),
                  //               SizedBox(
                  //                 width:
                  //                     150, // Adjust width to control text space
                  //                 child: Text(
                  //                   "You get: ${mobilyPayResult.toStringAsFixed(2)} SAR",
                  //                   style: secondaryTextStyle(
                  //                       size: 14, color: Colors.grey),
                  //                   overflow: TextOverflow
                  //                       .ellipsis, // Truncate with "..."
                  //                   maxLines:
                  //                       1, // Ensures text stays on one line
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //       GestureDetector(
                  //         onTap: () {},
                  //         child: Container(
                  //           padding: EdgeInsets.symmetric(
                  //               vertical: 8, horizontal: 12),
                  //           decoration: BoxDecoration(
                  //             color: Colors.black,
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           child: Text("Convert",
                  //               style: TextStyle(
                  //                   color: Colors.white, fontSize: 14)),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Container(
                  //   margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                  //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //           color: Colors.grey.shade200,
                  //           blurRadius: 5,
                  //           spreadRadius: 2),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Image.asset('assets/ic_wallet.png',
                  //               height: 40, width: 40, fit: BoxFit.cover),
                  //           SizedBox(width: 16),
                  //           Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text('My Wallet', style: boldTextStyle()),
                  //               SizedBox(height: 4),
                  //               Text(
                  //                 "You get: 0.00 SAR",
                  //                 style: secondaryTextStyle(
                  //                     size: 14, color: Colors.grey),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //       GestureDetector(
                  //         onTap: () {},
                  //         child: Container(
                  //           padding: EdgeInsets.symmetric(
                  //               vertical: 8, horizontal: 12),
                  //           decoration: BoxDecoration(
                  //             color: Colors.black,
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           child: Text("Convert",
                  //               style: TextStyle(
                  //                   color: Colors.white, fontSize: 14)),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BillScreen extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserID;
  final String? highlightedBillId;
  const BillScreen(
      {super.key,
      required this.receiverUserName,
      required this.receiverUserID,
      this.highlightedBillId});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final TextEditingController _billController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = true;
  List<TextEditingController> _statusControllers = <TextEditingController>[];
  String? _highlightedBillId;

  @override
  void dispose() {
    _billController.dispose();
    _messageController.dispose();
    for (var controller in _statusControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _highlightedBillId = widget.highlightedBillId;
  }

  // void _scrollToBottom() {
  //   if (_scrollController.hasClients) {
  //     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  //   }
  // }

  // Send bill
  Future<void> _submitBill() async {
    if (_billController.text.isNotEmpty) {
      // get user info
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final String currentUserEmail =
          FirebaseAuth.instance.currentUser!.email.toString();
      final Timestamp timestamp = Timestamp.now();

      // Create New message
      Bill newBill = Bill(
        completed: false,
        sending: _isSending,
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: widget.receiverUserID,
        bill: _billController.text,
        message: _messageController.text,
        status:
            _statusControllers.map((controller) => controller.text).toList(),
        timestamp: timestamp,
      );

      // build chat room id
      List<String> ids = [currentUserId, widget.receiverUserID];
      ids.sort();
      String billRoomId = ids.join("_");

      // Send to firebase
      await FirebaseFirestore.instance
          .collection('bill_rooms')
          .doc(billRoomId)
          .collection('bills')
          .add(newBill.toMap());
    }

    _messageController.clear();
    _billController.clear();
    _statusControllers.forEach((controller) => controller.clear());
  }

  // Get bill
  Stream<QuerySnapshot> _getBill() {
    // build billroom Id
    List<String> ids = [
      widget.receiverUserID,
      FirebaseAuth.instance.currentUser!.uid
    ];
    ids.sort();
    String billRoomId = ids.join("_");

    // get the bills
    return FirebaseFirestore.instance
        .collection('bill_rooms')
        .doc(billRoomId)
        .collection('bills')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> _getDriverBills(String userZone) {
    // Build billRoom ID for drivers to access specific bill room with zone filter
    List<String> ids = [
      widget.receiverUserID,
      '7DHsNu3hGYfEiKA0CCKezD6VQ0N2' // Assuming driver is viewing admin bill rooms
    ];
    ids.sort();
    String billRoomId = ids.join("_");

    // Fetch only bills with the matching zone for the driver
    return FirebaseFirestore.instance
        .collection('bill_rooms')
        .doc(billRoomId)
        .collection('bills')
        .where('zone', isEqualTo: userZone)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  List img = [
    'assets/images/chat1.png',
    'assets/images/chat2.png',
    'assets/images/chat3.png',
    'assets/images/chat4.png',
    'assets/images/chat5.png',
    'assets/images/chat6.png',
  ];
  List text = [
    'Camera',
    'Galery',
    'Document',
    'Audio',
    'Location',
    'Contact',
  ];

  var selectIndex = [];

  changeValue({int? value}) {
    setState(() {
      if (selectIndex.contains(value)) {
        selectIndex.remove(value);
      } else {
        selectIndex.add(value);
      }
    });
  }

  List instastory1 = [
    "assets/images/lesserlogo.png",
    "assets/images/lesserlogo.png",
    "assets/images/lesserlogo.png",
    "assets/images/lesserlogo.png",
  ];

  List text1 = [
    'The order Completed!',
    'Captain in his way!',
    'The shipment has been received!',
    'The whole process finsihed!',
  ];
  List subtitle = [
    'Status 1',
    'Status 2',
    'Status 3',
    'Status 4',
  ];
  List time = [
    '2 min ago',
    '5 min ago',
    '10 min ago',
    '20 min ago',
  ];

  void _openBillDetailsScreen({
    required DocumentSnapshot document,
    required Map<String, dynamic> data,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              FocusScope.of(context).unfocus();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                backgroundColor: ApplicationColors.background,
              ),
              backgroundColor: ApplicationColors.background,
              body: SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Details _______
                      ListTile(
                        contentPadding: EdgeInsets.only(left: 16),
                        leading: Image(
                            image: AssetImage("assets/images/lesserlogo.png"),
                            height: 50,
                            width: 50),
                        title: Text(widget.receiverUserName,
                            style: boldTextStyle()),
                        // subtitle: Text(
                        //     "Official Account of Lesser ✔",
                        //     style:
                        //         secondaryTextStyle()),
                        trailing: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        receiverUserName:
                                            widget.receiverUserName ??
                                                'Unknown',
                                        receiverUserID: widget.receiverUserID,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.message_rounded, size: 20),
                              ),
                              // IconButton(
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => ChatScreen(
                              //           receiverUserName:
                              //               widget.receiverUserName ??
                              //                   'Unknown',
                              //           receiverUserID: widget.receiverUserID,
                              //         ),
                              //       ),
                              //     );
                              //   },
                              //   icon: Icon(Icons.call, size: 20),
                              // ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Billing number ________
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text("Booking number: ${document.id}",
                            style: boldTextStyle(size: 20)),
                      ),
                      SizedBox(height: 15),
                      // Price and confirmation _______
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: Text("Price", style: boldTextStyle())),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("${data['bill']} Point",
                                style: boldTextStyle(size: 18)),
                            SizedBox(width: 50),
                            if (data['cancelled'] == true)
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 42),
                                  margin: EdgeInsets.all(8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  child: Text('Cancelled',
                                      style: boldTextStyle(color: white)),
                                ),
                              )
                            else if (data['completed'] == true)
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 42),
                                  margin: EdgeInsets.all(8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  child: Text('Completed!',
                                      style: boldTextStyle(color: white)),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  _payNow(
                                      widget.receiverUserID, document.id, data);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 42),
                                  margin: EdgeInsets.all(8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  child: Text('Edit booking!',
                                      style: boldTextStyle(color: white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Product/sevice description and bio ________
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: Text('Details', style: boldTextStyle())),
                      ),
                      SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          style: secondaryTextStyle(),
                          text: data['message'],
                        ),
                      ).paddingOnly(right: 16, left: 16),
                      const SizedBox(height: 20),
                      // Map and location details ________
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text('Map', style: boldTextStyle()),
                        ),
                      ),
                      SizedBox(height: 10),
                      if (data['latitude'] != null &&
                          data['longitude'] != null &&
                          data['locationName'] != null)
                        Container(
                          height: 200, // Set the height of the map
                          width:
                              double.infinity, // Make the map take full width
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target:
                                    LatLng(data['latitude'], data['longitude']),
                                zoom: 15, // Adjust the zoom level as needed
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId('bill_location'),
                                  position: LatLng(
                                      data['latitude'], data['longitude']),
                                  icon: BitmapDescriptor
                                      .defaultMarker, // or your custom icon if used
                                  consumeTapEvents: true,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              data['locationName'] ?? '',
                                            ),
                                            if ((data['locationDetails'] ?? '')
                                                .toString()
                                                .trim()
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: Text(
                                                  data['locationDetails'],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        content: Text(
                                            'Open this location in Google Maps?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);

                                              final Uri googleMapsUrl =
                                                  Uri.parse(
                                                'https://www.google.com/maps/search/?api=1&query=${data['latitude']},${data['longitude']}',
                                              );

                                              if (await canLaunchUrl(
                                                  googleMapsUrl)) {
                                                await launchUrl(googleMapsUrl,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Could not open Google Maps.')),
                                                );
                                              }
                                            },
                                            child: Text('Open'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Text(
                            'Location details are not available.',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 20),
                      // Status order _________
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text(
                                'Bill Status',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Urbanist-semibold',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: (data['status'] ?? [])
                                  .length, // Accessing status updates
                              itemBuilder: (context, index) {
                                var statusEntry = data['status'][index];
                                var statusText = statusEntry['statustext'];
                                var statusTime =
                                    statusEntry['statustime'] as Timestamp;
                                var formattedTime =
                                    intl.DateFormat('yyyy-MM-dd HH:mm:ss')
                                        .format(statusTime.toDate());

                                return Column(
                                  children: [
                                    ListTile(
                                      leading: Image.asset(
                                        instastory1[
                                            index], // Replace instastory1 with actual list of icons if needed
                                        height: 30,
                                        width: 30,
                                      ),
                                      title: Text(
                                        statusText, // Dynamic status text now as title
                                        style: const TextStyle(
                                          fontFamily: 'Urbanist-semibold',
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        subtitle[
                                            index], // Keeping original subtitle as is
                                        style: const TextStyle(
                                          fontFamily: 'Urbanist-medium',
                                        ),
                                      ),
                                      trailing: Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontFamily: 'Urbanist-medium',
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    // Padding(
                                    //   padding: const EdgeInsets.only(left: 20),
                                    //   child: Row(
                                    //     mainAxisAlignment:
                                    //         MainAxisAlignment.start,
                                    //     children: [
                                    //       InkWell(
                                    //         onTap: () {
                                    //           changeValue(
                                    //               value:
                                    //                   index); // Function to handle "like"
                                    //         },
                                    //         child: Image.asset(
                                    //           selectIndex.contains(index)
                                    //               ? 'assets/images/heart2.png'
                                    //               : 'assets/images/hearts.png',
                                    //           height: 15,
                                    //           width: 15,
                                    //         ),
                                    //       ),
                                    //       const SizedBox(width: 10),
                                    //       Image.asset(
                                    //         'assets/images/comment.png',
                                    //         height: 15,
                                    //         width: 15,
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _payNow(
      String receiverUid, String documentId, Map<String, dynamic> data) async {
    // 🔒 Block UI immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Fetch current user's role
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    String userRole = userDoc['role'] ?? '';

    // ✅ Close initial loading
    Navigator.of(context, rootNavigator: true).pop();

    // Handle user (non-driver)
    if (userRole != 'driver') {
      bool cancel = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cancel Order'),
          content:
              Text('The order is being processed. Do you want to cancel it?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes, Cancel')),
          ],
        ),
      );

      if (cancel == true) {
        List<String> ids = [
          receiverUid,
          FirebaseAuth.instance.currentUser!.uid
        ];
        ids.sort();
        String billRoomId = ids.join("_");

        await FirebaseFirestore.instance
            .collection('bill_rooms')
            .doc(billRoomId)
            .collection('bills')
            .doc(documentId)
            .update({
          'cancelled': true,
          'status': FieldValue.arrayUnion([
            {
              'statustext': 'Order Cancelled by User',
              'statustime': Timestamp.now(),
            },
          ]),
        });

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Cancelled'),
            content: Text('Your order has been cancelled.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        Navigator.of(context).pop(); // Back to bill list
      }
      return;
    }

    // Show driver actions
    String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Action Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.of(context).pop('confirm'),
              child: Text('✅ Confirm Order'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.of(context).pop('edit'),
              child: Text('✏️ Edit Order'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text('❌ Cancel Order'),
            ),
          ],
        ),
      ),
    );

    // Build billRoomId between user and driver
    List<String> ids = [receiverUid, FirebaseAuth.instance.currentUser!.uid];
    ids.sort();
    String billRoomId = ids.join("_");

    if (action == 'cancel') {
      await FirebaseFirestore.instance
          .collection('bill_rooms')
          .doc(billRoomId)
          .collection('bills')
          .doc(documentId)
          .update({
        'cancelled': true,
        'status': FieldValue.arrayUnion([
          {
            'statustext': 'Order Cancelled by Driver',
            'statustime': Timestamp.now(),
          },
        ]),
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Cancelled'),
          content: Text('Order has been cancelled successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      Navigator.of(context).pop(); // Back to bill list
      return;
    } else if (action == 'edit') {
      final totalKgsController =
          TextEditingController(text: data['totalKgs'].toString());
      final billController =
          TextEditingController(text: data['bill'].toString());
      final messageController =
          TextEditingController(text: data['message'] ?? '');

      bool edited = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalKgsController,
                decoration: InputDecoration(labelText: 'Total KGs'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: billController,
                decoration: InputDecoration(labelText: 'Points (bill)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: messageController,
                decoration: InputDecoration(labelText: 'Message'),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Save')),
          ],
        ),
      );

      if (edited == true) {
        await FirebaseFirestore.instance
            .collection('bill_rooms')
            .doc(billRoomId)
            .collection('bills')
            .doc(documentId)
            .update({
          'totalKgs':
              double.tryParse(totalKgsController.text) ?? data['totalKgs'],
          'bill': int.tryParse(billController.text) ?? data['bill'],
          'message': messageController.text,
          'status': FieldValue.arrayUnion([
            {
              'statustext': 'Driver edited order metadata',
              'statustime': Timestamp.now(),
            },
          ]),
        });

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Updated'),
            content: Text('Order data was updated successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

        Navigator.of(context).pop(); // Back to bill list
      }
      return;
    } else if (action == 'confirm') {
      // processing ___
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('bill_rooms')
            .doc(billRoomId)
            .collection('bills')
            .doc(documentId)
            .update({
          'completed': true,
          'status': FieldValue.arrayUnion([
            {
              'statustext': 'Order Confirmed',
              'statustime': Timestamp.now(),
            },
          ]),
        });

        int points = data['bill'];
        int totalKgs = data['totalKgs'];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUid)
            .update({
          'points': FieldValue.increment(points),
          'waste': FieldValue.increment(totalKgs),
        });

        // 🧠 Multi-timeframe score logic
        final now = DateTime.now();
        Map<String, String> timeframes = {
          'all_time': 'all_time',
          'monthly': '${now.year}-${now.month.toString().padLeft(2, '0')}',
          'weekly': () {
            final firstDayOfYear = DateTime(now.year, 1, 1);
            final daysOffset = firstDayOfYear.weekday - 1;
            final firstMonday =
                firstDayOfYear.subtract(Duration(days: daysOffset));
            final diff = now.difference(firstMonday);
            final weekNumber = ((diff.inDays + 1) / 7).ceil();
            return '${now.year}-W$weekNumber';
          }(),
          'daily':
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'hourly':
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}',
        };

        final locationOwner = data['locationOwner'];
        final locationId = data['locationId'];
        final subfileId = data['subfileId'] ?? 'root';

        if (locationOwner != null && locationId != null) {
          if (locationOwner == receiverUid) {
            // 🔷 Public leaderboard
            for (final timeframeId in timeframes.values) {
              final memberRef = FirebaseFirestore.instance
                  .collection('relations')
                  .doc('oTrF3pYeDJPkYUyxMdFU')
                  .collection('timeframes')
                  .doc(timeframeId)
                  .collection('members')
                  .doc(receiverUid);

              await memberRef.set({
                'uid': receiverUid,
                'username': userDoc['username'] ?? '',
                'score': FieldValue.increment(points),
                'trophies': 0,
                'joinedAt': FieldValue.serverTimestamp(),
                'role': 'member',
              }, SetOptions(merge: true));
            }
          } else {
            // 🟡 Private leaderboard (group + member)
            for (final timeframeId in timeframes.values) {
              final memberRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(locationOwner)
                  .collection('locations')
                  .doc(locationId)
                  .collection('subfiles')
                  .doc(subfileId)
                  .collection('timeframes')
                  .doc(timeframeId)
                  .collection('members')
                  .doc(receiverUid);

              final groupRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(locationOwner)
                  .collection('locations')
                  .doc(locationId)
                  .collection('timeframes')
                  .doc(timeframeId)
                  .collection('groups')
                  .doc(subfileId);

              await FirebaseFirestore.instance.runTransaction((txn) async {
                txn.set(
                    memberRef,
                    {
                      'uid': receiverUid,
                      'username': userDoc['username'] ?? '',
                      'score': FieldValue.increment(points),
                      'trophies': 0,
                      'joinedAt': FieldValue.serverTimestamp(),
                      'role': 'member',
                    },
                    SetOptions(merge: true));

                txn.set(
                    groupRef,
                    {
                      'uid': subfileId,
                      'username': data['locationName'] ?? '',
                      'score': FieldValue.increment(points),
                      'trophies': 0,
                      'joinedAt': FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true));
              });
            }
          }
        }

        Navigator.of(context).pop();

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Order Confirmed'),
            content: Text('Order confirmed and points transferred!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );

        Navigator.of(context).pop(); // Back to bill list
      } catch (error) {
        Navigator.of(context).pop(); // Close loading
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to confirm order. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _pageBody() {
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ApplicationColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/nonuser.png'),
            ),
            SizedBox(width: 8),
            Text(
              widget.receiverUserName,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBill(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text('No bills found.');
          }

          // Fetch the last read timestamp for the current user or driver
          final billRoomId = [
            FirebaseAuth.instance.currentUser!.uid,
            widget.receiverUserID
          ];
          billRoomId.sort();
          final billRoomDocRef = FirebaseFirestore.instance
              .collection('bill_rooms')
              .doc(billRoomId.join("_"));

          return FutureBuilder<DocumentSnapshot>(
            future: billRoomDocRef.get(),
            builder: (context, billRoomSnapshot) {
              if (!billRoomSnapshot.hasData || !billRoomSnapshot.data!.exists) {
                return Text('No bills found..');
              }

              final billRoomData =
                  billRoomSnapshot.data!.data() as Map<String, dynamic>;
              final Timestamp? lastReadTimestamp =
                  billRoomData['lastReadTimestamps']
                      ?[FirebaseAuth.instance.currentUser!.uid];

              if (_highlightedBillId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final index = snapshot.data!.docs
                      .indexWhere((doc) => doc.id == _highlightedBillId);
                  if (index != -1 && _scrollController.hasClients) {
                    final position =
                        (snapshot.data!.docs.length - 1 - index) * 180.0;
                    _scrollController.animateTo(
                      position,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }

              // List of bills for specific user _________
              return ListView(
                controller: _scrollController,
                reverse: true,
                children: snapshot.data!.docs.reversed.map((document) {
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  final Timestamp billTimestamp = data['timestamp'];

                  // Determine id it's highlighted
                  final isHighlighted = document.id == _highlightedBillId;

                  // Determine if the message is unread
                  bool isUnread = lastReadTimestamp == null ||
                      billTimestamp
                          .toDate()
                          .isAfter(lastReadTimestamp.toDate());
                  var alignment = (data['senderId'] ==
                          FirebaseAuth.instance.currentUser!.uid)
                      ? Alignment.centerRight
                      : Alignment.centerLeft;

                  return Container(
                    color:
                        isHighlighted ? Colors.yellow.withOpacity(0.3) : null,
                    alignment: alignment,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Indicator for unread messages
                            if (isUnread)
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: Colors
                                      .red, // Red indicator for unread messages
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Message bubble
                            Text(
                              intl.DateFormat('yyyy-MM-dd | HH:mm:ss').format(
                                (data['timestamp'] as Timestamp).toDate(),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          // Bill details screen/widget ________
                          onTap: () async {
                            // Mark messages as read when bill is opened
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              await FirebaseFirestore.instance
                                  .collection('bill_rooms')
                                  .doc(billRoomId.join(
                                      "_")) // Ensure this matches your bill room logic
                                  .update({
                                'lastReadTimestamps.${FirebaseAuth.instance.currentUser!.uid}':
                                    Timestamp.now(),
                              });
                            });
                            // Open the bill details screen
                            _openBillDetailsScreen(
                              document: document,
                              data: data,
                            );
                          },
                          // Bills List screen/widget ________
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: ApplicationContainers.container1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text("${data['message']}",
                                //     style: boldTextStyle()),
                                SizedBox(height: 8),
                                Text(document.id, style: secondaryTextStyle()),
                                Text("${data['bill']} Point",
                                    style: boldTextStyle()),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Status:',
                                        style: boldTextStyle()), // Label
                                    SizedBox(width: 4),
                                    Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: data['cancelled'] == true
                                            ? Colors.red
                                            : data['completed'] == true
                                                ? Colors.green
                                                : Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            data['cancelled'] == true
                                                ? Icons.cancel
                                                : data['completed'] == true
                                                    ? Icons.check_circle
                                                    : Icons.hourglass_empty,
                                            color: white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            data['cancelled'] == true
                                                ? 'Cancelled'
                                                : data['completed'] == true
                                                    ? 'Completed'
                                                    : 'In Progress',
                                            style: boldTextStyle(
                                                size: 14, color: white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text("Transaction type: ${data['type']}",
                                    style: boldTextStyle()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      // bottomNavigationBar: Container(
      //   height: _statusControllers.length == 0 ? 180 : 300,
      //   color: Colors.white,
      //   child: Center(
      //     child: SingleChildScrollView(
      //       child: ListTile(
      //         leading: Container(
      //           height: 36,
      //           width: 36,
      //           decoration: BoxDecoration(
      //               image: const DecorationImage(
      //                 image: AssetImage(
      //                   'assets/images/nonuser.png',
      //                 ),
      //               ),
      //               borderRadius: BorderRadius.circular(100)),
      //         ),
      //         title: Column(
      //           children: [
      //             Row(
      //               children: [
      //                 Expanded(
      //                   child: Text(
      //                     'Request',
      //                     textAlign: TextAlign.center,
      //                     style: TextStyle(
      //                         color: Colors.black,
      //                         fontSize: 15,
      //                         fontWeight: FontWeight.w600),
      //                   ),
      //                 ),
      //                 SizedBox(width: 2),
      //                 Switch(
      //                   value: _isSending,
      //                   onChanged: (value) {
      //                     setState(() {
      //                       _isSending = value;
      //                     });
      //                   },
      //                 ),
      //                 SizedBox(width: 2),
      //                 Expanded(
      //                   child: Text(
      //                     'Send',
      //                     textAlign: TextAlign.center,
      //                     style: TextStyle(
      //                         color: Colors.black,
      //                         fontSize: 15,
      //                         fontWeight: FontWeight.w600),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //             TextField(
      //               controller: _billController,
      //               style: const TextStyle(color: Colors.black),
      //               decoration: InputDecoration(
      //                 enabledBorder: OutlineInputBorder(
      //                   borderSide:
      //                       BorderSide(color: Colors.grey.shade300),
      //                 ),
      //                 focusedBorder: OutlineInputBorder(
      //                   borderSide:
      //                       BorderSide(color: Colors.grey.shade300),
      //                 ),
      //                 contentPadding:
      //                     const EdgeInsets.symmetric(horizontal: 10),
      //                 hintText: 'How much?...',
      //                 hintStyle: const TextStyle(
      //                     color: Color(0xffCBD5E1),
      //                     fontFamily: 'Urbanist-medium',
      //                     fontWeight: FontWeight.w500),
      //                 border: OutlineInputBorder(
      //                   borderRadius: BorderRadius.circular(12),
      //                 ),
      //               ),
      //             ),
      //             TextField(
      //               controller: _messageController,
      //               style: const TextStyle(color: Colors.black),
      //               maxLines: null,
      //               decoration: InputDecoration(
      //                 enabledBorder: OutlineInputBorder(
      //                   borderSide:
      //                       BorderSide(color: Colors.grey.shade300),
      //                 ),
      //                 focusedBorder: OutlineInputBorder(
      //                   borderSide:
      //                       BorderSide(color: Colors.grey.shade300),
      //                 ),
      //                 contentPadding:
      //                     const EdgeInsets.symmetric(horizontal: 10),
      //                 hintText: 'Details (Optionally)',
      //                 hintStyle: const TextStyle(
      //                     color: Color(0xffCBD5E1),
      //                     fontFamily: 'Urbanist-medium',
      //                     fontWeight: FontWeight.w500),
      //                 border: OutlineInputBorder(
      //                   borderRadius: BorderRadius.circular(12),
      //                 ),
      //               ),
      //             ),
      //             if (_statusControllers.length <
      //                 5) // Conditionally show the add button
      //               TextButton(
      //                 onPressed: () {
      //                   setState(() {
      //                     if (_statusControllers.length < 5) {
      //                       _statusControllers
      //                           .add(TextEditingController());
      //                     }
      //                   });
      //                 },
      //                 child: Text('+ Add bill status +',
      //                     style: Theme.of(context).textTheme.bodyMedium),
      //               ),
      //             ..._statusControllers.asMap().entries.map((entry) {
      //               final index = entry.key;
      //               final controller = entry.value;
      //               return Row(
      //                 children: [
      //                   Expanded(
      //                     child: TextField(
      //                       controller: controller,
      //                       style: TextStyle(color: Colors.black),
      //                       decoration: InputDecoration(
      //                         enabledBorder: OutlineInputBorder(
      //                           borderSide: BorderSide(
      //                               color: Colors.grey.shade300),
      //                         ),
      //                         focusedBorder: OutlineInputBorder(
      //                           borderSide: BorderSide(
      //                               color: Colors.grey.shade300),
      //                         ),
      //                         contentPadding: const EdgeInsets.symmetric(
      //                             horizontal: 10),
      //                         hintText: 'Bill Status',
      //                         hintStyle: TextStyle(
      //                           color: Color(0xffCBD5E1),
      //                           fontFamily: 'Urbanist-medium',
      //                           fontWeight: FontWeight.w500,
      //                         ),
      //                         border: OutlineInputBorder(
      //                           borderRadius: BorderRadius.circular(12),
      //                         ),
      //                       ),
      //                     ),
      //                   ),
      //                   IconButton(
      //                     icon: Icon(Icons.remove),
      //                     onPressed: () {
      //                       setState(() {
      //                         _statusControllers.removeAt(index);
      //                       });
      //                     },
      //                   ),
      //                 ],
      //               );
      //             }).toList(),
      //           ],
      //         ),
      //         trailing: SizedBox(
      //           height: 40,
      //           width: 40,
      //           child: FloatingActionButton(
      //             heroTag: null,
      //             backgroundColor: const Color(0xff3BBAA6),
      //             elevation: 0,
      //             onPressed: _submitBill,
      //             child: Image.asset(
      //               'assets/images/send.png',
      //               height: 24,
      //               width: 24,
      //               color: Colors.white,
      //             ),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 800
        ? _pageBody()
        : Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 200,
                right: 200,
              ),
              child: _pageBody(),
            ),
          );
  }
}

class Bill {
  final bool completed;
  final bool sending;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String bill;
  final String message;
  final status;
  final Timestamp timestamp;

  Bill(
      {required this.completed,
      required this.sending,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.bill,
      required this.message,
      required this.status,
      required this.timestamp});

  // convert to map
  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'sending': sending,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'bill': bill,
      'message': message,
      'status': status,
      'timestamp': timestamp,
    };
  }
}

// ________________________________________________
// NetPage Section || Widget 2
// ________________________________________________

class NetPageWidget extends StatefulWidget {
  const NetPageWidget({super.key});

  @override
  State<NetPageWidget> createState() => _NetPageWidgetState();
}

class _NetPageWidgetState extends State<NetPageWidget> {
  @override
  void initState() {
    super.initState();
    // loadRelationPages();
  }

  // Posts Functions and Vars area ____________________

  String dropdownValue = 'All Posts'; // Default dropdown value
  String searchText = ''; // Text for search bar
  final TextEditingController searchController = TextEditingController();
  String sortBy = 'Date'; // Default sorting option
  String filterCategory = ''; // Default category (empty means no filter)

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Local state for filter options
            String selectedSort = 'Date'; // Default sort option
            String selectedCategory = ''; // Selected category
            List<String> categories = []; // Categories fetched dynamically

            // Fetch categories dynamically (Example)
            if (categories.isEmpty) {
              FirebaseFirestore.instance
                  .collection('posts')
                  .get()
                  .then((querySnapshot) {
                final uniqueCategories = querySnapshot.docs
                    .map((doc) => doc['category'] as String?)
                    .where(
                        (category) => category != null && category.isNotEmpty)
                    .toSet()
                    .toList();
                setState(() {
                  //  categories = uniqueCategories;
                });
              });
            }

            return AlertDialog(
              title: Text('Filter Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Filter
                  Text('Sort By:'),
                  DropdownButton<String>(
                    value: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                    items: ['Date', 'Price', 'Most Liked'].map((sortOption) {
                      return DropdownMenuItem<String>(
                        value: sortOption,
                        child: Text(sortOption),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  Text('Category:'),
                  DropdownButton<String>(
                    value:
                        selectedCategory.isNotEmpty ? selectedCategory : null,
                    hint: Text('Select a Category'),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog without applying
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Apply filters
                    setState(() {
                      // Store the selected sort and category for filtering
                      sortBy = selectedSort;
                      filterCategory = selectedCategory;
                    });
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void toggleLike(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final userLikesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('likes')
        .doc(postId);

    bool isNewLike = false;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final userLikedSnapshot = await transaction.get(userLikesRef);

      if (userLikedSnapshot.exists) {
        // Unlike
        transaction.delete(userLikesRef);
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        transaction.set(userLikesRef, {
          'timeStamp': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(1),
        });
        isNewLike = true;
      }
    });

    // ✅ Add score after the like was successful
    if (isNewLike) {
      final now = DateTime.now();

      Map<String, String> timeframes = {
        'all_time': 'all_time',
        'monthly': '${now.year}-${now.month.toString().padLeft(2, '0')}',
        'weekly': () {
          final firstDayOfYear = DateTime(now.year, 1, 1);
          final daysOffset = firstDayOfYear.weekday - 1;
          final firstMonday =
              firstDayOfYear.subtract(Duration(days: daysOffset));
          final diff = now.difference(firstMonday);
          final weekNumber = ((diff.inDays + 1) / 7).ceil();
          return '${now.year}-W$weekNumber';
        }(),
        'daily':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'hourly':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}',
      };

      for (final timeframeId in timeframes.values) {
        final memberRef = FirebaseFirestore.instance
            .collection('relations')
            .doc('oTrF3pYeDJPkYUyxMdFU')
            .collection('timeframes')
            .doc(timeframeId)
            .collection('members')
            .doc(userId);

        final memberSnapshot = await memberRef.get();

        if (memberSnapshot.exists) {
          await memberRef.update({
            'score': FieldValue.increment(5),
          });
        } else {
          await memberRef.set({
            'score': 5,
            'trophies': 0,
            'joinedAt': FieldValue.serverTimestamp(),
            'role': 'member',
          });
        }
      }
    }
  }

  Future<void> _addPostOrRelation() async {
    // Show the alert dialog with fields for product name, price, and images
    final postContentController = TextEditingController();
    final postDiscController = TextEditingController();
    final postImages = <String>[]; // List to store product image URLs

    // Use the latest file_picker version
    final filePicker = await FilePicker.platform;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add post/relation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: postContentController,
                      decoration:
                          const InputDecoration(hintText: 'Post Header'),
                    ),
                    TextField(
                      controller: postDiscController,
                      decoration: const InputDecoration(hintText: 'Post Body'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () async {
                        final result = await filePicker.pickFiles(
                          allowMultiple: true,
                          type: FileType.image,
                        );
                        if (result != null) {
                          for (final pickedFile in result.files) {
                            final file = kIsWeb
                                ? File.fromRawPath(pickedFile.bytes!)
                                : File(pickedFile.path!);

                            String contentType;
                            if (!kIsWeb) {
                              if (pickedFile.path!
                                      .toLowerCase()
                                      .endsWith('.jpg') ||
                                  pickedFile.path!
                                      .toLowerCase()
                                      .endsWith('.jpeg')) {
                                contentType = 'image/jpeg';
                              } else if (pickedFile.path!
                                  .toLowerCase()
                                  .endsWith('.png')) {
                                contentType = 'image/png';
                              } else {
                                contentType = 'application/octet-stream';
                              }
                            } else {
                              final bytes = pickedFile.bytes!;
                              if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
                                contentType = 'image/jpeg';
                              } else if (bytes[0] == 0x89 && bytes[1] == 0x50) {
                                contentType = 'image/png';
                              } else {
                                contentType = 'application/octet-stream';
                              }
                            }

                            final imageRef = FirebaseStorage.instance.ref().child(
                                'post_images/${DateTime.now().millisecondsSinceEpoch}.png');
                            final uploadTask = kIsWeb
                                ? imageRef.putData(
                                    pickedFile.bytes!,
                                    SettableMetadata(contentType: contentType),
                                  )
                                : imageRef.putFile(
                                    file,
                                    SettableMetadata(contentType: contentType),
                                  );

                            final url =
                                await (await uploadTask).ref.getDownloadURL();

                            postImages.add(url);
                            setState(() {});
                          }
                        }
                      },
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: postImages.length,
                      itemBuilder: (context, index) {
                        final imageUrl = postImages[index];
                        return Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              height: 50,
                              width: 50,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    postImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  color: Colors.red,
                                  child: Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Send the product data to Firestore
                    await FirebaseFirestore.instance.collection('posts').add({
                      'postHeader': postContentController.text,
                      'postBody': postDiscController.text,
                      'postImages': postImages,
                      'userId': FirebaseAuth.instance.currentUser!.uid,
                      'userEmail':
                          FirebaseAuth.instance.currentUser!.email.toString(),
                      'timeStamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _postOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: 220,
                  width: 375,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Add to list',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Mute',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Block',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please Sign In or Sign Up'),
        content: const Text('You need to be signed in to perform this action.'),
      ),
    );
  }

  Widget _pageBody() {
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // Messages and notifz __________________
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Navigate to the Message Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MessageScreen(),
                                ),
                              );
                            } else {
                              // Show dialog if user is not signed in
                              _notSignedIn();
                            }
                          },
                          style: ApplicationButtons.button2(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    child: Image.asset(
                                      "assets/images/Messager.png",
                                      color: Colors.black,
                                    ),
                                  ),
                                  StreamBuilder<User?>(
                                    stream: FirebaseAuth.instance
                                        .authStateChanges(),
                                    builder: (context, authSnapshot) {
                                      if (authSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(); // Avoid showing errors during loading
                                      }

                                      if (!authSnapshot.hasData ||
                                          authSnapshot.data == null) {
                                        return const SizedBox(); // No unread indicator if not logged in
                                      }

                                      String currentUserId = authSnapshot
                                          .data!.uid; // Current user ID

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('chat_rooms')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return const SizedBox(); // No unread indicator if no data
                                          }

                                          // Check if there are unread messages
                                          bool hasUnread =
                                              snapshot.data!.docs.any((doc) {
                                            Map<String, dynamic> data = doc
                                                .data() as Map<String, dynamic>;

                                            // Only consider chat rooms the user has participated in
                                            if (!data['lastReadTimestamps']
                                                .containsKey(currentUserId)) {
                                              return false;
                                            }

                                            Timestamp lastReadTimestamp =
                                                data['lastReadTimestamps']
                                                    [currentUserId];
                                            Timestamp lastMessageTimestamp =
                                                data['lastMessageTimestamp'];

                                            return lastMessageTimestamp
                                                .toDate()
                                                .isAfter(
                                                    lastReadTimestamp.toDate());
                                          });

                                          return hasUnread
                                              ? Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    height: 10,
                                                    width: 10,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(width: 4.toDouble()),
                              Text(
                                '${translate('messages', targetLanguage)}',
                                style: primaryTextStyle(color: black),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Posts Area & adding posts/relations ____________
            Column(
              children: [
                // Dropdown Menu
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: <String>['All Posts', 'Likes']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                // Search Bar
                // Padding(
                //   padding: const EdgeInsets.symmetric(
                //       horizontal: 16, vertical: 4),
                //   child: TextField(
                //     controller: searchController,
                //     decoration: InputDecoration(
                //       labelText: 'Search',
                //       prefixIcon: Icon(Icons.search),
                //       suffixIcon: IconButton(
                //         icon: Icon(Icons.filter_list),
                //         onPressed: () {
                //           _showFilterDialog(context);
                //         },
                //       ),
                //       border: OutlineInputBorder(),
                //     ),
                //     onChanged: (value) {
                //       setState(() {
                //         searchText = value
                //             .trim()
                //             .toLowerCase(); // Normalize the search query
                //       });
                //     },
                //   ),
                // ),
                // Posts List
                Builder(
                  builder: (context) {
                    final userId = FirebaseAuth.instance.currentUser?.uid;

                    // Handle non-registered users selecting "Likes"
                    if (dropdownValue == 'Likes' && userId == null) {
                      return Center(
                        child: Text(
                          "\n \n \nYou need to log in to view liked posts.\n \n \n",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: dropdownValue == 'Likes'
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('likes')
                              .snapshots()
                          : FirebaseFirestore.instance
                              .collection('posts')
                              .orderBy('timeStamp', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              dropdownValue == 'All Posts'
                                  ? "No posts yet..."
                                  : "No liked posts yet...",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // For "Likes", fetch post IDs; for "All Posts", use document snapshots
                        final posts = dropdownValue == 'Likes'
                            ? snapshot.data!.docs.map((doc) => doc.id).toList()
                            : snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final Future<DocumentSnapshot<Object?>> postFuture =
                                dropdownValue == 'Likes'
                                    ? FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(posts[index] as String)
                                        .get()
                                    : Future.value(posts[index]
                                        as DocumentSnapshot<Object?>);

                            return FutureBuilder<DocumentSnapshot<Object?>>(
                              future: postFuture,
                              builder: (context, postSnapshot) {
                                if (!postSnapshot.hasData ||
                                    !postSnapshot.data!.exists) {
                                  return SizedBox(); // Post not found
                                }

                                final postData = postSnapshot.data!;
                                final timestamp =
                                    postData['timeStamp'] as Timestamp;
                                final postTime = timestamp.toDate();
                                final now = DateTime.now();
                                final difference = now.difference(postTime);

                                String displayText;
                                if (difference.inDays > 0) {
                                  displayText = '${difference.inDays} days ago';
                                } else if (difference.inHours > 0) {
                                  displayText =
                                      '${difference.inHours} hours ago';
                                } else {
                                  displayText =
                                      '${difference.inMinutes} minutes ago';
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/posts/${postData.id}');
                                  },
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: AssetImage(
                                              'assets/images/nonuser.png'),
                                          radius: 24,
                                        ),
                                        title: Row(
                                          children: [
                                            Text(
                                              'Lesser',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Urbanist-semibold',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Image.asset(
                                              'assets/images/badge-check.png',
                                              height: 20,
                                              width: 20,
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          displayText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontFamily: 'Urbanist-regular',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        // trailing: Icon(Icons.more_vert),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          postData['postHeader'] ?? 'Unknown',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Urbanist-medium',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if ((postData['postImages'] ?? [])
                                          .isNotEmpty)
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.55,
                                          child: Image.network(
                                            postData['postImages'][0],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      // Post Engaging Section
                                      Row(
                                        children: [
                                          const SizedBox(width: 20),
                                          // Like Button
                                          StreamBuilder<DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .collection('likes')
                                                .doc(postData.id)
                                                .snapshots(),
                                            builder: (context, likeSnapshot) {
                                              bool isLiked = false;

                                              // Check if data is available and the like exists
                                              if (likeSnapshot.hasData &&
                                                  likeSnapshot.data!.exists) {
                                                isLiked = true;
                                              }

                                              return Column(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (userId == null) {
                                                        // Show login prompt for non-registered users
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                            title: Text(
                                                                "Login Required"),
                                                            content: Text(
                                                                "You need to log in to like posts."),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child: Text(
                                                                    "Close"),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      } else {
                                                        toggleLike(postData.id);
                                                      }
                                                    },
                                                    child: Container(
                                                      height: 36,
                                                      width: 36,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: isLiked
                                                              ? Colors.red
                                                              : Colors.grey
                                                                  .shade200,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                      ),
                                                      child: Center(
                                                        child: Image.asset(
                                                          isLiked
                                                              ? 'assets/images/heart2.png'
                                                              : 'assets/images/hearts.png',
                                                          height: 16,
                                                          width: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${postData['likesCount'] ?? 0} likes',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          // Share Button
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  // Show loading dialog
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) => Dialog(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                                "Copying link..."),
                                                            const SizedBox(
                                                                height: 10),
                                                            CircularProgressIndicator(),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );

                                                  try {
                                                    final postId = postData.id;
                                                    final postLink =
                                                        'https://lessernaqaa.web.app/#/posts/$postId';

                                                    await Clipboard.setData(
                                                        ClipboardData(
                                                            text: postLink));

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('posts')
                                                        .doc(postId)
                                                        .update({
                                                      'shareCount':
                                                          FieldValue.increment(
                                                              1)
                                                    });

                                                    Navigator.pop(
                                                        context); // Close loading dialog

                                                    // Show success dialog
                                                    await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title:
                                                            Text("Link Copied"),
                                                        content: Text(
                                                            "The post link has been copied to your clipboard."),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child:
                                                                Text("Close"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    Navigator.pop(
                                                        context); // Close loading dialog if error
                                                    print(
                                                        "Error during copy/share: $e");
                                                  }
                                                },
                                                child: Container(
                                                  height: 36,
                                                  width: 36,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade200),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                  ),
                                                  child: Center(
                                                    child: Image.asset(
                                                      'assets/images/send.png',
                                                      height: 16,
                                                      width: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              StreamBuilder<DocumentSnapshot>(
                                                stream: FirebaseFirestore
                                                    .instance
                                                    .collection('posts')
                                                    .doc(postData.id)
                                                    .snapshots(),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData ||
                                                      !snapshot.data!.exists) {
                                                    return Text(
                                                      '0 shares',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  }

                                                  final shareCount =
                                                      snapshot.data![
                                                              'shareCount'] ??
                                                          0;

                                                  return Text(
                                                    '$shareCount shares',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? _pageBody()
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 200, right: 200),
                child: _pageBody(),
              ),
            ),
    );
  }
}

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  @override
  void initState() {
    super.initState();
    loadRelationPages();
  }

  // Documentations and policies goes here _______________________

  String translated = '';
  Map<String, String> languageNames1 = {
    'ar': 'Arabic',
    'en': 'English',
    // 'ja': 'Japanese',
    // 'fr': 'French',
    // 'es': 'Spanish',
    // 'de': 'German',
    // Add more language codes and names as needed
  };

  int selectedItem = 1; // Default to the first item (1: Social Channels)

  List<Map<String, dynamic>> relationPageOptions = [];
  Map<String, dynamic>? selectedRelationPage;

  String selectedLeaderboardType = "recyclers"; // Default starting page
  String selectedTimeframe = "Monthly"; // Default timeframe

  Map<String, String> leaderboardPages = {
    "recyclers": "Top Recyclers",
    // "referrers": "Top Referrers",
    'rules': 'Score Rules',
    // "social_channels": "Social Channels",
    // "social_channels2": "Social Channels",
    // "contact_us": "Contact Us",
    // "privacy_policy": "Privacy Policy",
    // "how_to_use": "How to Use",
    // "terms_of_service": "Terms of Service",
    // "translation": "Translation",
  };

  List<String> timeframes = [
    "All Time",
    "Monthly",
    "Weekly",
    //  "Daily",
    //  "Hourly",
  ];

  Widget _getContent() {
    switch (selectedLeaderboardType) {
      case "recyclers":
        return _buildTopRecyclers(); // 🏆 (First leaderboard screen)
      case "referrers":
        return _buildTopReferrers(); // 🏆 (Second leaderboard screen)
      case "social_channels":
        return _buildSocialChannels();
      case "social_channels2":
        return _buildSocialChannels2();
      case 'rules':
        return _buildRulesPage(); // We’ll create this now as placeholder
      case "contact_us":
        return _buildPolicies();
      case "privacy_policy":
        return _buildPoliciesX();
      case "how_to_use":
        return _buildPoliciesY();
      case "terms_of_service":
        return _buildPoliciesZ();
      case "translation":
        return _buildTranslation();
      default:
        return Center(
          child: Text(
            translate('Select an option.', targetLanguage),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        );
    }
  }

  Widget _buildTopRecyclers() {
    final selectedPath = selectedRelationPage?['path'];
    final label = selectedTimeframe;
    final now = DateTime.now();

    // Internal timeframe generator
    String getTimeframeId() {
      switch (label) {
        case 'Monthly':
          return '${now.year}-${now.month.toString().padLeft(2, '0')}';
        case 'Weekly':
          int getSundayWeekNumber(DateTime date) {
            final firstDayOfYear = DateTime(date.year, 1, 1);

            // 🔁 ONLY CHANGE IS HERE
            final daysOffset = firstDayOfYear.weekday % 7;

            final firstSunday =
                firstDayOfYear.subtract(Duration(days: daysOffset));

            final diff = date.difference(firstSunday);
            return ((diff.inDays + 1) / 7).ceil();
          }

          final week = getSundayWeekNumber(now);
          return '${now.year}-W$week';

        case 'Daily':
          return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        case 'Hourly':
          return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}';
        default:
          return 'all_time';
      }
    }

    final timeframeId = getTimeframeId();

    if (selectedPath == null) {
      return Center(child: Text('Select a relation page.'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: () async {
        final firestore = FirebaseFirestore.instance;

        // 🔹 Fetch members
        final membersSnapshot = await firestore
            .collection('$selectedPath/timeframes/$timeframeId/members')
            .orderBy('score', descending: true)
            .limit(10)
            .get();

        List<Map<String, dynamic>> entries = [];

        for (var doc in membersSnapshot.docs) {
          final uid = doc.id;
          final data = doc.data();

          final userDoc = await firestore.collection('users').doc(uid).get();
          final userData = userDoc.data() ?? {};

          entries.add({
            'uid': uid,
            'type': 'member',
            'score': data['score'] ?? 0,
            'trophies': data['trophies'] ?? 0,
            'role': data['role'] ?? 'member',
            'username': userData['username'] ?? 'User',
            'photoUrl': userData['photoUrl'],
          });
        }

        // 🔹 Fetch groups (subfiles/branches)
        final groupsSnapshot = await firestore
            .collection('$selectedPath/timeframes/$timeframeId/groups')
            .orderBy('score', descending: true)
            .get();

        for (var doc in groupsSnapshot.docs) {
          final subfileId = doc.id;
          final data = doc.data();

          // Reconstruct subfile path from selectedPath + subfileId
          final subfilePath = '$selectedPath/subfiles/$subfileId';

          final subfileDoc = await firestore.doc(subfilePath).get();
          final subfileData = subfileDoc.data() ?? {};

          entries.add({
            'uid': subfileId,
            'type': 'group',
            'score': data['score'] ?? 0,
            'trophies': data['trophies'] ?? 0,
            'role': 'group',
            'username': subfileData['name'] ?? 'Branch',
            'photoUrl': null, // or assign folder icon later
          });
        }

        // 🔄 Sort all entries by score
        entries
            .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

        return entries;
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        // Assign ranks
        for (int i = 0; i < users.length; i++) {
          users[i]['rank'] = i + 1;
        }

        if (users.isEmpty) {
          return Center(child: Text('No members yet.'));
        }

        return Column(
          children: [
            // Rules button _____
            ElevatedButton(
              onPressed: () async {
                final path = selectedRelationPage?['path'];

                if (path != null && path.startsWith('/relations/')) {
                  // Show hardcoded rules (for public "recyclers" page only)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: Text('Rules')),
                        body: _buildRulesPage(),
                      ),
                    ),
                  );
                } else {
                  // Show Firestore 'notes' (for all other relation pages)
                  try {
                    final docSnapshot =
                        await FirebaseFirestore.instance.doc(path!).get();
                    final notes =
                        docSnapshot.data()?['notes'] ?? 'No rules available.';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: Text('Rules')),
                          body: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              notes,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error fetching rules: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load rules.')),
                    );
                  }
                }
              },
              style: ApplicationButtons.button2(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    child: Icon(
                      Icons.rule,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4.toDouble()),
                  Text(
                    '${translate('rules', targetLanguage)}',
                    style: primaryTextStyle(color: black),
                  ),
                ],
              ),
            ),
            // Header Row _____
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Trophies',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Score',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Divider(thickness: 1.0),
            // Leaderboard List _____
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 16, color: Colors.grey[400]),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final rank = user['rank'];

                  // Background color for Top 3
                  Color backgroundColor;
                  if (rank == 1) {
                    backgroundColor = Color(0xFFFFD700); // Gold
                  } else if (rank == 2) {
                    backgroundColor = Color(0xFFC0C0C0); // Silver
                  } else if (rank == 3) {
                    backgroundColor = Color(0xFFCD7F32); // Bronze
                  } else {
                    backgroundColor = Colors.white;
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(rank <= 3 ? 0.2 : 0.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 12),

                        // Avatar + Username
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: user['photoUrl'] != null
                                    ? NetworkImage(user['photoUrl'])
                                    : AssetImage('assets/images/nonuser.png')
                                        as ImageProvider,
                                radius: 20,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  user['username'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trophies
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events,
                                  size: 20, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                '${user['trophies']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score
                        Expanded(
                          child: Text(
                            '${user['score']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Viewer Bottom Row (You or Guest)
            if (selectedLeaderboardType == 'recyclers' &&
                selectedRelationPage?['path']?.startsWith('/relations/') ==
                    true)
              FutureBuilder<Map<String, dynamic>>(
                future: Future<Map<String, dynamic>>(() async {
                  final firestore = FirebaseFirestore.instance;
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  // 1️⃣ Get member data (score + trophies) for this timeframe
                  final memberDoc = await firestore
                      .doc('$selectedPath/timeframes/$timeframeId/members/$uid')
                      .get();

                  if (!memberDoc.exists) {
                    return <String, dynamic>{};
                  }

                  final Map<String, dynamic> memberData =
                      (memberDoc.data() as Map<String, dynamic>?) ?? {};

                  final int score = memberData['score'] ?? 0;
                  final int trophies = memberData['trophies'] ?? 0;

                  // 2️⃣ Get user profile
                  final userDoc =
                      await firestore.collection('users').doc(uid).get();
                  final Map<String, dynamic> userData = userDoc.data() ?? {};

                  final String username = userData['username'] ?? 'You';
                  final String? photoUrl = userData['photoUrl'];

                  // 3️⃣ Calculate rank inside this timeframe
                  final higherScoreSnap = await firestore
                      .collection(
                          '$selectedPath/timeframes/$timeframeId/members')
                      .where('score', isGreaterThan: score)
                      .get();

                  final int rank = higherScoreSnap.size + 1;

                  return <String, dynamic>{
                    'rank': rank,
                    'score': score,
                    'trophies': trophies,
                    'username': username,
                    'photoUrl': photoUrl,
                  };
                }),
                builder: (context, snapshot) {
                  // if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  //   return const SizedBox();
                  //   }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Start recycling to join the leaderboard.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final viewer = snapshot.data!;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Text(
                          '#${viewer['rank']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Avatar + Username
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: viewer['photoUrl'] != null
                                    ? NetworkImage(viewer['photoUrl'])
                                    : const AssetImage(
                                            'assets/images/nonuser.png')
                                        as ImageProvider,
                                radius: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  viewer['username'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trophies
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events,
                                  size: 20, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${viewer['trophies']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score
                        Expanded(
                          child: Text(
                            '${viewer['score']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> loadRelationPages() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    List<Map<String, dynamic>> publicPages = [];
    List<Map<String, dynamic>> privatePages = [];

    // 🔹 Helper to add subfiles recursively
    Future<void> addSubfilesRecursively(
      String parentPath,
      String idPrefix,
    ) async {
      final subfilesSnapshot =
          await firestore.collection('$parentPath/subfiles').get();

      for (final subDoc in subfilesSnapshot.docs) {
        final subfilePath = '$parentPath/subfiles/${subDoc.id}';
        final data = subDoc.data();

        privatePages.add({
          'id': '${idPrefix}__${subDoc.id}',
          'title': data['name'] ?? subDoc.id,
          'type': 'subfile',
          'path': subfilePath,
        });

        await addSubfilesRecursively(
          subfilePath,
          '${idPrefix}__${subDoc.id}',
        );
      }
    }

    // 🔹 1. Public relation pages
    final publicSnapshot = await firestore.collection('relations').get();
    for (final doc in publicSnapshot.docs) {
      print("ADDING PUBLIC: id=${doc.id}, title=${doc.data()['name']}");
      publicPages.add({
        'id': doc.id,
        'title': doc.data()['name'] ?? doc.id,
        'type': 'public',
        'path': '/relations/${doc.id}',
      });
    }

    // 🔹 2. Private locations & subfiles
    if (userRole == 'business') {
      final locationsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .get();

      for (final locDoc in locationsSnapshot.docs) {
        final locationId = locDoc.id;
        final locationData = locDoc.data();

        privatePages.add({
          'id': locationId,
          'title': locationData['name'] ?? locationId,
          'type': 'private',
          'path': '/users/$uid/locations/$locationId',
        });

        await addSubfilesRecursively(
          '/users/$uid/locations/$locationId',
          locationId,
        );
      }
    }

    // 🔹 3. Shared files & subfiles
    final membersSnap = await firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    final Set<String> seenPaths = {};

    for (final memberDoc in membersSnap.docs) {
      final membersColl = memberDoc.reference.parent;
      final allTimeDoc = membersColl.parent;
      if (allTimeDoc == null || allTimeDoc.id != 'all_time') continue;

      final timeframesColl = allTimeDoc.parent;
      if (timeframesColl == null) continue;

      final fileDocRef = timeframesColl.parent;
      if (fileDocRef == null) continue;

      final fileDoc = await fileDocRef.get();
      if (!fileDoc.exists) continue;

      final path = fileDoc.reference.path;

      // 🚫 Skip if this is under the /relations collection
      if (path.startsWith('relations/')) {
        print("SKIPPED SHARED (relation): path=$path");
        continue;
      }

      if (!seenPaths.add(path)) continue;

      final data = fileDoc.data() as Map<String, dynamic>?;

      print(
          "ADDING SHARED: id=${fileDoc.id}, title=${data?['name']}, path=$path");
      privatePages.add({
        'id': fileDoc.id,
        'title': data?['name'] ?? fileDoc.id,
        'type': 'shared',
        'path': path,
      });

      await addSubfilesRecursively(
        path,
        fileDoc.id,
      );
    }

    // ✅ Combine
    relationPageOptions = [
      ...privatePages,
      if (userRole != 'business') ...publicPages,
    ];

    if (relationPageOptions.isNotEmpty) {
      selectedRelationPage = relationPageOptions.first;
      setState(() {});
    }
  }

  Widget _buildRulesPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rules and Scoring System',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          // 1. Score System
          Text(
            '1. Score System',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- +1 point for each plastic bottle recycled (adds +1 score).\n'
            '- +100 points for each paper bag recycled (adds +100 score).\n'
            '- Bonus points may be awarded for completing tasks like daily streaks or seasonal events.\n'
            '- All points directly increase your score, which determines your leaderboard ranking.\n'
            '- Redeeming points for coupons or rewards does not affect your score.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 2. Level System
          Text(
            '2. Level System',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Image.asset('assets/images/Level1.png', width: 32, height: 32),
              SizedBox(width: 8),
              Text('Seed: 0 – 999', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Image.asset('assets/images/Level2.png', width: 32, height: 32),
              SizedBox(width: 8),
              Text('Leaf: 1000 – 2499', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Image.asset('assets/images/Level3.png', width: 32, height: 32),
              SizedBox(width: 8),
              Text('Branch: 2500 – 4999', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Image.asset('assets/images/Level4.png', width: 32, height: 32),
              SizedBox(width: 8),
              Text('Tree: 5000 – 7499', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Image.asset('assets/images/Level5.png', width: 32, height: 32),
              SizedBox(width: 8),
              Text('Forest: 7500 – 9999', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '- Levels reflect your long-term growth in the app.\n'
            '- In the future, levels may unlock visual effects, badges, or access to special features.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 3. Trophies & Tasks
          Text(
            '3. Trophies & Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- Trophies are earned by completing specific in-app tasks or milestones.\n'
            '- Examples include recycling milestones, completing missions, or joining campaigns.\n'
            '- Trophies are for recognition only — they do not affect leaderboard rank.\n'
            '- They may be used later for unlocking badges, titles, or access to new features.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 4. Leaderboard Rules
          Text(
            '4. Leaderboard Rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- Leaderboards rank users by total score (not trophies or level).\n'
            '- The top 3 users are highlighted (Gold, Silver, Bronze).\n'
            '- The organizer is always shown at the top (symbolic row).\n'
            '- Your own row is always shown at the bottom, whether ranked or not.\n'
            '- Tapping any user opens their public profile.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 5. Timeframes
          Text(
            '5. Timeframes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- Leaderboards can be filtered by Weekly and Monthly\n'
            '- Monthly rankings reset on the 1st of each month.\n'
            '- Weekly filters are for viewing only — actual ranks are based on total score.\n'
            '- All-Time shows cumulative performance since the user joined.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 6. Fair Play
          Text(
            '6. Fair Play',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- Any form of cheating (e.g. fake bottle scans) will lead to penalties or account suspension.\n'
            '- Inactive or suspicious accounts may be hidden from public rankings.\n'
            '- You must be logged in to earn trophies and appear on the leaderboard.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // 7. Public Profiles & Relation Pages
          Text(
            '7. Public Profiles & Relation Pages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '- Each user has a public profile showing their score, trophies, and level.\n'
            '- Users can create Relation Pages that group other users, show relevant tables, and display custom content like rules or bios.\n'
            '- These pages are organized and editable by the page owner, and can be filtered like any leaderboard.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Last Updated: May 2025',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTopReferrers() {
    return Center(
      child: Text(
        translate(
            'Top Referrers Leaderboard will appear here...', targetLanguage),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSocialChannels() {
    // Dummy social platforms data
    List<Map<String, dynamic>> socialData = [
      {
        'rank': 1,
        'platform': 'Website',
        'avatar': 'assets/images/00.png',
        'url': 'https://www.lesserapp.com',
        'clicks': 124,
        'followers': '3K+',
      },
      {
        'rank': 2,
        'platform': 'LinkedIn',
        'avatar': 'assets/images/01.png',
        'url':
            'https://www.linkedin.com/company/lesser-for-sustainability-solutions/',
        'clicks': 98,
        'followers': '5K+',
      },
      {
        'rank': 3,
        'platform': 'X',
        'avatar': 'assets/images/03.png',
        'url': 'https://x.com/lesserappksa',
        'clicks': 87,
        'followers': '10K+',
      },
      {
        'rank': 4,
        'platform': 'Instagram',
        'avatar': 'assets/images/04.png',
        'url': 'https://www.instagram.com/lesserapp/',
        'clicks': 150,
        'followers': '2K+',
      },
    ];

    return Column(
      children: [
        // Header Row
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Text('Social channels',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('Clicks',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Follower',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Social Platform Rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: socialData.length,
            separatorBuilder: (context, index) =>
                Divider(height: 16, color: Colors.grey[400]),
            itemBuilder: (context, index) {
              final item = socialData[index];
              final rank = item['rank'];

              return GestureDetector(
                onTap: () async {
                  await launch(item['url']);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Text(
                        '#${item['rank']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 12),

                      // Avatar + Platform Name
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(item['avatar']),
                              radius: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item['platform'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Clicks
                      Expanded(
                        child: Text(
                          '${item['clicks']}',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Followers
                      Expanded(
                        child: Text(
                          '${item['followers']}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialChannels2() {
    List<Map<String, dynamic>> socialData = [
      {
        'platform': 'Website',
        'avatar': 'assets/images/00.png',
        'url': 'https://www.lesserapp.com',
      },
      {
        'platform': 'LinkedIn',
        'avatar': 'assets/images/01.png',
        'url':
            'https://www.linkedin.com/company/lesser-for-sustainability-solutions/',
      },
      {
        'platform': 'X',
        'avatar': 'assets/images/03.png',
        'url': 'https://x.com/lesserappksa',
      },
      {
        'platform': 'Instagram',
        'avatar': 'assets/images/04.png',
        'url': 'https://www.instagram.com/lesserapp/',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: socialData.map((item) {
          return GestureDetector(
            onTap: () async {
              final url = Uri.parse(item['url']);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage(item['avatar']),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTranslation() {
    return Expanded(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text(
                  //   'Select Language: ',
                  //   style: TextStyle(
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.bold),
                  // ),
                  DropdownButton<String>(
                    value: targetLanguage,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          targetLanguage = newValue;
                        });
                        // _saveLanguage(
                        //     newValue); // Save the selected language
                      }
                    },
                    items: languageNames1.keys
                        .map<DropdownMenuItem<String>>((String code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(languageNames1[code]!),
                      );
                    }).toList(),
                  ),
                ],
              ),
              TextField(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Translate Any Language',
                ),
                onChanged: (text) async {
                  const apiKey =
                      'AIzaSyAu7Pn5i4S-R78ccg25dhLcpI5HxFBcwJo'; // Replace with your Google Cloud Translation API key
                  final url = Uri.parse(
                      'https://translation.googleapis.com/language/translate/v2?q=$text&target=$targetLanguage&key=$apiKey');

                  final response = await http.post(url);

                  if (response.statusCode == 200) {
                    final body = json.decode(response.body);
                    final translations = body['data']['translations'] as List;
                    final translation = HtmlUnescape().convert(
                      translations.first['translatedText'],
                    );

                    setState(() {
                      translated = translation;
                    });
                  }
                },
              ),
              Text(
                translated,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicies() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${translate('contact_us', targetLanguage)}:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            translate('contact_us_content', targetLanguage),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesX() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('privacy_policy', targetLanguage),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            translate('privacy_policy_content', targetLanguage),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesY() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('how_to_use', targetLanguage),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            translate('how_to_use_content', targetLanguage),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesZ() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('terms_of_service', targetLanguage),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            translate('terms_of_service_content', targetLanguage),
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _notSignedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please Sign In or Sign Up'),
        content: const Text('You need to be signed in to perform this action.'),
      ),
    );
  }

  Widget _pageBody() {
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // Score and triggers ____
            // Padding(
            //   padding: const EdgeInsets.only(top: 10),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       SizedBox(
            //         height: 40,
            //         child: Row(
            //           children: [
            //             ElevatedButton(
            //               onPressed: () {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                       builder: (context) => SharingScreen(),
            //                     ));
            //               },
            //               style: ApplicationButtons.button2(),
            //               child: Row(
            //                 crossAxisAlignment:
            //                     CrossAxisAlignment.center,
            //                 children: [
            //                   Icon(Icons.emoji_events,
            //                       size: 18, color: black),
            //                   SizedBox(width: 4.toDouble()),
            //                   Text('Share & Earn',
            //                       style:
            //                           primaryTextStyle(color: black)),
            //                 ],
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Relations, policies and languages _____________________
            Card(
              margin: EdgeInsets.all(ApplicationSpacing.medium),
              child: Container(
                height: 500,
                decoration: ApplicationContainers.container1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organizer Top Row (Rank #0)
                    // Container(
                    //  padding:
                    //      EdgeInsets.all(ApplicationSpacing.medium),
                    //  decoration: BoxDecoration(
                    //    borderRadius: BorderRadius.circular(12),
                    //  ),
                    //  child: Row(
                    //    children: [
                    // Rank
                    //      Text(
                    //        '#0',
                    //        style: TextStyle(
                    //          fontSize: 18,
                    //          fontWeight: FontWeight.bold,
                    //        ),
                    //      ),
                    //      SizedBox(width: 12),

                    // Avatar + Username
                    // Expanded(
                    // flex: 2,
                    // child: Row(
                    // children: [
                    // CircleAvatar(
                    // backgroundImage: AssetImage(
                    //  'assets/images/lesserlogo.png'), // or dynamic
                    // radius: 20,
                    // ),
                    // SizedBox(width: 8),
                    // Flexible(
                    // child: Text(
                    // 'Organizer', // Replace with dynamic username if needed
                    // style: TextStyle(
                    // fontSize: 16,
                    // fontWeight: FontWeight.bold,
                    // ),
                    // overflow: TextOverflow.ellipsis,
                    // ),
                    // ),
                    // ],
                    // ),
                    // ),

                    // Star Icon (instead of trophy)
                    // Expanded(
                    // child: Row(
                    // mainAxisAlignment:
                    //  MainAxisAlignment.center,
                    // children: [
                    // Icon(Icons.star,
                    //  size: 20, color: Colors.amber),
                    // SizedBox(width: 4),
                    // Text(
                    //   '-', // No count, just symbolic
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // ],
                    // ),
                    // ),

                    // Score (just a dash)
                    // Expanded(
                    // child: Text(
                    // '-', // No numeric score
                    // style: TextStyle(
                    // fontSize: 16,
                    // fontWeight: FontWeight.bold,
                    // ),
                    // textAlign: TextAlign.center,
                    // ),
                    // ),
                    // ],
                    // ),
                    // ),
                    // Language & pages Selection Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ApplicationSpacing.medium,
                        vertical: ApplicationSpacing.small,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<Map<String, dynamic>>(
                            value: selectedRelationPage,
                            hint: const Text("Select Page"),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRelationPage = newValue;
                              });
                            },
                            items: relationPageOptions.map((page) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: page,
                                child: Text(page['title']),
                              );
                            }).toList(),
                          ),
                          DropdownButton<String>(
                            value: selectedTimeframe,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedTimeframe = newValue;
                                });
                              }
                            },
                            items: timeframes.map((timeframe) {
                              return DropdownMenuItem<String>(
                                value: timeframe,
                                child: Text(
                                  translate(timeframe, targetLanguage),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Divider(height: 16),
                    // Content with Navigation and Display
                    Expanded(
                      child: Row(
                        children: [
                          // Content Area ___________
                          Expanded(
                            child: Container(
                              //  padding: EdgeInsets.only(left: 12.0),
                              child: Center(child: _getContent()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? _pageBody()
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 200, right: 200),
                child: _pageBody(),
              ),
            ),
    );
  }
}

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late DocumentSnapshot post;
  late String displayText;
  PageController pageController1 = PageController(viewportFraction: 1);

  var selectIndex1 = [];

  changeValue1({int? value}) {
    setState(() {
      if (selectIndex1.contains(value)) {
        selectIndex1.remove(value);
      } else {
        selectIndex1.add(value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Fetch the post data here if needed
  }

  Future<void> _postOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: 220,
                  width: 375,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Add to list',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Mute',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Block',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 13, top: 13, bottom: 10),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pageBody() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: ApplicationColors.background,
      ),
      backgroundColor: ApplicationColors.background,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final post = snapshot.data!;
            // Extract timestamp and calculate displayText as before
            final timestamp = post['timeStamp'] as Timestamp;
            final now = DateTime.now();
            final postTime = timestamp.toDate();
            final differenceInSeconds = now.difference(postTime).inSeconds;
            final minutesAgo = differenceInSeconds ~/ 60;
            final hoursAgo = minutesAgo ~/ 60;
            final daysAgo = hoursAgo ~/ 24;

            if (daysAgo > 0) {
              displayText = '$daysAgo days ago';
            } else if (hoursAgo > 0) {
              displayText = '$hoursAgo hours ago';
            } else {
              displayText = '$minutesAgo minutes ago';
            }

            return SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // User Info _______________
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ListTile(
                        leading: SizedBox(
                          height: 48,
                          width: 48,
                          child: Container(
                            height: 173,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(nonuser),
                                    fit: BoxFit.fill),
                                borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text('Lesser',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Urbanist-semibold',
                                    fontWeight: FontWeight.w600)),
                            Image.asset(
                              'assets/images/badge-check.png',
                              height: 20,
                              width: 20,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          displayText,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'Urbanist-regular',
                              fontWeight: FontWeight.w400),
                        ),
                        // trailing: GestureDetector(
                        //     // onTap: _postOptions,
                        //     child: const Icon(Icons.more_vert_sharp)),
                      ),
                    ),
                    // Post Content ___________________
                    RichText(
                      text: TextSpan(
                        text: post['postHeader'],
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontFamily: 'Urbanist-medium',
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Post Media _____________
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width * 0.65,
                            child: PageView.builder(
                              controller: pageController1,
                              itemCount: post['postImages'].length,
                              itemBuilder: (context, index) => Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.width * 0.55,
                                padding: EdgeInsets.all(20),
                                margin: EdgeInsets.all(5),
                                alignment: Alignment.center,
                                child: Image.network(post['postImages'][index],
                                    alignment: Alignment.topCenter),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SmoothPageIndicator(
                              controller: pageController1,
                              count: post['postImages'].length,
                              effect: CustomizableEffect(
                                activeDotDecoration: DotDecoration(
                                  height: 8,
                                  width: 8,
                                  color: primaryBlackColor,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                dotDecoration: DotDecoration(
                                  height: 8,
                                  width: 8,
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              itemCount: post['postImages'].length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    final List<String> images =
                                        List<String>.from(post['postImages']);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ZoomImageScreen(
                                          galleryImages: images,
                                          index: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: gray.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Image(
                                        image: NetworkImage(
                                            post['postImages'][index]),
                                        height: 50,
                                        width: 50),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Product/Service Description and bio _________________________________________
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text('Post Body', style: boldTextStyle())),
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        style: secondaryTextStyle(),
                        text: post['postBody'],
                      ),
                    ).paddingOnly(right: 16, left: 16),

                    const SizedBox(
                      height: 20,
                    ),
                    // Comments _____________
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Comments',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Urbanist-semibold'),
                                textAlign: TextAlign.center),
                            // trailing: InkWell(
                            //   onTap: () => Navigator.pop(context),
                            //   child: const Icon(
                            //     Icons.close,
                            //     color: Colors.black,
                            //   ),
                            // ),
                          ),
                          // Post Numbers _______________
                          // Padding(
                          //   padding: const EdgeInsets.only(
                          //       left: 30,
                          //       right: 20,
                          //       top: 5),
                          //   child:
                          //       Row(
                          //     children: [
                          //       SizedBox(
                          //         height: 20,
                          //         width: 12,
                          //         child: Image.asset('assets/images/heart.png'),
                          //       ),
                          //       SizedBox(
                          //         height: 20,
                          //         width: 12,
                          //         child: Image.asset('assets/images/like.png'),
                          //       ),
                          //       const Text(
                          //         '  2.8K',
                          //         style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Urbanist-regular', fontWeight: FontWeight.w400),
                          //         overflow: TextOverflow.ellipsis,
                          //       ),
                          //       const Expanded(child: SizedBox(width: 185)),
                          //       const Text(
                          //         '948 Comment',
                          //         style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Urbanist-regular', fontWeight: FontWeight.w400),
                          //         overflow: TextOverflow.ellipsis,
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // const SizedBox(
                          //     height: 10),
                          // // Post Engaging ________________
                          // Row(
                          //   children: [
                          //     const SizedBox(
                          //       width: 20,
                          //     ),
                          //     // Like ________
                          //     GestureDetector(
                          //       onTap: () {
                          //         changeValue1(value: index);
                          //       },
                          //       child: Container(
                          //         height: 36,
                          //         width: 36,
                          //         decoration: BoxDecoration(
                          //           // color: Colors.red,
                          //           border: Border.all(color: selectIndex1.contains(index) ? Colors.grey.shade200 : Colors.red),
                          //           borderRadius: BorderRadius.circular(100),
                          //         ),
                          //         child: Center(
                          //             child: Image.asset(
                          //           selectIndex1.contains(index) ? 'assets/images/hearts.png' : 'assets/images/heart2.png',
                          //           height: 16,
                          //           width: 16,
                          //         )),
                          //       ),
                          //     ),
                          //     const SizedBox(
                          //       width: 10,
                          //     ),
                          //     // Comment _______
                          //     GestureDetector(
                          //       onTap: () {
                          //         showModalBottomSheet(
                          //           context: context,
                          //           shape: const RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          //           ),
                          //           builder: (context) {
                          //             return SingleChildScrollView(
                          //               child: Column(
                          //                 children: [
                          //                   ListTile(
                          //                     title: const Text('Comments', style: TextStyle(fontSize: 15, fontFamily: 'Urbanist-semibold'), textAlign: TextAlign.center),
                          //                     trailing: InkWell(
                          //                       onTap: () => Navigator.pop(context),
                          //                       child: const Icon(
                          //                         Icons.close,
                          //                         color: Colors.black,
                          //                       ),
                          //                     ),
                          //                   ),
                          //                   ListView.builder(
                          //                     physics: const NeverScrollableScrollPhysics(),
                          //                     shrinkWrap: true,
                          //                     scrollDirection: Axis.vertical,
                          //                     itemCount: instastory1.length,
                          //                     itemBuilder: (context, index) {
                          //                       return Column(
                          //                         children: [
                          //                           ListTile(
                          //                             leading: Image.asset(
                          //                               instastory1[index],
                          //                               height: 30,
                          //                               width: 30,
                          //                             ),
                          //                             title: Text(
                          //                               text1[index],
                          //                               style: const TextStyle(fontFamily: 'Urbanist-semibold', fontSize: 15),
                          //                             ),
                          //                             subtitle: Text(
                          //                               subtitle[index],
                          //                               style: const TextStyle(fontFamily: "Urbanist-medium"),
                          //                             ),
                          //                             trailing: Text(
                          //                               time[index],
                          //                               style: TextStyle(fontFamily: "Urbanist-medium", fontSize: 12, color: Colors.grey.shade400),
                          //                             ),
                          //                           ),
                          //                           Padding(
                          //                             padding: const EdgeInsets.only(left: 20),
                          //                             child: Row(
                          //                               mainAxisAlignment: MainAxisAlignment.start,
                          //                               children: [
                          //                                 InkWell(
                          //                                     onTap: () {
                          //                                       changeValue(value: index);
                          //                                     },
                          //                                     child: Image.asset(
                          //                                       selectIndex.contains(index) ? 'assets/images/heart2.png' : 'assets/images/hearts.png',
                          //                                       height: 15,
                          //                                       width: 15,
                          //                                     )),
                          //                                 const SizedBox(
                          //                                   width: 10,
                          //                                 ),
                          //                                 Image.asset(
                          //                                   'assets/images/comment.png',
                          //                                   height: 15,
                          //                                   width: 15,
                          //                                 ),
                          //                               ],
                          //                             ),
                          //                           ),
                          //                           const SizedBox(
                          //                             height: 10,
                          //                           ),
                          //                         ],
                          //                       );
                          //                     },
                          //                   ),
                          //                 ],
                          //               ),
                          //             );
                          //           },
                          //         );
                          //       },
                          //       child: Container(
                          //         height: 36,
                          //         width: 36,
                          //         decoration: BoxDecoration(
                          //           border: Border.all(color: Colors.grey.shade200),
                          //           borderRadius: BorderRadius.circular(100),
                          //         ),
                          //         child: Center(
                          //           child: Image.asset(
                          //             'assets/images/comment.png',
                          //             width: 16,
                          //             height: 16,
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //     const SizedBox(
                          //       width: 10,
                          //     ),
                          //     // Repost ______________
                          //     Container(
                          //       height: 36,
                          //       width: 36,
                          //       decoration: BoxDecoration(
                          //         border: Border.all(color: Colors.grey.shade200),
                          //         borderRadius: BorderRadius.circular(100),
                          //       ),
                          //       child: Center(
                          //           child: Image.asset(
                          //         'assets/images/repost.png',
                          //         height: 16,
                          //         width: 16,
                          //       )),
                          //     ),
                          //     const SizedBox(
                          //       width: 10,
                          //     ),
                          //     // Share ________________
                          //     Container(
                          //       height: 36,
                          //       width: 36,
                          //       decoration: BoxDecoration(
                          //         border: Border.all(color: Colors.grey.shade200),
                          //         borderRadius: BorderRadius.circular(100),
                          //       ),
                          //       child: Center(
                          //           child: Image.asset(
                          //         'assets/images/send.png',
                          //         height: 16,
                          //         width: 16,
                          //       )),
                          //     ),
                          //   ],
                          // ),
                          // // The comments ________
                          // ListView
                          //     .builder(
                          //   physics:
                          //       const NeverScrollableScrollPhysics(),
                          //   shrinkWrap:
                          //       true,
                          //   scrollDirection:
                          //       Axis.vertical,
                          //   itemCount:
                          //       instastory1.length,
                          //   itemBuilder:
                          //       (context, index) {
                          //     return Column(
                          //       children: [
                          //         ListTile(
                          //           leading: Image.asset(
                          //             instastory1[index],
                          //             height: 30,
                          //             width: 30,
                          //           ),
                          //           title: Text(
                          //             text1[index],
                          //             style: const TextStyle(fontFamily: 'Urbanist-semibold', fontSize: 15),
                          //           ),
                          //           subtitle: Text(
                          //             subtitle[index],
                          //             style: const TextStyle(fontFamily: "Urbanist-medium"),
                          //           ),
                          //           trailing: Text(
                          //             time[index],
                          //             style: TextStyle(fontFamily: "Urbanist-medium", fontSize: 12, color: Colors.grey.shade400),
                          //           ),
                          //         ),
                          //         Padding(
                          //           padding: const EdgeInsets.only(left: 20),
                          //           child: Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               InkWell(
                          //                   onTap: () {
                          //                     changeValue(value: index);
                          //                   },
                          //                   child: Image.asset(
                          //                     selectIndex.contains(index) ? 'assets/images/heart2.png' : 'assets/images/hearts.png',
                          //                     height: 15,
                          //                     width: 15,
                          //                   )),
                          //               const SizedBox(
                          //                 width: 10,
                          //               ),
                          //               Image.asset(
                          //                 'assets/images/comment.png',
                          //                 height: 15,
                          //                 width: 15,
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          //         const SizedBox(
                          //           height: 10,
                          //         ),
                          //       ],
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(child: Text('Post not found.'));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: width <= 800
          ? _pageBody()
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 200, right: 200),
                child: _pageBody(),
              ),
            ),
    );
  }
}

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // SingingCharacter? _character = SingingCharacter.a;

  List img = [
    'assets/images/02.png',
    'assets/images/03.png',
    'assets/images/04.png',
    'assets/images/05.png',
    'assets/images/03.png',
  ];
  List text = [
    'M.S. Dhoni',
    'Alon musk',
    'Farrukh',
    'Popatlal',
    'Muatfa yeaf',
  ];
  List subtext = [
    'Typing Message...',
    'perfect!',
    'just ideas for next time',
    'How are you?',
    "So, what's your plan this week...",
  ];
  List time = [
    'Online',
    'Today',
    'Today',
    '27/01',
    '25/01',
  ];
  List<Color> colors = [
    const Color(0xff3BBAA6),
    const Color(0xff64748B),
    const Color(0xff64748B),
    const Color(0xff64748B),
    const Color(0xff64748B),
  ];

  String searchText = ''; // Text for search bar
  final TextEditingController searchController = TextEditingController();
  String sortBy = 'Date'; // Default sorting option
  String filterCategory = ''; // Default category (empty means no filter)

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Local state for filter options
            String selectedSort = 'Date'; // Default sort option
            String selectedCategory = ''; // Selected category
            List<String> categories = []; // Categories fetched dynamically

            // Fetch categories dynamically (Example)
            if (categories.isEmpty) {
              FirebaseFirestore.instance
                  .collection('posts')
                  .get()
                  .then((querySnapshot) {
                final uniqueCategories = querySnapshot.docs
                    .map((doc) => doc['category'] as String?)
                    .where(
                        (category) => category != null && category.isNotEmpty)
                    .toSet()
                    .toList();
                setState(() {
                  //  categories = uniqueCategories;
                });
              });
            }

            return AlertDialog(
              title: Text('Filter Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Filter
                  Text('Sort By:'),
                  DropdownButton<String>(
                    value: selectedSort,
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                    items: ['Date', 'Price', 'Most Liked'].map((sortOption) {
                      return DropdownMenuItem<String>(
                        value: sortOption,
                        child: Text(sortOption),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  Text('Category:'),
                  DropdownButton<String>(
                    value:
                        selectedCategory.isNotEmpty ? selectedCategory : null,
                    hint: Text('Select a Category'),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog without applying
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Apply filters
                    setState(() {
                      // Store the selected sort and category for filtering
                      sortBy = selectedSort;
                      filterCategory = selectedCategory;
                    });
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _pageBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: ApplicationColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: ApplicationColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            title: const Text(
              'Messages',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Urbanist-semibold',
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gamification/Contact/Card details ___________
                // Container(
                //   margin: EdgeInsets.only(left: 16, right: 16),
                //   child: Stack(
                //     children: [
                //       ClipRRect(
                //         borderRadius:
                //             BorderRadius.circular(24), // Apply the radius
                //         clipBehavior: Clip
                //             .antiAliasWithSaveLayer, // Ensures smooth clipping
                //         child: Image.asset(
                //           "assets/card3.jpg",
                //           fit: BoxFit.cover,
                //           height: 195,
                //           width: MediaQuery.of(context).size.width,
                //         ),
                //       ),
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           FutureBuilder<String>(
                //             future: FirebaseFirestore.instance
                //                 .collection("users")
                //                 .doc(FirebaseAuth
                //                     .instance.currentUser!.uid)
                //                 .get()
                //                 .then((snapshot) => snapshot
                //                     .data()!['full_name']
                //                     .toString()),
                //             builder: (context, snapshot) {
                //               if (snapshot.hasError) {
                //                 return Text(
                //                   "Error: ${snapshot.error}", // Handle errors
                //                   style: boldTextStyle(
                //                       color: white, size: 18),
                //                 );
                //               }
                //               switch (snapshot.connectionState) {
                //                 case ConnectionState.waiting:
                //                   return Text(
                //                     "Loading...",
                //                     style: boldTextStyle(
                //                         color: white, size: 18),
                //                   );
                //                 default:
                //                   return Text(
                //                     "${snapshot.data!}",
                //                     style: boldTextStyle(
                //                         color: white, size: 18),
                //                   );
                //               }
                //             },
                //           ),
                //           FutureBuilder<String>(
                //             future: FirebaseFirestore.instance
                //                 .collection("users")
                //                 .doc(FirebaseAuth
                //                     .instance.currentUser!.uid)
                //                 .get()
                //                 .then((snapshot) => snapshot
                //                     .data()!['username']
                //                     .toString()),
                //             builder: (context, snapshot) {
                //               if (snapshot.hasError) {
                //                 return Text(
                //                   "Error: ${snapshot.error}", // Handle errors
                //                   style: boldTextStyle(color: white),
                //                 );
                //               }
                //               switch (snapshot.connectionState) {
                //                 case ConnectionState.waiting:
                //                   return Text(
                //                     "Loading...",
                //                     style: boldTextStyle(color: white),
                //                   );
                //                 default:
                //                   return Text(
                //                     "@${snapshot.data!}",
                //                     style: boldTextStyle(color: white),
                //                   );
                //               }
                //             },
                //           ),
                //           SizedBox(height: 32.toDouble()),
                //           Text("Your Level/Score",
                //               style: boldTextStyle(
                //                   color: white.withOpacity(0.7))),
                //           Row(
                //             mainAxisAlignment:
                //                 MainAxisAlignment.spaceBetween,
                //             children: [
                //               Text(
                //                 "(1001)",
                //                 style:
                //                     boldTextStyle(color: white, size: 28),
                //               ),
                //               ElevatedButton(
                //                 onPressed: () {
                //                   Navigator.push(
                //                       context,
                //                       MaterialPageRoute(
                //                         builder: (context) =>
                //                             SharingScreen(),
                //                       ));
                //                 },
                //                 style: ApplicationButtons.button2(),
                //                 child: Row(
                //                   crossAxisAlignment:
                //                       CrossAxisAlignment.start,
                //                   children: [
                //                     Icon(Icons.emoji_events,
                //                         size: 18, color: black),
                //                     SizedBox(width: 4.toDouble()),
                //                     Text('Share & Earn',
                //                         style: primaryTextStyle(
                //                             color: black)),
                //                   ],
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ],
                //       ).paddingAll(24),
                //       SizedBox(height: 10.toDouble()),
                //     ],
                //   ),
                // ),
                // Chats Section ________________________
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chats History',
                        style: AppTypo.heading3
                            .copyWith(color: AppTextColors.primary)),
                  ],
                ).paddingSymmetric(horizontal: 16),
                // Padding(
                //   padding: const EdgeInsets.symmetric(
                //       horizontal: 8, vertical: 4),
                //   child: TextField(
                //     controller: searchController,
                //     decoration: InputDecoration(
                //       labelText: 'Search',
                //       prefixIcon: Icon(Icons.search),
                //       suffixIcon: IconButton(
                //         icon: Icon(Icons.filter_list),
                //         onPressed: () {
                //           _showFilterDialog(context);
                //         },
                //       ),
                //       border: OutlineInputBorder(),
                //     ),
                //     onChanged: (value) {
                //       setState(() {
                //         searchText = value
                //             .trim()
                //             .toLowerCase(); // Normalize the search query
                //       });
                //     },
                //   ),
                // ),
                // Showing only Chats opened! _____________________
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text('No relevant chat rooms found..');
                    }

                    String currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    List<DocumentSnapshot> filteredDocs =
                        snapshot.data!.docs.where((doc) {
                      List<String> ids = doc.id.split('_');
                      return ids.contains(currentUserId);
                    }).toList();

                    // ✅ Sort by lastMessageTimestamp descending
                    filteredDocs.sort((a, b) {
                      Timestamp? t1 = (a.data()
                          as Map<String, dynamic>)['lastMessageTimestamp'];
                      Timestamp? t2 = (b.data()
                          as Map<String, dynamic>)['lastMessageTimestamp'];
                      return (t2?.compareTo(t1 ?? Timestamp(0, 0)) ?? 0);
                    });

                    if (filteredDocs.isEmpty) {
                      return Text('No relevant chat rooms found.');
                    }

                    return ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                          left: 16, bottom: 16, right: 16, top: 8),
                      children: filteredDocs.map((doc) {
                        List<String> ids = doc.id.split('_');
                        String otherUserId =
                            ids.firstWhere((id) => id != currentUserId);

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(otherUserId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData)
                              return Text('Loading user info...');
                            Map<String, dynamic> userData = userSnapshot.data!
                                .data() as Map<String, dynamic>;
                            Map<String, dynamic> chatData =
                                doc.data() as Map<String, dynamic>;

                            // Check if there are unread messages
                            Timestamp? lastReadTimestamp =
                                chatData['lastReadTimestamps']?[currentUserId];
                            Timestamp lastMessageTimestamp =
                                chatData['lastMessageTimestamp'];

                            bool hasUnread = lastReadTimestamp == null ||
                                lastMessageTimestamp
                                    .toDate()
                                    .isAfter(lastReadTimestamp.toDate());

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      receiverUserName:
                                          userData['username'] ?? 'Unknown',
                                      receiverUserID: otherUserId,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(nonuser,
                                      height: 40, width: 40, fit: BoxFit.cover),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '@${userData['username'] ?? 'Unknown'}',
                                          style: boldTextStyle()),
                                      SizedBox(height: 8),
                                      Text('Press here to open Chat!',
                                          style: secondaryTextStyle()),
                                    ],
                                  ),
                                  if (hasUnread)
                                    Container(
                                      margin: EdgeInsets.only(left: 8),
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ).paddingSymmetric(vertical: 8),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) {
          //             return Scaffold(
          //               appBar: AppBar(title: Text('New Message')),
          //               body: SingleChildScrollView(
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Padding(
          //                       padding: const EdgeInsets.symmetric(
          //                           horizontal: 10),
          //                       child: General(text: 'Search'),
          //                     ),
          //                     StreamBuilder<QuerySnapshot>(
          //                       stream: FirebaseFirestore.instance
          //                           .collection('users')
          //                           .snapshots(),
          //                       builder: (context, snapshot) {
          //                         if (snapshot.hasError) {
          //                           return Text('Error Occured!');
          //                         }
          //                         if (snapshot.connectionState ==
          //                             ConnectionState.waiting) {
          //                           return Text('Loading!...');
          //                         }
          //                         return ListView(
          //                           physics:
          //                               const NeverScrollableScrollPhysics(),
          //                           shrinkWrap: true,
          //                           scrollDirection: Axis.vertical,
          //                           children: snapshot.data!.docs
          //                               .map<Widget>(
          //                                   (DocumentSnapshot document) {
          //                             Map<String, dynamic> data =
          //                                 document.data()!
          //                                     as Map<String, dynamic>;
          //                             return InkWell(
          //                               onTap: () {
          //                                 Navigator.push(
          //                                     context,
          //                                     MaterialPageRoute(
          //                                       builder: (context) =>
          //                                           ChatScreen(
          //                                         receiverUserName:
          //                                             data['username'],
          //                                         receiverUserID:
          //                                             data['uid'],
          //                                       ),
          //                                     ));
          //                               },
          //                               child: Column(
          //                                 children: [
          //                                   ListTile(
          //                                     leading: Container(
          //                                       height: 44,
          //                                       width: 44,
          //                                       margin: const EdgeInsets
          //                                               .symmetric(
          //                                           horizontal: 10),
          //                                       child: Container(
          //                                         height: 173,
          //                                         width: MediaQuery.of(
          //                                                 context)
          //                                             .size
          //                                             .width,
          //                                         decoration:
          //                                             BoxDecoration(
          //                                                 image:
          //                                                     DecorationImage(
          //                                                         image:
          //                                                             AssetImage(
          //                                                           nonuser,
          //                                                         ),
          //                                                         fit: BoxFit
          //                                                             .fill),
          //                                                 borderRadius:
          //                                                     BorderRadius
          //                                                         .circular(
          //                                                             100)),
          //                                       ),
          //                                     ),
          //                                     title: Text(
          //                                         '@${data['username']}',
          //                                         style: const TextStyle(
          //                                             fontSize: 14,
          //                                             fontWeight:
          //                                                 FontWeight.w400,
          //                                             fontFamily:
          //                                                 'Urbanist-regular',
          //                                             color:
          //                                                 Colors.black)),
          //                                     subtitle: Text('Hello!',
          //                                         style: TextStyle(
          //                                             fontSize: 14,
          //                                             fontWeight:
          //                                                 FontWeight.w400,
          //                                             fontFamily:
          //                                                 'Urbanist-regular',
          //                                             color:
          //                                                 Colors.black)),
          //                                     trailing: Text(
          //                                       'Time: _',
          //                                       style: const TextStyle(
          //                                           fontSize: 12,
          //                                           fontFamily:
          //                                               'Urbanist-medium',
          //                                           fontWeight:
          //                                               FontWeight.w500,
          //                                           color: Color(
          //                                               0xff64748B)),
          //                                     ),
          //                                   ),
          //                                   const SizedBox(
          //                                     height: 10,
          //                                   ),
          //                                 ],
          //                               ),
          //                             );
          //                           }).toList(),
          //                         );
          //                       },
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             );
          //           },
          //         ),
          //       );
          //     },
          //     child: Icon(Icons.message),
          //     backgroundColor: Colors.blue),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 800
        ? _pageBody()
        : Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 200,
                right: 200,
              ),
              child: _pageBody(),
            ),
          );
  }
}

class SharingScreen extends StatefulWidget {
  @override
  _SharingScreenState createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  TextEditingController? certificationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ApplicationColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Trophies & Certifications',
          style: TextStyle(
              fontSize: 18,
              fontFamily: 'Urbanist-semibold',
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
      ),
      backgroundColor: ApplicationColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Trophy image header ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                ],
              ),
            ),
          ),
          // --- Your Level Section ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Level/Score:", style: boldTextStyle()),
                SizedBox(height: 4),
                Text("Seed (1001)", style: boldTextStyle(size: 28)),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.3, // Placeholder progress value
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blue,
                  minHeight: 8,
                ),
              ],
            ),
          ),
          // --- Certification Code Entry ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter certification code below to unlock trophies or level up.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: certificationCodeController,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter your certification code',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    final enteredCode =
                        certificationCodeController?.text.trim();
                    if (enteredCode == null || enteredCode.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Please enter a certification code.')),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Code "$enteredCode" submitted (validation coming soon)')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // --- Trophy Cards (Standalone for each) ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Trophy 1
                  Container(
                    margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/trophy1.png',
                                height: 40, width: 40, fit: BoxFit.cover),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invite a Friend', style: boldTextStyle()),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    'Successfully refer someone to the app.',
                                    style: secondaryTextStyle(
                                        size: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Earn",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  // Trophy 2
                  Container(
                    margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/trophy1.png',
                                height: 40, width: 40, fit: BoxFit.cover),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Certified Recycler',
                                    style: boldTextStyle()),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    'Submit a valid recycling certificate code.',
                                    style: secondaryTextStyle(
                                        size: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Earn",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  // Trophy 3
                  Container(
                    margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/trophy1.png',
                                height: 40, width: 40, fit: BoxFit.cover),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('5-Day Login Streak',
                                    style: boldTextStyle()),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    'Login 5 days in a row to earn this trophy.',
                                    style: secondaryTextStyle(
                                        size: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Earn",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserID;
  const ChatScreen(
      {super.key,
      required this.receiverUserName,
      required this.receiverUserID});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send messages
  Future<void> _submitMessage() async {
    if (_messageController.text.isNotEmpty) {
      // Get user info
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final String currentUserFullName =
          userSnapshot.data()?['full_name'] ?? 'Unknown';

      final Timestamp timestamp = Timestamp.now();

      // Create new message
      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserFullName,
        receiverId: widget.receiverUserID,
        message: _messageController.text,
        timestamp: timestamp,
      );

      // Build chat room ID
      List<String> ids = [currentUserId, widget.receiverUserID];
      ids.sort();
      String chatRoomId = ids.join("_");

      // Firestore reference for chat room and messages
      final chatRoomRef =
          FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
      final messageRef = chatRoomRef.collection('messages').doc();

      try {
        // Add the message
        await messageRef.set(newMessage.toMap());
        print('Message added successfully.');

        // Check if chat room exists and update it
        final chatRoomSnapshot = await chatRoomRef.get();
        if (chatRoomSnapshot.exists) {
          // Update the existing chat room
          await chatRoomRef.update({
            'lastMessageTimestamp': timestamp,
            'lastReadTimestamps.$currentUserId': timestamp,
          });
          print('Chat room updated successfully.');
        } else {
          // Initialize the chat room
          await chatRoomRef.set({
            'lastMessageTimestamp': timestamp,
            'lastReadTimestamps': {
              currentUserId: timestamp, // Sender has read the message
              widget.receiverUserID: null, // Receiver hasn't read anything
            },
          });
          print('Chat room initialized successfully.');
        }
      } catch (e) {
        print('Error sending message: $e');
      }

      _messageController.clear();
    }
  }

  // Get messages
  Stream<QuerySnapshot> _getMessage() {
    // build chatroom Id
    List<String> ids = [
      widget.receiverUserID,
      FirebaseAuth.instance.currentUser!.uid
    ];
    ids.sort();
    String chatRoomId = ids.join("_");

    //get the messages
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  List img = [
    'assets/images/chat6.png',
    'assets/images/chat1.png',
    'assets/images/chat2.png',
    'assets/images/chat3.png',
    'assets/images/chat4.png',
    'assets/images/chat5.png',
  ];

  List text = [
    'Contact',
    'Camera',
    'Gallery',
    'Document',
    'Audio',
    'Location',
  ];

  void _openMessageDetailsScreen(String message, Timestamp timestamp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final formattedTime =
              intl.DateFormat('yyyy-MM-dd – HH:mm').format(timestamp.toDate());

          return Scaffold(
            appBar: AppBar(
              title: Text('Message Details'),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              backgroundColor: ApplicationColors.background,
            ),
            backgroundColor: ApplicationColors.background,
            body: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🕓 Timestamp
                    Text(
                      'Sent at: $formattedTime',
                      style: secondaryTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // 🗨️ Message content
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue,
                      ),
                      child: Text(
                        message,
                        style: boldTextStyle(color: Colors.white, size: 18),
                        softWrap: true,
                      ),
                    ),
                    SizedBox(height: 30),

                    // 📤 Copy & Share buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Copied to clipboard")),
                            );
                          },
                          icon: Icon(Icons.copy),
                          label: Text("Copy"),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            //  Share.share(message);
                          },
                          icon: Icon(Icons.share),
                          label: Text("Share"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pageBody() {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ensures body resizes with keyboard
      backgroundColor: ApplicationColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ApplicationColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/nonuser.png'),
            ),
            SizedBox(width: 8),
            Text(
              widget.receiverUserName,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessage(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading...');
                }

                // Fetch the last read timestamp for the current user
                final chatRoomId = [
                  FirebaseAuth.instance.currentUser!.uid,
                  widget.receiverUserID
                ]..sort();
                final chatRoomDocRef = FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId.join("_"));

                return FutureBuilder<DocumentSnapshot>(
                  future: chatRoomDocRef.get(),
                  builder: (context, chatRoomSnapshot) {
                    if (!chatRoomSnapshot.hasData ||
                        !chatRoomSnapshot.data!.exists) {
                      return Text('No messages found.');
                    }

                    final chatRoomData =
                        chatRoomSnapshot.data!.data() as Map<String, dynamic>;
                    final Timestamp? lastReadTimestamp =
                        chatRoomData['lastReadTimestamps']
                            ?[FirebaseAuth.instance.currentUser!.uid];

                    // Mark messages as read when chat is opened
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final chatRoomId = [
                        FirebaseAuth.instance.currentUser!.uid,
                        widget.receiverUserID
                      ]..sort();
                      await FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .doc(chatRoomId.join("_"))
                          .update({
                        'lastReadTimestamps.${FirebaseAuth.instance.currentUser!.uid}':
                            Timestamp.now(),
                      });
                    });

                    // Build message items
                    return ListView(
                      controller: _scrollController,
                      reverse: true,
                      children: snapshot.data!.docs.reversed.map((document) {
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        final Timestamp messageTimestamp = data['timestamp'];

                        // Determine if the message is unread
                        bool isUnread = lastReadTimestamp == null ||
                            messageTimestamp
                                .toDate()
                                .isAfter(lastReadTimestamp.toDate());

                        // Aligning messages for the sender and receiver
                        var alignment = (data['senderId'] ==
                                FirebaseAuth.instance.currentUser!.uid)
                            ? Alignment.centerRight
                            : Alignment.centerLeft;

                        return Container(
                          alignment: alignment,
                          child: Column(
                            crossAxisAlignment:
                                alignment == Alignment.centerRight
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Text(data['senderEmail']), // Sender's email
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Indicator for unread messages
                                  if (isUnread)
                                    Container(
                                      margin: EdgeInsets.only(right: 8),
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .red, // Red indicator for unread messages
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  // Message bubble
                                  InkWell(
                                    onTap: () {
                                      _openMessageDetailsScreen(
                                          data['message'], data['timestamp']);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.blue,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                      ),
                                      child: Text(
                                        data['message'],
                                        style: boldTextStyle(),
                                        softWrap: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                // bottom: MediaQuery.of(context).viewInsets.bottom,
                ), // pushes up when keyboard opens
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: ListTile(
                  leading: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/nonuser.png'),
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  title: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      hintText: 'Type something in here...',
                      hintStyle: const TextStyle(
                        color: Color(0xffCBD5E1),
                        fontFamily: 'Urbanist-medium',
                        fontWeight: FontWeight.w500,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (context) {
                                  return Container(
                                    height: 300,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 15),
                                        const Center(
                                          child: Text(
                                            'More Menu',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Urbanist-semibold',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 20),
                                          child: Divider(
                                            height: 2,
                                            thickness: 1,
                                            color: Color(0xffE2E8F0),
                                          ),
                                        ),
                                        GridView.builder(
                                          itemCount: img.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                          ),
                                          itemBuilder: (context, index) {
                                            return Column(
                                              children: [
                                                Image.asset(
                                                  img[index],
                                                  height: 44,
                                                  width: 44,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  text[index],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'Urbanist-medium',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Icon(Icons.more_vert,
                                color: Colors.grey, size: 16),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  trailing: SizedBox(
                    height: 40,
                    width: 40,
                    child: FloatingActionButton(
                      heroTag: null,
                      backgroundColor: const Color(0xff3BBAA6),
                      elevation: 0,
                      onPressed: _submitMessage,
                      child: Image.asset(
                        'assets/images/send.png',
                        height: 24,
                        width: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: Container(
      //   height: 90,
      //   color: Colors.white,
      //   child: Center(
      //     child: ListTile(
      //       leading: Container(
      //         height: 36,
      //         width: 36,
      //         decoration: BoxDecoration(
      //             image: const DecorationImage(
      //               image: AssetImage(
      //                 'assets/images/nonuser.png',
      //               ),
      //             ),
      //             borderRadius: BorderRadius.circular(100)),
      //       ),
      //       title: SizedBox(
      //         height: 40,
      //         child: TextField(
      //           controller: _messageController,
      //           style: const TextStyle(color: Colors.black),
      //           decoration: InputDecoration(
      //             enabledBorder: OutlineInputBorder(
      //               borderSide: BorderSide(color: Colors.grey.shade300),
      //             ),
      //             focusedBorder: OutlineInputBorder(
      //               borderSide: BorderSide(color: Colors.grey.shade300),
      //             ),
      //             contentPadding:
      //                 const EdgeInsets.symmetric(horizontal: 10),
      //             hintText: 'Type something in here...',
      //             hintStyle: const TextStyle(
      //                 color: Color(0xffCBD5E1),
      //                 fontFamily: 'Urbanist-medium',
      //                 fontWeight: FontWeight.w500),
      //             suffixIcon: Row(
      //               mainAxisSize: MainAxisSize.min,
      //               mainAxisAlignment: MainAxisAlignment.end,
      //               children: [
      //                 InkWell(
      //                     onTap: () {
      //                       showModalBottomSheet(
      //                         backgroundColor: Colors.transparent,
      //                         context: context,
      //                         builder: (context) {
      //                           return Container(
      //                             height: 300,
      //                             decoration: const BoxDecoration(
      //                                 color: Colors.white,
      //                                 borderRadius: BorderRadius.only(
      //                                   topRight: Radius.circular(20),
      //                                   topLeft: Radius.circular(20),
      //                                 )),
      //                             child: Column(
      //                               crossAxisAlignment:
      //                                   CrossAxisAlignment.start,
      //                               children: [
      //                                 const SizedBox(
      //                                   height: 15,
      //                                 ),
      //                                 const Center(
      //                                     child: Text(
      //                                   'More Menu',
      //                                   style: TextStyle(
      //                                       fontSize: 16,
      //                                       fontFamily:
      //                                           'Urbanist-semibold',
      //                                       fontWeight: FontWeight.w600),
      //                                 )),
      //                                 const Padding(
      //                                   padding: EdgeInsets.symmetric(
      //                                       horizontal: 20, vertical: 20),
      //                                   child: Divider(
      //                                     height: 2,
      //                                     thickness: 1,
      //                                     color: Color(0xffE2E8F0),
      //                                   ),
      //                                 ),
      //                                 GridView.builder(
      //                                   itemCount: img.length,
      //                                   scrollDirection: Axis.vertical,
      //                                   shrinkWrap: true,
      //                                   gridDelegate:
      //                                       const SliverGridDelegateWithFixedCrossAxisCount(
      //                                           crossAxisCount: 4),
      //                                   itemBuilder: (context, index) {
      //                                     return Column(
      //                                       children: [
      //                                         Image.asset(
      //                                           img[index],
      //                                           height: 44,
      //                                           width: 44,
      //                                         ),
      //                                         const SizedBox(
      //                                           height: 10,
      //                                         ),
      //                                         Text(
      //                                           text[index],
      //                                           style: const TextStyle(
      //                                               fontSize: 12,
      //                                               fontFamily:
      //                                                   'Urbanist-medium',
      //                                               fontWeight:
      //                                                   FontWeight.w500),
      //                                         ),
      //                                       ],
      //                                     );
      //                                   },
      //                                 ),
      //                               ],
      //                             ),
      //                           );
      //                         },
      //                       );
      //                     },
      //                     child: Image.asset(
      //                       'assets/images/happyemoji.png',
      //                       height: 16,
      //                       width: 16,
      //                     )),
      //                 const SizedBox(
      //                   width: 10,
      //                 ),
      //                 InkWell(
      //                     onTap: () {
      //                       showModalBottomSheet(
      //                         backgroundColor: Colors.transparent,
      //                         context: context,
      //                         builder: (context) {
      //                           return Container(
      //                             height: 300,
      //                             decoration: const BoxDecoration(
      //                               borderRadius: BorderRadius.only(
      //                                   topLeft: Radius.circular(20),
      //                                   topRight: Radius.circular(20)),
      //                               color: Colors.white,
      //                             ),
      //                             child: Column(
      //                               crossAxisAlignment:
      //                                   CrossAxisAlignment.start,
      //                               children: [
      //                                 const SizedBox(
      //                                   height: 15,
      //                                 ),
      //                                 const Center(
      //                                     child: Text(
      //                                   'More Menu',
      //                                   style: TextStyle(
      //                                       fontSize: 16,
      //                                       fontFamily:
      //                                           'Urbanist-semibold',
      //                                       fontWeight: FontWeight.w600),
      //                                 )),
      //                                 const Padding(
      //                                   padding: EdgeInsets.symmetric(
      //                                       horizontal: 20, vertical: 20),
      //                                   child: Divider(
      //                                     height: 2,
      //                                     thickness: 1,
      //                                     color: Color(0xffE2E8F0),
      //                                   ),
      //                                 ),
      //                                 GridView.builder(
      //                                   itemCount: img.length,
      //                                   scrollDirection: Axis.vertical,
      //                                   shrinkWrap: true,
      //                                   gridDelegate:
      //                                       const SliverGridDelegateWithFixedCrossAxisCount(
      //                                           crossAxisCount: 4),
      //                                   itemBuilder: (context, index) {
      //                                     return Column(
      //                                       children: [
      //                                         Image.asset(
      //                                           img[index],
      //                                           height: 44,
      //                                           width: 44,
      //                                         ),
      //                                         const SizedBox(
      //                                           height: 10,
      //                                         ),
      //                                         Text(
      //                                           text[index],
      //                                           style: const TextStyle(
      //                                               fontSize: 12,
      //                                               fontFamily:
      //                                                   'Urbanist-medium',
      //                                               fontWeight:
      //                                                   FontWeight.w500),
      //                                         ),
      //                                       ],
      //                                     );
      //                                   },
      //                                 ),
      //                               ],
      //                             ),
      //                           );
      //                         },
      //                       );
      //                     },
      //                     child: const Icon(Icons.more_vert,
      //                         color: Colors.grey, size: 16)),
      //                 const SizedBox(
      //                   width: 10,
      //                 ),
      //               ],
      //             ),
      //             border: OutlineInputBorder(
      //               borderRadius: BorderRadius.circular(12),
      //             ),
      //           ),
      //         ),
      //       ),
      //       trailing: SizedBox(
      //         height: 40,
      //         width: 40,
      //         child: FloatingActionButton(
      //           heroTag: null,
      //           backgroundColor: const Color(0xff3BBAA6),
      //           elevation: 0,
      //           onPressed: _submitMessage,
      //           child: Image.asset(
      //             'assets/images/send.png',
      //             height: 24,
      //             width: 24,
      //             color: Colors.white,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 800
        ? _pageBody()
        : Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 200,
                right: 200,
              ),
              child: _pageBody(),
            ),
          );
  }
}

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  Message(
      {required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp});

  // convert to map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
