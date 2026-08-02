// lib/main.dart (Refactored Glassmorphic Neomorphism Edition)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'login_page.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';
import 'assign_task_page.dart';
import 'new_project_page.dart';
import 'profile_page.dart';
import 'task_list_page.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

// --- GLOBAL NOTIFIERS FOR APPLICATION FLOW ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<int> mainTabNotifier = ValueNotifier(0);

// --- PREMIUM GLASSMORPHIC DESIGN TOKENS ---
const Color kPrimaryColor = Color(0xFF0F1923); 
const Color kSurfaceColor = Color(0xFF1A2634);
const Color kBackgroundColor = Color(0xFF070B12);      // Latar belakang terdalam
const Color kBgGradientStart = Color(0xFF0F1626);     // Permulaan gradien cecair
const Color kBgGradientEnd = Color(0xFF05080F);       // Hujung gradien cecair
const Color kAccentColor = Color(0xFF2DD4A8);         // Teal neon utama
const Color kAccentGlow = Color(0x262DD4A8);          // Teal glow (alpha 15%)
const Color kPrimaryPurpleGlow = Color(0x1F6C5DD3);   // Ungu ambient (alpha 12%)

const Color kCardGlass = Color(0x0FFFFFFF);           // Lapisan kaca frosted (white 6%)
const Color kCardGlassBorder = Color(0x1AFFFFFF);     // Sempadan kilauan kaca (white 10%)
const Color kTextPrimary = Color(0xFFF8FAFC);         // Putih Slate tinggi
const Color kTextSecondary = Color(0xFF94A3B8);       // Kelabu Slate lembut

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
    NotificationService().startAutoSync();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // --- APP WIDE THEME CONFIGURATION ---
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      colorScheme: const ColorScheme.dark(
        primary: kAccentColor,
        secondary: kAccentColor,
        surface: kCardGlass,
        onPrimary: kBackgroundColor,
        onSurface: kTextPrimary,
        outlineVariant: kCardGlassBorder,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk melihat ambient glow
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: kTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
          letterSpacing: -0.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kCardGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kCardGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kAccentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        labelStyle: const TextStyle(color: kTextSecondary),
        hintStyle: const TextStyle(color: kTextSecondary),
        prefixIconColor: kTextSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentColor,
          foregroundColor: kBackgroundColor,
          elevation: 0,
          shadowColor: kAccentColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: kCardGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: kCardGlassBorder, width: 1),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF131B2E),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kCardGlassBorder, width: 1),
        ),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Uni-X Project Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ),
            colorScheme: const ColorScheme.light(
              primary: kAccentColor,
              secondary: kAccentColor,
              surface: Colors.white70,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
              outlineVariant: Colors.black12,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            elevatedButtonTheme: theme.elevatedButtonTheme,
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: Colors.black.withValues(alpha: 0.03),
            ),
          ),
          darkTheme: theme,
          themeMode: currentMode,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/forgot': (context) => const ForgotPasswordPage(),
            '/dashboard': (context) => const MainNavigationWrapper(),
          },
        );
      },
    );
  }
}

// ================= REUSABLE GLASS CONTAINER =================
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? fillColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 25.0,
    this.borderColor,
    this.fillColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor ?? kCardGlass,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? kCardGlassBorder,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ================= MAIN NAVIGATION WRAPPER =================
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int currentIndex = 0;

  final pages = [
    const DashboardPage(),
    const TaskListPage(),
    const NewProjectPage(),
    const AssignTaskPage(),
    const ProfilePage(),
  ];

  final icons = [
    Icons.grid_view_rounded,      // Home / Dashboard
    Icons.assignment_rounded,     // Tasks
    Icons.add_circle_outline,     // New Project
    Icons.hub_rounded,            // Assign Task
    Icons.account_circle_rounded, // Profile
  ];

  final labels = ['Dashboard', 'Analytics', 'Assets', 'Nodes', 'Profile'];

  @override
  void initState() {
    super.initState();
    mainTabNotifier.addListener(_syncTab);
  }

  @override
  void dispose() {
    mainTabNotifier.removeListener(_syncTab);
    super.dispose();
  }

  void _syncTab() {
    if (mounted && currentIndex != mainTabNotifier.value) {
      setState(() {
        currentIndex = mainTabNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // 1. BACKDROP CECAIR GLOW (Ambient Fluid Background Layers)
          Positioned.fill(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final bool isDark = currentMode == ThemeMode.dark;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [kBgGradientStart, kBgGradientEnd]
                          : [const Color(0xFF6C5DD3), const Color(0xFF2DD4A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              }
            ),
          ),
          // Sfera Glow Kiri Atas (Ungu)
          Positioned(
            top: -150,
            left: -50,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final bool isDark = currentMode == ThemeMode.dark;
                return Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? kPrimaryPurpleGlow : const Color(0x33A5B4FC),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                    child: Container(color: Colors.transparent),
                  ),
                );
              }
            ),
          ),
          // Sfera Glow Kanan Bawah (Teal)
          Positioned(
            bottom: -100,
            right: -50,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final bool isDark = currentMode == ThemeMode.dark;
                return Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? kAccentGlow : const Color(0x3399F6E4),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                    child: Container(color: Colors.transparent),
                  ),
                );
              }
            ),
          ),

          // 2. RESPONSIVE INTERFACE CORES
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 950;

                if (isDesktop) {
                  // --- DESKTOP GLASS SIDEBAR LAYOUT ---
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // Custom Vertical Glass Sidebar
                        GlassContainer(
                          width: 260,
                          borderRadius: 28,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Logo Identity
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: kAccentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                                      ),
                                      child: const Icon(Icons.token_rounded, color: kAccentColor, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'UNI-X',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: kTextPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              
                              // Navigation Menu Items
                              Expanded(
                                child: ListView.builder(
                                  itemCount: icons.length,
                                  itemBuilder: (context, index) {
                                    final bool isActive = index == currentIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            currentIndex = index;
                                            mainTabNotifier.value = index;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isActive ? kCardGlassBorder : Colors.transparent,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                icons[index],
                                                color: isActive ? kAccentColor : kTextSecondary,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                labels[index],
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: isActive ? kTextPrimary : kTextSecondary,
                                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (isActive) ...[
                                                const Spacer(),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: kAccentColor,
                                                  ),
                                                )
                                              ]
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              // Bottom Info / Status Card
                              GlassContainer(
                                borderRadius: 16,
                                fillColor: Colors.black.withValues(alpha: 0.2),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: kAccentColor,
                                      child: Icon(Icons.person, color: kBackgroundColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Active Terminal',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary),
                                          ),
                                          Text(
                                            'node_usr_01',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextSecondary),
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
                        const SizedBox(width: 24),
                        
                        // Workspace Dynamic Page Content
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: pages[currentIndex],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ---- MOBILE GLASS FLOATING MENUBAR LAYOUT ----
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 90),
                        child: pages[currentIndex],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: GlassContainer(
                        height: 72,
                        borderRadius: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        borderColor: Colors.white.withValues(alpha: 0.15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(icons.length, (index) {
                            final bool isActive = index == currentIndex;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentIndex = index;
                                    mainTabNotifier.value = index;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOutCubic,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isActive ? kAccentColor.withValues(alpha: 0.12) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icons[index],
                                          size: isActive ? 24 : 22,
                                          color: isActive ? kAccentColor : kTextSecondary,
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 200),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                            color: isActive ? kAccentColor : Colors.transparent,
                                          ),
                                          child: Text(
                                            labels[index],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}