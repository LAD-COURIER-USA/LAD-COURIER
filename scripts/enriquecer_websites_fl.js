const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');

// --- CONFIGURACIÓN ---
const ESTADO_CODIGO = 'fl';
const COLECCION = `geodata_us_${ESTADO_CODIGO}`;
const ARCHIVO_CSV = path.join(__dirname, 'data', 'geodata-FL-final.csv');
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');

// Inicializar Firebase
if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function actualizarWebsites() {
    console.log(`🚀 INICIANDO ENRIQUECIMIENTO DE WEBSITES EN ${COLECCION}...`);

    if (!fs.existsSync(ARCHIVO_CSV)) {
        console.error("❌ ERROR: No se encontró el archivo CSV en " + ARCHIVO_CSV);
        return;
    }

    let batch = db.batch();
    let count = 0;
    let totalActualizados = 0;
    let totalLeidos = 0;

    // Leemos el CSV generado por convert_fl.py
    const stream = fs.createReadStream(ARCHIVO_CSV).pipe(csv());

    for await (const row of stream) {
        totalLeidos++;
        const placeId = row.place_id;
        const websitesStr = row.websites;

        // Solo procesamos si hay un ID y si la columna websites no está vacía
        if (placeId && websitesStr && websitesStr !== '[]' && websitesStr !== '') {
            try {
                // Limpieza del formato Overture: ["url1", "url2"]
                let website = "";
                const cleanStr = websitesStr.replace(/[\[\]"]/g, '').replace(/'/g, '');
                const links = cleanStr.split(',').map(s => s.trim());

                if (links.length > 0 && links[0].startsWith('http')) {
                    website = links[0];
                }

                if (website) {
                    const docRef = db.collection(COLECCION).doc(placeId);

                    // 🛡️ ACTUALIZACIÓN SEGURA: set(..., {merge: true})
                    batch.set(docRef, {
                        website: website,
                        last_enriched_at: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });

                    count++;
                    totalActualizados++;

                    if (count === 400) {
                        await batch.commit();
                        process.stdout.write(`🌐 Websites Inyectados: ${totalActualizados}...\r`);
                        batch = db.batch();
                        count = 0;
                    }
                }
            } catch (e) {
                // Error silencioso
            }
        }
    }

    if (count > 0) await batch.commit();
    console.log(`\n\n🏁 PROCESO FINALIZADO:`);
    console.log(`📊 Registros analizados: ${totalLeidos}`);
    console.log(`✅ Locales enriquecidos con Website: ${totalActualizados}`);
}

actualizarWebsites().catch(console.error);
