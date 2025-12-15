const admin = require("firebase-admin");
const fs = require("fs");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const products = JSON.parse(fs.readFileSync("products.json", "utf8"));

async function uploadProducts() {
  for (const product of products) {
    await db.collection("products").add(product);
    console.log(`Uploaded: ${product.name}`);
  }
  console.log("✅ All products uploaded!");
}

uploadProducts();
