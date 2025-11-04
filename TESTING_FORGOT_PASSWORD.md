# Quick Start - Testing Forgot Password (Simplified!)

## For Development/Testing (Current Setup)

OTPs are logged to the console. **No Cloud Functions deployment needed!**

### Steps to Test:

1. **Start your app in debug mode**
   ```powershell
   flutter run
   ```

2. **Navigate to Forgot Password**
   - Open the app
   - On login page, click "Forgot your password?"

3. **Enter a registered email**
   - Must be an email that exists in your Firestore `users` collection
   - **IMPORTANT**: Use a REAL email you have access to (for receiving the Firebase reset link)

4. **Get the OTP from console**
   - Look in your VS Code terminal or debug console
   - You'll see: `OTP for user@example.com: 123456`
   - Copy the 6-digit code

5. **Enter the OTP**
   - The app will navigate to OTP verification page
   - Enter the 6 digits (auto-advances between fields)
   - Press "Verify Code" or wait for auto-verify

6. **Check your email**
   - After successful OTP verification, a Firebase password reset email is automatically sent
   - Check your email inbox (and spam/junk folder)
   - You'll receive an email from Firebase with a password reset link

7. **Click the link and set new password**
   - Click the link in the email
   - Firebase will open a page to set your new password
   - Enter your desired new password
   - Confirm and submit

8. **Login with new password**
   - Return to the app
   - Click "OK" to go to login page
   - Use your email and the new password you just set
   - Success! 🎉

## ✅ Super Simple Flow

```
1. Enter Email → 2. Enter OTP → 3. Email Sent → 4. Click Link → 5. Set Password → 6. Login!
```

That's it! No need to enter password twice (once in app, once in email).

## Why You're Not Receiving Email

If you're not receiving the Firebase password reset email, check these:

### 1. **Email/Password Authentication Enabled**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Go to **Authentication** → **Sign-in method**
   - Make sure **Email/Password** is **enabled**

### 2. **Check Spam/Junk Folder**
   - Firebase emails sometimes go to spam
   - Check all email folders

### 3. **Verify Email Address**
   - Make sure you entered the correct email
   - The email must exist in your Firestore `users` collection

### 4. **Firebase Email Configuration**
   - Go to Firebase Console → **Authentication** → **Templates**
   - Check the **Password reset** template
   - Make sure it's configured properly
   - You can customize it if needed

### 5. **Wait a Few Minutes**
   - Sometimes emails can be delayed
   - Wait 2-3 minutes and check again

### 6. **Check Firebase Logs**
   - Go to Firebase Console → **Authentication** → **Users**
   - Verify the user exists
   - Check if there are any error messages

## Common Issues

### "No user found with this email"
- Verify the email exists in Firestore `users` collection
- Check spelling/capitalization

### "OTP has expired"
- OTPs expire after 10 minutes
- Click "Resend" to get a new one

### "Invalid OTP"
- Check you copied the correct 6-digit code from console
- Make sure you didn't use it already

### "This OTP has already been used"
- Each OTP can only be used once
- Click "Resend" to get a new one

### Email not received
- **Most common issue**: Email/Password auth not enabled in Firebase Console
- Check spam folder
- Verify email address is correct
- Wait a few minutes
- Try resending OTP and verifying again

## Testing Checklist

- [ ] Click "Forgot password?" on login
- [ ] Enter email that exists in Firestore
- [ ] See OTP in console (e.g., "OTP for email: 123456")
- [ ] Enter OTP correctly
- [ ] See "Check Your Email" dialog
- [ ] Receive Firebase email (check spam if not in inbox)
- [ ] Click link in email
- [ ] Set new password on Firebase page
- [ ] Login successfully with new password

## Production Setup

When ready for production:

1. **Send OTP via Email** (Optional but Recommended):
   - Integrate email service in `password_reset_service.dart`
   - SendGrid, AWS SES, Mailgun, etc.
   - Remove console.log of OTP

2. **Customize Firebase Email**:
   - Go to Firebase Console → Authentication → Templates
   - Edit the "Password reset" template
   - Add your branding and custom message

3. **Add Rate Limiting**:
   - Prevent spam/abuse
   - Limit requests per email/IP

---

## The Complete Flow:

1. **User enters email** ✓
2. **User verifies OTP** ✓ (proves email ownership)
3. **Firebase sends password reset email** ✓ (automatic)
4. **User clicks link in email** ✓
5. **User sets new password** ✓
6. **User logs in** ✓

**No backend code needed!** 🎉

---

**Quick Tips**: 
- Keep your terminal visible to see the OTP
- Use a real email you can access
- Check spam folder if email doesn't arrive
- Make sure Email/Password auth is enabled in Firebase Console!
