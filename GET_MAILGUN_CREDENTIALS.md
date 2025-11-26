# Get Mailgun API Credentials

## ✅ You're in Mailgun Dashboard

Great! You've successfully created a Mailgun account. Now let's get your API credentials.

---

## 🔑 Step 1: Get API Key

### In Mailgun Dashboard:

1. **Look at the left menu**
   - You should see options like:
     - Get started
     - Dashboard
     - Send
     - Inspect
     - Optimize
     - List Health Preview

2. **Click on "Get started"** (if not already there)

3. **Look for "Activate your account"**
   - This might already be done

4. **Find "API Keys" section**
   - In left menu, look for a settings or API option
   - Or go directly to: https://app.mailgun.com/app/account/security/api_keys

5. **Copy your "Private API Key"**
   - It looks like: `key-abc123def456...`
   - This is your `MAILGUN_API_KEY`

---

## 🌐 Step 2: Get Domain

### In Mailgun Dashboard:

1. **Look at the left menu**
   - Find "Sending" or "Domains" section

2. **Click on "Sending" or "Domains"**

3. **Find your "Sandbox Domain"**
   - It looks like: `sandboxabc123def456.mailgun.org`
   - This is your `MAILGUN_DOMAIN`

4. **Copy the full domain**

---

## 📋 What You Need

After getting credentials, you should have:

```
API Key: key-abc123def456...
Domain: sandboxabc123def456.mailgun.org
```

---

## 🔗 Direct Links

### API Keys Page
https://app.mailgun.com/app/account/security/api_keys

### Domains Page
https://app.mailgun.com/app/sending/domains

---

## 📝 Next Steps

Once you have both credentials:

1. **Open Flutter code file**
   - `lib/services/email_verification_service.dart`

2. **Find lines 75-76**
   ```dart
   const mailgunApiKey = 'YOUR_MAILGUN_API_KEY';
   const mailgunDomain = 'YOUR_MAILGUN_DOMAIN';
   ```

3. **Replace with your credentials**
   ```dart
   const mailgunApiKey = 'key-abc123def456...';
   const mailgunDomain = 'sandboxabc123def456.mailgun.org';
   ```

4. **Save file**

5. **Run flutter pub get**

6. **Test registration**

---

## ✨ You're Almost Done!

Just need to:
1. Copy API Key
2. Copy Domain
3. Update 2 lines in Flutter code
4. Test!

---

*Status: Getting Credentials*
