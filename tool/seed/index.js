#!/usr/bin/env node
'use strict';

// Seed script for the dev Firebase project.
//
//   GOOGLE_APPLICATION_CREDENTIALS=tool/seed/service-account.json node tool/seed
//   node tool/seed --dry-run
//
// What it writes (all schema contract — see lib/core/entities/doctor.dart
// and lib/core/entities/time_slot.dart):
//   doctors/<stable id>                     8 sample doctors
//   slots/<doctorId>__<start ISO no colons> hourly Mon–Sat slots, next 14 days
//   storage: doctor-photos/<doctor-id>.png  generated avatars (or real photos
//                                           dropped into tool/seed/data/images/)
//
// Idempotency: every document uses a deterministic id + set(), so re-running
// overwrites in place and never creates duplicates.
//
// WARNING: re-seeding resets every slot's isBooked to false — it silently
// wipes test bookings in the dev project.

const admin = require('firebase-admin');
const fs = require('fs');
const os = require('os');
const path = require('path');
const doctors = require('./data/doctors');
const { generateDoctorPhoto, readOverridePhoto } = require('./images');

const DRY_RUN = process.argv.includes('--dry-run');

// --- config ---------------------------------------------------------------

function readProjectId() {
  const env = process.env.FIREBASE_PROJECT_ID;
  if (env) return env;
  const rcPath = path.join(__dirname, '..', '..', '.firebaserc');
  try {
    const rc = JSON.parse(fs.readFileSync(rcPath, 'utf8'));
    const id = rc.projects && rc.projects.default;
    if (id) return id;
  } catch {
    // fall through to the error below
  }
  throw new Error(
    'Could not determine the Firebase project id. Set FIREBASE_PROJECT_ID or ensure .firebaserc has a default project.',
  );
}

const PROJECT_ID = readProjectId();
const STORAGE_BUCKET =
  process.env.FIREBASE_STORAGE_BUCKET || `${PROJECT_ID}.firebasestorage.app`;

/// Locates the service-account key: explicit env var, then the two obvious
/// project paths, then the standard `*-firebase-adminsdk-*.json` filename in
/// Downloads. Returns null when nothing is found (the seed then fails with
/// a clear message instead of a raw ENOENT).
function resolveCredentialsPath() {
  const candidates = [
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.join(__dirname, 'service-account.json'),
    path.join(__dirname, '..', '..', 'service-account.json'),
  ];
  for (const c of candidates) {
    if (c && fs.existsSync(c)) return c;
  }
  const downloads = path.join(os.homedir(), 'Downloads');
  try {
    for (const f of fs.readdirSync(downloads)) {
      if (f.includes('firebase-adminsdk') && f.endsWith('.json')) {
        return path.join(downloads, f);
      }
    }
  } catch {
    // Downloads unreadable — fall through to the helpful error.
  }
  return null;
}

// --- slot generation --------------------------------------------------------

const SLOT_DAYS = 14;
const OPEN_HOUR = 9;
const CLOSE_HOUR = 17;

/// Hourly slots from [from] (default now) for the next SLOT_DAYS days,
/// Monday–Saturday. Times are real instants in the machine's local zone and
/// stored as UTC Timestamps — the app maps them back to device-local time.
function buildSlots(doctorId, from) {
  const slots = [];
  const today = new Date(from);
  today.setHours(0, 0, 0, 0);
  for (let day = 0; day < SLOT_DAYS; day++) {
    const date = new Date(today);
    date.setDate(today.getDate() + day);
    if (date.getDay() === 0) continue; // closed Sundays (getDay 0 = Sunday)
    for (let hour = OPEN_HOUR; hour < CLOSE_HOUR; hour++) {
      const start = new Date(date);
      start.setHours(hour, 0, 0, 0);
      const end = new Date(start);
      end.setHours(hour + 1, 0, 0, 0);
      // Firestore document ids cannot contain ':' — strip them from the ISO
      // timestamp. Deterministic per (doctor, start) → idempotent set().
      const id = `${doctorId}__${start.toISOString().replace(/[:.]/g, '-')}`;
      slots.push({ id, doctorId, startTime: start, endTime: end, isBooked: false });
    }
  }
  return slots;
}

// --- the seed ---------------------------------------------------------------

async function run() {
  const allSlots = doctors.flatMap((d) => buildSlots(d.id, new Date()));

  if (DRY_RUN) {
    console.log(`[dry-run] Project:            ${PROJECT_ID}`);
    console.log(`[dry-run] Storage bucket:     ${STORAGE_BUCKET}`);
    console.log(`[dry-run] Doctors:            ${doctors.length}`);
    console.log(
      `[dry-run] Slots:               ${allSlots.length} ` +
        `(${SLOT_DAYS} days, Mon–Sat, ${OPEN_HOUR}:00–${CLOSE_HOUR}:00)`,
    );
    console.log(
      `[dry-run] Images:              ${doctors.length} → doctor-photos/<doctor-id>.png`,
    );
    console.log('[dry-run] No writes performed.');
    return;
  }

  const credentialsPath = resolveCredentialsPath();
  if (!credentialsPath) {
    throw new Error(
      'Service account key not found. Generate one at Firebase console → ' +
        'Project settings → Service accounts → Generate new private key, and ' +
        'save it as tool/seed/service-account.json (or drop the ' +
        '*-firebase-adminsdk-*.json in Downloads / set GOOGLE_APPLICATION_CREDENTIALS).',
    );
  }
  process.env.GOOGLE_APPLICATION_CREDENTIALS = credentialsPath;
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    storageBucket: STORAGE_BUCKET,
  });
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  console.log(`Seeding project ${PROJECT_ID} (bucket: ${STORAGE_BUCKET})…`);

  // 1. Upload photos first so the doctors get stable download URLs. Real
  //    photos in data/images/<id>.png win over generated avatars.
  //    If the storage bucket doesn't exist yet (project without billing /
  //    Storage not provisioned), degrade to an empty photoUrl — the app
  //    falls back to initials avatars — and warn so a later re-run after
  //    provisioning upgrades the photos (idempotent set()).
  const uploads = [];
  let photosUploaded = 0;
  for (const doctor of doctors) {
    try {
      const photo = readOverridePhoto(doctor.id) ?? generateDoctorPhoto(doctor.id);
      const objectPath = `doctor-photos/${doctor.id}.png`;
      await bucket.file(objectPath).save(photo, {
        contentType: 'image/png',
        metadata: { cacheControl: 'public, max-age=86400' },
      });
      const url =
        `https://firebasestorage.googleapis.com/v0/b/${STORAGE_BUCKET}/o/` +
        `${encodeURIComponent(objectPath)}?alt=media`;
      uploads.push({ doctor, url });
      photosUploaded++;
    } catch (error) {
      const msg = String(error && error.message ? error.message : error);
      if (msg.includes('bucket does not exist')) {
        console.warn(
          `  ⚠ storage bucket ${STORAGE_BUCKET} not available; ` +
            `${doctor.id} photoUrl left empty (app shows initials). ` +
            `Provision Storage (console → Storage → Get started), then re-run.`,
        );
        uploads.push({ doctor, url: '' });
      } else {
        throw error;
      }
    }
  }
  console.log(`  ✓ uploaded ${photosUploaded}/${uploads.length} doctor photos`);

  // 2. Doctors — one document per stable id (set = overwrite in place).
  await Promise.all(
    uploads.map(({ doctor, url }) =>
      db.collection('doctors').doc(doctor.id).set({
        name: doctor.name,
        specialty: doctor.specialty,
        rating: doctor.rating,
        clinicAddress: doctor.clinicAddress,
        bio: doctor.bio,
        photoUrl: url,
      }),
    ),
  );
  console.log(`  ✓ wrote ${doctors.length} doctors`);

  // 3. Slots — batched (Firestore allows ≤500 writes per commit).
  for (let i = 0; i < allSlots.length; i += 450) {
    const batch = db.batch();
    for (const slot of allSlots.slice(i, i + 450)) {
      batch.set(db.collection('slots').doc(slot.id), {
        doctorId: slot.doctorId,
        startTime: admin.firestore.Timestamp.fromDate(slot.startTime),
        endTime: admin.firestore.Timestamp.fromDate(slot.endTime),
        isBooked: slot.isBooked,
      });
    }
    await batch.commit();
  }
  console.log(`  ✓ wrote ${allSlots.length} slots`);

  console.log(`Done. Doctors: ${doctors.length} · Slots: ${allSlots.length} · Images: ${photosUploaded}/${uploads.length}`);
  console.log(
    'Note: re-seeding resets every slot to isBooked=false, wiping any test bookings.',
  );
}

run().catch((error) => {
  console.error('Seed failed:', error);
  process.exitCode = 1;
});
