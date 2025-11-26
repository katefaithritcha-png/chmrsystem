# Create Mailgun API Keys

## ✅ Step-by-Step Guide

### Step 1: Go to API Keys Page

1. **In Mailgun Dashboard**
2. **Click on left menu** → Look for settings or account
3. **Or go directly to:**
   ```
   https://app.mailgun.com/app/account/security/api_keys
   ```

### Step 2: Find Your API Key

1. **On the API Keys page**
2. **Look for "Private API Key"**
3. **It should already exist** (created when you signed up)
4. **Copy the key** (it looks like: `key-abc123def456...`)

### Step 3: Get Your Domain

1. **In Mailgun Dashboard**
2. **Click on left menu** → "Send" or "Domains"
3. **Or go directly to:**
   ```
   https://app.mailgun.com/app/sending/domains
   ```

4. **Look for "Sandbox Domain"**
5. **Copy the domain** (it looks like: `sandboxabc123def456.mailgun.org`)

---

## 🔑 What You'll Get

After these steps, you'll have:

```
API Key: key-abc123def456...
Domain: sandboxabc123def456.mailgun.org
```

---

## 📝 Update Flutter Code

Once you have both:

**File**: `lib/services/email_verification_service.dart`  
**Lines**: 75-76

Replace:
```dart
const mailgunApiKey = 'YOUR_MAILGUN_API_KEY';
const mailgunDomain = 'YOUR_MAILGUN_DOMAIN';
```

With:
```dart
const mailgunApiKey = 'key-abc123def456...';
const mailgunDomain = 'sandboxabc123def456.mailgun.org';
```

---

## 🚀 Quick Links

- **API Keys**: https://app.mailgun.com/app/account/security/api_keys
- **Domains**: https://app.mailgun.com/app/sending/domains
- **Dashboard**: https://app.mailgun.com/app/dashboard

---

## ✨ You're Almost Done!

Just need to:
1. ✅ Copy API Key
2. ✅ Copy Domain
3. ✅ Update 2 lines in Flutter code
4. ✅ Run `flutter pub get`
5. ✅ Test registration

**Total time: 5 minutes**
