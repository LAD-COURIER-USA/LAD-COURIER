const admin = require('firebase-admin');
const path = require('path');

// Sincronización con su llave maestra
const serviceAccountPath = path.join(__dirname, 'llave_maestra.json');
const serviceAccount = require(serviceAccountPath);

if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

async function borrarColeccion(nombreColeccion) {
    console.log(`💣 INICIANDO LIMPIEZA DE: ${nombreColeccion}...`);
    const collectionRef = db.collection(nombreColeccion);
    const query = collectionRef.limit(500);

    let totalBorrados = 0;

    async function deleteBatch() {
        const snapshot = await query.get();
        if (snapshot.empty) {
            console.log(`🏁 ${nombreColeccion} está vacía.`);
            return;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        totalBorrados += snapshot.size;
        process.stdout.write(`🗑️ Borrados ${totalBorrados} de ${nombreColeccion}...\r`);
        return deleteBatch();
    }

    await deleteBatch();
    console.log("\n");
}

async function operacionLimpieza() {
    await borrarColeccion('geodata_fl');
    await borrarColeccion('retailers_cache');
    console.log("✅ LIMPIEZA TOTAL COMPLETADA. Terreno listo para Overture Maps.");
}

operacionLimpieza().catch(console.error);
