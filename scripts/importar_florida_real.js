const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Sincronización con su llave maestra
const serviceAccountPath = path.join(__dirname, 'llave_maestra.json');
if (!fs.existsSync(serviceAccountPath)) {
    console.error("❌ ERROR CRÍTICO: No se encuentra 'llave_maestra.json'");
    process.exit(1);
}
const serviceAccount = require(serviceAccountPath);

if (admin.apps.length === 0) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const db = admin.firestore();

function parseCSVLine(line) {
    const result = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
            if (i + 1 < line.length && line[i + 1] === '"') { cur += '"'; i++; }
            else { inQuotes = !inQuotes; }
        } else if (char === ',' && !inQuotes) {
            result.push(cur.trim());
            cur = '';
        } else { cur += char; }
    }
    result.push(cur.trim());
    return result;
}

async function iniciarInyeccionSoberana() {
    const fileName = 'geodata-FL-1772814226341.csv';
    const filePath = path.join(__dirname, 'data', fileName);

    if (!fs.existsSync(filePath)) {
        console.error(`❌ ERROR: No se encuentra el archivo en scripts/data/`);
        return;
    }

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

    console.log(`🚀 MAQUINARIA SOBERANA: Iniciando importación de 138k locales...`);

    let batch = db.batch();
    let count = 0;
    let totalInyectados = 0;
    let isHeader = true;

    for await (const line of rl) {
        if (isHeader) { isHeader = false; continue; }

        const cols = parseCSVLine(line);
        if (cols.length < 13) continue;

        try {
            const id = cols[0];
            const name = cols[1].toUpperCase();
            const fullAddress = cols[6].replace(/[\t\n\r]/g, ' ').trim();

            // --- EXTRACCIÓN ADN POSTAL ---
            // Extraer el número de calle (ej: "18753")
            const streetNumber = fullAddress.split(' ')[0].replace(/\D/g, '');
            // Extraer ZIP de 5 dígitos (ej: "33469")
            const zipCode = (cols[9] || "").split('-')[0].trim();

            if (!streetNumber || !zipCode) continue;

            const lat = parseFloat(cols[11]);
            const lng = parseFloat(cols[12]);
            if (isNaN(lat) || isNaN(lng)) continue;

            const storeRef = db.collection('geodata_fl').doc(id);

            batch.set(storeRef, {
                name,
                address: {
                    full: fullAddress,
                    street_number: streetNumber,
                    zip: zipCode,
                    city: cols[7] || "Florida",
                    state: 'FL'
                },
                coordinates: { lat, lon: lng },
                category: cols[4] || "Comercio",
                active: true,
                source: 'geodata_official_fl_csv',
                last_updated: admin.firestore.FieldValue.serverTimestamp()
            });

            count++;
            totalInyectados++;

            // ✅ Lotes estrictos de 500 como un reloj suizo
            if (count === 500) {
                await batch.commit();
                process.stdout.write(`📦 Lote de 500 enviado. Total: ${totalInyectados}\r`);
                batch = db.batch();
                count = 0;
            }
        } catch (e) { /* Saltar errores de línea individual */ }
    }

    if (count > 0) await batch.commit();
    console.log(`\n\n🏁 MISIÓN COMPLETADA:`);
    console.log(`✅ Total inyectados en 'geodata_fl': ${totalInyectados}`);
}

iniciarInyeccionSoberana().catch(console.error);