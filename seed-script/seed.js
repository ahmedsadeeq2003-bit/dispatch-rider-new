const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function seed() {
  const db = admin.firestore();

  const existing = await db.collection('companies').where('code', '==', 'DEFAULT').get();
  if (!existing.empty) {
    console.log('DEFAULT company already exists, skipping.');
    return;
  }

  await db.collection('companies').add({
    code: 'DEFAULT',
    name: 'Default Company',
    plan: 'free',
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('Seeded DEFAULT company successfully.');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
  });