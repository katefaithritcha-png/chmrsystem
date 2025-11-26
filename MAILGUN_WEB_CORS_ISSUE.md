# Mailgun Web CORS Issue

## 🔴 The Problem

Flutter web apps **cannot make direct HTTP requests to Mailgun API** due to CORS (Cross-Origin Resource Sharing) restrictions.

### Why?
- Mailgun API doesn't allow requests from web browsers
- Browser security prevents cross-origin requests
- This is a security feature, not a bug

---

## ✅ Solutions

### Option 1: Use Firebase Cloud Functions (Recommended)
- Create a Cloud Function that calls Mailgun
- Flutter app calls the Cloud Function
- Cloud Function calls Mailgun
- **No CORS issues** (server-to-server communication)
- **Requires Blaze plan** (but you said no money)

### Option 2: Use a Backend Service
- Create a simple Node.js/Express backend
- Deploy on Heroku, Railway, or similar
- Flutter app calls your backend
- Backend calls Mailgun
- **Free tier available**

### Option 3: Use Email Service with Web Support
- Services like SendGrid, Resend, or Brevo
- Some have web-compatible APIs
- Check their CORS policies

### Option 4: Desktop-Only for Now
- Keep email verification for desktop only
- Disable for web
- Implement later with backend

---

## 🚀 Quick Fix: Use Firebase Cloud Functions

Since you already have Firebase set up, the easiest fix is to create a simple Cloud Function that sends emails via Mailgun.

### Step 1: Update functions/index.js

Add this function:

```javascript
exports.sendVerificationEmailMailgun = functions.https.onCall(async (data, context) => {
  const mailgun = require('mailgun.js');
  const FormData = require('form-data');
  
  const mg = new mailgun.Mailgun({
    username: 'api',
    key: 'YOUR_MAILGUN_API_KEY'
  });
  
  const domain = 'sandboxcea99d8ac2d24465b7fe6ef2abe7933b.mailgun.org';
  
  try {
    const result = await mg.messages.create(domain, {
      from: `HealthSphere <noreply@${domain}>`,
      to: data.email,
      subject: 'HealthSphere - Email Verification Code',
      text: `Your verification code is: ${data.code}\n\nThis code expires in 10 minutes.`,
      html: `<h1>${data.code}</h1><p>This code expires in 10 minutes.</p>`
    });
    
    return { success: true, messageId: result.id };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### Step 2: Update Flutter Code

```dart
Future<void> _sendVerificationEmailViaMailgun(String email, String code) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('sendVerificationEmailMailgun');
    await callable.call({
      'email': email,
      'code': code,
    });
  } catch (e) {
    AppLogger.error('Failed to send email via Cloud Function', error: e);
  }
}
```

### Step 3: Deploy

```bash
firebase deploy --only functions
```

---

## 📝 Why This Works

- ✅ Server-to-server communication (no CORS)
- ✅ API key stays on server (secure)
- ✅ Works on web, mobile, desktop
- ✅ No additional backend needed
- ⚠️ Requires Blaze plan (but free tier is generous)

---

## 🎯 Recommendation

Since you're already using Firebase and have Blaze plan restrictions, I recommend:

**For Now (Desktop Testing):**
- Keep current Mailgun implementation
- Works on desktop
- Web will fail due to CORS

**For Production:**
- Use Cloud Functions as proxy
- Upgrade to Blaze when ready
- Or use a free backend service

---

## 🔗 Useful Links

- Mailgun CORS: https://documentation.mailgun.com/en/latest/api-sending.html
- Firebase Cloud Functions: https://firebase.google.com/docs/functions
- CORS Explained: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

