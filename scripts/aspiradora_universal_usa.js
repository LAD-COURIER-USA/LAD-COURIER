const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');

// --- CONFIGURACIÓN MAESTRA LAD DIGITAL SYSTEMS ---
const DATA_DIR = path.join(__dirname, 'data');
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');

// Inicializar Firebase
if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function procesarArchivo(filePath) {
    const fileName = path.basename(filePath);
    const match = fileName.match(/geodata-([A-Z]{2,3})-final\.csv/);
    if (!match) return;

    const estado = match[1].toLowerCase();
    const coleccion = `geodata_us_${estado}`;

    console.log(`\n📂 PROCESANDO: ${fileName} -> [${coleccion}]`);

    let batch = db.batch();
    let count = 0;
    let totalEnEsteEstado = 0;

    const stream = fs.createReadStream(filePath).pipe(csv());

    for await (const row of stream) {
        const placeId = row.place_id;

        if (placeId) {
            let updateData = {};

            // 🌐 1. Extraer Website
            const webRaw = row.websites;
            if (webRaw && webRaw !== '[]' && webRaw !== '') {
                const cleanWeb = webRaw.replace(/[\[\]"']/g, '').split(',')[0].trim();
                if (cleanWeb.startsWith('http')) updateData.website = cleanWeb;
            }

            // 📞 2. Extraer Teléfono
            const phoneRaw = row.phones;
            if (phoneRaw && phoneRaw !== '[]' && phoneRaw !== '') {
                const cleanPhone = phoneRaw.replace(/[\[\]"']/g, '').split(',')[0].trim();
                if (cleanPhone.length > 5) updateData.phone = cleanPhone;
            }

            // 🏷️ 3. Extraer Categoría Principal
            const catRaw = row.category || row.basic_category;
            if (catRaw) {
                updateData.category = catRaw.toUpperCase().trim();
            }

            // 🏷️ 4. Extraer Marca (Brand)
            const brandRaw = row.brand;
            if (brandRaw && brandRaw !== '') {
                updateData.brand = brandRaw.toUpperCase().trim();
            }

            // 🧬 5. Extraer Categorías Secundarias (Alternate)
            const altCatsRaw = row.alternate_categories;
            if (altCatsRaw && altCatsRaw !== '[]' && altCatsRaw !== '') {
                // Limpiamos la lista ['cat1', 'cat2'] y la convertimos en un Arreglo real de Firestore
                const altList = altCatsRaw.replace(/[\[\]"']/g, '')
                                         .split(',')
                                         .map(s => s.trim().toUpperCase())
                                         .filter(s => s !== "" && s !== updateData.category);

                if (altList.length > 0) {
                    updateData.alternate_categories = altList;
                }
            }

            if (Object.keys(updateData).length > 0) {
                const docRef = db.collection(coleccion).doc(placeId);

                // 🛡️ MERGE: TRUE - El blindaje de LAD Courier. Protege GPS y ADN.
                batch.set(docRef, {
                    ...updateData,
                    last_enriched_at: admin.firestore.FieldValue.serverTimestamp(),
                    source_enrichment: 'overture_usa_universal_v5_full_brain'
                }, { merge: true });

                count++;
                totalEnEsteEstado++;

                if (count === 450) {
                    await batch.commit();
                    process.stdout.write(`   ⚡ [${estado.toUpperCase()}] Sincronizados: ${totalEnEsteEstado} locales inteligentes...\r`);
                    batch = db.batch();
                    count = 0;
                }
            }
        }
    }

    if (count > 0) await batch.commit();
    console.log(`\n✅ FINALIZADO: ${estado.toUpperCase()} con ${totalEnEsteEstado} locales enriquecidos.`);
}

async function aspiradoraUniversal() {
    console.log("🚀 INICIANDO ASPIRADORA UNIVERSAL USA - VERSIÓN GOLD (WEB + TEL + CAT + BRAND + ALT_CAT)...");

    if (!fs.existsSync(DATA_DIR)) {
        console.error("❌ ERROR: No existe la carpeta scripts/data");
        return;
    }

    const files = fs.readdirSync(DATA_DIR);
    const csvFiles = files.filter(f => f.endsWith('-final.csv'));

    console.log(`📊 Encontrados ${csvFiles.length} archivos de estado para procesar.`);

    for (const file of csvFiles) {
        const fullPath = path.join(DATA_DIR, file);
        try {
            await procesarArchivo(fullPath);
        } catch (e) {
            console.error(`\n❌ Error procesando ${file}:`, e.message);
        }
    }

    console.log("\n\n🏆 ¡CONQUISTA COMPLETADA! Tu base de datos nacional es ahora un Cerebro Inteligente.");
}

aspiradoraUniversal().catch(console.error);
