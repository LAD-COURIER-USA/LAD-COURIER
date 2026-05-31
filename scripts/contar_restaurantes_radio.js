const admin = require('firebase-admin');
const path = require('path');

// --- CONFIGURACIÓN LAD DIGITAL SYSTEMS LLC ---
const LLAVE_PATH = path.join(__dirname, 'llave_maestra.json');
const CENTER_LAT = 25.5110645; // 14334 SW 275 LN, Homestead
const CENTER_LON = -80.4220201;
const RADIUS_MILES = 5.0;

if (admin.apps.length === 0) {
    const serviceAccount = require(LLAVE_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// Fórmula matemática para calcular distancia real entre dos puntos GPS
function calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;    // Math.PI / 180
    const c = Math.cos;
    const a = 0.5 - c((lat2 - lat1) * p)/2 +
            c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;

    return 12742 * Math.asin(Math.sqrt(a)) * 0.621371; // Retorna Millas
}

async function contarRestaurantes() {
    console.log(`📡 ESCANEANDO RADAR LAD EN HOMESTEAD (Radio: ${RADIUS_MILES} millas)...`);
    console.log(`📍 Centro: ${CENTER_LAT}, ${CENTER_LON}\n`);

    const coleccion = "geodata_us_fl";

    // 1. Definimos el "Cuadrado" inicial para no bajar toda la base de datos (Optimización)
    const latDelta = 0.073; // Aprox 5.1 millas
    const minLat = CENTER_LAT - latDelta;
    const maxLat = CENTER_LAT + latDelta;

    try {
        // Consultamos locales en el rango de latitud
        const snapshot = await db.collection(coleccion)
            .where('gps.lat', '>=', minLat)
            .where('gps.lat', '<=', maxLat)
            .get();

        let totalLocalesEnCuadrado = snapshot.size;
        let restaurantesEnRadio = 0;
        let conWebsite = 0;
        let conTelefono = 0;

        console.log(`📊 Locales analizados en el área: ${totalLocalesEnCuadrado}`);

        snapshot.forEach(doc => {
            const data = doc.data();
            const lat = data.gps?.lat;
            const lon = data.gps?.lon;
            const category = (data.category || "").toUpperCase();
            const altCats = (data.alternate_categories || []).map(c => c.toUpperCase());

            // 🕵️ FILTRO 1: ¿Es un restaurante? (Categoría principal o secundaria)
            const esRestaurante = category.includes("RESTAURANT") ||
                                 category.includes("FOOD") ||
                                 altCats.some(c => c.includes("RESTAURANT"));

            if (esRestaurante && lat && lon) {
                // 🕵️ FILTRO 2: ¿Está dentro del CÍRCULO de 5 millas exactas?
                const distance = calculateDistance(CENTER_LAT, CENTER_LON, lat, lon);

                if (distance <= RADIUS_MILES) {
                    restaurantesEnRadio++;
                    if (data.website) conWebsite++;
                    if (data.phone) conTelefono++;
                }
            }
        });

        console.log(`--------------------------------------------------`);
        console.log(`✅ RESULTADOS FINALES PARA SMART SHOPPER:`);
        console.log(`🍔 Restaurantes encontrados en el radio: ${restaurantesEnRadio}`);
        console.log(`🌐 Tienen Website: ${conWebsite}`);
        console.log(`📞 Tienen Teléfono: ${conTelefono}`);
        console.log(`💡 Locales sin website para "Aprender": ${restaurantesEnRadio - conWebsite}`);
        console.log(`--------------------------------------------------`);
        console.log(`🚀 Conclusión: Smart Shopper puede mostrar ${restaurantesEnRadio} opciones cerca de ti.`);

    } catch (e) {
        console.error(`❌ Error en el radar: ${e.message}`);
    }
}

contarRestaurantes().catch(console.error);
