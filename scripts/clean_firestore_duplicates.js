/**
 * Firestore duplicate cleanup script.
 *
 * Removes duplicate Firestore documents that were created by the old .add()
 * code path. Keeps only the document whose ID matches its oldId (the canonical
 * doc created by .doc(id).set() or syncAllFromSqlite()).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=~/rems-key.json node scripts/clean_firestore_duplicates.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Resolve firebase-admin from functions/node_modules
const functionsNodeModules = path.join(__dirname, '..', 'functions', 'node_modules');
const Module = require('module');
const origResolve = Module._resolveFilename;
Module._resolveFilename = function (request, parent) {
  if (request === 'firebase-admin') {
    return origResolve.call(this, request, { paths: [functionsNodeModules] });
  }
  return origResolve.call(this, request, parent);
};

async function main() {
  const app = admin.initializeApp({ projectId: 'rems-dae41' });
  const db = app.firestore();

  const collections = [
    { name: 'tenants',     idField: 'oldTenantId' },
    { name: 'owners',      idField: 'oldOwnerId' },
    { name: 'properties',  idField: 'oldPropertyId' },
    { name: 'units',       idField: 'oldUnitId' },
    { name: 'leases',      idField: 'oldLeaseId' },
  ];

  for (const { name, idField } of collections) {
    console.log(`\n--- ${name} ---`);
    const snap = await db.collection(name).get();
    const docs = snap.docs.map((d) => ({ id: d.id, data: d.data(), ref: d.ref }));

    // Group by oldId
    const groups = new Map();
    for (const doc of docs) {
      const oldId = doc.data[idField];
      if (oldId == null) continue;
      if (!groups.has(oldId)) groups.set(oldId, []);
      groups.get(oldId).push(doc);
    }

    let deleted = 0;
    for (const [oldId, group] of groups) {
      if (group.length <= 1) continue;

      // The canonical doc has id === oldId.toString()
      const canonical = group.find((d) => d.id === oldId.toString());
      const toDelete = group.filter((d) => d.id !== oldId.toString());

      if (!canonical) {
        // No canonical doc — pick the first one and rename it
        console.log(`  oldId=${oldId}: no canonical doc, keeping ${group[0].id}`);
        continue;
      }

      for (const d of toDelete) {
        console.log(`  oldId=${oldId}: deleting duplicate ${d.id}`);
        await d.ref.delete();
        deleted++;
      }
    }

    if (deleted === 0) console.log('  No duplicates found.');
    console.log(`  Total deleted: ${deleted}`);
  }

  console.log('\nDone.');
}

main().catch(console.error);
