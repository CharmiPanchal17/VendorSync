# Firestore Indexes Setup

## Issue
You're getting a Firestore index error when querying notifications. The error message indicates that you need to create composite indexes for the notifications collection.

## Solution

### Option 1: Use the Direct Link (Recommended)
Click on the link provided in the error message to create the index directly:
```
https://console.firebase.google.com/v1/r/project/vendorsync-e2234/firestore/indexes?create_composite=ClZwcm9qZWN0cy92ZW5kb3JzeW5jLWUyMjM0L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ub3RpZmljYXRpb25zL2luZGV4ZXMvXxABGhIKDnJlY2lwaWVudEVtYWlsEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

### Option 2: Manual Setup via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `vendorsync-e2234`
3. Navigate to Firestore Database
4. Click on the "Indexes" tab
5. Click "Create Index"
6. Create the following indexes:

#### Index 1: Notifications by recipientEmail and createdAt
- Collection ID: `notifications`
- Fields:
  - `recipientEmail` (Ascending)
  - `createdAt` (Descending)

#### Index 2: Notifications by recipientEmail and isRead
- Collection ID: `notifications`
- Fields:
  - `recipientEmail` (Ascending)
  - `isRead` (Ascending)

### Option 3: Deploy via Firebase CLI
If you have Firebase CLI installed:

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```

4. Deploy the indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

## Required Indexes
The following composite indexes are needed for the notification queries:

1. **Collection**: `notifications`
   - **Fields**: `recipientEmail` (Ascending), `createdAt` (Descending)
   - **Used by**: `getNotificationsForUser()` method

2. **Collection**: `notifications`
   - **Fields**: `recipientEmail` (Ascending), `isRead` (Ascending)
   - **Used by**: `markAllNotificationsAsRead()` and `getUnreadNotificationCount()` methods

## Wait Time
After creating the indexes, it may take a few minutes for them to build. You can monitor the progress in the Firebase Console under Firestore > Indexes.

## Verification
Once the indexes are built, the error should disappear and your notification queries should work properly. 