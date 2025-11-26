import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../core/logging/app_logger.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for handling email verification with OTP codes
class EmailVerificationService {
  static final EmailVerificationService _instance =
      EmailVerificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory EmailVerificationService() {
    return _instance;
  }

  EmailVerificationService._internal();

  /// Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send verification code to user's email via Mailgun
  Future<String> sendVerificationCode(String email) async {
    try {
      AppLogger.info('Generating verification code for: $email');

      // Generate 6-digit code
      final verificationCode = _generateVerificationCode();

      // Store verification code in Firestore with expiry (10 minutes)
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('email_verifications').doc(email).set({
        'email': email.toLowerCase(),
        'code': verificationCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'verified': false,
        'attempts': 0,
      }, SetOptions(merge: true));

      AppLogger.info('Verification code generated and stored for: $email');

      // Send email via Mailgun
      try {
        await _sendVerificationEmailViaMailgun(email, verificationCode);
        AppLogger.info('Verification email sent successfully to: $email');
      } catch (e) {
        AppLogger.error('Failed to send verification email via Mailgun',
            error: e);
        // Log the code for debugging if email service fails
        AppLogger.debug('Verification code for $email: $verificationCode');
      }

      return verificationCode;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send verification code',
          error: e, stackTrace: stackTrace);
      throw DatabaseException(
        message: 'Failed to send verification code',
        originalException: e,
      );
    }
  }

  /// Send verification email via Resend API
  Future<void> _sendVerificationEmailViaMailgun(
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

  /// Verify the code entered by user
  Future<bool> verifyCode(String email, String code) async {
    try {
      AppLogger.info('Verifying code for: $email');

      final doc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!doc.exists) {
        AppLogger.warning('No verification record found for: $email');
        throw NotFoundException(
          message: 'Verification code not found. Please request a new code.',
        );
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int?) ?? 0;
      final verified = (data['verified'] as bool?) ?? false;

      // Check if already verified
      if (verified) {
        AppLogger.info('Email already verified: $email');
        return true;
      }

      // Check if code expired
      if (DateTime.now().isAfter(expiresAt)) {
        AppLogger.warning('Verification code expired for: $email');
        throw ValidationException(
          message: 'Verification code has expired. Please request a new code.',
        );
      }

      // Check max attempts (5 attempts)
      if (attempts >= 5) {
        AppLogger.warning('Max verification attempts exceeded for: $email');
        throw ValidationException(
          message: 'Too many failed attempts. Please request a new code.',
        );
      }

      // Verify code
      if (storedCode != code) {
        AppLogger.warning('Invalid verification code for: $email');
        // Increment attempts
        await _firestore.collection('email_verifications').doc(email).update({
          'attempts': attempts + 1,
        });
        throw ValidationException(
          message: 'Invalid verification code. Please try again.',
        );
      }

      // Code is valid, mark as verified
      await _firestore.collection('email_verifications').doc(email).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

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

  /// Check if email is verified
  Future<bool> isEmailVerified(String email) async {
    try {
      final doc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!doc.exists) {
        return false;
      }

      return (doc.data()?['verified'] as bool?) ?? false;
    } catch (e) {
      AppLogger.error('Error checking email verification', error: e);
      return false;
    }
  }

  /// Resend verification code
  Future<String> resendVerificationCode(String email) async {
    try {
      AppLogger.info('Resending verification code for: $email');

      // Check if email exists in verifications
      final doc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!doc.exists) {
        throw NotFoundException(
          message: 'Email not found. Please register first.',
        );
      }

      // Generate new code
      final newCode = _generateVerificationCode();
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Update with new code
      await _firestore.collection('email_verifications').doc(email).update({
        'code': newCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'attempts': 0,
        'verified': false,
      });

      AppLogger.info('Verification code resent for: $email');
      AppLogger.debug('New verification code for $email: $newCode');

      return newCode; // Return for testing purposes only
    } catch (e, stackTrace) {
      AppLogger.error('Failed to resend verification code',
          error: e, stackTrace: stackTrace);
      throw DatabaseException(
        message: 'Failed to resend verification code',
        originalException: e,
      );
    }
  }

  /// Clean up expired verification codes
  Future<void> cleanupExpiredCodes() async {
    try {
      AppLogger.info('Cleaning up expired verification codes');

      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('email_verifications')
          .where('expiresAt', isLessThan: now)
          .where('verified', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      AppLogger.info(
          'Cleaned up ${snapshot.docs.length} expired verification codes');
    } catch (e, stackTrace) {
      AppLogger.error('Error cleaning up expired codes',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get remaining time for verification code
  Future<Duration?> getRemainingTime(String email) async {
    try {
      final doc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!doc.exists) {
        return null;
      }

      final expiresAt = (doc.data()?['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt == null) {
        return null;
      }

      final remaining = expiresAt.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      AppLogger.error('Error getting remaining time', error: e);
      return null;
    }
  }

  /// Get verification attempts remaining
  Future<int> getAttemptsRemaining(String email) async {
    try {
      final doc =
          await _firestore.collection('email_verifications').doc(email).get();

      if (!doc.exists) {
        return 5;
      }

      final attempts = (doc.data()?['attempts'] as int?) ?? 0;
      return 5 - attempts;
    } catch (e) {
      AppLogger.error('Error getting attempts remaining', error: e);
      return 5;
    }
  }
}
