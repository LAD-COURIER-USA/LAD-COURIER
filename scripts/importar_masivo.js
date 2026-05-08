const admin = require('firebase-admin');
const fs = require('fs');
const readline = require('readline');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'llave_maestra.json'));
if (admin.apps.length === 0) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// 🚀 CONFIGURACIÓN PARA ESCALA REAL
const LIMITE_REGISTROS = null; // NULL procesa el millón completo
const COLECCION_DESTINO = 'geodata_fl';

async function importarTodo() {
    const filePath = path.join(__dirname, '..', '..', 'LAD_DATA _FACTORY', 'florida_final.json');
    
    if (!fs.existsSync(filePath)) {
        console.error(`❌ Error: No se encontró el archivo en ${filePath}`);
        return;
    }

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

    let batch = db.batch();
    let count = 0;
    let totalCargado = 0;

    console.log(`📡 INICIANDO CARGA MASIVA A '${COLECCION_DESTINO}'...`);
    console.log(`⏱️ Esto puede tomar un tiempo (aprox. 1-2 horas para 1M de registros).`);

    for await (const line of rl) {
        if (LIMITE_REGISTROS && totalCargado >= LIMITE_REGISTROS) break;

        const item = JSON.parse(line);
        const ref = db.collection(COLECCION_DESTINO).doc(item.id);
        
        // 🌎 DINÁMICO: Detecta si es FL, GA, etc.
        const country = item.address.country || "US";
        const state = item.address.state || "FL";
        const regionTag = `${country}_${state}`;

        batch.set(ref, {
            ...item,
            search_key: `${regionTag}_${item.address.zip}_${item.address.number}_${item.id}`.replace(/\s/g, ''),
            region_tag: regionTag,
            active: true,
            is_verified: false, // Nuevo: para validación por Driver
            delivery_count: 0,   // Nuevo: para estadísticas logísticas
            source: 'overture_maps_v1',
            last_updated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        count++;
        totalCargado++;

        if (count === 500) {
            await batch.commit();
            if (totalCargado % 5000 === 0) {
                console.log(`📦 Progreso: ${totalCargado.toLocaleString()} registros cargados...`);
            }
            batch = db.batch();
            count = 0;
            // Pequeña pausa para evitar saturar el canal de red
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    }

    if (count > 0) await batch.commit();
    console.log(`\n✅ ¡ÉXITO TOTAL! Se cargaron ${totalCargado.toLocaleString()} registros.`);
}

importarTodo().catch(error => {
    console.error("❌ Error crítico en la carga:", error);
    process.exit(1); // Detener la ejecución en caso de error
});
