# Resend Email Verification Setup

## ✅ Why Resend?

- **Free tier**: 100 emails/day
- **Works on web** (no CORS issues)
- **No payment required**
- **Easy integration**
- **Better than Mailgun for web apps**

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Create Resend Account (2 min)

1. Go to: https://resend.com
2. Click "Sign Up"
3. Create free account
4. Verify email

### Step 2: Get API Key (1 min)

1. Go to: https://resend.com/api-keys
2. Create new API key
3. Copy the key (looks like: `re_xxx...`)

### Step 3: Update Flutter Code (1 min)

**File**: `lib/services/email_verification_service.dart`  
**Line**: 77

Replace:
```dart
const resendApiKey = 'YOUR_RESEND_API_KEY';
```

With:
```dart
const resendApiKey = 're_your_actual_key_here';
```

### Step 4: Run (1 min)

```bash
flutter pub get
flutter run -d chrome
```

### Step 5: Test (5 min)

1. Register new user
2. Check Gmail inbox
3. Enter verification code
4. Done! ✅

---

## 📋 Resend API Key

Get from: https://resend.com/api-keys

Looks like: `re_abc123def456...`

---

## 🧪 Testing

1. Run Flutter app on web
2. Go to Register screen
3. Enter email: `gonzagaprince919@gmail.com`
4. Enter password
5. Select role
6. Click "Register"
7. Check Gmail inbox
8. Copy code
9. Enter code in app
10. Done!

---

## ✨ Features

✅ **Free** (100 emails/day)  
✅ **Works on web**  
✅ **No CORS issues**  
✅ **Professional emails**  
✅ **Easy setup**  
✅ **No payment required**  

---

## 📊 Resend Free Tier

- **100 emails/day**
- **Unlimited domains**
- **Professional templates**
- **Webhook support**
- **No credit card required**

---

## 🔐 Security

- Keep API key private
- Don't commit to git
- Use environment variables in production

---

## 📝 Next Steps

1. Sign up: https://resend.com
2. Get API key: https://resend.com/api-keys
3. Update Flutter code (1 line)
4. Run `flutter pub get`
5. Test!

---

**Total time: 10 minutes**  
**Cost: $0**
