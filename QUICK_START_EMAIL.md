# Quick Start - Gmail SMTP Setup

## 🚀 5-Minute Setup

### Step 1: Get Gmail App Password
1. Go to: https://myaccount.google.com/apppasswords
2. Select **Mail** and **Windows Computer**
3. Click **Generate**
4. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

### Step 2: Update Configuration
Open: `lib/config/email_config.dart`

```dart
static const String gmailUsername = 'your-email@gmail.com'; // Your Gmail
static const String gmailAppPassword = 'abcd efgh ijkl mnop'; // Paste password here
```

### Step 3: Test It!
```bash
flutter run
```

1. Click **Forgot Password**
2. Enter your email
3. Check your inbox for the OTP email! 📧

---

## 📧 Expected Email

**Subject:** Password Reset OTP - MeadowMiles

**Content:**
```
🔐 Password Reset

Your verification code is:

  1 2 3 4 5 6

Valid for 10 minutes

⚠️ Important:
• This code expires in 10 minutes
• Never share this code with anyone
• If you didn't request this, please ignore
```

---

## 🔍 Troubleshooting

### Email not sending?
- Check debug console for errors
- Verify App Password is correct (no spaces)
- Make sure 2-Step Verification is enabled

### Email not received?
- Check spam/junk folder
- Verify email address is correct
- Wait 1-2 minutes (SMTP can be slow)

### "Authentication failed" error?
- Use **App Password**, not your regular Gmail password
- Generate a new App Password if needed

---

## 📱 Testing Checklist

- [ ] Updated email credentials in `email_config.dart`
- [ ] Ran `flutter pub get`
- [ ] Tested "Forgot Password" flow
- [ ] Received email successfully
- [ ] OTP verified correctly
- [ ] Password reset link received

---

## ⚠️ Security Reminder

**DO NOT commit real credentials to Git!**

Add to `.gitignore`:
```
lib/config/email_config.dart
```

Keep a template:
```
lib/config/email_config.dart.template
```

---

**All set!** Your OTP emails should now be sent automatically. 🎉
