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
// import 'package:syncfusion_flutter_calendar/calendar.dart';
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
        '/': (context) => HomePageWidget(),
        // '/contactus': (context) => ContactusPage(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        return null; // For undefined routes
      },
    );
  }
}

// ________________________________________________
// NavBar Section
// HomePage Section || Widget 0
// ________________________________________________

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  final FocusNode f1 = FocusNode();
  final FocusNode f2 = FocusNode();

  String _enteredPhone = '';
  String _selectedCountryCode = '+966'; // Default country code
  String _enteredEmail = '';
  String _enteredUserName = '';
  String _enteredPassword = '';
  String _enteredFullName = '';

  bool isIconTrue = true;
  bool isChecked = false;
  bool? checkBoxValue = false;
  bool _isPhoneInput = false;

  int? _resendToken;
  bool _isSignIn = true;

  String otpBaseUrl = "https://otpbridge-42656840839.europe-west8.run.app";

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

    if (_enteredPhone.isEmpty) {
      _showError("Please enter your phone number");
      return;
    }

    try {
      // ✅ 1. Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(ApplicationSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("Checking phone number..."),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );

      // ✅ 2. Firestore REST query
      final url = Uri.parse(
        "https://firestore.googleapis.com/v1/projects/lessernaqaa/databases/(default)/documents:runQuery",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "structuredQuery": {
            "from": [
              {"collectionId": "users"}
            ],
            "where": {
              "fieldFilter": {
                "field": {"fieldPath": "phone_number"},
                "op": "EQUAL",
                "value": {"stringValue": _enteredPhone}
              }
            },
            "limit": 1
          }
        }),
      );

      Navigator.pop(context); // close loading

      final data = jsonDecode(response.body);

      // ❌ 3. Not found
      if (data.isEmpty || data[0]["document"] == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Not Registered"),
            content: const Text("This phone number is not registered."),
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

      // ✅ 4. Extract userId
      final docPath = data[0]["document"]["name"];
      final userId = docPath.split("/").last;

      // ✅ 5. Navigate
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WeightScreen(
            phone: _enteredPhone,
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      try {
        Navigator.pop(context);
      } catch (_) {}
      _showError("Something went wrong. Please try again!");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _pageBody() {
    return Center(
      child: Column(
        children: [
          // The main Logo and slogan ____________________
          SizedBox(height: 8),
          const Image(
            image: AssetImage('assets/images/lesserlogo1.png'),
            width: 200,
          ),
          SizedBox(height: 8),
          // Login/Start ________
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'أعِد التدوير وإحصل على جوائز!',
                    style: AppTypo.heading2.copyWith(
                      color: AppTextColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Recycle and get rewards!',
                    style: AppTypo.heading2.copyWith(
                      color: AppTextColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Phone _______
                  SizedBox(height: 20),
                  IntlPhoneField(
                    showDropdownIcon: true, // Keep dropdown icon for selection
                    showCountryFlag: false,
                    decoration: InputDecoration(hintText: "Enter Phone Number"),
                    initialCountryCode: 'SA',
                    onChanged: (phone) => _enteredPhone = phone.completeNumber,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _submit();
                      }
                    },
                    style: ApplicationButtons.button0(),
                    child: Text(
                      'Start',
                      style: AppTypo.bodyBold.copyWith(
                        color: AppTextColors.inverse,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      // _showResetPasswordDialog(context);
                    },
                    child: Text('Do not have an account?',
                        style: AppTypo.bodyBold.copyWith(
                          color: AppTextColors.secondary,
                        )),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          // Chart visualizations Section __________________
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.large),
                            decoration: ApplicationContainers.container1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Image(
                                  image: AssetImage('assets/images/co2-2.png'),
                                  width: 62,
                                ),
                                const SizedBox(height: 8),
                                // FutureBuilder<String?>(
                                //   future:
                                //       FirebaseAuth.instance.currentUser?.uid !=
                                //               null
                                //           ? FirebaseFirestore.instance
                                //               .collection('users')
                                //               .doc(FirebaseAuth
                                //                   .instance.currentUser!.uid)
                                //               .get()
                                //               .then(
                                //                 (snapshot) => snapshot
                                //                     .data()!['bottles']
                                //                     .toString(),
                                //               )
                                //           : Future.value(null),
                                //   builder: (context, snapshot) {
                                //     if (snapshot.hasError) {
                                //       return Text(
                                //         'Error: ${snapshot.error}',
                                //         style: const TextStyle(
                                //           fontSize: 16.0,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       );
                                //     }
                                //     switch (snapshot.connectionState) {
                                //       case ConnectionState.waiting:
                                //         return Text(
                                //           '...',
                                //           style: AppTypo.heading3.copyWith(
                                //             color: ApplicationColors.primary,
                                //           ),
                                //         );
                                //       default:
                                //         final data = snapshot.data ?? '0';
                                //         final numberOfBottles =
                                //             int.tryParse(data) ?? 0;
                                //         final totalCO2 =
                                //             numberOfBottles * 0.015;
                                //         return Text(
                                //           totalCO2.toStringAsFixed(3),
                                //           style: AppTypo.heading3.copyWith(
                                //             color: ApplicationColors.secondary,
                                //           ),
                                //         );
                                //     }
                                //   },
                                // ),
                                const SizedBox(height: 4),
                                Text(
                                  translate('co2_emissions', targetLanguage),
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
                            padding:
                                const EdgeInsets.all(ApplicationSpacing.large),
                            decoration: ApplicationContainers.container1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Image(
                                  image:
                                      AssetImage('assets/images/waste-2.png'),
                                  width: 62,
                                ),
                                const SizedBox(height: 8),
                                // FutureBuilder<String?>(
                                //   future:
                                //       FirebaseAuth.instance.currentUser?.uid !=
                                //               null
                                //           ? FirebaseFirestore.instance
                                //               .collection('users')
                                //               .doc(FirebaseAuth
                                //                   .instance.currentUser!.uid)
                                //               .get()
                                //               .then(
                                //                 (snapshot) => snapshot
                                //                     .data()!['waste']
                                //                     .toString(),
                                //               )
                                //           : Future.value(null),
                                //   builder: (context, snapshot) {
                                //     if (snapshot.hasError) {
                                //       return Text(
                                //         'Error: ${snapshot.error}',
                                //         style: const TextStyle(
                                //           fontSize: 16.0,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       );
                                //     }
                                //     switch (snapshot.connectionState) {
                                //       case ConnectionState.waiting:
                                //         return Text(
                                //           '...',
                                //           style: AppTypo.heading3.copyWith(
                                //             color: AppTextColors.primary,
                                //           ),
                                //         );
                                //       default:
                                //         return Text(
                                //           snapshot.data ?? '0',
                                //           style: AppTypo.heading3.copyWith(
                                //             color: ApplicationColors.secondary,
                                //           ),
                                //         );
                                //     }
                                //   },
                                // ),
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
          ),
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

class WeightScreen extends StatefulWidget {
  final String phone;
  final String userId;

  const WeightScreen({
    super.key,
    required this.phone,
    required this.userId,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  double? baselineWeight;
  double currentWeight = 0.0;
  double sessionWeight = 0.0;

  bool isLoading = true;
  bool hasError = false;
  bool isFinished = false;

  Timer? _timer;

  final String apiUrl = "http://localhost:5000/weight";

  // ⚙️ tuning
  final double noiseThreshold = 0.02; // ignore small fluctuations
  final Duration pollInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initializeWeight();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 🌐 API call
  Future<double> _fetchWeight() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception("API error");
    }

    final data = jsonDecode(response.body);

    // ⚠️ you will adjust this after calibration
    final raw = data["raw_value"];

    // TEMP conversion (you will calibrate later)
    double weight = raw / 100000.0;

    return weight;
  }

  // 🔥 STEP 1: get baseline
  Future<void> _initializeWeight() async {
    try {
      final weight = await _fetchWeight();

      baselineWeight = weight;
      currentWeight = weight;

      isLoading = false;

      setState(() {});

      _startPolling();
    } catch (e) {
      hasError = true;
      isLoading = false;
      setState(() {});
    }
  }

  // 🔁 STEP 2: polling
  void _startPolling() {
    _timer = Timer.periodic(pollInterval, (_) async {
      if (isFinished) return;

      try {
        final newWeight = await _fetchWeight();

        // 🧠 Noise filtering
        if ((newWeight - currentWeight).abs() < noiseThreshold) {
          return;
        }

        currentWeight = newWeight;

        // 🧠 Session calculation
        if (baselineWeight != null) {
          double diff = currentWeight - baselineWeight!;

          // ❌ Prevent negative
          if (diff < 0) diff = 0;

          sessionWeight = diff;
        }

        setState(() {});
      } catch (e) {
        hasError = true;
        setState(() {});
      }
    });
  }

  // ✅ Finish
  void _finishSession() {
    _timer?.cancel();

    setState(() {
      isFinished = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Session Complete"),
        content: Text(
          "Total weight: ${sessionWeight.toStringAsFixed(2)} kg",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // back to first screen
            },
            child: Text("Done"),
          ),
        ],
      ),
    );

    // 👉 later:
    // send to Firestore / backend here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApplicationColors.background,
      appBar: AppBar(actions: []),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 👤 User info
              Text(
                widget.phone,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // 🔄 STATES
              if (isLoading)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Initializing scale..."),
                  ],
                )
              // else if (hasError)
              //   Column(
              //     children: const [
              //       Icon(Icons.error, color: Colors.red, size: 40),
              //       SizedBox(height: 10),
              //       Text("Connection error"),
              //     ],
              //   )
              else ...[
                // ⚖️ WEIGHT DISPLAY
                Text(
                  sessionWeight.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "KG",
                  style: TextStyle(fontSize: 24),
                ),

                const SizedBox(height: 20),

                const Text("Add items to the container"),

                const SizedBox(height: 30),

                // 🟢 Live indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    SizedBox(width: 6),
                    Text("Live"),
                  ],
                ),

                const SizedBox(height: 40),

                // ✅ Finish button
                ElevatedButton(
                  onPressed: _finishSession,
                  style: ApplicationButtons.button0(),
                  child: const Text("Finish"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
