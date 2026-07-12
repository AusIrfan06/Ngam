# AI Usage & Disclosure Log

**Project Component:** Real-Time WebSockets, Concurrency, Voice AI, and Biometric Security (Ngam App)
**AI Tool Used:** Antigravity IDE (Gemini)

---

### 1. The Intent
*What specific problem were you trying to solve with AI?*
I needed to solve four highly complex programming challenges in the Ngam app that would otherwise require senior-level experience:
1. **Frontend & Backend (WebSockets):** Building a full-fledged Real-Time Chat Engine (`chat_service.dart` & `chat_screen.dart`). I needed to implement Supabase `RealtimeChannel` to handle instant messaging, live typing indicators (Presence), and optimistic UI updates without crashing the app.
2. **Backend (Concurrency):** Writing a PostgreSQL Remote Procedure Call (RPC) to handle wallet withdrawals securely (`withdraw_wallet`), ensuring Row-Level Locking so rapid clicks wouldn't result in negative balances.
3. **Generative AI Integration:** Building a "Voice-Activated AI Assistant" in the Runner's Discover screen (`runner_home_screen.dart`). This assistant listens to the runner's voice, feeds nearby gigs to a Large Language Model (Llama-3 via NVIDIA API), and reads back the best-matched jobs using Text-to-Speech.
4. **Security & Hardware (Biometrics):** Implementing an app-wide security lock (`app_lock_wrapper.dart`) that detects when the app goes into the background using `WidgetsBindingObserver` and requires Fingerprint/FaceID (`local_auth`) to unlock upon resuming.

### 2. The Interaction (Prompting)
*What was your primary prompt, and did you have to refine it?*
- **For the Real-Time Chat:** "Write a Dart service using `supabase_flutter` that subscribes to database changes via `RealtimeChannel`. It needs to listen to INSERT events for new messages and use Presence to track when the other user is typing."
- **For the Database RPC:** "Write a Supabase PostgreSQL function to deduct a user's wallet balance securely. It must use `SELECT FOR UPDATE` to prevent race conditions."
- **For the Voice AI Assistant:** "Write a Dart function integrating `speech_to_text`, `flutter_tts`, and `http` requests. It must capture the runner's voice, gather the top 5 closest gigs using `Geolocator`, inject this into the NVIDIA Llama-3 API, and speak the response."
- **For Biometric Lock:** "Write a Flutter `StatefulWidget` wrapper that listens to `AppLifecycleState`. If the app is paused for more than the user's timeout setting, blur the screen with `BackdropFilter` and prompt `local_auth` biometric unlock when resumed."

### 3. The Output & Verification
*Did the AI provide working code? How did you test/verify it?*
Yes, the AI generated highly sophisticated, production-grade code:
- **Real-Time Chat:** The AI provided the full WebSocket stream subscription logic. I verified it by opening two emulators side-by-side and watching the typing indicator appear instantly on the other screen.
- **RPC:** The AI produced a secure `plpgsql` function. Tested by spamming the withdraw API.
- **Voice AI Assistant:** Successfully built the `_aiHandleSend` method. Verified by voice-commanding the app to find nearby gigs.
- **Biometric Lock:** The AI flawlessly implemented the observer pattern. I verified it by minimizing the app on a physical device, waiting 1 minute, and confirming the biometric prompt appeared over a frosted glass overlay.

### 4. Human Refinement
*What changes did YOU make to the AI's code to make it fit your specific project?*
- **Real-Time Chat:** I manually wrote the Flutter UI (`ListView.builder`) to handle reverse-scrolling (bottom-up) and integrated a local state variable to immediately render the sender's message (optimistic UI) before the database confirmed it.
- **RPC:** Mapped the UUID parameter types to match my `users` table schema.
- **Voice AI Assistant:** Optimized the geospatial sorting algorithm (`Geolocator.distanceBetween`) so the payload wouldn't exceed API token limits by only sending the top 5 closest gigs.
- **Biometric Lock:** Adjusted the `BackdropFilter` blur radiuses (`sigmaX: 30, sigmaY: 30`) to match my app's specific glassmorphism UI theme and routed the timeout values to my `SecurityData` global provider.
