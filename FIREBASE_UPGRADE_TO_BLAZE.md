# Firebase Upgrade to Blaze Plan

## ⚠️ Issue

Your Firebase project `capstone-a3e18` is on the **Spark Plan** (free tier), which doesn't support Cloud Functions.

**Error:**
```
Your project capstone-a3e18 must be on the Blaze (pay-as-you-go) plan to complete this command.
```

## ✅ Solution: Upgrade to Blaze Plan

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/project/capstone-a3e18/usage/details
2. Or manually:
   - Go to https://console.firebase.google.com
   - Select project: `capstone-a3e18`
   - Click "Upgrade" button

### Step 2: Click "Upgrade to Blaze"

- You'll see a button to upgrade
- Click it to proceed

### Step 3: Add Billing Information

- Enter credit card details
- Set up billing account
- Confirm upgrade

### Step 4: Wait for Upgrade

- Upgrade usually completes in 1-2 minutes
- You'll see confirmation message

### Step 5: Deploy Functions

Once upgraded, run:
```bash
firebase deploy --only functions
```

---

## 💰 Blaze Plan Pricing

### Free Tier (Always Free)
- **Cloud Functions**: 2 million invocations/month
- **Firestore**: 50,000 reads/day, 20,000 writes/day
- **Storage**: 5 GB

### Pay-As-You-Go
- **Cloud Functions**: $0.40 per million invocations after free tier
- **Firestore**: $0.06 per 100K reads after free tier
- **Storage**: $0.18 per GB after free tier

### Estimated Cost for Email Verification
- 100 users/month = 100 function invocations
- **Cost**: ~$0.00 (within free tier)

---

## 🔄 Upgrade Process

```
Current Plan: Spark (Free)
    ↓
Click "Upgrade to Blaze"
    ↓
Enter Billing Information
    ↓
Confirm Upgrade
    ↓
New Plan: Blaze (Pay-as-you-go)
    ↓
Deploy Cloud Functions
    ↓
Email verification working
```

---

## 📋 Upgrade Checklist

- [ ] Go to Firebase Console
- [ ] Select project: capstone-a3e18
- [ ] Click "Upgrade to Blaze"
- [ ] Enter credit card
- [ ] Confirm upgrade
- [ ] Wait 1-2 minutes
- [ ] Run: firebase deploy --only functions
- [ ] Verify deployment successful
- [ ] Test registration

---

## 🚀 After Upgrade

### Deploy Functions

```bash
firebase deploy --only functions
```

Expected output:
```
✔  Deploy complete!

Function URL (sendVerificationEmail): 
https://us-central1-capstone-a3e18.cloudfunctions.net/sendVerificationEmail
```

### Update Flutter App

```bash
flutter pub get
```

### Test Registration

1. Run Flutter app
2. Go to Register screen
3. Enter email and password
4. Click "Register"
5. Check Gmail inbox for verification email

---

## ❓ FAQ

### Q: Will I be charged?
**A**: Only if you exceed the free tier. Email verification is within free tier.

### Q: Can I downgrade later?
**A**: Yes, you can downgrade back to Spark plan anytime.

### Q: How do I monitor costs?
**A**: Go to Firebase Console → Usage → Details

### Q: What if I exceed free tier?
**A**: You'll be charged based on usage. Set budget alerts in Firebase Console.

---

## 🔗 Useful Links

- **Firebase Console**: https://console.firebase.google.com
- **Upgrade Page**: https://console.firebase.google.com/project/capstone-a3e18/usage/details
- **Pricing Details**: https://firebase.google.com/pricing
- **Blaze Plan Info**: https://firebase.google.com/docs/projects/billing/firebase-pricing-plans

---

## ✨ Summary

✅ **Issue**: Project on Spark plan (no Cloud Functions)  
✅ **Solution**: Upgrade to Blaze plan  
✅ **Cost**: Free for email verification (within free tier)  
✅ **Time**: 5-10 minutes  

---

## 📝 Next Steps

1. **Upgrade to Blaze**
   - Go to Firebase Console
   - Click "Upgrade to Blaze"
   - Enter billing info

2. **Deploy Functions**
   ```bash
   firebase deploy --only functions
   ```

3. **Create `.env.local`**
   - Copy `.env.local.example`
   - Add Gmail credentials

4. **Test Registration**
   - Register new user
   - Verify email received

---

*Status: Waiting for Blaze Upgrade*  
*Estimated Time: 15-20 minutes total*
