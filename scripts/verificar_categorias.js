const admin = require('firebase-admin');
const path = require('path');

const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');
const ESTADOS = ['fl', 'tx', 'ny'];

if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

async function checkCategories() {
    console.log("🔍 BUSCANDO EL CAMPO 'CATEGORY' EN TU BASE DE DATOS...\n");

    for (const estado of ESTADOS) {
        const coll = `geodata_us_${estado}`;
        const snapshot = await db.collection(coll).limit(5).get();

        console.log(`📍 ESTADO: ${estado.toUpperCase()}`);
        if (snapshot.empty) {
            console.log("   ❌ No hay datos en esta colección.");
            continue;
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            console.log(`   🏢 ${data.name}: [Category: ${data.category || '⚠️ NO EXISTE'}]`);
        });
        console.log("");
    }
}

checkCategories().catch(console.error);
