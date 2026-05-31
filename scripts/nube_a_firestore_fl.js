const duckdb = require('duckdb');
const admin = require('firebase-admin');
const path = require('path');

// --- CONFIGURACIÓN LAD DIGITAL SYSTEMS LLC ---
const ESTADO = 'FL';
const COLECCION = `geodata_us_${ESTADO.toLowerCase()}`;
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');

// URL ACTUALIZADA Y ESTABLE DE OVERTURE (VÍA CLOUDFRONT PARA MÁXIMA VELOCIDAD)
const OVERTURE_URL = "https://data.overturemaps.org/release/2024-03-12-alpha.0/theme=places/type=place/*.parquet";

// Inicializar Firebase
if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function enriquecerDesdeLaNube() {
    console.log(`🌐 CONECTANDO CON EL CEREBRO DE OVERTURE MAPS (NUBE)...`);

    const db_memory = new duckdb.Database(':memory:');
    const con = db_memory.connect();

    // 1. Configuración de Red para DuckDB
    con.run("INSTALL httpfs; LOAD httpfs; SET s3_region='us-west-2';", (err) => {
        if (err) return console.error("❌ Error cargando extensiones:", err);

        console.log(`🔍 Escaneando Florida en la nube (esto puede tardar 1 min mientras filtra 6M de registros)...`);

        // 2. Consulta optimizada: Traemos ID, Websites y Phones
        // Filtramos por región 'FL' para no bajar datos basura
        const query = `
            SELECT
                id,
                CAST(websites AS VARCHAR) as web_list,
                CAST(phones AS VARCHAR) as phone_list
            FROM read_parquet('${OVERTURE_URL}')
            WHERE (addresses[1].region = 'US-${ESTADO}' OR addresses[1].region = '${ESTADO}')
            AND (websites IS NOT NULL OR phones IS NOT NULL)
            LIMIT 15000
        `;

        con.all(query, async (err, rows) => {
            if (err) {
                console.error("❌ Error en consulta Overture:");
                console.error(err);
                return;
            }

            if (!rows || rows.length === 0) {
                console.log("⚠️ No se encontraron locales nuevos con Web/Tel en esta zona.");
                return;
            }

            console.log(`✅ ¡BINGO! Encontrados ${rows.length} locales potenciales.`);

            let batch = db.batch();
            let count = 0;
            let total = 0;

            for (const row of rows) {
                const placeId = row.id;

                // Limpieza de datos
                let web = row.web_list.replace(/[\[\]"']/g, '').split(',')[0].trim();
                let phone = row.phone_list.replace(/[\[\]"']/g, '').split(',')[0].trim();

                let updateData = {};
                if (web && web.startsWith('http')) updateData.website = web;
                if (phone && phone.length > 5) updateData.phone = phone;

                if (Object.keys(updateData).length > 0) {
                    const docRef = db.collection(COLECCION).doc(placeId);

                    batch.set(docRef, {
                        ...updateData,
                        last_enriched_at: admin.firestore.FieldValue.serverTimestamp(),
                        source: 'overture_cloud_stream_v2'
                    }, { merge: true });

                    count++;
                    total++;

                    if (count === 400) {
                        await batch.commit();
                        process.stdout.write(`   ⚡ Sincronizados ${total} locales con Web/Tel...\r`);
                        batch = db.batch();
                        count = 0;
                    }
                }
            }

            if (count > 0) await batch.commit();
            console.log(`\n\n🏁 PROCESO FINALIZADO.`);
            console.log(`🏆 Florida ha sido enriquecida con éxito.`);
        });
    });
}

enriquecerDesdeLaNube().catch(console.error);
