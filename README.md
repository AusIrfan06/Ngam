# Ngam - Roger Anything, Kautim Instantly

[![Download APK](https://img.shields.io/badge/Download-Android_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/AusIrfan06/Ngam/releases/latest/download/app-release.apk)

[Or click here to go to the Releases page](https://github.com/AusIrfan06/Ngam/releases)


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

# Ngam App User Manual

Welcome to **Ngam - Roger Anything, Kautim Instantly**. Ngam is a community app that connects people who need help with daily tasks (Customer) with those ready to help (Runner). 

This manual covers all the core functions and advanced features of the app, from registration to task completion.

---

## 1. Getting Started

### 1.1 Registration & Login
- **Standard Email Registration**: While registering with an email and password, you can immediately choose your role as a **Customer** or **Runner**. If you choose Runner, the *Runner Details* form (IC & Vehicle) will appear to be completed during registration.
- **Google Login**: For a fast process, you can use your Google Account. By default, logging in via Google will register you as a **Customer**.
- After registration, make sure to update your basic profile (Full Name, Profile Picture, Phone Number) to make it easier for other users to contact you.

### 1.2 Dual-Role System & Runner Verification
- **One Account, Two Functions**: You don't need to register separate accounts to be a user or a deliverer.
- **From Customer to Runner**: If you registered using a Google account (or registered as a Customer initially), you can always apply to be a Runner within the app.
- **Steps to Become a Runner (For Existing Accounts)**: If you try to register again on the *Register* page as a Runner using the same Customer email, the system will not allow duplicate accounts. Instead, simply **Log In** normally, go to the **Profile** menu, and tap the *Toggle* button to Runner. The *Runner Verification* form (IC, License Plate, Vehicle Type) will automatically appear for you to fill in.
- **Switching Roles**: Once verification is successful, you are now a registered Runner. After this, you are free to switch roles between Customer <-> Runner anytime in a blink of an eye!

### 1.3 Language & Theme Settings
- **Dual-Language**: The Ngam app supports **English** and **Malay**.
- **Dark Mode**: You can also switch the display to *Light* or *Dark Mode*.
- **How to Change**: You can configure Language & Theme directly at:
  1. **Login Page (Sign In / Register)**: Tap the button at the top right of the screen before registering.
  2. **Profile Page**: There is a dedicated toggle button to change the theme and language anytime. The system will automatically save your preferences.

---

## 2. Ngam Pay (Digital Wallet System)

Ngam comes with a built-in digital wallet, **Ngam Pay**, to ensure every transaction runs smoothly, securely, and free from scams.

### 2.1 Top Up
1. Go to the **Wallet** page.
2. You can add a Payment Method like Credit/Debit Card or use Online Banking.
3. Tap the **Top Up** button, enter the desired amount, and confirm. Your wallet balance will be updated in real-time.

### 2.2 Add Payment Method (Card / Bank Account / DuitNow QR)
The system allows you to securely save card, bank account, or DuitNow QR information in the wallet.
1. On the **Wallet** page, scroll down until you find the **Payment Methods** section.
2. Tap the card box marked **+ Add New**.
3. Select the type of method you want to add:
   - **Bank Account**: Choose your bank (e.g., Maybank, CIMB) and enter the account number. This is crucial for enabling Withdrawals.
   - **Credit / Debit Card**: Enter the card number, expiry date, and CVV (securely encrypted).
   - **DuitNow QR**: Specifically for Runners to receive payments, upload a verified QR image (unedited).
4. This info will be saved as a "Card" that can be swiped in the Payment Methods section.

### 2.3 Withdraw
- The *Withdraw* function allows funds from the wallet to be transferred directly to your bank account.
- **Important**: You MUST register your Bank Account Information (Refer to 2.2) in the system first before the withdrawal function can be used.
- The withdrawal process is secure, and your wallet balance will be deducted automatically based on the withdrawal amount.

### 2.4 DuitNow QR & Anti-Scam System
- Runners can upload their **DuitNow QR** image.
- When it's time for payment, Ngam will display the original QR code (uncropped and unedited) so Customers can visually check the registrant's full name in their banking app. This prevents fake profile impersonation scams.

---

## 3. Customer Mode (When You Need Help)

Use this mode when you need a Runner to complete daily tasks like buying food, groceries, or delivering parcels.

### 3.1 Post Task
1. Go to the **Post Task** tab (the '+' icon in the middle of the bottom menu).
2. Fill in the task details:
   - **Task Title** & **Full Description**.
   - **Category** (Food, Groceries, Delivery, Repair, etc.).
   - **Bounty (Reward)**: The payment you are offering. The system will deduct this amount from your Ngam Pay into the *Escrow* system (safe holding) while the task is ongoing.
   - **Location**: Use the smart *Map Picker* to accurately set the GPS coordinates (red pin).
3. Tap **Submit**. Your task is now broadcasted *live* on the Runners' map.

### 3.2 Discover (Find Nearby Runners & Services)
The **Home** screen provides an **Interactive Map** showing service offerings from various nearby Runners. There are 2 main ways to book a service from this page:
1. **Tap on Map Pins**: If you see a nearby service pin (e.g., "Fix Leaking Pipe - RM50"), you can tap directly on that pin. An info box will appear, tap it and press **Book Service**. A successful booking reminder will appear as an elegant *Glass Toast* notification.
2. **Use the Carousel Function (Swipe Cards)**: At the bottom of the map, there is a **Carousel** (a list of swipeable cards). When you swipe the cards, the map will automatically *auto-focus* and show the exact location of the service. This allows you to quickly browse without having to tap individual pins on the map.

### 3.3 Managing Tasks (My Tasks)
You can monitor all your tasks in the **My Tasks** section.
- **Sort Function**: Use the arrow button next to the "My Tasks" title to sort the task list from **Newest** to **Oldest**.
- **Open**: The task is still looking for a Runner. You can **Cancel/Delete** the task at this stage, and the money will be 100% refunded to your wallet.
- **Locked**: A Runner is interested in taking your task. You need to approve/accept the Runner before the task begins.
- **In-Progress**: The Runner is currently executing the task. The private **Chat** room will be opened.
- **Delivered**: The Runner has marked the task as done.
- **Completed**: You verify that the work is finished, and the system releases the *Bounty* money to the Runner's wallet.

---

## 4. Runner Mode (Make Extra Money)

Use this mode to find tasks, help the community, and generate flexible income.

### 4.1 Find Tasks on the Discover Page (Map & Carousel)
Similar to Customers, Runners also use the **Home** Map to find nearby Customer tasks (*Job Requests*):
- **Tap Directly on Pins**: You can tap any task pin on the map, read the details (Bounty, distance, description), and press **Accept Job** to take the job.
- **Carousel (Card List)**: Swipe the task cards in the *Carousel* section at the bottom of the screen. Every time you swipe to a new card, the map will *zoom in* on that customer's location. This makes it easier for you to compare task distances without opening a new page.

### 4.2 Offering Services (Service Listing)
- You can also offer your expertise as a service package. Tap the **Post Service** button in the *My Jobs* section.
- Fill in the details of the service you provide, such as "Laptop Formatting Service (RM50)" or "IKEA Personal Shopper (RM30)". Use the map to set the location where you offer the service.
- **100% Free**: Posting service ads is free and does not deduct any amount from your *Ngam Pay* balance. This service will remain on the map (Discover page) and Customers can book your service anytime. Incoming bookings will appear in the "Customer Bookings" section in your profile.

### 4.3 Workflow
1. After pressing *Accept Job*, the task moves to the **My Jobs** tab under the **In-Progress** or **Locked** category.
2. **Sort Function**: You can sort your job list chronologically (Newest/Oldest).
3. You can communicate and update the status directly through the **Chat** room. 
4. Once you have completed the task, press the **Mark as Delivered** button. 
5. When the Customer confirms, the task becomes **Completed** and the *bounty* will go straight into your Ngam Pay Wallet.

### 4.4 Managing Your Own Services (My Services)
As a Runner, you can monitor the service ads you offer in the **My Jobs > My Services** section:
1. **Details**: View full details of your service ad.
2. **Pause / Resume**: You can *Pause* your service ad if you are busy, and *Resume* when you are ready to accept bookings again.
3. **Delete**: Permanently delete a service ad.
4. **Customer Bookings**: If a customer makes a booking for your service, it will be listed directly under that ad for you to manage.

---

## 5. Advanced AI & Unique Features

Ngam is not just an ordinary app; it is equipped with future technology to make your life easier:

### 5.1 AI Voice Assistant (Ngam AI)
- On the main screen, there is an AI smart assistant. You can type or **speak directly** (Speech-to-Text)!
- **Example Commands**:
  - *"Please find the most expensive job around here."*
  - *"Does anyone need food delivery services?"*
- The AI will scan all nearby jobs *live* and tell you the results. 
- Ngam AI supports casual language (Manglish/Malay).
- **Text-to-Speech (TTS)**: The AI will reply to you with a voice so you don't have to read text while driving or walking.

### 5.2 Real-time Chat & Voice
- Every task provides a dedicated chat room.
- You can send normal text messages.
- **Voice Dictation**: Too lazy to type? Use the built-in microphone icon in the chat to automatically convert your speech into text!

### 5.3 "Liquid Glass" Interface (Glassmorphism)
- The app is built with a modern design theme called *Liquid Glass*. You will notice transparent blur elements, micro-light effects, smooth animations that give a premium iOS-like feel, as well as elegant **Glass Toast** notifications (like when you successfully book a service).
- **Dark Mode / Light Mode**: Supported automatically according to your smartphone's settings.

---

## 6. Ngam Security Features (Security & Privacy)

The Ngam app is designed with multiple layers of security to protect users, money, and your personal data:

### 6.1 Data & Access Security (Supabase & RLS)
- **Secure Login**: World-class authentication support using the Supabase Auth system.
- **Row Level Security (RLS)**: Ngam uses strict Database Policies. This means your personal data, chat messages, and wallet balance are locked at the server level and **only you** can view/modify them. Third parties cannot hack your data.

### 6.2 "Escrow" Payment System
- **Financial Guarantee**: Customers don't need to worry about Runners running away without doing the job, and Runners don't need to worry about not getting paid after working hard. 
- When a task is agreed upon, the money will be pulled into the *Escrow* system (Ngam's safe holding). This money will only be released to the Runner *after* the Customer presses the confirm job completed button (Completed).

### 6.3 Anti-Scam DuitNow QR
- Our system requires Runners to upload an original (uncropped) DuitNow QR image.
- When Customers want to pay/verify via their banking app, they can visually see the registered account owner's name directly to ensure it matches the Runner's profile. This prevents identity impersonation.

### 6.4 Map Location Privacy (Location Privacy)
- The map only displays the location where the Task needs to be done. 
- **Your actual GPS location is always safe and hidden** from public view to avoid any privacy intrusion.

### 6.5 Device Privacy Controls (App Lock & App Switcher)
You can further tighten the security of the Ngam app on your phone via the **Profile > Privacy & Security** menu:
1. **App Lock**: You can activate App Lock using a fingerprint (Biometrics) or phone PIN. You can set a time (Immediately, 1 min, 15 min, 1 hour) so the app locks automatically when you exit (minimize).
2. **Hide in App Switcher (Blur Screen)**: Activate this feature to blur the Ngam app display when you open the *Recent Apps* or *App Switcher* function on your phone. This prevents people next to you from peeking at your Ngam Pay balance or private chats from afar.

---

## 7. In-App Chat System

Ngam has a highly interactive built-in messaging/chat function to facilitate communication between Customer and Runner:
1. **Real-time Messaging**: Messages are sent and received instantly without needing to *refresh*.
2. **Presence Status (Online/Offline)**: You can see if the other party is 'Online'.
3. **Typing Indicator**: You will see a small animation when the other party is typing a message.
4. **Message Search**: You can use the *Search* function to find old messages.
5. **Auto-Scroll to Bottom**: Ensures new incoming messages always appear instantly on the screen.

*(Important Note: The swiping / Carousel function only exists on the Map/Discover page. If you want to open Chat for different tasks, you need to go to the My Tasks/My Jobs page and press the Chat button on the respective task card.)*

---

## 8. Help & Support

- If there are any disputes or technical issues (e.g., Runner didn't finish the job, or refund hasn't arrived), use the **Help & Support** button in the Profile section. 
- The Ngam Team is always ready to help you review the chat logs and refund money fairly in the event of fraud.

> [!TIP]
> Always check the *push* notifications on your mobile phone and enable location permissions (GPS Permission - Always/While In Use) to experience the optimal Ngam app experience.

Thank you for using Ngam. Keep on **"Roger Anything, Kautim Instantly"**!
