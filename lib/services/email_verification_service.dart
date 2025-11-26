import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/logging/app_logger.dart';
import '../core/exceptions/app_exceptions.dart';

/// Model for storing verification data in-memory
class _VerificationData {
  final String code;
  final DateTime expiresAt;
  int attempts;
  bool verified;

  _VerificationData({
    required this.code,
    required this.expiresAt,
    this.attempts = 0,
    this.verified = false,
  });
}

/// Service for handling email verification with OTP codes sent via Gmail/Resend
class EmailVerificationService {
  static final EmailVerificationService _instance =
      EmailVerificationService._internal();

  /// In-memory storage for verification codes (no Firestore)
  final Map<String, _VerificationData> _verificationCodes = {};

  factory EmailVerificationService() {
    return _instance;
  }

  EmailVerificationService._internal();

  /// Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send verification code to user's email via Resend API
  Future<void> sendVerificationCode(String email) async {
    try {
      AppLogger.info('Generating verification code for: $email');

      // Generate 6-digit code
      final verificationCode = _generateVerificationCode();

      // Store verification code in in-memory storage with expiry (10 minutes)
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));
      _verificationCodes[email] = _VerificationData(
        code: verificationCode,
        expiresAt: expiryTime,
        attempts: 0,
        verified: false,
      );

      AppLogger.info('Verification code generated and stored for: $email');

      // Send email via Resend API
      try {
        await _sendVerificationEmailViaResend(email, verificationCode);
        AppLogger.info('Verification email sent successfully to: $email');
      } catch (e) {
        AppLogger.error('Failed to send verification email via Resend',
            error: e);
        // Log the code for debugging if email service fails
        AppLogger.debug('Verification code for $email: $verificationCode');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send verification code',
          error: e, stackTrace: stackTrace);
      throw DatabaseException(
        message: 'Failed to send verification code',
        originalException: e,
      );
    }
  }

  /// Send verification email via Resend API to Gmail
  Future<void> _sendVerificationEmailViaResend(
      String email, String code) async {
    try {
      AppLogger.info('Sending verification email via Resend to: $email');

      // Resend API key - get from https://resend.com
      const resendApiKey = 're_BQsmwXxq_7XoHNpAwJtfyTqK9kSzsyj2d';

      if (resendApiKey == 'YOUR_RESEND_API_KEY') {
        AppLogger.warning(
            'Resend API key not configured. Email not sent. Get key from https://resend.com');
        return;
      }

      final htmlBody = '''
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }
              .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
              .header h1 { margin: 0; font-size: 28px; font-weight: 600; }
              .content { padding: 30px; }
              .code { font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 4px; text-align: center; font-family: 'Courier New', monospace; margin: 20px 0; }
              .footer { background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #999; border-top: 1px solid #eee; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🏥 HealthSphere</h1>
                <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Email Verification</p>
              </div>
              <div class="content">
                <p>Hello,</p>
                <p>Thank you for registering with HealthSphere. To complete your registration, please verify your email address using the code below:</p>
                <div class="code">$code</div>
                <p style="color: #999; font-size: 14px;">⏱️ This code expires in 10 minutes</p>
                <p style="color: #666; font-size: 14px; margin-top: 20px;">
                  If you didn't request this verification code, please ignore this email.
                </p>
              </div>
              <div class="footer">
                <p>© 2024 HealthSphere. All rights reserved.</p>
                <p>This is an automated email. Please do not reply to this message.</p>
              </div>
            </div>
          </body>
        </html>
      ''';

      AppLogger.debug('Resend API Key: $resendApiKey');
      AppLogger.debug('Sending to: $email');

      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'HealthSphere <onboarding@resend.dev>',
          'to': email,
          'subject': 'HealthSphere - Email Verification Code',
          'html': htmlBody,
        }),
      );

      AppLogger.debug('Resend response status: ${response.statusCode}');
      AppLogger.debug('Resend response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        AppLogger.error(
            'Resend API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to send email via Resend: ${response.statusCode} ${response.body}');
      }

      AppLogger.info(
          'Verification email sent successfully to: $email via Resend');
    } catch (e) {
      AppLogger.error('Failed to send verification email via Resend', error: e);
      rethrow;
    }
  }

  /// Verify the code entered by user (from in-memory storage)
  Future<bool> verifyCode(String email, String code) async {
    try {
      AppLogger.info('Verifying code for: $email');

      final verificationData = _verificationCodes[email];

      if (verificationData == null) {
        AppLogger.warning('No verification record found for: $email');
        throw NotFoundException(
          message: 'Verification code not found. Please request a new code.',
        );
      }

      // Check if already verified
      if (verificationData.verified) {
        AppLogger.info('Email already verified: $email');
        return true;
      }

      // Check if code expired
      if (DateTime.now().isAfter(verificationData.expiresAt)) {
        AppLogger.warning('Verification code expired for: $email');
        throw ValidationException(
          message: 'Verification code has expired. Please request a new code.',
        );
      }

      // Check max attempts (5 attempts)
      if (verificationData.attempts >= 5) {
        AppLogger.warning('Max verification attempts exceeded for: $email');
        throw ValidationException(
          message: 'Too many failed attempts. Please request a new code.',
        );
      }

      // Verify code
      if (verificationData.code != code) {
        AppLogger.warning('Invalid verification code for: $email');
        verificationData.attempts++;
        throw ValidationException(
          message: 'Invalid verification code. Please try again.',
        );
      }

      // Code is valid, mark as verified
      verificationData.verified = true;

      AppLogger.info('Email verified successfully: $email');
      return true;
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Error verifying code', error: e, stackTrace: stackTrace);
      throw DatabaseException(
        message: 'Error verifying code',
        originalException: e,
      );
    }
  }

  /// Resend verification code
  Future<void> resendVerificationCode(String email) async {
    try {
      AppLogger.info('Resending verification code for: $email');

      final verificationData = _verificationCodes[email];

      if (verificationData == null) {
        throw NotFoundException(
          message: 'Email not found. Please register first.',
        );
      }

      // Generate new code
      final newCode = _generateVerificationCode();
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Update with new code
      _verificationCodes[email] = _VerificationData(
        code: newCode,
        expiresAt: expiryTime,
        attempts: 0,
        verified: false,
      );

      AppLogger.info('Verification code resent for: $email');
      AppLogger.debug('New verification code for $email: $newCode');

      // Send new code via email
      await _sendVerificationEmailViaResend(email, newCode);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to resend verification code',
          error: e, stackTrace: stackTrace);
      throw DatabaseException(
        message: 'Failed to resend verification code',
        originalException: e,
      );
    }
  }

  /// Get remaining attempts for verification
  Future<int> getAttemptsRemaining(String email) async {
    try {
      final verificationData = _verificationCodes[email];

      if (verificationData == null) {
        return 5;
      }

      return 5 - verificationData.attempts;
    } catch (e) {
      AppLogger.error('Error getting attempts remaining', error: e);
      return 5;
    }
  }
}
