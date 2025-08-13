// Simple WebSocket signaling server for WebRTC
// Usage: node server.js PORT (default 8081)
const WebSocket = require("ws");

const port = parseInt(process.argv[2], 10) || 8081;
const wss = new WebSocket.Server({ port });

/** rooms: Map<roomId, Set<ws>> */
const rooms = new Map();

function joinRoom(room, ws) {
  if (!rooms.has(room)) rooms.set(room, new Set());
  rooms.get(room).add(ws);
  ws._roomId = room;
}

function leaveRoom(ws) {
  const room = ws._roomId;
  if (!room) return;
  const set = rooms.get(room);
  if (!set) return;
  set.delete(ws);
  if (set.size === 0) rooms.delete(room);
  ws._roomId = null;
}

wss.on("connection", (ws) => {
  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch (e) {
      return;
    }
    if (msg.type === "join") {
      joinRoom(msg.room, ws);
      // informer les pairs déjà dans la room
      const peers = rooms.get(msg.room) || new Set();
      peers.forEach((client) => {
        if (client !== ws && client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify({ type: "peer-joined", room: msg.room }));
        }
      });
      return;
    }
    if (msg.type === "leave") {
      leaveRoom(ws);
      return;
    }
    const room = ws._roomId || msg.room;
    if (!room) return;
    const peers = rooms.get(room) || new Set();
    peers.forEach((client) => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(msg));
      }
    });
  });
  ws.on("close", () => {
    const room = ws._roomId;
    leaveRoom(ws);
    if (room) {
      const peers = rooms.get(room) || new Set();
      peers.forEach((client) => {
        if (client !== ws && client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify({ type: "peer-left", room }));
        }
      });
    }
  });
});

console.log(`[signaling] WebSocket server running on port ${port}`);
