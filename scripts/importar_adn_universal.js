const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// CONFIGURACIÓN
const ESTADO_CODIGO = 'FL';
const ARCHIVO_DATOS = 'florida_gps_ready.json';

const serviceAccount = require(path.join(__dirname, 'llave_maestra.json'));
if (admin.apps.length === 0) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function inyeccionSeguraConGps() {
    const filePath = path.join(__dirname, '..', '..', 'LAD_DATA _FACTORY', ARCHIVO_DATOS);
    if (!fs.existsSync(filePath)) return console.error("❌ ERROR: No existe el archivo JSON con GPS.");

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

    console.log(`📡 REPARACIÓN MAESTRA: Añadiendo GPS a geodata_${ESTADO_CODIGO.toLowerCase()}...`);

    let batch = db.batch();
    let count = 0;
    let total = 0;

    for await (const line of rl) {
        if (!line.trim()) continue;
        try {
            const raw = JSON.parse(line);
            const docId = raw.id;
            const storeRef = db.collection(`geodata_${ESTADO_CODIGO.toLowerCase()}`).doc(docId);

            // USAMOS MERGE: TRUE para proteger datos existentes
            batch.set(storeRef, {
                name: (raw.name || "NEGOCIO").toUpperCase(),
                search_key: `US_${raw.zip}_${raw.num || 'SN'}_${docId}`.replace(/\s/g, ''),
                address: {
                    zip: raw.zip,
                    number: raw.num || "S/N",
                    street: raw.street || "CALLE",
                    state: ESTADO_CODIGO,
                    full: `${raw.num || ''} ${raw.street || ''}, ${raw.zip}, ${ESTADO_CODIGO}`.trim()
                },
                // EL ORO: Coordenadas GPS
                coordinates: {
                    lat: parseFloat(raw.lat),
                    lon: parseFloat(raw.lon)
                },
                category: raw.category || "COMERCIO",
                active: true,
                source: 'overture_maps_universal', // Aseguramos que el origen se mantenga
                last_updated: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true }); // <--- ESTO ES LO QUE PROTEGE TU BASE DE DATOS

            count++;
            total++;

            if (count === 500) {
                await batch.commit();
                process.stdout.write(`🛰️ GPS Sincronizado: ${total} locales...\r`);
                batch = db.batch();
                count = 0;
            }
        } catch (e) {
            // Error en línea individual, saltar para no detener el proceso masivo
        }
    }

    if (count > 0) await batch.commit();
    console.log(`\n\n🏁 VERIFICACIÓN FINALIZADA:`);
    console.log(`✅ ${total} locales ahora tienen coordenadas y ADN blindado.`);
}

inyeccionSeguraConGps().catch(console.error);