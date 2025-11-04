import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/email_config.dart';

class PasswordResetService {
  static final PasswordResetService _instance =
      PasswordResetService._internal();
  factory PasswordResetService() => _instance;
  PasswordResetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP to user's email (store in Firestore for verification)
  Future<bool> sendOTP(String email) async {
    try {
      // Check if user exists with this email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint('No user found with email: $email');
        return false;
      }

      final userId = userQuery.docs.first.id;
      final otp = generateOTP();

      // Store OTP in Firestore with expiration time (10 minutes)
      await _firestore.collection('password_resets').doc(userId).set({
        'email': email,
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
        'verified': false,
      });

      // Send OTP via email
      try {
        await _sendEmailWithOTP(email, otp);
        debugPrint('✅ OTP email sent successfully to $email');
      } catch (emailError) {
        // If email fails, still log to console as fallback
        debugPrint('❌ Failed to send email: $emailError');
        debugPrint('=================================');
        debugPrint('📧 OTP FOR $email: $otp');
        debugPrint('=================================');
        debugPrint('Copy this 6-digit code to verify your email');
        debugPrint('=================================');
      }

      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      // Get user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {'success': false, 'message': 'User not found'};
      }

      final userId = userQuery.docs.first.id;

      // Get OTP document
      final otpDoc = await _firestore
          .collection('password_resets')
          .doc(userId)
          .get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'message': 'No OTP found. Please request a new one.',
        };
      }

      final data = otpDoc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = data['expiresAt'] as int;
      final verified = data['verified'] as bool? ?? false;

      // Check if already verified
      if (verified) {
        return {'success': false, 'message': 'This OTP has already been used.'};
      }

      // Check if expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // Verify OTP
      if (storedOTP != otp) {
        return {'success': false, 'message': 'Invalid OTP. Please try again.'};
      }

      // Mark as verified
      await _firestore.collection('password_resets').doc(userId).update({
        'verified': true,
      });

      return {
        'success': true,
        'message': 'OTP verified successfully',
        'userId': userId,
      };
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Check if OTP is verified (before allowing password reset)
  Future<bool> isOTPVerified(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return false;
      }

      final userId = userQuery.docs.first.id;

      final otpDoc = await _firestore
          .collection('password_resets')
          .doc(userId)
          .get();

      if (!otpDoc.exists) {
        return false;
      }

      final data = otpDoc.data()!;
      return data['verified'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking OTP verification: $e');
      return false;
    }
  }

  // Store the user's current password temporarily for password reset
  // This is needed because Firebase Auth requires current password to change it
  Future<bool> storeTemporaryResetToken(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return false;
      }

      final userId = userQuery.docs.first.id;

      // Update the password_resets document with additional info
      await _firestore.collection('password_resets').doc(userId).update({
        'readyForReset': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error storing reset token: $e');
      return false;
    }
  }

  // Clean up OTP document after password reset
  Future<void> cleanupOTP(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        await _firestore.collection('password_resets').doc(userId).delete();
      }
    } catch (e) {
      debugPrint('Error cleaning up OTP: $e');
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String email) async {
    try {
      // Delete existing OTP
      await cleanupOTP(email);
      // Send new OTP
      return await sendOTP(email);
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      return false;
    }
  }

  // Send OTP via email using SMTP
  Future<void> _sendEmailWithOTP(String email, String otp) async {
    // Configure SMTP server using credentials from EmailConfig
    final smtpServer = gmail(
      EmailConfig.gmailUsername,
      EmailConfig.gmailAppPassword,
    );

    // Alternative SMTP configurations:
    // For Outlook/Hotmail:
    // final smtpServer = hotmail(EmailConfig.outlookUsername, EmailConfig.outlookPassword);

    // For custom SMTP:
    // final smtpServer = SmtpServer(
    //   EmailConfig.smtpHost,
    //   port: EmailConfig.smtpPort,
    //   username: EmailConfig.smtpUsername,
    //   password: EmailConfig.smtpPassword,
    //   ssl: EmailConfig.useSsl,
    //   allowInsecure: false,
    // );

    // Create email message
    final message = Message()
      ..from = Address(EmailConfig.senderEmail, EmailConfig.senderName)
      ..recipients.add(email)
      ..subject = EmailConfig.otpSubject
      ..html =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: Arial, sans-serif;
              background-color: #f4f4f4;
              margin: 0;
              padding: 20px;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              background-color: #ffffff;
              border-radius: 10px;
              overflow: hidden;
              box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
            .header {
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
              padding: 30px;
              text-align: center;
            }
            .content {
              padding: 40px 30px;
              text-align: center;
            }
            .otp-box {
              background-color: #f8f9fa;
              border: 2px dashed #667eea;
              border-radius: 8px;
              padding: 20px;
              margin: 30px 0;
            }
            .otp-code {
              font-size: 42px;
              font-weight: bold;
              color: #667eea;
              letter-spacing: 10px;
              margin: 10px 0;
            }
            .footer {
              background-color: #f8f9fa;
              padding: 20px;
              text-align: center;
              font-size: 12px;
              color: #666;
            }
            .button {
              display: inline-block;
              padding: 12px 30px;
              background-color: #667eea;
              color: white;
              text-decoration: none;
              border-radius: 5px;
              margin: 20px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔐 Password Reset</h1>
            </div>
            <div class="content">
              <h2>Hello!</h2>
              <p>You requested to reset your password for your MeadowMiles account.</p>
              <p>Please use the following One-Time Password (OTP) to verify your identity:</p>
              
              <div class="otp-box">
                <p style="margin: 0; color: #666; font-size: 14px;">Your verification code</p>
                <div class="otp-code">$otp</div>
                <p style="margin: 0; color: #666; font-size: 12px;">Valid for 10 minutes</p>
              </div>
              
              <p><strong>⚠️ Important:</strong></p>
              <ul style="text-align: left; display: inline-block;">
                <li>This code expires in <strong>10 minutes</strong></li>
                <li>Never share this code with anyone</li>
                <li>If you didn't request this, please ignore this email</li>
              </ul>
            </div>
            <div class="footer">
              <p>© 2025 MeadowMiles. All rights reserved.</p>
              <p>This is an automated message, please do not reply.</p>
            </div>
          </div>
        </body>
        </html>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email sent successfully: ${sendReport.toString()}');
    } on MailerException catch (e) {
      debugPrint('❌ Failed to send email: ${e.toString()}');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      rethrow;
    }
  }
}
