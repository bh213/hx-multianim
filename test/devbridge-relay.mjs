// A stand-in relay for a browser game's DevBridge (WebSocketTransport), with no dependencies:
// accepts the game's socket, runs test/devbridge-checks.js against it, prints the report.
//
//   node test/devbridge-relay.mjs [--port 9010] [--token abc] [--once]
//
// then open the game with ?devbridge=ws://127.0.0.1:9010 (and &token=abc). It checks every game
// that connects (and again when one reconnects); --once exits after the first, with status 1 on a
// failed check. See test/devbridge-page.md.

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import http from "node:http";

const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : fallback;
};
const port = Number(arg("--port", "9010"));
const token = arg("--token", null);
const once = process.argv.includes("--once");
const log = (msg) => console.log(`${new Date().toISOString().slice(11, 23)} ${msg}`);
const checks = (0, eval)(readFileSync(new URL("./devbridge-checks.js", import.meta.url), "utf8"));

const server = http.createServer((_, res) => res.writeHead(426).end("WebSocket only"));
server.on("upgrade", (req, socket) => {
  const accept = createHash("sha1").update(req.headers["sec-websocket-key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").digest("base64");
  socket.write(`HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${accept}\r\n\r\n`);
  const game = { pending: new Map(), nextId: 1, hello: null };
  const send = (obj, opcode = 1) => socket.write(frame(Buffer.from(typeof obj === "string" ? obj : JSON.stringify(obj)), opcode));
  game.call = (method, params) =>
    new Promise((resolve) => {
      const id = game.nextId++;
      const timer = setTimeout(() => (game.pending.delete(id), resolve({ ok: false, code: "timeout", error: `${method} timed out` })), 10000);
      game.pending.set(id, (reply) => (clearTimeout(timer), resolve(reply)));
      send({ kind: "call", id, method, params });
    });
  readFrames(socket, send, async (text) => {
    const msg = JSON.parse(text);
    if (!game.hello) {
      if (msg.kind !== "hello" || (token && msg.token !== token)) return socket.end(frame(closePayload(4401, "token"), 8));
      game.hello = msg;
      send({ kind: "welcome", protocol: 1, instance: "web-1" });
      log(`hello: ${msg.app} "${msg.title}" session ${msg.session} ${msg.url}`);
      const result = await checks((method, params) => game.call(method, params), null);
      log(`checks: ${result.passed.length} passed, ${result.failed.length} failed`);
      for (const f of result.failed) log(`  FAIL ${f.check}: ${JSON.stringify(f.detail)}`);
      log(`details: ${JSON.stringify(result.details)}`);
      if (once) process.exit(result.failed.length === 0 ? 0 : 1);
    } else if (msg.kind === "result") game.pending.get(msg.id)?.({ ...msg, kind: undefined, id: undefined });
    else if (msg.kind === "event" && msg.event !== "trace") log(`event #${msg.seq} ${msg.event}`);
  });
  socket.on("close", () => log(`closed: ${game.hello ? game.hello.session : "before hello"}`));
  socket.on("error", () => {});
});
server.listen(port, "127.0.0.1", () => log(`relay listening on ws://127.0.0.1:${port}`));

function frame(payload, opcode) {
  const n = payload.length;
  const head = n < 126 ? Buffer.from([0x80 | opcode, n]) : n < 65536 ? Buffer.alloc(4) : Buffer.alloc(10);
  if (n >= 126 && n < 65536) head.writeUInt8(0x80 | opcode, 0), head.writeUInt8(126, 1), head.writeUInt16BE(n, 2);
  if (n >= 65536) head.writeUInt8(0x80 | opcode, 0), head.writeUInt8(127, 1), head.writeBigUInt64BE(BigInt(n), 2);
  return Buffer.concat([head, payload]);
}

function closePayload(code, reason) {
  const b = Buffer.alloc(2 + Buffer.byteLength(reason));
  b.writeUInt16BE(code, 0);
  b.write(reason, 2);
  return b;
}

// Client frames are masked; a message may span continuation frames.
function readFrames(socket, send, onText) {
  let buf = Buffer.alloc(0);
  let parts = [];
  socket.on("data", (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    for (;;) {
      if (buf.length < 2) return;
      const fin = buf[0] & 0x80, opcode = buf[0] & 0x0f, masked = buf[1] & 0x80;
      let len = buf[1] & 0x7f, off = 2;
      if (len === 126) (len = buf.length >= 4 ? buf.readUInt16BE(2) : -1), (off = 4);
      else if (len === 127) (len = buf.length >= 10 ? Number(buf.readBigUInt64BE(2)) : -1), (off = 10);
      if (len < 0 || buf.length < off + (masked ? 4 : 0) + len) return;
      const mask = masked ? buf.subarray(off, off + 4) : null;
      off += masked ? 4 : 0;
      const data = Buffer.from(buf.subarray(off, off + len));
      if (mask) for (let i = 0; i < data.length; i++) data[i] ^= mask[i & 3];
      buf = buf.subarray(off + len);
      if (opcode === 8) return socket.end(frame(Buffer.alloc(0), 8));
      if (opcode === 9) send(data.toString(), 10);
      if (opcode === 1 || opcode === 0) {
        parts.push(data);
        if (fin) void onText(Buffer.concat(parts).toString("utf8")), (parts = []);
      }
    }
  });
}
