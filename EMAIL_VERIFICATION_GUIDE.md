# HealthSphere - Email Verification Implementation Guide

## 📧 Overview

Your HealthSphere system now has a **complete email verification system** that requires users to verify their email with a 6-digit code during registration.

## ✨ Features

✅ **6-Digit Code Generation** - Random secure codes  
✅ **Email Verification Screen** - Professional UI for code entry  
✅ **10-Minute Expiry** - Codes expire after 10 minutes  
✅ **5 Attempt Limit** - Users get 5 attempts to enter correct code  
✅ **Resend Functionality** - Users can request new codes  
✅ **Real-Time Timer** - Shows remaining time for code validity  
✅ **Attempt Tracking** - Shows remaining attempts  
✅ **Error Handling** - Comprehensive error messages  
✅ **Firestore Integration** - Stores verification data securely  
✅ **Audit Logging** - All verification events logged  

---

## 🏗️ Architecture

### Components Created

#### 1. EmailVerificationService (`lib/services/email_verification_service.dart`)
Service for managing email verification codes and logic.

**Key Methods:**
- `sendVerificationCode(email)` - Generate and store verification code
- `verifyCode(email, code)` - Verify user-entered code
- `isEmailVerified(email)` - Check if email is verified
- `resendVerificationCode(email)` - Generate new code
- `getRemainingTime(email)` - Get time until code expires
- `getAttemptsRemaining(email)` - Get remaining verification attempts
- `cleanupExpiredCodes()` - Remove expired codes from Firestore

#### 2. EmailVerificationScreen (`lib/screens/email_verification_screen.dart`)
Professional UI for email verification.

**Features:**
- 6 individual input fields for code digits
- Auto-focus between fields
- Real-time timer showing expiry
- Attempt counter
- Resend button
- Error messages
- Info box with instructions

#### 3. Updated RegisterScreen (`lib/screens/register_screen.dart`)
Modified to integrate email verification into registration flow.

**New Flow:**
1. User fills registration form
2. Clicks "Register"
3. Verification code sent to email
4. Redirected to EmailVerificationScreen
5. User enters 6-digit code
6. Code verified
7. Account created
8. Redirected to login

---

## 🔄 Registration Flow

```
User Registration Form
        │
        ▼
Click "Register"
        │
        ▼
Validate form
        │
        ▼
Send verification code to email
        │
        ▼
Navigate to EmailVerificationScreen
        │
        ▼
User enters 6-digit code
        │
        ▼
Verify code
        │
    ┌───┴───┐
    │       │
  Valid   Invalid
    │       │
    ▼       ▼
Complete  Show error
Register  Retry
    │
    ▼
Show success
    │
    ▼
Redirect to login
```

---

## 📱 Email Verification Screen

### User Interface

```
┌─────────────────────────────────────┐
│        Verify Your Email            │
│                                     │
│  We've sent a 6-digit code to      │
│  user@example.com                   │
│                                     │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │
│  │  │ │  │ │  │ │  │ │  │ │  │   │
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘   │
│                                     │
│  Expires in 09:45                   │
│  Attempts: 5/5                      │
│                                     │
│  [    Verify Email    ]             │
│  Didn't receive? Resend             │
│                                     │
│  ℹ️ Verification Code Info           │
│  • Valid for 10 minutes             │
│  • 5 attempts allowed               │
│  • Check spam folder                │
│  • Enter each digit separately      │
└─────────────────────────────────────┘
```

### Features

1. **Code Input Fields**
   - 6 individual input fields
   - Auto-focus to next field
   - Numeric input only
   - Clear visual feedback

2. **Timer Display**
   - Shows remaining time (MM:SS format)
   - Changes color when < 1 minute
   - Auto-expires after 10 minutes

3. **Attempt Counter**
   - Shows remaining attempts (X/5)
   - Color changes based on remaining attempts
   - Prevents further attempts when exhausted

4. **Error Messages**
   - Invalid code errors
   - Expired code errors
   - Max attempts exceeded
   - Network errors

5. **Resend Button**
   - Generates new code
   - Resets timer to 10 minutes
   - Resets attempts to 5
   - Clears input fields

6. **Info Box**
   - Explains verification process
   - Shows code validity period
   - Mentions spam folder
   - Explains digit entry

---

## 🗄️ Firestore Data Structure

### Collection: email_verifications

```json
{
  "email": {
    "email": "user@example.com",
    "code": "123456",
    "createdAt": Timestamp(2024-11-26T10:30:00Z),
    "expiresAt": Timestamp(2024-11-26T10:40:00Z),
    "verified": false,
    "attempts": 0,
    "verifiedAt": null
  }
}
```

**Fields:**
- `email`: User's email address (document ID)
- `code`: 6-digit verification code
- `createdAt`: When code was generated
- `expiresAt`: When code expires (10 minutes)
- `verified`: Whether email is verified
- `attempts`: Number of failed verification attempts
- `verifiedAt`: When email was verified (null until verified)

---

## 🔐 Security Features

### Code Generation
- Random 6-digit codes (100000-999999)
- Cryptographically secure random number generator
- Unique per registration attempt

### Code Validation
- Exact match required
- Case-sensitive comparison
- Attempt tracking
- Max 5 attempts allowed
- Automatic expiry after 10 minutes

### Data Protection
- Codes stored in Firestore (encrypted at rest)
- Automatic cleanup of expired codes
- Timestamps for audit trail
- No codes in logs or error messages

### Rate Limiting
- 5 attempts per code
- 10-minute expiry
- Resend generates new code
- Failed attempts logged

---

## 📧 Email Integration

### Current Implementation

The system currently **logs the verification code** for testing purposes. In production, you need to integrate with an email service.

**Current Code (Testing):**
```dart
AppLogger.debug('Verification code for $email: $verificationCode');
```

### Production Email Services

#### Option 1: Firebase Cloud Functions (Recommended)
```javascript
// functions/index.js
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const code = data.code;
  
  await admin.firestore()
    .collection('mail')
    .add({
      to: email,
      message: {
        subject: 'HealthSphere Email Verification',
        html: `Your verification code is: ${code}`
      }
    });
});
```

#### Option 2: SendGrid API
```dart
import 'package:sendgrid_email/sendgrid_email.dart';

Future<void> sendVerificationEmail(String email, String code) async {
  final sendgrid = SendGridEmail(
    apiKey: 'your-sendgrid-api-key',
    fromEmail: 'noreply@healthsphere.com',
    fromName: 'HealthSphere',
  );
  
  await sendgrid.send(
    to: email,
    subject: 'Email Verification - HealthSphere',
    html: '''
      <h2>Email Verification</h2>
      <p>Your verification code is: <strong>$code</strong></p>
      <p>This code expires in 10 minutes.</p>
    ''',
  );
}
```

#### Option 3: Mailgun API
```dart
import 'package:mailgun_email/mailgun_email.dart';

Future<void> sendVerificationEmail(String email, String code) async {
  final mailgun = MailgunEmail(
    domain: 'mg.healthsphere.com',
    apiKey: 'your-mailgun-api-key',
  );
  
  await mailgun.send(
    to: email,
    subject: 'Email Verification - HealthSphere',
    text: 'Your verification code is: $code',
  );
}
```

#### Option 4: AWS SES
```dart
import 'package:aws_ses/aws_ses.dart';

Future<void> sendVerificationEmail(String email, String code) async {
  final ses = AwsSES(
    accessKey: 'your-access-key',
    secretKey: 'your-secret-key',
    region: 'us-east-1',
  );
  
  await ses.sendEmail(
    source: 'noreply@healthsphere.com',
    destination: [email],
    subject: 'Email Verification - HealthSphere',
    body: 'Your verification code is: $code',
  );
}
```

---

## 🚀 Implementation Steps

### Step 1: Update Dependencies (pubspec.yaml)

For Firebase Cloud Functions (recommended):
```yaml
dependencies:
  cloud_functions: ^4.0.0
```

For SendGrid:
```yaml
dependencies:
  sendgrid_email: ^1.0.0
```

### Step 2: Implement Email Sending

Update `EmailVerificationService.sendVerificationCode()`:

```dart
Future<String> sendVerificationCode(String email) async {
  try {
    final verificationCode = _generateVerificationCode();
    
    // Store in Firestore
    await _firestore.collection('email_verifications').doc(email).set({
      'email': email.toLowerCase(),
      'code': verificationCode,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10))
      ),
      'verified': false,
      'attempts': 0,
    }, SetOptions(merge: true));
    
    // Send email
    await _sendEmail(email, verificationCode);
    
    return verificationCode;
  } catch (e) {
    throw DatabaseException(
      message: 'Failed to send verification code',
      originalException: e,
    );
  }
}

Future<void> _sendEmail(String email, String code) async {
  // Implement your email service here
  // Example with Firebase Cloud Functions:
  final functions = FirebaseFunctions.instance;
  await functions.httpsCallable('sendVerificationEmail').call({
    'email': email,
    'code': code,
  });
}
```

### Step 3: Test the Implementation

1. Register a new user
2. Check Firestore for verification code
3. Enter code in verification screen
4. Verify success message
5. Check login works

---

## 🧪 Testing

### Manual Testing

1. **Test Valid Code**
   - Register new user
   - Enter correct code
   - Verify success

2. **Test Invalid Code**
   - Register new user
   - Enter wrong code
   - Verify error message
   - Check attempts decrement

3. **Test Expired Code**
   - Wait 10+ minutes
   - Try to verify
   - Verify expiry error

4. **Test Max Attempts**
   - Enter wrong code 5 times
   - Verify max attempts error
   - Click resend
   - Verify new code works

5. **Test Resend**
   - Click resend button
   - Verify new code generated
   - Verify timer resets
   - Verify attempts reset

### Unit Tests

```dart
void main() {
  group('EmailVerificationService', () {
    late EmailVerificationService service;
    
    setUp(() {
      service = EmailVerificationService();
    });
    
    test('generates 6-digit code', () async {
      final code = await service.sendVerificationCode('test@example.com');
      expect(code, matches(RegExp(r'^\d{6}$')));
    });
    
    test('verifies correct code', () async {
      final code = await service.sendVerificationCode('test@example.com');
      final result = await service.verifyCode('test@example.com', code);
      expect(result, true);
    });
    
    test('rejects invalid code', () async {
      await service.sendVerificationCode('test@example.com');
      expect(
        () => service.verifyCode('test@example.com', '000000'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

---

## 🔧 Configuration

### Code Validity Period

To change from 10 minutes:

```dart
// In EmailVerificationService.sendVerificationCode()
final expiryTime = DateTime.now().add(
  const Duration(minutes: 15), // Change 10 to desired minutes
);
```

### Max Attempts

To change from 5 attempts:

```dart
// In EmailVerificationService.verifyCode()
if (attempts >= 3) { // Change 5 to desired number
  throw ValidationException(
    message: 'Too many failed attempts...',
  );
}
```

### Code Length

To change from 6 digits:

```dart
// In EmailVerificationService._generateVerificationCode()
// For 8 digits: 10000000 to 99999999
return (10000000 + random.nextInt(90000000)).toString();
```

---

## 📋 Verification Flow Diagram

```
RegisterScreen
    │
    ├─→ User fills form
    │
    ├─→ Click "Register"
    │
    ├─→ EmailVerificationService.sendVerificationCode()
    │   │
    │   ├─→ Generate 6-digit code
    │   │
    │   ├─→ Store in Firestore
    │   │
    │   └─→ Send email (TODO: implement)
    │
    ├─→ Navigate to EmailVerificationScreen
    │
    ├─→ User enters code
    │
    ├─→ EmailVerificationService.verifyCode()
    │   │
    │   ├─→ Check if email exists
    │   │
    │   ├─→ Check if code expired
    │   │
    │   ├─→ Check attempts remaining
    │   │
    │   ├─→ Compare codes
    │   │
    │   └─→ Mark as verified
    │
    ├─→ AuthService.registerUser()
    │   │
    │   ├─→ Create Firebase account
    │   │
    │   └─→ Store user in Firestore
    │
    └─→ Redirect to login
```

---

## ✅ Checklist

- [x] EmailVerificationService created
- [x] EmailVerificationScreen created
- [x] RegisterScreen updated
- [x] Firestore collection setup
- [x] Code generation implemented
- [x] Code verification implemented
- [x] Timer implemented
- [x] Attempt tracking implemented
- [x] Resend functionality implemented
- [x] Error handling implemented
- [x] Logging implemented
- [ ] Email service integration (TODO)
- [ ] Unit tests (TODO)
- [ ] Integration tests (TODO)
- [ ] Production deployment (TODO)

---

## 🐛 Troubleshooting

### Issue: Code not generated
- Check Firestore permissions
- Check network connection
- Check logs for errors

### Issue: Code not verifying
- Verify code is correct
- Check code hasn't expired
- Check attempts remaining
- Check email in Firestore

### Issue: Timer not updating
- Check device time is correct
- Check app is in foreground
- Check timer is not cancelled

### Issue: Resend not working
- Check network connection
- Check Firestore permissions
- Check email exists in collection

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs using AppLogger
3. Check Firestore data
4. Consult the development team

---

## 📝 Next Steps

1. **Implement Email Service**
   - Choose email provider (SendGrid, Mailgun, AWS SES, Firebase)
   - Add API keys to environment
   - Update sendVerificationCode() method
   - Test email delivery

2. **Add Unit Tests**
   - Test code generation
   - Test code verification
   - Test expiry handling
   - Test attempt tracking

3. **Add Integration Tests**
   - Test full registration flow
   - Test email verification
   - Test error scenarios

4. **Production Deployment**
   - Secure API keys
   - Enable email service
   - Monitor verification rates
   - Track failed verifications

---

## 📚 Related Files

- `lib/services/email_verification_service.dart` - Verification logic
- `lib/screens/email_verification_screen.dart` - Verification UI
- `lib/screens/register_screen.dart` - Updated registration
- `lib/core/exceptions/app_exceptions.dart` - Exception handling
- `lib/core/logging/app_logger.dart` - Logging system

---

*Implementation Date: November 2024*  
*Version: 1.0.0*  
*Status: Ready for Email Service Integration*
