const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'llave_maestra.json'));
if (admin.apps.length === 0) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function subirPrueba() {
    const filePath = path.join(__dirname, '..', '..', 'LAD_DATA _FACTORY', 'test_200_calidad.json');
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

    console.log(`🚀 Subiendo 200 locales con ADN completo a 'geodata_test'...`);
    const batch = db.batch();

    data.forEach(item => {
        const ref = db.collection('geodata_test').doc(item.id);
        batch.set(ref, {
            ...item,
            search_key: `US_${item.address.zip}_${item.address.number}_${item.id}`.replace(/\s/g, ''),
            last_updated: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    await batch.commit();
    console.log("✅ ¡PROCESO COMPLETADO! Revisa la colección 'geodata_test' en tu Firebase.");
}

subirPrueba().catch(console.error);