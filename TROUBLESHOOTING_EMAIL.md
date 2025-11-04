# Troubleshooting: Not Receiving Firebase Password Reset Email

## Most Common Issue: Email/Password Authentication Not Enabled

If you're not receiving the Firebase password reset email after OTP verification, the most likely cause is that **Email/Password authentication is not enabled** in your Firebase project.

### ✅ Quick Fix:

1. **Go to Firebase Console**
   - Visit [https://console.firebase.google.com](https://console.firebase.google.com)
   - Select your project (meadowmiles)

2. **Enable Email/Password Authentication**
   - In the left sidebar, click **Authentication**
   - Click the **Sign-in method** tab
   - Find **Email/Password** in the list
   - Click on it
   - Toggle **Enable** to ON
   - Click **Save**

3. **Test Again**
   - Go back to your app
   - Start the forgot password flow again
   - After OTP verification, you should receive the email!

## Other Common Issues

### 1. **Check Spam/Junk Folder**
   - Firebase emails sometimes get flagged as spam
   - Check all your email folders
   - Add `noreply@<your-project>.firebaseapp.com` to your contacts

### 2. **Wrong Email Address**
   - Make sure you entered the correct email
   - The email must exist in your Firestore `users` collection
   - Check for typos or extra spaces

### 3. **Email Delivery Delay**
   - Sometimes emails can take a few minutes to arrive
   - Wait 2-5 minutes and check again

### 4. **Firebase Project Configuration**
   - Go to Firebase Console → **Authentication** → **Templates**
   - Check the **Password reset** template
   - Make sure it's not disabled
   - You can customize the template if needed

### 5. **Domain Verification (For Custom Domains)**
   - If you're using a custom email domain, make sure it's verified
   - Go to Firebase Console → **Authentication** → **Settings**
   - Check **Authorized domains**

## How to Test if Email is Working

### Method 1: Use Firebase Console
1. Go to Firebase Console → **Authentication** → **Users**
2. Find a test user
3. Click the three dots (⋮) next to the user
4. Select **Send password reset email**
5. Check if you receive the email

### Method 2: Check Firebase Logs
1. Go to Firebase Console
2. Click the **≡** menu
3. Go to **Analytics** → **Dashboard**
4. Or check **Authentication** → **Users** for any error messages

## Verify Your Setup

### ✅ Checklist:
- [ ] Email/Password authentication is **enabled** in Firebase Console
- [ ] User exists in Firestore `users` collection
- [ ] Email address is correct (no typos)
- [ ] Checked spam/junk folder
- [ ] Waited at least 2-3 minutes
- [ ] Firebase project is active (not in free tier limits)

## Alternative: Test with Firebase Console

To verify that Firebase emails are working at all:

1. Go to Firebase Console → **Authentication** → **Users**
2. Click **Add user**
3. Create a test user with your email
4. Click the three dots next to the user
5. Select **Send password reset email**
6. If you receive this email, your Firebase email is working!
   - If yes: The issue is with your app's OTP flow
   - If no: The issue is with Firebase email configuration

## Still Not Working?

### Check Firebase Quotas:
- Free tier: 100 emails/day
- Go to Firebase Console → **Usage and billing**
- Check if you've hit any limits

### Check Firebase Status:
- Visit [Firebase Status Dashboard](https://status.firebase.google.com)
- Check if there are any ongoing issues

### Contact Support:
- Firebase Community: [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)
- Firebase Support: Available for paid plans

## Success Indicators

You'll know it's working when:
- ✅ Email appears in inbox within 1-2 minutes
- ✅ Email is from `noreply@<your-project>.firebaseapp.com`
- ✅ Email contains a "Reset Password" link
- ✅ Clicking the link opens Firebase's password reset page

---

## Quick Test Script

Use this quick test to verify everything:

1. ✅ Enable Email/Password auth in Firebase Console
2. ✅ Run app: `flutter run`
3. ✅ Click "Forgot password?"
4. ✅ Enter email that exists in Firestore
5. ✅ Check console for OTP
6. ✅ Enter OTP
7. ✅ See "Check Your Email" message
8. ✅ Wait 2 minutes
9. ✅ Check email (and spam folder)
10. ✅ Receive Firebase email with reset link

If step 10 fails, go back to the top of this document and check Email/Password authentication status.
