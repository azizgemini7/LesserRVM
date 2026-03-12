// UI: Design and translation system: __________________
import 'package:flutter/material.dart';
import 'main.dart';

// Translation System: ________________________

String translate(String key, String languageCode) {
  return translations[languageCode]?[key] ?? key;
}

const Map<String, Map<String, String>> translations = {
  'en': {
    // HomePage ______
    'welcome_message': 'Welcome to Lesser!',
    'home': 'Home',
    'discover': 'Discover',
    'leaderboard': 'Leaderboard',
    'offers': 'Offers',
    'recycle': 'Recycle',
    'show_profile': 'Show Profile',
    'hide_profile': 'Hide Profile',
    'points': 'Points',
    'total_points': 'Total Points',
    'impact': 'Impact',
    'bottles': 'Bottles',
    'cans': 'Cans',
    'co2_emissions': 'CO2 Emissions',
    'kg_waste': 'KG Waste',
    'new_branch': 'New branch',
    'required_signing': 'Please Sign In or Sign Up',
    'required_signing2': 'You need to be signed in to perform this action',
    'loading_profile': 'Loading profile...',
    'something_wrong': "Something went wrong.",
    // NetPage ______
    'messages': 'Messages',
    'rules': 'Rules And Notes',
    'social_channels': 'Social Channels',
    'contact_us': 'Contact us',
    'contact_us_content':
        'Contact us live inside the application through Messaging in "Discover" page, or you can send an email to support team: care@lesserapp.com',
    'privacy_policy': 'Privacy policy',
    'privacy_policy_content':
        'While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to: Email address, First name and last name, Phone number, Address, State, Province, ZIP/Postal code, City \nUsage Data: Age group, Number of recycling activities through the application',
    'how_to_use': 'How to use',
    'how_to_use_content':
        'We have two main services in the application that gives you points:\n1- Drop Off: which done by our reverse vending machines (RVM) you can find nearest to your location via recycle page \n2- Pickup order: which done by our trucks that come to your location and pickup the items/bags in the recycle page.',
    'terms_of_service': 'Terms of service',
    'terms_of_service_content':
        'Disclosure of Your Personal Data \nBusiness Transactions \nIf the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred. We will provide notice before Your Personal Data is transferred and becomes subject to a different Privacy Policy.\n Law enforcement\n Under certain circumstances, the Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities (e.g. a court or a government agency).',
    // EnvPage ______
    'wallet': 'Redeem',
    // Add more translations here
  },
  'ar': {
    // HomePage ______
    'welcome_message': 'مرحبًا بك في ليسر!',
    'home': 'الرئيسية',
    'discover': 'إكتشف',
    'leaderboard': 'الترتيب',
    'offers': 'العروض',
    'recycle': 'التدوير',
    'show_profile': 'إظهار الملف الشخصي',
    'hide_profile': 'إخفاء الملف الشخصي',
    'points': 'النقاط',
    'total_points': 'مجموع النقاط',
    'impact': 'الأثر',
    'bottles': 'علب بلاستيكية',
    'cans': 'علب معدنية',
    'co2_emissions': 'إنبعاث كربوني',
    'kg_waste': 'وزن كيلوجرام',
    'new_branch': 'إضافة فرع',
    'required_signing': 'الرجاء تسجيل الدخول أو إنشاء حساب',
    'required_signing2': 'يجب ان يكون لديك حساب لإتمام العملية',
    'loading_profile': 'جارٍ تحميل الملف الشخصي...',
    'something_wrong': "حدث خطاء",
    // NetPage ______
    'messages': 'الرسائل',
    'rules': 'القوانين والملاحظات',
    'social_channels': 'القنوات الاجتماعية',
    'contact_us': 'إتصل بنا',
    'contact_us_content':
        'تواصل معنا مباشرة من داخل التطبيق عن طريق أيقونة التواصل في أعلى صفحة "إكتشف"، /n أو يمكنك إرسال رسالة عبر الإيميل الخاص بالدعم: care@lesserapp.com',
    'privacy_policy': 'سياسة الخصوصية',
    'privacy_policy_content':
        'While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to: Email address, First name and last name, Phone number, Address, State, Province, ZIP/Postal code, City \nUsage Data: Age group, Number of recycling activities through the application',
    'how_to_use': 'كيفية الإستخدام',
    'how_to_use_content':
        'لدينا طريقتان رئيسيتان للحصول أو جمع النقاط في التطبيق:\n1- Drop Off: والذي يتم عن طريق إيداع أو إدخال العلب في الأجهزة المخصصة الموجودة في الخريطة الخاصة بإعادة التدوير \n2- Pickup order: والذي يتم عن طريق شاحناتنا التي ستحضر في موقعك من خلال طلبك للخدمة في صفحة إعادة التدوير.',
    'terms_of_service': 'شروط الخدمة',
    'terms_of_service_content':
        'Disclosure of Your Personal Data \nBusiness Transactions \nIf the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred. We will provide notice before Your Personal Data is transferred and becomes subject to a different Privacy Policy.\n Law enforcement\n Under certain circumstances, the Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities (e.g. a court or a government agency).',
    // EnvPage ______
    'wallet': 'المحفظة',
    // Add more translations here
  },
  // Add other languages as needed
};

// Example Usage Translation:
// 1. Translate the word/text needed
// 2. Go to translations map in uisystem.dart create a variable like 'discover'
// 3. use this same variable for all languages needed: eg. arabic and english
// 4. Insert this function in a Text widget in main.dart file:
// translate('Var', targetLanguage)
// 5. Exchange Var text with the actual variable from translation map inside uisystem.dart

/// Design System: __________________

// Colors & (Modes = Light/Dark/Colorful)

enum AppThemeMode {
  light,
  dark,
  colorful,
}

class ApplicationColors {
  // Background
  static Color get background {
    switch (targetThemeMode) {
      case AppThemeMode.dark:
        return Color(0xFF072f45);
      case AppThemeMode.colorful:
        return const Color(0xFFecfdff);
      case AppThemeMode.light:
      default:
        return Color(0xFFFAFDFF);
    }
  }

  static Color get surface {
    switch (targetThemeMode) {
      case AppThemeMode.dark:
        return Color(0xFF0b4f6f);
      case AppThemeMode.colorful:
        return const Color(0xFFecfdff);
      case AppThemeMode.light:
      default:
        return Color(0xFFFFFFFF);
    }
  }

  // Main brand colors
  static Color get primary {
    switch (targetThemeMode) {
      case AppThemeMode.dark:
        return const Color(0xFF02A5D0); // Softer blue in dark mode
      case AppThemeMode.colorful:
        return const Color(0xFF23A18C); // Bright amber for fun
      case AppThemeMode.light:
      default:
        return const Color(0xFF02A5D0); // Original bright blue
    }
  }

// App theme text colors
  static Color get secondary {
    switch (targetThemeMode) {
      case AppThemeMode.dark:
        return Colors.white;
      case AppThemeMode.colorful:
        return Colors.black;
      case AppThemeMode.light:
      default:
        return Colors.black;
    }
  }

  // Status colors (Static — same across themes)
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}

const Color white = Color(0xFFFFFFFF);
const Color black = Color(0xFF000000);
const Color gray = Color(0xFF757575);
const Color primaryBlackColor = Colors.black;

// Icons & Images
const nonuser = 'assets/images/nonuser.png';

// class ApplicationIcons {
//   static const IconData home = Icons.home;
//   static const IconData settings = Icons.settings;
//   static const IconData account = Icons.account_circle;
// }

// Typography - (maryam: to be removed later)
class ApplicationTextStyles {
  static TextStyle get textPrimary {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: ApplicationColors.secondary,
    );
  }

  static TextStyle get textSecondary {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    );
  }
}

// New Typography
class AppTypo {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );
}

class AppTextColors {
  static Color get primary {
    switch (targetThemeMode) {
      case AppThemeMode.dark:
        return const Color(0xFFFFFFFF); // Softer blue in dark mode
      case AppThemeMode.colorful:
        return const Color(0xe2000000); // Bright amber for fun
      case AppThemeMode.light:
      default:
        return const Color(0xe2000000); // Original bright blue
    }
  }

  static const Color secondary = Color(0xFF466873);
  static const Color disabled = Color(0xFFB3C0C5);
  static const Color brand = Color(0xFF02A5D0);
  static const Color inverse = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFE11D48);
}

// maryam: to be removed later
TextStyle boldTextStyle({Color color = Colors.black, double size = 18}) {
  return TextStyle(fontWeight: FontWeight.bold, fontSize: size, color: color);
}

TextStyle primaryTextStyle({Color color = Colors.black, double size = 16}) {
  return TextStyle(fontWeight: FontWeight.w500, fontSize: size, color: color);
}

TextStyle secondaryTextStyle({Color color = Colors.grey, double size = 14}) {
  return TextStyle(fontWeight: FontWeight.normal, fontSize: size, color: color);
}

// Spacing
class ApplicationSpacing {
  static const double xSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
}

// Containers
class ApplicationContainers {
  // Most common: solid white with medium shadow
  static BoxDecoration get container1 {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: ApplicationColors.surface,
      boxShadow: [
        BoxShadow(
          color: ApplicationColors.secondary.withAlpha(20),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // Slightly lighter shadow — can be used for cards/lists
  static BoxDecoration get container2 {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: ApplicationColors.surface,
      boxShadow: [
        BoxShadow(
          color: ApplicationColors.secondary.withAlpha(20),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  // No shadow — just border (for outlines)
  static BoxDecoration get container3 {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: ApplicationColors.background,
      border: Border.all(
        color: ApplicationColors.secondary,
        width: 1,
      ),
    );
  }

  // Gradient background — for highlight sections or cards
  static BoxDecoration get container4 {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF21A18C),
          Color(0xFF01A4D0),
          Color(0xFF004E64),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// Input Fields
class ApplicationInputFields {
  // 0- Material/Flutter Original
  static InputDecoration input0() {
    return const InputDecoration(
        // No properties
        );
  }

  // 1- First
  static InputDecoration input1() {
    return InputDecoration(
      filled: true, // ✅ enable background color
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: ApplicationColors.primary),
      ),
      contentPadding: EdgeInsets.all(ApplicationSpacing.small),
    );
  }

  // 2- Second
  static InputDecoration input2() {
    return InputDecoration(
      filled: true, // ✅ enable background color
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        borderSide: BorderSide(color: ApplicationColors.primary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}

// Buttons
class ApplicationButtons {
  /// 0 - Original raw style from existing UI (black bg, white text, large padding)
  static ButtonStyle button0() {
    return ElevatedButton.styleFrom(
      backgroundColor: ApplicationColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  /// 1 - Primary app-wide style
  static ButtonStyle button1() {
    return ElevatedButton.styleFrom(
      backgroundColor: ApplicationColors.primary,
      foregroundColor: AppTextColors.inverse,
      padding: EdgeInsets.symmetric(
        vertical: ApplicationSpacing.small,
        horizontal: ApplicationSpacing.medium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(45.0),
      ),
      textStyle: AppTypo.bodyBold,
    );
  }

  /// 2 - Secondary outlined style
  static ButtonStyle button2() {
    return OutlinedButton.styleFrom(
      // padding: EdgeInsets.symmetric(
      //   vertical: ApplicationSpacing.small,
      //   horizontal: ApplicationSpacing.medium,
      // ),
      padding: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      textStyle: AppTypo.bodyBold,
    );
  }

  /// 3 - Style used by the old AppButton (white, rounded, no elevation)
  static ButtonStyle button3() {
    return TextButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      elevation: 0.0,
    );
  }
}

class AppButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String? text;
  final double? width;
  final Color? color;
  final Color? textColor;
  final Color? disabledColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final ShapeBorder? shapeBorder;
  final Widget? child;
  final double? elevation;
  final double? height;
  final bool enabled;
  final bool enableScaleAnimation;
  final Color? disabledTextColor;
  final double? hoverElevation;
  final double? focusElevation;
  final double? highlightElevation;

  const AppButton({
    Key? key,
    this.onTap,
    this.text,
    this.width,
    this.color,
    this.textColor,
    this.padding,
    this.margin,
    this.textStyle,
    this.shapeBorder,
    this.child,
    this.elevation = 2.0,
    this.enabled = true,
    this.height = 48.0,
    this.disabledColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.enableScaleAnimation = true,
    this.disabledTextColor,
    this.hoverElevation,
    this.focusElevation,
    this.highlightElevation,
  }) : super(key: key);

  @override
  _AppButtonState createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.enableScaleAnimation) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 50),
        lowerBound: 0.0,
        upperBound: 0.1,
      )..addListener(() {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && widget.enabled) {
      _scale = 1 - _controller!.value;
    }

    return Listener(
      onPointerDown: (_) => _controller?.forward(),
      onPointerUp: (_) => _controller?.reverse(),
      child: Transform.scale(
        scale: _scale,
        child: buildButton(),
      ),
    );
  }

  Widget buildButton() {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: MaterialButton(
        minWidth: widget.width,
        padding: widget.padding ??
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        onPressed: widget.enabled ? widget.onTap : null,
        color: widget.color ?? Colors.blue, // Default button color
        textColor: widget.textColor ?? Colors.white, // Default text color
        shape: widget.shapeBorder ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: widget.elevation,
        height: widget.height,
        disabledColor: widget.disabledColor ?? Colors.grey,
        focusColor: widget.focusColor,
        hoverColor: widget.hoverColor,
        splashColor: widget.splashColor ?? Colors.white.withOpacity(0.2),
        hoverElevation: widget.hoverElevation ?? 4.0,
        focusElevation: widget.focusElevation ?? 2.0,
        highlightElevation: widget.highlightElevation ?? 4.0,
        animationDuration: const Duration(milliseconds: 300),
        child: widget.child ??
            Text(
              widget.text ?? "Button",
              style: widget.textStyle ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }
}

class StyledDropdownButton<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const StyledDropdownButton({
    Key? key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withAlpha(30),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint),
        onChanged: onChanged,
        items: items,
        isExpanded: true,
        underline: SizedBox(), // Remove the default underline
        icon: Icon(Icons.arrow_drop_down),
      ),
    );
  }
}

// Drpodowns
class ApplicationDropdowns {
  static InputDecoration dropdown1 = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.black.withAlpha(30),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: ApplicationColors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  static InputDecoration dropdown2 = InputDecoration(
    filled: true,
    fillColor: Colors.white, // lighter background
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withAlpha(30)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ApplicationColors.primary, width: 2.5),
    ),
    contentPadding: EdgeInsets.all(14),
  );

  static InputDecoration dropdown3 = InputDecoration(
    filled: true,
    fillColor: Colors.transparent,
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: ApplicationColors.secondary),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ApplicationColors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

// // Grid System
// class ApplicationGrid {
//   static const int columns = 12;
//   static double getColumnWidth(BuildContext context) {
//     return MediaQuery.of(context).size.width / columns;
//   }
// }

// // Animations
// class ApplicationAnimations {
//   static Widget fadeIn({
//     required Widget child,
//     Duration duration = const Duration(milliseconds: 300),
//   }) {
//     return AnimatedOpacity(
//       opacity: 1.0,
//       duration: duration,
//       child: child,
//     );
//   }

//   static Widget slideIn({
//     required Widget child,
//     Duration duration = const Duration(milliseconds: 300),
//     Offset begin = const Offset(0, 1),
//   }) {
//     return TweenAnimationBuilder<Offset>(
//       tween: Tween(begin: begin, end: Offset.zero),
//       duration: duration,
//       builder: (context, offset, child) {
//         return Transform.translate(offset: offset, child: child);
//       },
//       child: child,
//     );
//   }
// }

// Example Usage Comment:
// 1. Import this file: `import 'translation.dart';`
// 2. Use components like:
//    - Colors: `ApplicationColors.primary`
//    - TextStyles: `ApplicationTextStyles.headline1`
//    - Buttons: `ApplicationButtons.primaryButton(...)`
//    - Input Fields: `ApplicationInputFields.textField(...)`
//    - Animations: `ApplicationAnimations.fadeIn(...)`
