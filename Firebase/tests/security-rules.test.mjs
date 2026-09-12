import { after, before, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp, runTransaction } from 'firebase/firestore';
import { ref, uploadBytes, getBytes } from 'firebase/storage';
import assert from 'node:assert/strict';

let environment;
const logID = 'a'.repeat(64);
const path = `users/alice/pregnancyLogs/${logID}`;
const log = () => ({
  schemaVersion: 1, id: logID, origin: 'ultrasound', sourceID: 'photo.jpg',
  weekNumber: 8, isDeleted: false, updatedAt: serverTimestamp(),
});
const user = (uid = 'alice', provider = 'password') => environment.authenticatedContext(uid, {
  firebase: { sign_in_provider: provider },
});
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-babyloading-backup',
    firestore: { rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: await readFile(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => { await environment.clearFirestore(); await environment.clearStorage(); });
after(async () => { if (environment) await environment.cleanup(); });

test('only a permanent owner can create and read a log', async () => {
  await assertSucceeds(setDoc(doc(user().firestore(), path), log()));
  await assertSucceeds(getDoc(doc(user().firestore(), path)));
  for (const context of [user('bob'), user('alice', 'anonymous'), environment.unauthenticatedContext()]) {
    await assertFails(getDoc(doc(context.firestore(), path)));
    await assertFails(setDoc(doc(context.firestore(), path), log()));
  }
});
test('local-only fields, invalid schemas and malformed values are rejected', async () => {
  const reference = doc(user().firestore(), path);
  for (const addition of [
    { localImagePath: '/private/photo' }, { syncStatus: 'uploading' }, { schemaVersion: 2 },
    { weekNumber: '8' }, { weekNumber: -1 }, { origin: 'unknown' }, { notes: 5 }, { id: 'wrong' },
  ]) await assertFails(setDoc(reference, { ...log(), ...addition }));
});
test('a tombstone is permanent and identity cannot change', async () => {
  const reference = doc(user().firestore(), path);
  await setDoc(reference, log());
  await assertFails(updateDoc(reference, { sourceID: 'different.jpg', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(reference, { isDeleted: true, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { isDeleted: false, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { notes: 'late edit', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(reference));
});
test('settings preserve civil date shape and permitted cadence', async () => {
  const reference = doc(user().firestore(), 'users/alice/settings/pregnancy');
  await assertSucceeds(setDoc(reference, {
    schemaVersion: 1, lastPeriodDay: '2026-03-29', cadenceDays: 14, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, { cadenceDays: 3, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { lastPeriodDay: 'yesterday', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(user('bob').firestore(), reference.path)));
});
test('a transaction receipt prevents replay from overwriting a newer field', async () => {
  const database = user().firestore();
  const reference = doc(database, path);
  const receipt = doc(database, 'users/alice/mutations/operation-1');
  await setDoc(reference, log());
  const apply = () => runTransaction(database, async transaction => {
    if ((await transaction.get(receipt)).exists()) return;
    await transaction.get(reference);
    transaction.update(reference, { notes: 'first', updatedAt: serverTimestamp() });
    transaction.set(receipt, { schemaVersion: 1, documentPath: `pregnancyLogs/${logID}`, appliedAt: serverTimestamp() });
  });
  await apply();
  await updateDoc(reference, { notes: 'newer', updatedAt: serverTimestamp() });
  await apply();
  assert.equal((await getDoc(reference)).data().notes, 'newer');
  await assertFails(deleteDoc(receipt));
  await assertFails(updateDoc(receipt, { appliedAt: serverTimestamp() }));
});
test('storage requires a permanent owner, a live document and JPEG metadata', async () => {
  const objectPath = `users/alice/photos/${logID}.jpg`;
  const bytes = new Uint8Array([255, 216, 255, 217]);
  await assertFails(uploadBytes(ref(user().storage(), objectPath), bytes, { contentType: 'image/jpeg' }));
  await setDoc(doc(user().firestore(), path), log());
  await assertSucceeds(uploadBytes(ref(user().storage(), objectPath), bytes, { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(ref(user().storage(), objectPath), bytes, { contentType: 'image/png' }));
  for (const context of [user('bob'), user('alice', 'anonymous')]) {
    await assertFails(uploadBytes(ref(context.storage(), objectPath), bytes, { contentType: 'image/jpeg' }));
    await assertFails(getBytes(ref(context.storage(), objectPath)));
  }
  await updateDoc(doc(user().firestore(), path), { isDeleted: true, updatedAt: serverTimestamp() });
  await assertFails(uploadBytes(ref(user().storage(), objectPath), bytes, { contentType: 'image/jpeg' }));
});
