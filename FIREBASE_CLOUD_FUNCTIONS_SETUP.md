# Firebase Cloud Functions - Email Verification Setup

## ✅ What Was Implemented

Your HealthSphere system now sends verification emails via **Firebase Cloud Functions** - a secure, server-side solution.

### Files Created

1. **`functions/package.json`** - Node.js dependencies
2. **`functions/index.js`** - Cloud Functions code (3 functions)
3. **Updated `pubspec.yaml`** - Added cloud_functions dependency
4. **Updated `email_verification_service.dart`** - Calls Cloud Functions

---

## 🚀 Setup Steps

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

### Step 2: Login to Firebase

```bash
firebase login
```

This opens your browser to authenticate.

### Step 3: Initialize Firebase Functions

```bash
cd c:\Users\ADMIN\Desktop\chmrsystem
firebase init functions
```

When prompted:
- **Language**: Choose `JavaScript`
- **ESLint**: Choose `No`
- **Overwrite existing files**: Choose `No` (keep our files)

### Step 4: Install Dependencies

```bash
cd functions
npm install
```

This installs:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- `nodemailer` - Email sending library

### Step 5: Configure Gmail Credentials

#### Option A: Using Gmail App Password (Recommended)

1. **Enable 2-Step Verification** on your Gmail account
   - Go to https://myaccount.google.com/security
   - Click "2-Step Verification"
   - Follow the setup

2. **Generate App Password**
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and "Windows Computer"
   - Google generates a 16-character password
   - Copy this password

3. **Set Environment Variables**

   Create `.env.local` file in `functions/` directory:
   ```
   GMAIL_USER=your-email@gmail.com
   GMAIL_APP_PASSWORD=your-16-char-app-password
   ```

   Or set via Firebase CLI:
   ```bash
   firebase functions:config:set gmail.user="your-email@gmail.com" gmail.password="your-app-password"
   ```

#### Option B: Using Gmail API (More Complex)

1. Enable Gmail API in Google Cloud Console
2. Create OAuth 2.0 credentials
3. Use OAuth tokens instead of password

**Recommendation**: Use Option A (App Password) - simpler and more secure.

### Step 6: Test Locally

```bash
cd c:\Users\ADMIN\Desktop\chmrsystem
firebase emulators:start --only functions
```

This starts the emulator. You'll see:
```
✔  functions: http function initialized at http://localhost:5001/your-project/us-central1/sendVerificationEmail
```

### Step 7: Deploy to Firebase

```bash
firebase deploy --only functions
```

You should see:
```
✔  Deploy complete!

Function URL (sendVerificationEmail): https://us-central1-your-project.cloudfunctions.net/sendVerificationEmail
```

### Step 8: Update Flutter App

Run in your project:
```bash
flutter pub get
```

This installs the new `cloud_functions` dependency.

---

## 📧 Cloud Functions Included

### 1. sendVerificationEmail

**Purpose**: Send 6-digit verification code during registration

**Called from**: `EmailVerificationService.sendVerificationCode()`

**Parameters**:
```dart
{
  'email': 'user@example.com',
  'code': '123456'
}
```

**Email Template**: Professional HTML with:
- HealthSphere branding
- 6-digit code prominently displayed
- 10-minute expiry notice
- Security warning
- Plain text fallback

### 2. sendPasswordResetEmail

**Purpose**: Send password reset link

**Parameters**:
```dart
{
  'email': 'user@example.com',
  'resetLink': 'https://...'
}
```

### 3. sendWelcomeEmail

**Purpose**: Welcome new users after registration

**Parameters**:
```dart
{
  'email': 'user@example.com',
  'name': 'John Doe',
  'role': 'patient'
}
```

---

## 🧪 Testing

### Test 1: Local Testing

1. Start emulator:
   ```bash
   firebase emulators:start --only functions
   ```

2. Register a user in your app
3. Check emulator logs for email sending
4. Verify code in Firestore

### Test 2: Production Testing

1. Deploy functions:
   ```bash
   firebase deploy --only functions
   ```

2. Register a user
3. Check Gmail inbox for verification email
4. Enter code in app

### Test 3: Error Handling

Test these scenarios:
- [ ] Invalid email format
- [ ] Missing code
- [ ] Network timeout
- [ ] Gmail credentials wrong

---

## 🔐 Security Best Practices

### ✅ What We're Doing Right

1. **Keys on Server** - Gmail credentials never in app
2. **Environment Variables** - Credentials in `.env.local`
3. **Validation** - Email and code validated server-side
4. **Error Handling** - Graceful fallback if email fails
5. **Logging** - All events logged for debugging
6. **HTTPS Only** - Cloud Functions use HTTPS

### ⚠️ Important

1. **Never commit `.env.local`** - Add to `.gitignore`
2. **Use App Password** - Not your Gmail password
3. **Enable 2FA** - Required for App Password
4. **Monitor Logs** - Check Firebase Logs for errors
5. **Rate Limiting** - Consider adding in production

---

## 📊 File Structure

```
chmrsystem/
├── functions/
│   ├── package.json          ← Node.js dependencies
│   ├── index.js              ← Cloud Functions code
│   ├── .env.local            ← Gmail credentials (DO NOT COMMIT)
│   └── node_modules/         ← Installed packages
├── lib/
│   └── services/
│       └── email_verification_service.dart  ← Updated to use Cloud Functions
└── pubspec.yaml              ← Added cloud_functions dependency
```

---

## 🚀 Deployment Checklist

- [ ] Firebase CLI installed
- [ ] Logged in to Firebase
- [ ] Functions initialized
- [ ] Dependencies installed
- [ ] Gmail App Password generated
- [ ] Environment variables set
- [ ] Functions tested locally
- [ ] Functions deployed to Firebase
- [ ] Flutter app dependencies updated
- [ ] Tested registration flow
- [ ] Verified email received
- [ ] Code verification works

---

## 📝 Troubleshooting

### Issue: "Cannot find module 'firebase-admin'"

**Solution**:
```bash
cd functions
npm install
```

### Issue: "Gmail credentials not found"

**Solution**:
1. Check `.env.local` exists in `functions/` directory
2. Verify format: `GMAIL_USER=...` and `GMAIL_APP_PASSWORD=...`
3. Restart emulator after setting env vars

### Issue: "Email not received"

**Solution**:
1. Check Gmail credentials are correct
2. Check spam folder
3. Verify email address is correct
4. Check Firebase Logs for errors
5. Test with console.log in Cloud Function

### Issue: "Function timeout"

**Solution**:
1. Increase timeout in code (default 60s)
2. Check Gmail API response time
3. Check network connection
4. Verify Gmail credentials work

### Issue: "Permission denied" in Firestore

**Solution**:
1. Check Firestore rules include email_verifications
2. Verify rules were deployed
3. Check user is authenticated

---

## 📚 Documentation

### Cloud Functions Code
- `functions/index.js` - All functions with comments

### Email Service
- `lib/services/email_verification_service.dart` - Updated service

### Setup Guide
- This file - Complete setup instructions

---

## 🎯 Next Steps

1. **Complete Setup**
   - Follow all setup steps above
   - Deploy functions to Firebase

2. **Test Registration**
   - Register new user
   - Verify email received
   - Enter code and verify

3. **Monitor**
   - Check Firebase Logs
   - Monitor email delivery
   - Track verification rates

4. **Enhance (Optional)**
   - Add rate limiting
   - Add email templates
   - Add welcome email
   - Add password reset

---

## 📞 Support

### Common Issues

| Issue | Solution |
|-------|----------|
| No email received | Check Gmail credentials and spam folder |
| Function timeout | Increase timeout or check network |
| Permission denied | Check Firestore rules |
| Module not found | Run `npm install` in functions/ |

### Useful Commands

```bash
# View logs
firebase functions:log

# Deploy only functions
firebase deploy --only functions

# Test locally
firebase emulators:start --only functions

# View function details
firebase functions:describe sendVerificationEmail

# Delete a function
firebase functions:delete sendVerificationEmail
```

---

## ✨ Summary

✅ **Cloud Functions Created** - 3 email functions  
✅ **Email Service Updated** - Calls Cloud Functions  
✅ **Dependencies Added** - cloud_functions package  
✅ **Setup Guide Provided** - Complete instructions  
✅ **Security Implemented** - Keys on server  
✅ **Error Handling** - Graceful fallback  

**Status: Ready for Deployment**

---

*Setup Date: November 2024*  
*Status: Ready for Firebase Deployment*
