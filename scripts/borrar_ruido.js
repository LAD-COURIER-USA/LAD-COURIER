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

async function borrarSoloRuido() {
    // 🎯 SOLO BORRAMOS LA COLECCIÓN CON ERRORES
    const COLECCION_A_LIMPIAR = 'geodata_fl';

    console.log(`💣 INICIANDO LIMPIEZA DE: ${COLECCION_A_LIMPIAR}...`);
    console.log(`ℹ️  Nota: 'geodata_test' NO será tocada.`);

    let totalBorrados = 0;

    async function deleteBatch() {
        // Tomamos lotes de 500 (límite de Firestore)
        const snapshot = await db.collection(COLECCION_A_LIMPIAR).limit(500).get();

        if (snapshot.empty) {
            console.log(`\n🏁 LIMPIEZA COMPLETADA. La colección '${COLECCION_A_LIMPIAR}' está vacía.`);
            return;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        totalBorrados += snapshot.size;
        console.log(`🗑️ Borrados ${totalBorrados} registros de ${COLECCION_A_LIMPIAR}...`);

        // Llamada recursiva para el siguiente lote
        return deleteBatch();
    }

    try {
        await deleteBatch();
    } catch (error) {
        console.error("❌ Error durante la limpieza:", error);
    }
}

borrarSoloRuido().catch(console.error);