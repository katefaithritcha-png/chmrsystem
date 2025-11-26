import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import 'dart:async';
import '../services/email_verification_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/logging/app_logger.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String role;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.role,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final EmailVerificationService _verificationService =
      EmailVerificationService();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorMessage;
  int _remainingSeconds = 600; // 10 minutes
  late Timer _timer;
  int _attemptsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadAttemptsRemaining();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _showExpiredDialog();
      }
    });
  }

  Future<void> _loadAttemptsRemaining() async {
    try {
      final remaining =
          await _verificationService.getAttemptsRemaining(widget.email);
      setState(() => _attemptsRemaining = remaining);
    } catch (e) {
      AppLogger.error('Error loading attempts', error: e);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Code Expired'),
        content: const Text(
            'Your verification code has expired. Please request a new one.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resendCode();
            },
            child: const Text('Request New Code'),
          ),
        ],
      ),
    );
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    if (!mounted) return;

    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _verificationService.verifyCode(widget.email, code);

      if (!mounted) return;

      if (isValid) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to register with verified flag
        Navigator.pop(context, {
          'email': widget.email,
          'password': widget.password,
          'role': widget.role,
          'verified': true,
        });
      }
    } on ValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _attemptsRemaining--;
      });
      AppLogger.warning('Verification failed: ${e.message}');
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
      AppLogger.error('Verification error: ${e.message}', error: e);
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
      AppLogger.error('Unexpected error during verification', error: e);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _verificationService.resendVerificationCode(widget.email);

      if (!mounted) return;

      setState(() {
        _remainingSeconds = 600;
        _attemptsRemaining = 5;
        // Clear code inputs
        for (var controller in _codeControllers) {
          controller.clear();
        }
      });

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New verification code sent to your email'),
          backgroundColor: Colors.blue,
        ),
      );

      _focusNodes[0].requestFocus();
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
      AppLogger.error('Resend error: ${e.message}', error: e);
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to resend code. Please try again.');
      AppLogger.error('Unexpected error during resend', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _timer.cancel();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Email'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We\'ve sent a 6-digit code to\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      enabled: !_isVerifying,
                      onChanged: (value) => _onCodeChanged(value, index),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Timer and attempts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: _remainingSeconds < 60
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${_formatTime(_remainingSeconds)}',
                        style: TextStyle(
                          color: _remainingSeconds < 60
                              ? Colors.red
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                          fontWeight: _remainingSeconds < 60
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: _attemptsRemaining > 2
                            ? Colors.green
                            : _attemptsRemaining > 0
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attempts: $_attemptsRemaining/5',
                        style: TextStyle(
                          color: _attemptsRemaining > 2
                              ? Colors.green
                              : _attemptsRemaining > 0
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: _attemptsRemaining <= 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifying || _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend button
              TextButton(
                onPressed: _isLoading || _isVerifying ? null : _resendCode,
                child: Text(
                  _isLoading
                      ? 'Sending...'
                      : 'Didn\'t receive the code? Resend',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Verification Code Info',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Code is valid for 10 minutes\n'
                      '• You have 5 attempts to enter the correct code\n'
                      '• Check your spam folder if you don\'t see the email\n'
                      '• Each digit must be entered separately',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
