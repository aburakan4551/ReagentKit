# App Store Reviewer Information

## Core Details

* **App Store Subscriptions / Monetization**: In this initial submission, all Premium features, advanced reagent scan features, priority AI chemical observations, and scientific references are **fully unlocked** by default. No purchase configuration is required to test or validate any aspect of the application.
* **StoreKit / RevenueCat Configurations**: Standard StoreKit subscriptions and RevenueCat entitlements have been bypassed for this build. Monetization features and corresponding App Store In-App Purchases (IAP) will be fully configured and activated in a subsequent production update.
* **External Payment Systems**: The application does **NOT** use or query any external or third-party payment systems. All features are natively open and available for immediate validation.
* **Preloaded Demo Data**: To provide a polished first-time user experience and prevent empty-state indicators, the application preloads mock reagent scan histories and safety reports under the "History" and "Profile" views.

## Verification Checklist

1. **Monetization Visibility**: The paywall, billing sections, promotional crowns, upsell banners, and purchase/restore options are completely hidden from the user interface.
2. **Access Controls**: Reviewers can initiate, process, and complete reagent color testing scans, view safety handling procedures, analyze reactions, and consult scientific references without trial warnings or count limitations.
3. **Offline Stability**: The application does not block or show endless loading indicators if internet connectivity is absent. Billing features are simulated locally and return immediate success.
