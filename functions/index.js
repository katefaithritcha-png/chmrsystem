const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Configure email transporter
// Using Gmail with App Password (more secure than regular password)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER || 'your-email@gmail.com',
    pass: process.env.GMAIL_APP_PASSWORD || 'your-app-password',
  },
});

/**
 * Send verification email with 6-digit code
 * 
 * Callable from Flutter app:
 * await FirebaseFunctions.instance
 *   .httpsCallable('sendVerificationEmail')
 *   .call({'email': 'user@example.com', 'code': '123456'});
 */
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, code } = data;

    // Validate input
    if (!email || !code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and code are required'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    // Validate code format (6 digits)
    if (!/^\d{6}$/.test(code)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Code must be 6 digits'
      );
    }

    // Email content
    const mailOptions = {
      from: process.env.GMAIL_USER || 'your-email@gmail.com',
      to: email,
      subject: 'HealthSphere - Email Verification Code',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
                margin: 0;
                padding: 0;
              }
              .container {
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                overflow: hidden;
              }
              .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
              }
              .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: 600;
              }
              .content {
                padding: 30px;
              }
              .greeting {
                font-size: 16px;
                color: #333;
                margin-bottom: 20px;
              }
              .code-section {
                background-color: #f9f9f9;
                border-left: 4px solid #667eea;
                padding: 20px;
                margin: 20px 0;
                border-radius: 4px;
              }
              .code-label {
                font-size: 14px;
                color: #666;
                margin-bottom: 10px;
                font-weight: 500;
              }
              .code {
                font-size: 36px;
                font-weight: bold;
                color: #667eea;
                letter-spacing: 4px;
                text-align: center;
                font-family: 'Courier New', monospace;
              }
              .expiry {
                font-size: 14px;
                color: #999;
                margin-top: 15px;
                text-align: center;
              }
              .warning {
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 20px 0;
                border-radius: 4px;
                font-size: 14px;
                color: #856404;
              }
              .footer {
                background-color: #f5f5f5;
                padding: 20px;
                text-align: center;
                font-size: 12px;
                color: #999;
                border-top: 1px solid #eee;
              }
              .footer p {
                margin: 5px 0;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🏥 HealthSphere</h1>
                <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Email Verification</p>
              </div>
              
              <div class="content">
                <div class="greeting">
                  <p>Hello,</p>
                  <p>Thank you for registering with HealthSphere. To complete your registration, please verify your email address using the code below:</p>
                </div>
                
                <div class="code-section">
                  <div class="code-label">Your Verification Code:</div>
                  <div class="code">${code}</div>
                  <div class="expiry">⏱️ This code expires in 10 minutes</div>
                </div>
                
                <div class="warning">
                  <strong>⚠️ Security Notice:</strong> Never share this code with anyone. HealthSphere staff will never ask for this code.
                </div>
                
                <p style="font-size: 14px; color: #666; margin-top: 20px;">
                  If you didn't request this verification code, please ignore this email or contact our support team.
                </p>
              </div>
              
              <div class="footer">
                <p>© 2024 HealthSphere. All rights reserved.</p>
                <p>This is an automated email. Please do not reply to this message.</p>
                <p>For support, contact: support@healthsphere.com</p>
              </div>
            </div>
          </body>
        </html>
      `,
      text: `
HealthSphere Email Verification

Hello,

Thank you for registering with HealthSphere. Your verification code is:

${code}

This code expires in 10 minutes.

Security Notice: Never share this code with anyone. HealthSphere staff will never ask for this code.

If you didn't request this verification code, please ignore this email.

© 2024 HealthSphere. All rights reserved.
      `,
    };

    // Send email
    await transporter.sendMail(mailOptions);

    // Log the event
    console.log(`Verification email sent to ${email}`);

    return {
      success: true,
      message: 'Verification email sent successfully',
      email: email,
    };
  } catch (error) {
    console.error('Error sending verification email:', error);

    // Return appropriate error
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to send verification email: ' + error.message
    );
  }
});

/**
 * Send password reset email
 * 
 * Callable from Flutter app:
 * await FirebaseFunctions.instance
 *   .httpsCallable('sendPasswordResetEmail')
 *   .call({'email': 'user@example.com', 'resetLink': 'https://...'});
 */
exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, resetLink } = data;

    if (!email || !resetLink) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and resetLink are required'
      );
    }

    const mailOptions = {
      from: process.env.GMAIL_USER || 'your-email@gmail.com',
      to: email,
      subject: 'HealthSphere - Password Reset Request',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
              }
              .container {
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
              }
              .content {
                padding: 30px;
              }
              .button {
                display: inline-block;
                background-color: #667eea;
                color: white;
                padding: 12px 30px;
                text-decoration: none;
                border-radius: 4px;
                margin: 20px 0;
              }
              .footer {
                background-color: #f5f5f5;
                padding: 20px;
                text-align: center;
                font-size: 12px;
                color: #999;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🏥 HealthSphere</h1>
                <p style="margin: 10px 0 0 0;">Password Reset</p>
              </div>
              
              <div class="content">
                <p>Hello,</p>
                <p>We received a request to reset your password. Click the button below to reset it:</p>
                
                <center>
                  <a href="${resetLink}" class="button">Reset Password</a>
                </center>
                
                <p>Or copy and paste this link in your browser:</p>
                <p style="word-break: break-all; font-size: 12px; color: #666;">${resetLink}</p>
                
                <p style="color: #999; font-size: 14px;">This link expires in 1 hour.</p>
                
                <p>If you didn't request this, please ignore this email.</p>
              </div>
              
              <div class="footer">
                <p>© 2024 HealthSphere. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`Password reset email sent to ${email}`);

    return {
      success: true,
      message: 'Password reset email sent successfully',
    };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send password reset email: ' + error.message
    );
  }
});

/**
 * Send welcome email to new user
 * 
 * Callable from Flutter app:
 * await FirebaseFunctions.instance
 *   .httpsCallable('sendWelcomeEmail')
 *   .call({'email': 'user@example.com', 'name': 'John Doe', 'role': 'patient'});
 */
exports.sendWelcomeEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, name, role } = data;

    if (!email || !name) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and name are required'
      );
    }

    const mailOptions = {
      from: process.env.GMAIL_USER || 'your-email@gmail.com',
      to: email,
      subject: 'Welcome to HealthSphere!',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
              }
              .container {
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
              }
              .content {
                padding: 30px;
              }
              .feature {
                margin: 15px 0;
                padding: 10px;
                background-color: #f9f9f9;
                border-left: 4px solid #667eea;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🏥 Welcome to HealthSphere!</h1>
              </div>
              
              <div class="content">
                <p>Hello ${name},</p>
                <p>Thank you for joining HealthSphere! We're excited to have you on board.</p>
                
                <h3>Your Account Details:</h3>
                <p><strong>Email:</strong> ${email}</p>
                <p><strong>Role:</strong> ${role}</p>
                
                <h3>Getting Started:</h3>
                <div class="feature">
                  <strong>📋 Complete Your Profile</strong> - Add your personal information and preferences
                </div>
                <div class="feature">
                  <strong>🔐 Secure Your Account</strong> - Enable two-factor authentication for extra security
                </div>
                <div class="feature">
                  <strong>📚 Learn the Basics</strong> - Check out our help center for tutorials
                </div>
                
                <p>If you have any questions, feel free to contact our support team.</p>
                <p>Happy to have you with us!</p>
              </div>
              
              <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #999;">
                <p>© 2024 HealthSphere. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`Welcome email sent to ${email}`);

    return {
      success: true,
      message: 'Welcome email sent successfully',
    };
  } catch (error) {
    console.error('Error sending welcome email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send welcome email: ' + error.message
    );
  }
});

/**
 * Send verification email via Mailgun (for web compatibility)
 * 
 * Callable from Flutter app:
 * await FirebaseFunctions.instance
 *   .httpsCallable('sendVerificationEmailMailgun')
 *   .call({'email': 'user@example.com', 'code': '123456'});
 */
exports.sendVerificationEmailMailgun = functions.https.onCall(async (data, context) => {
  try {
    const { email, code } = data;

    // Validate input
    if (!email || !code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and code are required'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    // Mailgun credentials from environment variables
    const mailgunApiKey = process.env.MAILGUN_API_KEY;
    const mailgunDomain = process.env.MAILGUN_DOMAIN;

    // Create Basic Auth header
    const auth = Buffer.from(`api:${mailgunApiKey}`).toString('base64');

    // Email HTML template
    const htmlBody = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
            .header h1 { margin: 0; font-size: 28px; font-weight: 600; }
            .content { padding: 30px; }
            .code { font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 4px; text-align: center; font-family: 'Courier New', monospace; margin: 20px 0; }
            .footer { background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #999; border-top: 1px solid #eee; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🏥 HealthSphere</h1>
              <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Email Verification</p>
            </div>
            <div class="content">
              <p>Hello,</p>
              <p>Thank you for registering with HealthSphere. To complete your registration, please verify your email address using the code below:</p>
              <div class="code">${code}</div>
              <p style="color: #999; font-size: 14px;">⏱️ This code expires in 10 minutes</p>
              <p style="color: #666; font-size: 14px; margin-top: 20px;">
                If you didn't request this verification code, please ignore this email.
              </p>
            </div>
            <div class="footer">
              <p>© 2024 HealthSphere. All rights reserved.</p>
              <p>This is an automated email. Please do not reply to this message.</p>
            </div>
          </div>
        </body>
      </html>
    `;

    // Send via Mailgun API
    const fetch = require('node-fetch');
    const FormData = require('form-data');
    const form = new FormData();
    
    form.append('from', `HealthSphere <noreply@${mailgunDomain}>`);
    form.append('to', email);
    form.append('subject', 'HealthSphere - Email Verification Code');
    form.append('html', htmlBody);
    form.append('text', `Your HealthSphere verification code is: ${code}\n\nThis code expires in 10 minutes.`);

    const response = await fetch(`https://api.mailgun.net/v3/${mailgunDomain}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
      },
      body: form,
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Mailgun API error: ${response.status} ${errorBody}`);
    }

    const result = await response.json();
    console.log(`Verification email sent to ${email} via Mailgun`);

    return {
      success: true,
      message: 'Verification email sent successfully',
      messageId: result.id,
    };
  } catch (error) {
    console.error('Error sending verification email via Mailgun:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send verification email: ' + error.message
    );
  }
});
