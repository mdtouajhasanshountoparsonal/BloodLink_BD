const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// নতুন রক্তের রিকোয়েস্ট তৈরি হলে matching blood group টপিক-এ পুশ notification
exports.onNewRequest = onDocumentCreated("requests/{requestId}", async (event) => {
  const r = event.data.data();
  const topic = `blood_${r.bloodGroup}`;
  const message = {
    notification: {
      title: "🚨 রক্তের রিকোয়েস্ট",
      body: `${r.bloodGroup} রক্ত প্রয়োজন — ${r.patientName} (${r.hospital})`,
    },
    topic,
  };

  try {
    await getMessaging().send(message);
  } catch (err) {
    console.error("FCM send failed:", err);
  }
});