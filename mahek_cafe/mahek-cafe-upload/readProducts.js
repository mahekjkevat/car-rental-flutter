const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function readProducts() {
  const snapshot = await db.collection("products").get();
  snapshot.forEach(doc => {
    console.log("🛍️", doc.id, "=>", doc.data());
  });
}

readProducts();
