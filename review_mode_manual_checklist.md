# Review Mode Manual Checklist

Use this checklist to manually verify the application state and behavior before submitting to the App Store.

## 1. User Interface (UI) Verification
* [ ] **No Paywall Visible**: Navigating the application (via Start Test, Profile, Settings) does not present the Paywall or any pricing sheet.
* [ ] **No Pricing Visible**: No prices (e.g., $4.99/month, $29.99/year, $59.99 lifetime) or trial notifications are displayed anywhere in the UI.
* [ ] **Restore Purchases Hidden**: The "Restore Purchases" action is fully hidden from both settings, profile, and paywall sections.
* [ ] **No Promo Banners**: The "PRO Laboratory Account" promotional banners, crowns, lock icons, and other monetization prompts are completely absent.
* [ ] **Dev Bypass Removed**: No debug or bypass labels are visible on the profile, settings, or dashboard views.

## 2. Navigation & Routing Guards
* [ ] **Route Interception**: Attempting to route to `subscription_page`, `premium_page`, or `paywall_page` (either programmatically or via deep links) triggers the routing shield and redirects back to Home.
* [ ] **Deep Links Blocked**: Incoming links with promo, premium, or paywall queries are intercepted and handled safely.

## 3. Persistent Storage & Services
* [ ] **RevenueCat Inactive**: No calls to `Purchases.configure()` are executed. Offerings query returns an empty collection immediately.
* [ ] **StoreKit Sandboxed**: No native OS App Store purchase prompts are triggered during any flow.
* [ ] **Local Storage Safe**: Review-mode temporary premium states are not persisted in local SharedPreferences or Keychain database.
* [ ] **Cloud Sync Blocked**: Database sync routines do not upload premium flags or temporary scans left metrics to Cloud Firestore.

## 4. Stability & Content
* [ ] **Offline Functionality**: The app functions smoothly without network connectivity, defaulting to safe offline configurations for premium assertions.
* [ ] **Preloaded Seed Data**: The "History" and "Profile" pages are pre-populated with realistic reagent scan details from `ReviewerDemoSeed`.
* [ ] **Zero Rejection Risk Indicators**: No unfinished placeholders or "To Be Done" premium alerts appear in the UI.
