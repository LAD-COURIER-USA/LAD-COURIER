const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');

// --- CONFIGURACIÓN ESTRATÉGICA LAD ---
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

async function enriquecerFlorida() {
    console.log(`🚀 INICIANDO ENRIQUECIMIENTO MASIVO (WEB + TELÉFONO) EN ${COLECCION}...`);

    if (!fs.existsSync(ARCHIVO_CSV)) {
        console.error("❌ ERROR: No se encontró el archivo CSV en " + ARCHIVO_CSV);
        return;
    }

    let batch = db.batch();
    let count = 0;
    let totalActualizados = 0;
    let totalLeidos = 0;

    const stream = fs.createReadStream(ARCHIVO_CSV).pipe(csv());

    for await (const row of stream) {
        totalLeidos++;
        const placeId = row.place_id;
        const websitesRaw = row.websites;
        const phonesRaw = row.phones;

        if (placeId) {
            let updateData = {};

            // 🌐 1. PROCESAR WEBSITE
            if (websitesRaw && websitesRaw !== '[]' && websitesRaw !== '') {
                const cleanWeb = websitesRaw.replace(/[\[\]"']/g, '').split(',')[0].trim();
                if (cleanWeb.startsWith('http')) {
                    updateData.website = cleanWeb;
                }
            }

            // 📞 2. PROCESAR TELÉFONO
            if (phonesRaw && phonesRaw !== '[]' && phonesRaw !== '') {
                const cleanPhone = phonesRaw.replace(/[\[\]"']/g, '').split(',')[0].trim();
                if (cleanPhone.length > 5) {
                    updateData.phone = cleanPhone;
                }
            }

            // ⚡ 3. INYECTAR SI HAY DATOS NUEVOS
            if (Object.keys(updateData).length > 0) {
                const docRef = db.collection(COLECCION).doc(placeId);

                // 🛡️ SEGURIDAD LAD: set(..., {merge: true}) asegura no borrar el ADN ni GPS
                batch.set(docRef, {
                    ...updateData,
                    last_enriched_at: admin.firestore.FieldValue.serverTimestamp(),
                    source_enrichment: 'overture_v2_shopper_ready'
                }, { merge: true });

                count++;
                totalActualizados++;

                if (count === 400) {
                    await batch.commit();
                    process.stdout.write(`📡 Locales Enriquecidos: ${totalActualizados}...\r`);
                    batch = db.batch();
                    count = 0;
                }
            }
        }
    }

    if (count > 0) await batch.commit();
    console.log(`\n\n🏁 PROCESO FINALIZADO:`);
    console.log(`📊 Registros leídos: ${totalLeidos}`);
    console.log(`✅ Locales blindados con Web/Tel: ${totalActualizados}`);
    console.log(`🏆 LAD Smart Shopper tiene ahora el 100% de la potencia disponible.`);
}

enriquecerFlorida().catch(console.error);
