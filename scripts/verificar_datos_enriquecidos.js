const admin = require('firebase-admin');
const path = require('path');

// --- CONFIGURACIÓN ---
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');
const ESTADOS_A_PROBAR = ['fl', 'tx', 'ny', 'ca'];

if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function verificarDatos() {
    console.log("🧐 AUDITORÍA DE CEREBRO TOTAL - LAD DIGITAL SYSTEMS LLC\n");

    for (const estado of ESTADOS_A_PROBAR) {
        const coleccion = `geodata_us_${estado}`;
        console.log(`--------------------------------------------------`);
        console.log(`📍 ESTADO: ${estado.toUpperCase()} (Colección: ${coleccion})`);

        try {
            // Buscamos locales que tengan la etiqueta de la versión más reciente (v5)
            const snapshot = await db.collection(coleccion)
                .where('source_enrichment', '==', 'overture_usa_universal_v5_full_brain')
                .limit(2)
                .get();

            if (snapshot.empty) {
                console.log(`⚠️ No se encontraron locales con la versión Gold (v5). Probando búsqueda general...`);
                // Búsqueda de emergencia por si la inyección falló o usó otra etiqueta
                const backup = await db.collection(coleccion).limit(1).get();
                if(!backup.empty) {
                   const d = backup.docs[0].data();
                   console.log(`   💡 Encontrado registro base: ${d.name}`);
                   console.log(`   🏷️ Etiqueta actual: ${d.source_enrichment || 'N/A'}`);
                }
                continue;
            }

            snapshot.forEach(doc => {
                const data = doc.data();
                console.log(`\n🏢 Local: ${data.name || 'SIN NOMBRE'}`);
                console.log(`   🆔 ID: ${doc.id}`);
                console.log(`   🌐 Website: ${data.website || '❌ NO TIENE'}`);
                console.log(`   📞 Phone: ${data.phone || '❌ NO TIENE'}`);
                console.log(`   🏷️ Category: ${data.category || '❌ NO TIENE'}`);
                console.log(`   🏭 Brand: ${data.brand || '---'}`);
                console.log(`   🧬 Alt Categories: ${data.alternate_categories ? data.alternate_categories.join(', ') : 'None'}`);
                console.log(`   📍 GPS: Lat ${data.gps?.lat}, Lon ${data.gps?.lon}`);

                const fullBrain = (data.website && data.phone && data.category) ? "✅ CEREBRO COMPLETO" : "⚠️ DATOS PARCIALES";
                console.log(`   🛡️ Status Inteligencia: ${fullBrain}`);
            });
        } catch (e) {
            console.error(`❌ Error consultando ${coleccion}: ${e.message}`);
        }
    }

    console.log(`\n--------------------------------------------------`);
    console.log(`🏁 AUDITORÍA FINALIZADA.`);
}

verificarDatos().catch(console.error);
