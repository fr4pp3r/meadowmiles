# Email Setup Guide - OTP via SMTP

This guide will help you configure email sending for OTP (One-Time Password) verification using the `mailer` Flutter package.

## 📦 Package Installed

The `mailer: ^6.1.2` package has been added to `pubspec.yaml` and installed.

## 🔧 Configuration Steps

### Option 1: Gmail SMTP (Recommended for Development)

1. **Enable 2-Step Verification**
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable "2-Step Verification"

2. **Generate App Password**
   - Visit [App Passwords](https://myaccount.google.com/apppasswords)
   - Select "Mail" and your device
   - Copy the 16-character password (format: `xxxx xxxx xxxx xxxx`)

3. **Update Configuration**
   - Open `lib/config/email_config.dart`
   - Replace `gmailUsername` with your Gmail address
   - Replace `gmailAppPassword` with the 16-character app password

   ```dart
   static const String gmailUsername = 'your-email@gmail.com';
   static const String gmailAppPassword = 'abcd efgh ijkl mnop'; // 16 chars
   ```

### Option 2: Outlook/Hotmail SMTP

1. **Update Configuration**
   - Open `lib/config/email_config.dart`
   - Uncomment the Outlook section
   - Add your Outlook credentials

2. **Update Password Reset Service**
   - Open `lib/services/password_reset_service.dart`
   - In `_sendEmailWithOTP()` method, change:
   
   ```dart
   // From:
   final smtpServer = gmail(EmailConfig.gmailUsername, EmailConfig.gmailAppPassword);
   
   // To:
   final smtpServer = hotmail(EmailConfig.outlookUsername, EmailConfig.outlookPassword);
   ```

### Option 3: Custom SMTP Server

1. **Get SMTP Credentials**
   - From your email provider (e.g., SendGrid, Mailgun, AWS SES)
   - Note: host, port, username, password

2. **Update Configuration**
   ```dart
   static const String smtpHost = 'smtp.yourserver.com';
   static const int smtpPort = 587;
   static const String smtpUsername = 'your-username';
   static const String smtpPassword = 'your-password';
   static const bool useSsl = false;
   ```

3. **Update Password Reset Service**
   ```dart
   final smtpServer = SmtpServer(
     EmailConfig.smtpHost,
     port: EmailConfig.smtpPort,
     username: EmailConfig.smtpUsername,
     password: EmailConfig.smtpPassword,
     ssl: EmailConfig.useSsl,
     allowInsecure: false,
   );
   ```

## 🎨 Email Template

The OTP email includes:
- Professional HTML design with gradient header
- Large, easy-to-read 6-digit code
- 10-minute expiration notice
- Security warnings
- Responsive design

Preview:
```
┌─────────────────────────────┐
│  🔐 Password Reset          │ (Purple gradient header)
├─────────────────────────────┤
│  Hello!                     │
│                             │
│  Your verification code:    │
│  ┌───────────────────┐      │
│  │   1 2 3 4 5 6     │      │ (Large, spaced digits)
│  │ Valid for 10 min  │      │
│  └───────────────────┘      │
│                             │
│  ⚠️ Important:              │
│  • Expires in 10 minutes    │
│  • Never share this code    │
│  • Ignore if not requested  │
└─────────────────────────────┘
```

## 🔒 Security Best Practices

### 1. Never Commit Credentials
Add to `.gitignore`:
```
# Email credentials
lib/config/email_config.dart
```

### 2. Use Environment Variables (Production)
Instead of hardcoding credentials, use environment variables:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get gmailUsername => dotenv.env['GMAIL_USERNAME'] ?? '';
static String get gmailAppPassword => dotenv.env['GMAIL_APP_PASSWORD'] ?? '';
```

### 3. Create a Template Config File
Commit a template without real credentials:

`lib/config/email_config.dart.template`:
```dart
class EmailConfig {
  static const String gmailUsername = 'YOUR_EMAIL_HERE';
  static const String gmailAppPassword = 'YOUR_APP_PASSWORD_HERE';
  static const String senderName = 'MeadowMiles';
  static const String senderEmail = gmailUsername;
  static const String otpSubject = 'Password Reset OTP - MeadowMiles';
}
```

## 🧪 Testing

### Test Email Sending

1. **Run the App**
   ```bash
   flutter run
   ```

2. **Trigger Password Reset**
   - Click "Forgot Password" on login screen
   - Enter a valid email address
   - Click "Send OTP"

3. **Check Console**
   - If email sends successfully: `✅ Email sent successfully`
   - If email fails: `❌ Failed to send email` (OTP will be in console as fallback)

4. **Check Email Inbox**
   - Look for email from your configured sender
   - Check spam folder if not in inbox
   - Copy the 6-digit code

5. **Verify OTP**
   - Enter the code in the app
   - Should navigate to password reset confirmation

### Common Issues

#### 1. "Authentication failed"
- **Gmail**: Make sure you're using App Password, not regular password
- **Outlook**: Check if "Less secure apps" is enabled
- **Custom**: Verify SMTP credentials

#### 2. "Connection timeout"
- Check your internet connection
- Verify SMTP server address and port
- Check firewall settings

#### 3. Email not received
- Check spam/junk folder
- Verify recipient email is correct
- Check email service quotas (Gmail: 500/day for free accounts)

#### 4. "535 Authentication failed"
- Incorrect username or password
- App Password might be expired (Gmail)
- 2-Step Verification not enabled (Gmail)

## 📊 Current Flow

```
User clicks "Forgot Password"
         ↓
Enter email address
         ↓
App generates 6-digit OTP
         ↓
Store OTP in Firestore
         ↓
Send OTP via SMTP email ✉️
         ↓
User receives email
         ↓
User enters OTP in app
         ↓
App verifies OTP from Firestore
         ↓
Firebase sends password reset link
         ↓
User resets password
```

## 🚀 Production Considerations

### Email Service Recommendations

1. **SendGrid** (Free tier: 100 emails/day)
   - Professional service
   - Good deliverability
   - Email analytics

2. **Mailgun** (Free tier: 1,000 emails/month)
   - Developer-friendly
   - Simple API
   - Pay as you grow

3. **AWS SES** (Free tier: 62,000 emails/month)
   - Highly scalable
   - Low cost
   - Requires AWS account

4. **Firebase Extensions - Trigger Email**
   - Easiest integration with Firebase
   - No code changes needed
   - Uses SendGrid or Mailgun backend

### Rate Limiting
Consider implementing rate limiting to prevent abuse:
- Max 3 OTP requests per email per hour
- Max 10 OTP requests per IP per hour

### Email Deliverability
- Use a verified domain email (not free Gmail)
- Set up SPF, DKIM, DMARC records
- Monitor bounce and spam rates

## 📝 Files Modified

- ✅ `pubspec.yaml` - Added mailer package
- ✅ `lib/config/email_config.dart` - Email configuration
- ✅ `lib/services/password_reset_service.dart` - Email sending implementation

## 🔗 Useful Links

- [Mailer Package Documentation](https://pub.dev/packages/mailer)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Mailgun Documentation](https://documentation.mailgun.com/)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)

## ✅ Next Steps

1. Choose your email provider (Gmail, Outlook, or custom)
2. Get SMTP credentials
3. Update `lib/config/email_config.dart`
4. Test the flow
5. (Optional) Set up environment variables for production
6. (Optional) Implement rate limiting
7. (Optional) Customize email template

---

**Need Help?** Check the troubleshooting section above or refer to the provider-specific documentation.
