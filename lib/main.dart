import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_admin.dart';
import 'screens/dashboard_health_worker.dart';
import 'screens/dashboard_patient.dart';
import 'screens/user_management_screen.dart';
import 'screens/patient_records_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/consultation_form_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chrms_alert_create_screen.dart';
import 'screens/audit_trail_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/appointments_approval_screen.dart';
import 'screens/health_records_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/medicine_inventory_screen.dart';
import 'screens/population_tracking_screen.dart';
import 'services/appointment_service.dart';
import 'package:provider/provider.dart';
import 'providers/customer_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/role_guard.dart';
import 'screens/home_page.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Continue even if Firebase isn't configured for this environment.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentService()),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HealthSphere',
          theme: AppTheme.light.copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          darkTheme: AppTheme.dark.copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          themeMode: context.watch<ThemeProvider>().mode,
          initialRoute: '/',
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFBFE7FF), // lighter sky blue
                    Color(0xFFD9F2F6), // lighter powder blue/teal
                    Color(0xFFF5FFFF), // near white cyan
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: child,
            );
          },
          routes: {
            '/': (context) => const StartGate(),
            '/login': (context) => const LoginScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/register': (context) => const RegisterScreen(),
            '/admin': (context) => const RoleGuard(
                allowedRoles: ['admin'], child: DashboardAdmin()),
            '/worker': (context) => const RoleGuard(
                allowedRoles: ['health_worker'],
                child: DashboardHealthWorker()),
            '/patient': (context) => const RoleGuard(
                allowedRoles: ['patient'], child: DashboardPatient()),
            '/users': (context) => const RoleGuard(
                allowedRoles: ['admin'], child: UserManagementScreen()),
            '/patients': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: PatientRecordsScreen()),
            '/reports': (context) => const RoleGuard(
                allowedRoles: ['admin'], child: ReportsScreen()),
            '/consultation': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: ConsultationScreen()),
            '/consultation/new': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: ConsultationFormScreen()),
            '/notifications': (context) => const RoleGuard(
                allowedRoles: ['patient', 'admin', 'health_worker'],
                child: NotificationsScreen()),
            '/chat': (context) => const RoleGuard(
                allowedRoles: ['patient', 'admin', 'health_worker'],
                child: ChatScreen()),
            '/records': (context) => const RoleGuard(
                allowedRoles: ['patient'], child: HealthRecordsScreen()),
            '/audit': (context) => const RoleGuard(
                allowedRoles: ['admin'], child: AuditTrailScreen()),
            '/backup': (context) =>
                const RoleGuard(allowedRoles: ['admin'], child: BackupScreen()),
            '/appointments': (context) => const RoleGuard(
                allowedRoles: ['patient'], child: AppointmentsScreen()),
            '/appointments/approvals': (context) => const RoleGuard(
                allowedRoles: ['health_worker', 'admin'],
                child: AppointmentsApprovalScreen()),
            '/inventory': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: MedicineInventoryScreen()),
            '/population': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: PopulationTrackingScreen()),
            '/home': (context) => const HomePage(),
            '/chrms-alerts/new': (context) => const RoleGuard(
                allowedRoles: ['admin', 'health_worker'],
                child: ChrmsAlertCreateScreen()),
            // Optional program routes removed
          },
        ),
      ),
    );
  }
}

class StartGate extends StatefulWidget {
  const StartGate({super.key});

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;
    if (seen) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
