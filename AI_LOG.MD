# AI Usage & Disclosure Log

**Project Component:** Real-Time WebSockets, Concurrency, Voice AI, and Biometric Security (Ngam App)
**AI Tool Used:** Android Studio (Gemini)

---

### 1. The Intent
*What specific problem were you trying to solve with AI?*
I needed to solve five highly complex programming challenges in the Ngam app that would otherwise require senior-level experience:
1. **Frontend & Backend (WebSockets):** Building a full-fledged Real-Time Chat Engine (`chat_service.dart` & `chat_screen.dart`). I needed to implement Supabase `RealtimeChannel` to handle instant messaging, live typing indicators (Presence), and optimistic UI updates without crashing the app.
2. **Backend (Concurrency):** Writing a PostgreSQL Remote Procedure Call (RPC) to handle wallet withdrawals securely (`withdraw_wallet`), ensuring Row-Level Locking so rapid clicks wouldn't result in negative balances.
3. **Generative AI Integration:** Building a "Voice-Activated AI Assistant" in the Runner's Discover screen (`runner_home_screen.dart`). This assistant listens to the runner's voice, feeds nearby gigs to a Large Language Model (Llama-3 via NVIDIA API), and reads back the best-matched jobs using Text-to-Speech.
4. **Security & Hardware (Biometric & App Switcher Hide):** Implementing an app-wide security lock (`app_lock_wrapper.dart`) that detects when the app goes into the background using `WidgetsBindingObserver` and requires Fingerprint/FaceID (`local_auth`) to unlock upon resuming. Additionally, implemented logic to obscure the app screen in the OS app switcher for privacy.
5. **Backend & Frontend (Transaction Payment Flow):** Building a comprehensive Wallet and Escrow system (`wallet_screen.dart`, `gig_service.dart`). I needed to implement an end-to-end payment flow including Wallet Top-ups, Bank Withdrawals, and Escrow logic where funds are safely held upon task creation and released to the runner via an RPC (`complete_gig_and_pay`) upon task completion.

### 2. The Interaction (Prompting)
*What was your primary prompt, and did you have to refine it?*
1. **For the Real-Time Chat:** "Write a Dart service using `supabase_flutter` that subscribes to database changes via `RealtimeChannel`. It needs to listen to INSERT events for new messages and use Presence to track when the other user is typing."
2. **For the Database RPC:** "Write a Supabase PostgreSQL function to deduct a user's wallet balance securely. It must use `SELECT FOR UPDATE` to prevent race conditions."
3. **For the Voice AI Assistant:** "Write a Dart function integrating `speech_to_text`, `flutter_tts`, and `http` requests. It must capture the runner's voice, gather the top 5 closest gigs using `Geolocator`, inject this into the NVIDIA Llama-3 API, and speak the response."
4. **For Biometric Lock & App Switcher Hide:** "Write a Flutter `StatefulWidget` wrapper that listens to `AppLifecycleState`. If the app is paused for more than the user's timeout setting, blur the screen with `BackdropFilter` and prompt `local_auth` biometric unlock when resumed. Also, obscure the app window when the app goes inactive to hide it in the app switcher."
5. **For Transaction Payment Flow:** "Write a Flutter UI for a Wallet with interactive glassmorphism credit cards. Then, write PostgreSQL RPCs (`top_up_wallet`, `withdraw_wallet`, `create_gig_with_payment`, `complete_gig_and_pay`) to securely deduct and transfer balances between users while logging everything to a transactions table."

### 3. The Output & Verification
*Did the AI provide working code? How did you test/verify it?*
Yes, the AI generated highly sophisticated, production-grade code:
1. **Real-Time Chat:** The AI provided the full WebSocket stream subscription logic. I verified it by opening two emulators side-by-side and watching the typing indicator appear instantly on the other screen.
2. **RPC:** The AI produced a secure `plpgsql` function. Tested by spamming the withdraw API.
3. **Voice AI Assistant:** Successfully built the `_aiHandleSend` method. Verified by voice-commanding the app to find nearby gigs.
4. **Biometric Lock & App Switcher Hide:** The AI flawlessly implemented the observer pattern. I verified it by minimizing the app on a physical device, confirming the app preview was obscured in the recent apps menu, waiting 1 minute, and confirming the biometric prompt appeared over a frosted glass overlay upon resuming.
5. **Transaction Payment Flow:** The AI generated a beautiful animated Wallet UI and secure RPCs that handle atomic database transactions. I verified it by creating a gig, ensuring the customer's wallet balance was deducted instantly, held in escrow, and successfully checking the transaction logs in Supabase.

### 4. Human Refinement
*What changes did YOU make to the AI's code to make it fit your specific project?*
1. **Real-Time Chat:** I manually wrote the Flutter UI (`ListView.builder`) to handle reverse-scrolling (bottom-up) and integrated a local state variable to immediately render the sender's message (optimistic UI) before the database confirmed it.
2. **RPC:** Mapped the UUID parameter types to match my `users` table schema.
3. **Voice AI Assistant:** Optimized the geospatial sorting algorithm (`Geolocator.distanceBetween`) so the payload wouldn't exceed API token limits by only sending the top 5 closest gigs.
4. **Biometric Lock & Hide in App Switcher:** Adjusted the `BackdropFilter` blur radiuses (`sigmaX: 30, sigmaY: 30`) to match my app's specific glassmorphism UI theme, routed the timeout values to my `SecurityData` global provider, and manually integrated the logic to obscure the app's preview in the recent apps/app switcher menu to enhance privacy.
5. **Transaction Payment Flow:** I manually linked the wallet top-up UI to the `AuthProvider` state to ensure the balance updates instantly on the screen without requiring an app reload, and refined the 3D tilt effects on the Ngam Pay card for better responsiveness.
