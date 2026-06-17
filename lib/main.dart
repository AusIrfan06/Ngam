import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/auth_provider.dart';
import 'providers/gig_provider.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_service.dart';
import 'utils/app_theme.dart';

// ─── Screens ─────────────────────────────────────────────────
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/post_task_screen.dart';
import 'screens/customer/task_posted_screen.dart';
import 'screens/customer/my_tasks_screen.dart';
import 'screens/customer/order_status_screen.dart';
import 'screens/customer/review_screen.dart';
import 'screens/runner/runner_home_screen.dart';
import 'screens/runner/task_detail_screen.dart';
import 'screens/runner/confirm_acceptance_screen.dart';
import 'screens/runner/active_job_screen.dart';
import 'screens/runner/my_jobs_screen.dart';
import 'screens/shared/profile_screen.dart';

// ============================================================
// Ngam — Local Errands, Powered by Community
// CSC264 Individual Project
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ms')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ms'),
      useOnlyLangCode: true,
      child: const NgamApp(),
    ),
  );
}

class NgamApp extends StatelessWidget {
  const NgamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => GigProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Ngam',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // ─── Initial Route ─────────────────────
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const _SplashScreen();
                }
                if (!auth.isLoggedIn) {
                  return const LoginScreen();
                }
                if (auth.isRunner) {
                  return const RunnerHomeScreen();
                }
                return const CustomerHomeScreen();
              },
            ),

            // ─── Named Routes ──────────────────────
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/customer-home': (context) => const CustomerHomeScreen(),
              '/post-task': (context) => const PostTaskScreen(),
              '/task-posted': (context) => const TaskPostedScreen(),
              '/my-tasks': (context) => const MyTasksScreen(),
              '/order-status': (context) => const OrderStatusScreen(),
              '/review': (context) => const ReviewScreen(),
              '/runner-home': (context) => const RunnerHomeScreen(),
              '/task-detail': (context) => const TaskDetailScreen(),
              '/confirm-acceptance': (context) =>
                  const ConfirmAcceptanceScreen(),
              '/active-job': (context) => const ActiveJobScreen(),
              '/my-jobs': (context) => const MyJobsScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}

// ─── Splash Screen (while checking auth state) ───────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/app.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
