# Privacy Policy
Tic Tac Go | Effective November 6, 2026 | Last updated November 6, 2026

## 01 Overview
Entire Solutions develops and publishes Tic Tac Go, an offline-first strategic board game available on Android and iOS mobile platforms. This Privacy Policy explains how information is handled when you download, install, and play Tic Tac Go.

Tic Tac Go is engineered to operate primarily as an offline, standalone application. Entire Solutions does not require you to create an account, does not maintain an online player database, and does not collect, transmit, or store your personal identity information on developer servers.

To support the free version of the game, third-party advertising SDKs (specifically Google AdMob) are integrated to deliver advertisements when your device is connected to the internet. This document outlines the local data stored on your device, the technical information processed by third-party ad networks, and your privacy choices.

## 02 Information stored on your device
Tic Tac Go stores game configuration, statistics, and progress locally on your device using operating system sandboxed storage (SharedPreferences). This data is never sent to Entire Solutions servers and includes the following categories:

- Player profile information: Local username or alias (such as Player 1), player bio, and local Elo-based skill rating.
- Match records and history: Match results (wins, losses, and draws), game duration, total move count, board dimensions (ranging from 3x3 to 8x8 grids), win streak requirements (ranging from 3 to 8 in a row), timestamps of completed matches, and player mark assignments (X or O).
- Gameplay progression: Highest unlocked difficulty level against the computer bot (ranging from Beginner through Master).
- Audio and feedback preferences: Sound effects toggle (enabled or disabled), background music toggle (enabled or disabled), volume level percentages, and haptic vibration feedback preferences.
- Visual and guidance settings: Dark mode theme preference and tutorial completion flags.

All local data remains strictly within the private application directory allocated by Android or iOS and is deleted when the application is uninstalled or when you clear application storage in your device settings.

## 03 Advertising and information processed by third parties
Tic Tac Go incorporates third-party advertising services provided by Google LLC through the Google Mobile Ads SDK (Google AdMob). When your device is connected to the internet, these advertising networks may automatically collect and process certain device and usage information to serve, target, and measure advertisements.

The categories of information processed by third-party advertising partners include:

- Unique and advertising identifiers: Google Advertising ID (GAID / AAID) on Android devices, Identifier for Advertisers (IDFA) on iOS devices (subject to user permission), and software developer kit (SDK) instance identifiers.
- Device and network data: Internet Protocol (IP) address (used to determine general, non-precise geographic location such as country or city), device make, device model, operating system version, mobile network carrier, language settings, and screen resolution.
- Ad interaction and performance data: Information regarding ad views, impressions, clicks, video completions, and user interactions with banner, interstitial, and rewarded advertisements.
- Diagnostic and telemetry metrics: Ad load requests, error logs, latency reports, and performance analytics necessary to diagnose delivery failures and prevent fraudulent impressions.

Ad types utilized in Tic Tac Go include banner advertisements, interstitial advertisements between gameplay sessions, and optional rewarded video advertisements that players may choose to view for gameplay perks.

Entire Solutions does not operate an external server to receive, process, or store these advertising identifiers. All advertising data collection is managed directly by Google AdMob in accordance with Google privacy standards.

## 04 How information is used and shared
The information processed through Tic Tac Go is used strictly for the following purposes:

- Providing core game features: Locally stored data is used exclusively on your device to maintain your rank progression, remember your sound and theme preferences, compute win-loss records, and display your match history.
- Serving and personalizing advertisements: Third-party advertising partners use technical identifiers, general location data, and interaction metrics to display relevant ads, cap the frequency of identical ads, detect invalid traffic, and combat click fraud.
- Measuring advertising performance: Aggregated metrics are used by advertising networks to report ad engagement and calculate developer ad revenue.
- Legal compliance: Information may be accessed or shared by advertising partners if required by applicable law, regulation, legal process, or enforceable governmental request.

Entire Solutions does not sell, rent, lease, or trade your personal information to any third parties.

## 05 Advertising choices and consent
You have multiple options to manage how advertisements are served and how your advertising identifiers are used:

- In-app consent controls: In regions governed by data protection laws requiring explicit consent (such as the European Economic Area, the United Kingdom, and Switzerland under the General Data Protection Regulation and ePrivacy Directive), a consent management platform powered by Google User Messaging Platform (UMP) is displayed upon launch. You can choose to consent to personalized advertising, allow only non-personalized advertising, or decline non-essential cookies and identifiers.
- Android system settings: You can reset or delete your advertising identifier at any time by navigating to Settings > Google > Ads on your Android device and selecting either Reset advertising ID or Delete advertising ID.
- iOS system settings: On iOS devices, you can manage tracking permissions by going to Settings > Privacy & Security > Tracking and toggling off Allow Apps to Request to Track, or going to Settings > Privacy & Security > Apple Advertising to disable Personalized Ads.
- Offline play: Because Tic Tac Go is fully functional offline, you can play without any advertising data collection by placing your device in Airplane Mode or disabling internet connectivity.

## 06 Device permissions
Tic Tac Go requests only the minimum device permissions necessary for gameplay and advertising functionality. The permissions utilized on Android include:

- android.permission.VIBRATE: Allows the game to trigger the device vibration hardware for tactile feedback when tapping buttons, placing stones on the board, and displaying winning strike animations. This permission does not access personal data.
- android.permission.INTERNET: Used exclusively by the Google Mobile Ads SDK to request and load advertisements over network connections.
- android.permission.ACCESS_NETWORK_STATE: Used by the advertising SDK to check whether an active Wi-Fi or cellular network connection exists before attempting to request ad inventory.
- com.google.android.gms.permission.AD_ID: Declared on Android 13 (API level 33) and higher to permit the advertising SDK to access the Google Advertising ID for ad serving, fraud prevention, and analytics.

The application does not request access to sensitive permissions such as precise GPS location, camera, microphone, device storage, contacts, or phone state.

## 07 Children's privacy
Tic Tac Go is designed as a general-audience strategy board game suitable for players of all ages. Entire Solutions does not knowingly collect, request, or solicit personal information from children under the age of 13 (or under 16 in applicable European jurisdictions).

When advertising is displayed, third-party advertising tools may be configured to comply with the Children's Online Privacy Protection Act (COPPA) and Google Play Families Policy requirements. When child-directed treatment is flagged (via COPPA tags such as tagForChildDirectedTreatment or maximum ad content ratings), the advertising SDK suppresses interest-based behavioral tracking and serves only contextual advertisements.

If you are a parent or guardian and believe that personal data of a minor has been collected through our third-party advertising partners, please contact us at support@entiresol.com so we can investigate and address your concern.

<!-- TODO: confirm if the game will be formally submitted under the Google Play Designed for Families program -->

## 08 Data retention and deletion
- Local application data: All gameplay data, match logs, settings, and profile statistics remain stored locally on your device for as long as Tic Tac Go remains installed. You can permanently delete all local game data at any time by navigating to your device Settings > Apps > Tic Tac Go > Storage and selecting Clear Storage or Clear Data, or by uninstalling the app.
- Third-party advertising data: Google AdMob retains technical logs, IP addresses, and interaction metrics according to its own published data retention schedules, typically keeping data for periods ranging from several days up to 18 months for security, fraud prevention, and aggregate reporting purposes.

## 09 Security and international processing
- Device security: All local game data is protected by the operating system application sandboxing architecture on Android and iOS, which prevents other installed applications from accessing Tic Tac Go private files without administrative root access.
- International data transmission: Third-party advertising services operated by Google LLC utilize globally distributed data centers. Consequently, advertising request data, device identifiers, and IP addresses may be transferred to and processed on servers located outside of your country of residence, including within the United States. Google utilizes recognized legal transfer mechanisms, including Standard Contractual Clauses (SCCs), to safeguard cross-border data transfers.

## 10 Your privacy rights
Depending on your geographic location and applicable data protection legislation (such as the European Union General Data Protection Regulation, the United Kingdom GDPR, or the California Consumer Privacy Act / California Privacy Rights Act), you may have the following rights:

- Right to know and access: The right to request confirmation of whether personal data is processed and to receive copies of collected data.
- Right to erasure and deletion: The right to request the deletion of personal data collected about you.
- Right to opt out of sale or sharing: The right to direct businesses not to sell or share your personal information for cross-context behavioral advertising.
- Right to non-discrimination: The right not to receive discriminatory treatment for exercising your privacy rights.

Because Entire Solutions does not collect or maintain identifiable personal records on any external server, you can directly exercise your right of deletion by clearing your app data or uninstalling Tic Tac Go. To exercise rights regarding data processed by Google AdMob, you may utilize Google privacy management tools or submit requests directly via Google privacy portals.

## 11 Changes to this policy
Entire Solutions reserves the right to update or modify this Privacy Policy periodically to reflect changes in our practices, platform requirements, advertising configurations, or legal obligations.

Any revisions will be indicated by updating the Effective date and Last updated date at the top of this document. We encourage you to review this Privacy Policy periodically. Your continued use of Tic Tac Go following the posting of an updated Privacy Policy signifies your acknowledgment and acceptance of the revised terms.

## 12 Contact and third-party privacy links
If you have questions, feedback, or concerns regarding this Privacy Policy or our data handling practices, please contact us:

- Developer and Publisher: Entire Solutions
- Privacy Contact Email: support@entiresol.com

For detailed information regarding how our third-party advertising partner collects, processes, and protects your data, please review the following official resources:

- Google Privacy Policy: https://policies.google.com/privacy
- How Google uses information from sites or apps that use our services: https://policies.google.com/technologies/partner-sites
- Google AdMob and Ads Settings: https://adssettings.google.com
- Google User Messaging Platform (UMP) Overview: https://developers.google.com/admob/flutter/eu-consent
