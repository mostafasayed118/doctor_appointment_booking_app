// Deterministic placeholder doctor avatars — a solid tinted square with a
// lighter disc, generated with Node built-ins only (zlib), so no binary
// assets are committed and no image dependency is needed.
//
// To use real photos instead: drop files named `<doctor-id>.png` into
// tool/seed/data/images/ and the seed will upload those instead (same
// object paths), keeping photoUrl stable.

const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

// --- minimal PNG encoder ---------------------------------------------------

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function makePng(width, height, rgb) {
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // color type: truecolor
  const stride = width * 3;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter type: none
    rgb.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const idat = zlib.deflateSync(raw);
  return Buffer.concat([
    signature,
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

function hashString(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) | 0;
  }
  return h >>> 0;
}

// --- public API -------------------------------------------------------------

/// Generates a 256×256 PNG for a doctor id. Deterministic: the same id
/// always produces the same image, so re-seeding does not churn Storage.
function generateDoctorPhoto(doctorId, { size = 256 } = {}) {
  const h = hashString(doctorId);
  const base = [h & 0xff, (h >>> 8) & 0xff, (h >>> 16) & 0xff];
  const light = base.map((c) => Math.min(255, c + 60));
  const rgb = Buffer.alloc(size * size * 3);
  const cx = size / 2;
  const cy = size / 2;
  const radius = size * 0.32;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 3;
      const inDisc = (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius;
      const c = inDisc ? light : base;
      rgb[i] = c[0];
      rgb[i + 1] = c[1];
      rgb[i + 2] = c[2];
    }
  }
  return makePng(size, size, rgb);
}

/// Real photos from tool/seed/data/images/<doctor-id>.png win over
/// generated ones; returns null when no such file exists.
function readOverridePhoto(doctorId) {
  const p = path.join(__dirname, 'data', 'images', `${doctorId}.png`);
  if (!fs.existsSync(p)) return null;
  return fs.readFileSync(p);
}

module.exports = { generateDoctorPhoto, readOverridePhoto };
