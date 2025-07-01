import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<bool> sendOrderNotification({
    required String supplierEmail,
    required String supplierName,
    required String vendorEmail,
    required String productName,
    required int quantity,
    required DateTime preferredDate,
    required String orderId,
  }) async {
    try {
      // For development/testing, you can use Gmail SMTP
      // In production, you should use a proper email service like SendGrid, AWS SES, etc.
      
      // Gmail SMTP configuration (you'll need to enable 2FA and generate an app password)
      // Replace with your actual Gmail credentials
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
      
      // Alternative: Use a service like SendGrid
      // final smtpServer = SmtpServer('smtp.sendgrid.net', username: 'apikey', password: 'your-sendgrid-api-key');
      
      final message = Message()
        ..from = Address('your-email@gmail.com', 'VendorSync')
        ..recipients.add(supplierEmail)
        ..subject = 'New Order Received - VendorSync'
        ..html = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>New Order Notification</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #2196F3, #43E97B); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .order-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2196F3; }
              .highlight { color: #2196F3; font-weight: bold; }
              .button { display: inline-block; background: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
              .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>📦 New Order Received</h1>
                <p>You have received a new order from VendorSync</p>
              </div>
              <div class="content">
                <h2>Hello ${supplierName},</h2>
                <p>A vendor has placed a new order with you. Here are the details:</p>
                
                <div class="order-details">
                  <h3>Order Details</h3>
                  <p><strong>Order ID:</strong> <span class="highlight">$orderId</span></p>
                  <p><strong>Product:</strong> $productName</p>
                  <p><strong>Quantity:</strong> $quantity</p>
                  <p><strong>Preferred Delivery Date:</strong> ${preferredDate.toString().split(' ')[0]}</p>
                  <p><strong>Vendor Email:</strong> $vendorEmail</p>
                </div>
                
                <p>Please review this order and update its status in your VendorSync dashboard.</p>
                
                <p>Best regards,<br>The VendorSync Team</p>
              </div>
              <div class="footer">
                <p>This is an automated message from VendorSync. Please do not reply to this email.</p>
              </div>
            </div>
          </body>
          </html>
        ''';

      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // For testing purposes, you can use a mock email service
  static Future<bool> sendMockOrderNotification({
    required String supplierEmail,
    required String supplierName,
    required String vendorEmail,
    required String productName,
    required int quantity,
    required DateTime preferredDate,
    required String orderId,
  }) async {
    // Simulate email sending delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, this would send an actual email
    // For now, we'll just print the email details
    print('''
    ===== MOCK EMAIL SENT =====
    To: $supplierEmail
    Subject: New Order Received - VendorSync
    
    Hello $supplierName,
    
    A vendor has placed a new order with you. Here are the details:
    
    Order ID: $orderId
    Product: $productName
    Quantity: $quantity
    Preferred Delivery Date: ${preferredDate.toString().split(' ')[0]}
    Vendor Email: $vendorEmail
    
    Please review this order and update its status in your VendorSync dashboard.
    
    Best regards,
    The VendorSync Team
    =========================
    ''');
    
    return true;
  }
} 