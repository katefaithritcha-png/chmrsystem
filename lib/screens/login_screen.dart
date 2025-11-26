import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import '../core/responsive/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String role = await _authService.loginUser(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (role == "admin") {
      AuditService()
          .addEvent(actor: 'Admin: $email', action: 'Login', level: 'info');
      context.read<AuthProvider>().setRole('admin');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == "health_worker") {
      AuditService().addEvent(
          actor: 'Health Worker: $email', action: 'Login', level: 'info');
      context.read<AuthProvider>().setRole('health_worker');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/worker');
    } else if (role == "patient") {
      AuditService()
          .addEvent(actor: 'Patient: $email', action: 'Login', level: 'info');
      context.read<AuthProvider>().setRole('patient');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/patient');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid email or password."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final responsiveBorderRadius =
        ResponsiveHelper.getResponsiveBorderRadius(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: responsivePadding,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(responsiveBorderRadius + 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (ctx, cons) {
                  final narrow = cons.maxWidth < 800;
                  final content = [
                    // Left panel (Welcome design)
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.health_and_safety,
                                size: 80,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Welcome to HealthSphere",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Manage community health records with efficiency and care.",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  tooltip: 'Toggle dark mode',
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  onPressed: () {
                                    // Access ThemeProvider via context
                                    try {
                                      // ignore: use_build_context_synchronously
                                      final provider =
                                          context.read<ThemeProvider>();
                                      provider.toggle();
                                    } catch (_) {}
                                  },
                                  icon: Icon(Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Icons.dark_mode
                                      : Icons.light_mode),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Right panel (Login form)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Access your dashboard",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2A9D8F),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 15),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/register',
                                  );
                                },
                                child: Text(
                                  "Don’t have an account? Register here",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ];
                  if (narrow) {
                    // On mobile: stack panels vertically and round all corners
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 28),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.health_and_safety,
                                    size: 56, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Welcome to HealthSphere',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Digitizing care for a healthier tomorrow',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Login form body
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: content[1],
                        ),
                      ],
                    );
                  }
                  // On wide screens keep two-column Row
                  return Row(children: content);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
