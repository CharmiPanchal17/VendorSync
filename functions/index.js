const functions = require('firebase-functions');
const admin = require('firebase-admin');
const csv = require('csv-parser');
const { Storage } = require('@google-cloud/storage');
const fs = require('fs');
const os = require('os');
const path = require('path');

Future<void> uploadSalesReport(String vendorId, File file) async {
  final storageRef = FirebaseStorage.instance.ref()
      .child('sales_reports/$vendorId/${DateTime.now().toIso8601String()}.csv');
  await storageRef.putFile(file);
}
//life