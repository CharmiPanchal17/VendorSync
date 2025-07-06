# Session Management Test Guide

## Test Scenarios

### 1. First Time User Flow
1. **Clear app data** (if testing on device)
2. **Open app** → Should show splash screen → Welcome screen
3. **Register as vendor/supplier** → Should save session → Redirect to dashboard
4. **Close app completely**
5. **Reopen app** → Should show splash screen → Automatically redirect to dashboard (no login required)

### 2. Login Flow
1. **Clear app data**
2. **Open app** → Welcome screen
3. **Login with existing credentials** → Should save session → Redirect to dashboard
4. **Close app completely**
5. **Reopen app** → Should automatically redirect to dashboard

### 3. Session Extension Test
1. **Login to app** → Session saved
2. **Use app for a few days** (or simulate by changing device date)
3. **Close app**
4. **Reopen app** → Should still be logged in (session extended)

### 4. Logout Test
1. **Login to app**
2. **Go to dashboard drawer** → Tap logout
3. **Confirm logout** → Should clear session → Redirect to welcome screen
4. **Close app**
5. **Reopen app** → Should show welcome screen (not logged in)

### 5. Session Expiration Test (14 days)
1. **Login to app**
2. **Change device date to 15 days later**
3. **Close and reopen app** → Should show welcome screen (session expired)

## Expected Behavior

### ✅ Success Indicators:
- Users stay logged in across app sessions
- Sessions extend when users are active
- Logout properly clears session data
- Expired sessions redirect to welcome screen
- No crashes or errors during session operations

### ❌ Issues to Watch For:
- App crashes on startup
- Users forced to login repeatedly
- Sessions not extending properly
- Logout not working
- Invalid redirects

## Debug Information

### Session Data Location:
- Android: `/data/data/[package_name]/shared_prefs/`
- iOS: App's Documents directory
- Web: Browser's localStorage

### Key Session Keys:
- `user_session`: Contains user data (email, role, userId, loginTime)
- `last_activity`: Contains last activity timestamp

### Session Service Methods:
- `saveSession()`: Called after login/registration
- `getSession()`: Called by splash screen
- `isLoggedIn()`: Checks if valid session exists
- `clearSession()`: Called during logout
- `updateLastActivity()`: Called when user interacts with app
- `extendSession()`: Called when session should be extended 