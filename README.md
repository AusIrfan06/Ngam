# Ngam - Local Errands, Powered by Community

Ngam is a community-driven Flutter application that connects people who need help with local errands (Customers) and people willing to do them (Runners). Whether it's buying food, doing a quick grocery run, printing documents, or heavy lifting, Ngam provides a seamless platform to get tasks done.

## Features

- **Dual-Role System:** Users can easily switch or register as a Customer (to request tasks) or a Runner (to earn money by completing tasks).
- **Real-Time Task Feed:** Runners can browse a live feed of open tasks and accept jobs instantly.
- **In-App Chat:** Real-time communication between Customers and Runners to coordinate tasks seamlessly.
- **DuitNow QR Integration:** Runners can upload their DuitNow QR codes for easy, direct payments from Customers upon task completion. 
- **Optimized Splash Screen:** The app uses a native splash screen that stays visible while initial data loads in the background, ensuring users land directly on a fully populated home screen.
- **Supabase Backend:** Powered by Supabase for fast, secure authentication, database management, and real-time features.

## Tech Stack

- **Frontend:** Flutter & Dart
- **Backend/Database:** Supabase (PostgreSQL, Realtime, Auth)
- **State Management:** Provider
- **Localization:** Easy Localization (Supports English and Malay)
- **UI Design:** Custom glassmorphism, animated backgrounds, and rich modern aesthetics (`liquid_glass_widgets`).

## Getting Started

### Prerequisites
- Flutter SDK (`>=3.0.0`)
- Dart SDK
- A Supabase project (for backend services)

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure your Supabase environment variables.
4. Run the app using `flutter run`.

## Payment Verification
Ngam emphasizes trust. When a Runner uploads their DuitNow QR for payment, the app displays the original, uncropped screenshot so Customers can visually verify the registered name provided directly by the bank before making any transfers.

---
*Made with ❤️ in Malaysia.*
