const WebSocket = require('ws');
const http = require('http');
const url = require('url');

const server = http.createServer();
const wss = new WebSocket.Server({ server });

// 🛡️ BÚNKER DE RADIO LAD: Diccionario de usuarios conectados
const clients = new Map();

wss.on('connection', (ws, req) => {
    const parameters = url.parse(req.url, true).query;
    const userId = parameters.userId;

    if (!userId) {
        ws.close();
        return;
    }

    console.log(`📡 Radio LAD: Usuario ${userId} sintonizado y al escucha.`);

    // Guardar el socket del usuario
    clients.set(userId, ws);
    ws.userId = userId;

    ws.on('message', (data) => {
        // 🎙️ PROTOCOLO DE RETRANSMISIÓN (P2P RELAY)
        // El primer mensaje o la metadata debe indicar el destinatario.
        // Por ahora, para simplificar y asegurar el éxito hoy,
        // retransmitimos a TODOS los demás.

        wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(data);
            }
        });
    });

    ws.on('close', () => {
        console.log(`🔌 Radio LAD: Usuario ${userId} fuera del aire.`);
        clients.delete(userId);
    });

    ws.on('error', (error) => {
        console.error(`❌ Error en Radio LAD para ${userId}:`, error);
    });
});

const PORT = process.env.PORT || 10000;
server.listen(PORT, () => {
    console.log(`🚀 Repetidor de Radio LAD operando en puerto ${PORT}`);
});
