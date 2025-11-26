import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart';
import '../screens/email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final EmailVerificationService _verificationService =
      EmailVerificationService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'patient';
  bool _isLoading = false;

  void _register() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String role = _selectedRole;

      try {
        // Send verification code to email
        await _verificationService.sendVerificationCode(email);

        if (!mounted) return;

        setState(() => _isLoading = false);

        // Navigate to email verification screen
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              password: password,
              role: role,
            ),
          ),
        );

        // If email verified, complete registration
        if (result != null && result['verified'] == true) {
          if (!mounted) return;

          setState(() => _isLoading = true);

          await _authService.registerUser(email, password, role);

          if (!mounted) return;

          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Create an Account"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.blueAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Register to HealthSphere",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Please enter your email" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.length < 6
                        ? "Password must be at least 6 characters"
                        : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text("Admin")),
                      DropdownMenuItem(
                        value: 'health_worker',
                        child: Text("Health Worker"),
                      ),
                      DropdownMenuItem(
                        value: 'patient',
                        child: Text("Patient"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Role",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      "Already have an account? Login",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
