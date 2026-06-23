const WebSocket = require('ws');
const http = require('http');
const url = require('url');

const server = http.createServer();
const wss = new WebSocket.Server({ server });

// 🛡️ BÚNKER DE RADIO LAD: Diccionario de salas por OrderID
const rooms = new Map();

wss.on('connection', (ws, req) => {
    const parameters = url.parse(req.url, true).query;
    const orderId = parameters.orderId;
    const userId = parameters.userId;

    if (!orderId || !userId) {
        ws.close();
        return;
    }

    console.log(`📡 Usuario ${userId} sintonizando frecuencia: ${orderId}`);

    // Unirse a la sala
    if (!rooms.has(orderId)) {
        rooms.set(orderId, new Set());
    }
    const room = rooms.get(orderId);
    room.add(ws);

    // Guardar metadata en el socket
    ws.orderId = orderId;
    ws.userId = userId;

    ws.on('message', (message) => {
        // 🎙️ RETRANSMISIÓN SOBERANA: Reenviar el audio a todos en la sala EXCEPTO al que habla
        const targetRoom = rooms.get(ws.orderId);
        if (targetRoom) {
            targetRoom.forEach((client) => {
                if (client !== ws && client.readyState === WebSocket.OPEN) {
                    client.send(message);
                }
            });
        }
    });

    ws.on('close', () => {
        console.log(`🔌 Usuario ${userId} fuera del aire.`);
        const targetRoom = rooms.get(ws.orderId);
        if (targetRoom) {
            targetRoom.delete(ws);
            if (targetRoom.size === 0) {
                rooms.delete(ws.orderId);
            }
        }
    });

    ws.on('error', (error) => {
        console.error(`❌ Error en frecuencia ${ws.orderId}:`, error);
    });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
    console.log(`🚀 Servidor de Radio LAD operando en puerto ${PORT}`);
});
