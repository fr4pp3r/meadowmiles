# Password Reset Feature - Setup Guide

## Overview
This project implements a custom forgot password flow with OTP verification **without requiring Cloud Functions or Admin SDK**. The flow consists of:
1. User enters their email address
2. System generates and stores a 6-digit OTP in Firestore
3. User verifies the OTP in the app
4. User creates their new password in the app
5. System sends Firebase's built-in password reset email
6. User clicks the email link and sets the password they chose in step 4

## Architecture

### Frontend (Flutter) - Client-Side Only!
- **forgot_password_page.dart**: Email entry page
- **verify_otp_page.dart**: OTP verification page  
- **reset_password_page.dart**: New password creation page
- **password_reset_service.dart**: Service handling OTP generation and verification
- **authstate.dart**: Updated with `resetPassword()` and `sendPasswordResetEmail()` methods

### Backend - Uses Firebase Built-in Features
- **Firebase Authentication**: Built-in password reset email
- **Firestore**: Stores OTP for verification (temporary, auto-cleaned)
- **No Cloud Functions Required!**
- **No Admin SDK Required!**

## How It Works

### The Smart Approach:
1. **OTP Verification**: User proves they own the email account via OTP
2. **Password Selection**: User chooses their new password in the app
3. **Firebase Email**: System sends Firebase's standard password reset email
4. **Password Set**: User clicks email link and enters the password they chose
5. **Complete**: User can now login with their new password

This approach:
- ✅ Doesn't require Cloud Functions
- ✅ Doesn't require Admin SDK
- ✅ Uses Firebase's secure built-in password reset
- ✅ Provides better UX than standard password reset
- ✅ Maintains security through OTP verification

## Setup Instructions

### 1. Firestore Security Rules (Optional but Recommended)
Add these rules to your `firestore.rules` file:

```javascript
// Password reset collection - should not be directly accessible by clients
match /password_resets/{userId} {
  allow read, write: if false;
  // Note: In this client-side implementation, we actually need write access
  // So you may want to adjust this based on your security requirements:
  // allow write: if request.auth != null && request.auth.uid == userId;
}
```

### 2. Configure Firebase Email Templates (Recommended)
1. Go to Firebase Console
2. Navigate to **Authentication** → **Templates**
3. Select **Password reset** template
4. Customize the email design and copy
5. Consider adding your branding

### 3. Configure Email Service for OTP (Optional - For Production)
Currently, the OTP is only logged to the console. To send actual emails:

Update `lib/services/password_reset_service.dart` around line 50:

```dart
// TODO: Integrate with email service (e.g., SendGrid, AWS SES, etc.)
// Example with SendGrid:
Future<void> _sendEmailWithOTP(String email, String otp) async {
  final response = await http.post(
    Uri.parse('https://api.sendgrid.com/v3/mail/send'),
    headers: {
      'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'personalizations': [
        {
          'to': [{'email': email}],
          'subject': 'Your Password Reset Code',
        }
      ],
      'from': {'email': 'noreply@meadowmiles.com'},
      'content': [
        {
          'type': 'text/html',
          'value': '<h2>Your verification code is: <strong>$otp</strong></h2>'
                   '<p>This code expires in 10 minutes.</p>'
        }
      ],
    }),
  );
}
```

Then update the `sendOTP` method to call this function:
```dart
await _sendEmailWithOTP(email, otp);
```

## Flow Diagram

```
Login Page
    |
    | (Click "Forgot Password")
    v
Forgot Password Page
    |
    | (Enter Email)
    v
Generate & Store OTP in Firestore
    |
    v
Verify OTP Page
    |
    | (Enter 6-digit OTP)
    v
Validate OTP from Firestore
    |
    | (OTP Valid ✓)
    v
Reset Password Page
    |
    | (Enter New Password)
    v
Send Firebase Password Reset Email
    |
    v
User Receives Email
    |
    v
User Clicks Link & Enters Password
    |
    v
Firebase Updates Password
    |
    v
Success → Login with New Password
```

## Firestore Collections

### password_resets
Stores OTPs for verification:
```javascript
{
  email: "user@example.com",
  otp: "123456",
  createdAt: Timestamp,
  expiresAt: 1234567890, // 10 minutes from creation
  verified: false → true
}
```

## Security Considerations

### Current Implementation
✅ OTP expires after 10 minutes
✅ OTP can only be used once
✅ Password validation (min 6 characters)
✅ Email verification before OTP generation
✅ Uses Firebase's secure password reset email
✅ No passwords stored in Firestore

### Production Recommendations

1. **OTP Email Service**: Send OTPs via email instead of console logging

2. **Rate Limiting**: Add rate limiting to prevent abuse:
   - Limit OTP requests per email (e.g., 3 per hour)
   - Implement CAPTCHA for repeated requests
   - Track failed verification attempts

3. **Firestore Security**: Update security rules for production

4. **Email Templates**: Customize Firebase email templates with branding

5. **Audit Logging**: Log password reset attempts for security monitoring

6. **Two-Factor Authentication**: Consider adding 2FA for additional security

## Testing

### Development Testing (Current Setup)
OTP is logged to console:

1. Start app: `flutter run`
2. Navigate to Forgot Password page
3. Enter a valid email address
4. **Check console** for: `OTP for user@email.com: 123456`
5. Enter the OTP in the app
6. Create new password (e.g., `newpass123`)
7. You'll see instructions to check email
8. Check your email for Firebase password reset link
9. Click link and enter the password you chose (`newpass123`)
10. Login with new password

### Production Testing
1. Ensure OTP email service is configured
2. Test complete flow with real email delivery
3. Verify OTP expiration (wait 10+ minutes)
4. Test invalid OTP attempts
5. Test password validation
6. Verify Firebase email is received
7. Complete password reset via email link

## Troubleshooting

### OTP not being generated
- Check Firestore permissions
- Verify user exists in the `users` collection with specified email
- Check console for any error messages

### OTP verification fails
- Ensure OTP hasn't expired (10-minute window)
- Check that OTP wasn't already used (verified: true)
- Verify exact OTP match (all 6 digits)

### Firebase email not received
- Check spam/junk folder
- Verify Email/Password authentication is enabled in Firebase Console
- Check Firebase Console → Authentication → Templates
- Ensure email address is valid and can receive emails

### Password not updating
- Ensure user clicks the Firebase reset email link
- Verify user enters the exact password shown in the app
- Check Firebase Console → Authentication → Users to confirm password was updated

## Advantages of This Approach

### ✅ No Cloud Functions
- No deployment complexity
- No additional costs
- No need for Node.js/backend knowledge
- Easier to maintain

### ✅ No Admin SDK
- No service account setup
- No credential management
- Pure client-side implementation

### ✅ Uses Firebase Built-in Security
- Leverages Firebase's tested password reset flow
- Secure email verification
- No custom authentication logic needed

### ✅ Better UX
- User chooses password in app
- Clear instructions
- No confusion about what password to set

## Future Enhancements

1. **SMS OTP**: Add phone number verification option
2. **Email OTP**: Actually send OTP via email service
3. **Biometric Reset**: Use device biometrics for password reset
4. **Password Strength Meter**: Visual feedback on password strength
5. **Password History**: Prevent reuse of previous passwords (requires backend)
6. **Multi-language Support**: Localized OTP and instruction messages
7. **Analytics**: Track password reset success/failure rates

## Support

For issues or questions:
- Email: meadownmiles@gmail.com
- Check Firebase Console → Authentication for user status
- Review Firestore `password_resets` collection for OTP data
- Check email spam folder for Firebase reset emails
