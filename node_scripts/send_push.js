// node_scripts/send_push.js
// Uso: node send_push.js <endpoint> <p256dh> <auth> <vapidPublicKey> <vapidPrivateKey> <subject> <payloadJson>

const webpush = require("web-push");

async function main() {
  const [
    endpoint,
    p256dh,
    auth,
    vapidPublicKey,
    vapidPrivateKey,
    subject,
    payloadJson
  ] = process.argv.slice(2);

  if (!endpoint || !p256dh || !auth || !vapidPublicKey || !vapidPrivateKey || !subject || !payloadJson) {
    console.error("Parâmetros insuficientes para enviar push.");
    process.exit(1);
  }

  webpush.setVapidDetails(
    subject,
    vapidPublicKey,
    vapidPrivateKey
  );

  const subscription = {
    endpoint,
    keys: { p256dh, auth }
  };

  let payload;
  try {
    payload = JSON.parse(payloadJson);
  } catch (e) {
    console.error("Payload JSON inválido:", e.message);
    process.exit(1);
  }

  try {
    await webpush.sendNotification(subscription, JSON.stringify(payload));
    console.log("OK");
  } catch (err) {
    console.error("ERROR", err.statusCode, err.body || err.message);
    process.exitCode = 1;
  }
}

main();
