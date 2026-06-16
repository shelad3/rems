/**
 * Dump all Firestore collections to JSON files for debugging.
 *
 * Run: GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node dump_firestore.js
 *
 * To get a service account key:
 *   1. Go to https://console.firebase.google.com/project/rems-dae41/settings/serviceaccounts/adminsdk
 *   2. Click "Generate new private key"
 *   3. Save the JSON file
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

async function main() {
  const app = admin.initializeApp({ projectId: 'rems-dae41' });
  const db = app.firestore();

  const outDir = path.join(__dirname, 'firestore_dump');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

  const collections = [
    'users',
    'owners',
    'properties',
    'units',
    'tenants',
    'leases',
    'payments',
    'maintenance',
    'applications',
    'documents',
    'inspections',
    'vendors',
    'expenses',
    'communications',
    'tasks',
  ];

  for (const name of collections) {
    try {
      const snap = await db.collection(name).get();
      const docs = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));
      const filePath = path.join(outDir, `${name}.json`);
      fs.writeFileSync(filePath, JSON.stringify(docs, null, 2));
      console.log(`✓ ${name}: ${docs.length} docs → ${filePath}`);
    } catch (e) {
      console.error(`✗ ${name}: ${e.message}`);
    }
  }

  console.log('\nDone. Files in:', outDir);
}

main().catch(console.error);
