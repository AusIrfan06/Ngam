import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.6";
import { initializeApp, cert } from "npm:firebase-admin/app";
import { getMessaging } from "npm:firebase-admin/messaging";

// 1. Initialize Firebase Admin
// You will store the contents of your google-services.json in a Supabase secret named FIREBASE_SERVICE_ACCOUNT
const firebaseServiceAccount = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}"
);

// Prevent re-initialization if the function is warm
try {
  initializeApp({
    credential: cert(firebaseServiceAccount),
  });
} catch (e) {
  // Already initialized
}

// 2. Initialize Supabase Client to query user tokens
const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const supabase = createClient(supabaseUrl, supabaseKey);

serve(async (req: Request) => {
  try {
    // 3. Parse the Webhook Payload
    const payload = await req.json();
    console.log("Webhook received:", payload);

    const record = payload.record;
    let targetUserId = null;
    let title = "Ngam Update";
    let body = "You have a new notification!";
    let payloadData: Record<string, string> = {};

    // --- LOGIC FOR STATUS UPDATES ---
    if (payload.table === "status_logs" && payload.type === "INSERT") {
      const gigId = record.gig_id;
      const status = record.status;

      // Fetch the Gig to know who the customer and runner are
      const { data: gig } = await supabase
        .from("gigs")
        .select("customer_id, gig_worker_id, title")
        .eq("id", gigId)
        .single();

      if (gig) {
        if (status === "LOCKED" || status === "IN_PROGRESS" || status === "COMPLETED") {
          // Runner took action -> Notify Customer
          targetUserId = gig.customer_id;
          title = `Task Update: ${gig.title}`;
          body = `Your task status is now: ${status}`;
          payloadData = { type: "gig_update", gig_id: gigId };
        } else if (status === "CANCELLED") {
          // If cancelled, notify the runner (if assigned)
          targetUserId = gig.gig_worker_id;
          title = `Task Cancelled`;
          body = `The task '${gig.title}' has been cancelled.`;
          payloadData = { type: "gig_update", gig_id: gigId };
        }
      }
    }

    // --- LOGIC FOR CHAT MESSAGES ---
    if (payload.table === "messages" && payload.type === "INSERT") {
      const senderId = record.sender_id;
      const conversationId = record.conversation_id;
      const content = record.content;

      // Find the other user in the conversation
      const { data: conv } = await supabase
        .from("conversations")
        .select("user1_id, user2_id")
        .eq("id", conversationId)
        .single();

      if (conv) {
        targetUserId = conv.user1_id === senderId ? conv.user2_id : conv.user1_id;
        
        // Fetch the sender's name to display in the notification title
        const { data: sender } = await supabase
          .from("users")
          .select("name")
          .eq("id", senderId)
          .single();
          
        const senderName = sender?.name || "Someone";

        // Fetch the last 4 messages in this conversation
        const { data: recentMessages } = await supabase
          .from("messages")
          .select("content, image_url, sender_id")
          .eq("conversation_id", conversationId)
          .order("created_at", { ascending: false })
          .limit(4);

        let bodyText = content;
        if (recentMessages && recentMessages.length > 0) {
          // Reverse to show chronological order
          const chronological = recentMessages.reverse();
          const lines = chronological
            .filter((msg: any) => !msg.content.startsWith("__SYSTEM__Context:"))
            .map((msg: any) => {
            let txt = msg.image_url ? "📷 Photo" : msg.content;
            
            if (txt.startsWith("__SYSTEM__:")) {
              txt = txt.replace("__SYSTEM__:", "");
            } else if (txt.startsWith("__TASK_CARD__:")) {
              txt = "Sent a Task Card";
            } else if (txt.startsWith("__QUOTE__:")) {
              txt = "Sent a Custom Quote";
            } else if (txt.startsWith("__COUNTER__:")) {
              txt = "Sent a Counter-Offer";
            } else if (txt === "__REQUEST_LOC__") {
              txt = "Requested your Location";
            }
            
            return msg.sender_id === senderId ? txt : `You: ${txt}`;
          });
          bodyText = lines.join("\n");
        }

        title = senderName;
        body = bodyText;
        payloadData = { type: "chat_message", conversation_id: conversationId };
      }
    }

    // 4. Send the Push Notification
    if (targetUserId) {
      // Get the target user's FCM token
      const { data: user } = await supabase
        .from("users")
        .select("fcm_token")
        .eq("id", targetUserId)
        .single();

      if (user && user.fcm_token) {
        const message = {
          notification: {
            title: title,
            body: body,
          },
          android: {
            notification: {
              tag: payloadData.conversation_id || payloadData.gig_id || "ngam_update",
              sound: "default",
              defaultVibrateTimings: true,
              defaultSound: true,
              icon: "notification",
            }
          },
          data: payloadData,
          token: user.fcm_token,
        };

        const response = await getMessaging().send(message);
        console.log("Successfully sent message:", response);
        return new Response(JSON.stringify({ success: true, response }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      } else {
        console.log("User does not have an FCM token.");
        return new Response(JSON.stringify({ error: "No FCM token for user" }), {
          headers: { "Content-Type": "application/json" },
          status: 400,
        });
      }
    }

    return new Response(JSON.stringify({ message: "No notification sent" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error processing webhook:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
