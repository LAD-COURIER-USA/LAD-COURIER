const admin = require('firebase-admin');
const path = require('path');

// --- CONFIGURACIÓN LAD ESTRATÉGICA ---
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');
const USER_LAT = 25.5110645;
const USER_LON = -80.4220201;
const RADIUS_MILES = 5.0;
const ZIP_CLUSTER = ["33032", "33030", "33033", "33031", "33170", "33034"];

if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

function getDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    const c = Math.cos;
    const a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * Math.asin(Math.sqrt(a)) * 0.621371; // Millas
}

async function runShopperRadar() {
    console.log(`🚀 SIMULADOR LAD SMART SHOPPER - RADAR 5 MILLAS`);
    console.log(`📍 Ubicación: Homestead (33032)\n`);

    try {
        // 1. Búsqueda por Zip Codes (MÁXIMA EFICIENCIA)
        const snapshot = await db.collection("geodata_us_fl")
            .where('address.zip', 'in', ZIP_CLUSTER)
            .get();

        let vips = [];
        let onDemand = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            const category = (data.category || "").toUpperCase();

            // Filtro de Restaurantes
            if (category.includes("RESTAURANT") || category.includes("FOOD")) {
                const dist = getDistance(USER_LAT, USER_LON, data.gps.lat, data.gps.lon);

                // 2. Filtro de 5 Millas exactas
                if (dist <= RADIUS_MILES) {
                    const storeInfo = { name: data.name, dist: dist.toFixed(2), id: doc.id };

                    // 3. Clasificación VIP vs On-Demand
                    if (data.website) {
                        vips.push(storeInfo);
                    } else {
                        onDemand.push(storeInfo);
                    }
                }
            }
        });

        console.log(`--------------------------------------------------`);
        console.log(`🌟 LOCALES VIP (Ya tienen Website): ${vips.length}`);
        vips.slice(0, 5).forEach(s => console.log(`   🏆 [${s.dist} mi] ${s.name}`));
        console.log(`   ... y ${vips.length - 5} más.`);

        console.log(`\n🔍 LOCALES ON-DEMAND (Para buscar y aprender): ${onDemand.length}`);
        onDemand.slice(0, 5).forEach(s => console.log(`   📖 [${s.dist} mi] ${s.name}`));
        console.log(`   ... y ${onDemand.length - 5} más.`);

        console.log(`--------------------------------------------------`);
        console.log(`✅ TOTAL DISPONIBLE EN SMART SHOPPER: ${vips.length + onDemand.length}`);
        console.log(`🚀 Conclusión: Roberto, el usuario verá ${vips.length} botones directos y ${onDemand.length} oportunidades de búsqueda.`);

    } catch (e) {
        console.error(`❌ Error: ${e.message}`);
    }
}

runShopperRadar().catch(console.error);
