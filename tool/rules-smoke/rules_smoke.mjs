#!/usr/bin/env node
// Part B rules smoke — verifies the DEPLOYED Firestore security rules
// (firestore.rules) by exercising them with real user ID tokens through the
// Firestore REST API. The rules engine runs server-side, so this is exactly
// what a client would be allowed to do — no admin-SDK bypass.
//
// Maps to the smoke-checklist matrix (B1–B9):
//   B1   catalog is public-read (doctors + slots)
//   B2   doctors are never client-writable
//   B3   slots reject any update beyond isBooked
//   B4   slots allow authenticated isBooked-only flips; deny unauthenticated
//   B5   appointments reject creation for another patient
//   B6   appointments reject a doctorId that doesn't match the slot (get() join)
//   B7   appointments allow an own, matching creation
//   B8   appointments are read-only for their owner
//   B9   appointment updates can't transfer ownership; deletes are denied
//
// The project id and web API key are read from the repo (.firebaserc and
// lib/firebase_options.dart). Credentials come from the environment so no
// password is ever committed:
//
//   RULES_SMOKE_OWNER_EMAIL / _PASSWORD        — owns the appointment under test
//   RULES_SMOKE_OWNER_APPOINTMENT_ID           — an existing appointment of the owner
//   RULES_SMOKE_ATTACKER_EMAIL / _PASSWORD     — a second user (does the denied tests)
//   RULES_SMOKE_SLOT_ID                        — an existing, ideally free, slot id
//
// Side effects (client-side only; rules forbid delete, so cleanup is manual):
//   - B4 flips RULES_SMOKE_SLOT_ID isBooked true then back to false (restored)
//   - B7 creates one appointment doc named `rules-smoke-<timestamp>` — delete
//     docs named `rules-smoke-*` from the console when you're done testing.

import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..', '..');

// --- config ---------------------------------------------------------------

function readProjectId() {
  const env = process.env.FIREBASE_PROJECT_ID;
  if (env) return env;
  const rcPath = path.join(root, '.firebaserc');
  try {
    const rc = JSON.parse(readFileSync(rcPath, 'utf8'));
    const id = rc.projects && rc.projects.default;
    if (id) return id;
  } catch {
    // fall through to the error below
  }
  throw new Error(
    'Could not determine the Firebase project id. Set FIREBASE_PROJECT_ID or ensure .firebaserc has a default project.',
  );
}

function readApiKey() {
  // The web apiKey is deliberately public (it ships in every web build);
  // parse it from the generated options so the tool follows the project config.
  const optionsPath = path.join(root, 'lib', 'firebase_options.dart');
  const src = readFileSync(optionsPath, 'utf8');
  const match = src.match(/apiKey:\s*'([^']+)'/);
  if (!match) throw new Error(`Could not find the web apiKey in ${optionsPath}.`);
  return match[1];
}

const REQUIRED_ENV = {
  RULES_SMOKE_OWNER_EMAIL: 'the appointment owner (patient A)',
  RULES_SMOKE_OWNER_PASSWORD: 'the appointment owner\'s password',
  RULES_SMOKE_OWNER_APPOINTMENT_ID: 'an existing appointment doc id owned by the owner',
  RULES_SMOKE_ATTACKER_EMAIL: 'a second user (patient B)',
  RULES_SMOKE_ATTACKER_PASSWORD: 'the second user\'s password',
  RULES_SMOKE_SLOT_ID: 'an existing slot doc id (ideally free)',
};

const missing = Object.entries(REQUIRED_ENV).filter(([name]) => !process.env[name]);
if (missing.length > 0) {
  throw new Error(
    'Missing environment variables:\n' +
      missing
        .map(([name, what]) => `  ${name} — ${what}`)
        .join('\n') +
      '\nExample:\n  RULES_SMOKE_OWNER_EMAIL=... RULES_SMOKE_OWNER_PASSWORD=... \\\n  RULES_SMOKE_OWNER_APPOINTMENT_ID=... RULES_SMOKE_ATTACKER_EMAIL=... \\\n  RULES_SMOKE_ATTACKER_PASSWORD=... RULES_SMOKE_SLOT_ID=... \\\n  node tool/rules-smoke/rules_smoke.mjs',
  );
}

const PROJECT_ID = readProjectId();
const API_KEY = readApiKey();
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const IDKIT = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';

const OWNER_EMAIL = process.env.RULES_SMOKE_OWNER_EMAIL;
const OWNER_PASSWORD = process.env.RULES_SMOKE_OWNER_PASSWORD;
const OWNER_APPOINTMENT = process.env.RULES_SMOKE_OWNER_APPOINTMENT_ID;
const ATTACKER_EMAIL = process.env.RULES_SMOKE_ATTACKER_EMAIL;
const ATTACKER_PASSWORD = process.env.RULES_SMOKE_ATTACKER_PASSWORD;
const SLOT_ID = process.env.RULES_SMOKE_SLOT_ID;
// Seed slot ids are `<doctorId>__<ISO>` — the doctor the get() join must match.
const SLOT_DOCTOR = SLOT_ID.split('__')[0];

// --- helpers --------------------------------------------------------------

async function signIn(email, password) {
  const r = await fetch(`${IDKIT}?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error(`sign-in failed for ${email}: ${JSON.stringify(j)}`);
  // identitytoolkit returns the uid as `localId`.
  return { idToken: j.idToken, uid: j.localId, email };
}

let pass = 0;
let fail = 0;
function check(name, expected, actual, detail = '') {
  const ok = actual === expected;
  console.log(
    `${ok ? 'PASS' : 'FAIL'}  ${name}: expected ${expected}, got ${actual}${detail ? ' — ' + detail : ''}`,
  );
  ok ? pass++ : fail++;
}

async function hit(method, docPath, token, body) {
  try {
    const r = await fetch(`${BASE}/${docPath}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { code: r.status };
  } catch (e) {
    return { code: 'ERR', detail: String(e) };
  }
}

const ts = (s) => ({ timestampValue: s });
const str = (s) => ({ stringValue: s });
const bool = (b) => ({ booleanValue: b });

// --- run ------------------------------------------------------------------

const owner = await signIn(OWNER_EMAIL, OWNER_PASSWORD);
const attacker = await signIn(ATTACKER_EMAIL, ATTACKER_PASSWORD);
console.log(
  `project ${PROJECT_ID} — owner ${owner.uid.slice(0, 8)}…, attacker ${attacker.uid.slice(0, 8)}…`,
);

// B1: catalog is public-read.
{
  const r = await hit('GET', `doctors/${SLOT_DOCTOR}`, null);
  check('B1  read doctors (no auth)', 200, r.code);
  const r2 = await hit('GET', `slots/${SLOT_ID}`, null);
  check('B1b read slots (no auth)', 200, r2.code);
}

// B2: doctors are never client-writable.
{
  const r = await hit('POST', `doctors?documentId=rules-smoke`, attacker.idToken, {
    fields: { name: str('Hacker') },
  });
  check('B2  create doctors/rules-smoke (authed)', 403, r.code);
}

// B3/B4: slots allow ONLY authenticated isBooked flips.
{
  const r = await hit(
    'PATCH',
    `slots/${SLOT_ID}?updateMask.fieldPaths=startTime`,
    attacker.idToken,
    { fields: { startTime: ts('2030-01-01T09:00:00.000Z') } },
  );
  check('B3  update slots changing startTime', 403, r.code);

  const r4a = await hit(
    'PATCH',
    `slots/${SLOT_ID}?updateMask.fieldPaths=isBooked`,
    attacker.idToken,
    { fields: { isBooked: bool(true) } },
  );
  check('B4a update slots isBooked flip (authed)', 200, r4a.code);
  const r4b = await hit(
    'PATCH',
    `slots/${SLOT_ID}?updateMask.fieldPaths=isBooked`,
    attacker.idToken,
    { fields: { isBooked: bool(false) } },
  );
  check('B4b flip back to free (authed, state restored)', 200, r4b.code);
  const r4c = await hit(
    'PATCH',
    `slots/${SLOT_ID}?updateMask.fieldPaths=isBooked`,
    null,
    { fields: { isBooked: bool(true) } },
  );
  check('B4c isBooked flip (NO auth)', 403, r4c.code);
}

// B5/B6/B7: appointment create — own + get() join.
const apptFields = (patientId, doctorId) => ({
  fields: {
    patientId: str(patientId),
    doctorId: str(doctorId),
    status: str('scheduled'),
    slotId: str(SLOT_ID),
    startTime: ts('2030-01-01T09:00:00.000Z'),
    endTime: ts('2030-01-01T10:00:00.000Z'),
    createdAt: ts('2026-01-01T00:00:00.000Z'),
  },
});
{
  const r5 = await hit(
    'POST',
    `appointments?documentId=rules-smoke-5`,
    attacker.idToken,
    apptFields(owner.uid, SLOT_DOCTOR),
  );
  check('B5  create appointment for ANOTHER patient', 403, r5.code);

  const r6 = await hit(
    'POST',
    `appointments?documentId=rules-smoke-6`,
    attacker.idToken,
    apptFields(attacker.uid, `${SLOT_DOCTOR}-other`),
  );
  check('B6  create appointment with doctorId not matching the slot', 403, r6.code);

  const testId = `rules-smoke-${Date.now()}`;
  const r7 = await hit(
    'POST',
    `appointments?documentId=${testId}`,
    attacker.idToken,
    apptFields(attacker.uid, SLOT_DOCTOR),
  );
  check('B7  create own appointment matching the slot', 200, r7.code, `(doc ${testId})`);
}

// B8: appointments read — own only.
{
  const r8a = await hit('GET', `appointments/${OWNER_APPOINTMENT}`, attacker.idToken);
  check('B8a read owner\'s appointment as attacker', 403, r8a.code);
  const r8b = await hit('GET', `appointments/${OWNER_APPOINTMENT}`, owner.idToken);
  check('B8b read owner\'s appointment as owner', 200, r8b.code);
  const r8c = await hit('GET', `appointments/${OWNER_APPOINTMENT}`, null);
  check('B8c read owner\'s appointment (NO auth)', 403, r8c.code);
}

// B9: update/delete — ownership holds before AND after; delete never.
{
  const r9a = await hit(
    'PATCH',
    `appointments/${OWNER_APPOINTMENT}?updateMask.fieldPaths=patientId`,
    owner.idToken,
    { fields: { patientId: str(attacker.uid) } },
  );
  check('B9a update transferring patientId to attacker', 403, r9a.code);
  const r9b = await hit('DELETE', `appointments/${OWNER_APPOINTMENT}`, owner.idToken);
  check('B9b delete own appointment', 403, r9b.code);
}

console.log(`\n${pass} passed, ${fail} failed`);
console.log(
  'Note: B7 leaves one appointment doc named rules-smoke-* — delete it from the console when done.',
);
process.exit(fail === 0 ? 0 : 1);
