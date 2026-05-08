const admin = require('firebase-admin');
const path = require('path');
const geofire = require('geofire-common'); // 🛰️ LIBRERÍA CRÍTICA PARA EL RADAR

// Inicialización de la Llave Maestra
const serviceAccount = require(path.join(__dirname, 'llave_maestra.json'));
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// 🗺️ MAPEO ESTRATÉGICO COMPLETO (EXPANDIDO SEGÚN CSV FLORIDA)
const CATEGORY_MAP = {
    // --- CATEGORÍA: RESTAURANTE ---
    'restaurant': 'Restaurante',
    'steakhouse': 'Restaurante',           // 🎯 Outback / LongHorn
    'steak_house': 'Restaurante',
    'breakfast_restaurant': 'Restaurante', // 🎯 IHOP / Denny's
    'pizza_restaurant': 'Restaurante',
    'pizzeria': 'Restaurante',
    'mexican_restaurant': 'Restaurante',
    'chinese_restaurant': 'Restaurante',
    'seafood_restaurant': 'Restaurante',
    'sushi_restaurant': 'Restaurante',
    'italian_restaurant': 'Restaurante',
    'caribbean_restaurant': 'Restaurante',
    'latin_american_restaurant': 'Restaurante',
    'cuban_restaurant': 'Restaurante',
    'american_restaurant': 'Restaurante',
    'eating_drinking_location': 'Restaurante',

    // --- CATEGORÍA: COMIDA RÁPIDA ---
    'fast_food_restaurant': 'Comida Rápida',
    'burger_joint': 'Comida Rápida',
    'burger_restaurant': 'Comida Rápida',   // 🎯 McDonald's / BK
    'hamburger_restaurant': 'Comida Rápida',
    'chicken_restaurant': 'Comida Rápida',
    'sandwich_shop': 'Comida Rápida',
    'taco_restaurant': 'Comida Rápida',

    // --- CATEGORÍA: CAFETERÍA ---
    'cafe': 'Cafetería',
    'bakery': 'Cafetería',
    'desserts': 'Cafetería',               // 🎯 Melt Brownie
    'coffee_shop': 'Cafetería',
    'donut_shop': 'Cafetería',
    'tea_house': 'Cafetería',
    'ice_cream_shop': 'Cafetería',

    // --- CATEGORÍA: BAR & COPAS ---
    'bar': 'Bar & Copas',
    'pub': 'Bar & Copas',
    'distillery': 'Bar & Copas',
    'brewery': 'Bar & Copas',
    'wine_bar': 'Bar & Copas',
    'nightclub': 'Bar & Copas',
    'liquor_store': 'Bar & Copas',

    // --- CATEGORÍA: FARMACIA ---
    'pharmacy': 'Farmacia',
    'drugstore': 'Farmacia',

    // --- CATEGORÍA: COMERCIO ---
    'grocery_store': 'Comercio',
    'supermarket': 'Comercio'
};

async function activacionRadarEliteTotal() {
    console.log("🛠️ INICIANDO NORMALIZACIÓN MAESTRA DE CATEGORÍAS...");
    const establishmentsRef = db.collection('establishments');

    // Filtramos por la carga de Florida
    const query = establishmentsRef.where('source', '==', 'geodata_official_fl_csv');

    let totalProcesados = 0;
    let totalAptos = 0;
    let lastDoc = null;

    while (true) {
        let currentQuery = query.limit(400); // Lotes seguros de 400
        if (lastDoc) currentQuery = currentQuery.startAfter(lastDoc);

        const snapshot = await currentQuery.get();
        if (snapshot.empty) break;

        const batch = db.batch();

        snapshot.docs.forEach(doc => {
            const data = doc.data();

            // 1. TRADUCCIÓN FLEXIBLE
            const rawCat = data.category || 'restaurant';
            const newCat = CATEGORY_MAP[rawCat] || 'Comercio';

            // 2. CONVERSIÓN CRÍTICA (Fuerza números para evitar NaN en Radar)
            const website = (data.website || "").trim();
            const lat = Number(data.lat);
            const lng = Number(data.lng);

            // Regla LAD: Debe tener Web y GPS válido
            const hasWeb = website.length > 8;
            const hasCoords = (!isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0);

            if (hasWeb && hasCoords) {
                totalAptos++;
                // 🛰️ GENERAR GEOHASH PARA BÚSQUEDA ESPACIAL
                const hash = geofire.geohashForLocation([lat, lng]);

                batch.update(doc.ref, {
                    lat: lat,
                    lng: lng,
                    geohash: hash,
                    category: newCat, // Etiqueta limpia para la App
                    active: true,
                    hasOnlineShopping: true,
                    country: 'USA',
                    state: 'FL',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Si no es apto para delivery, lo desactivamos del radar
                batch.update(doc.ref, {
                    active: false,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        });

        await batch.commit();
        totalProcesados += snapshot.size;
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        console.log(`✅ Procesados: ${totalProcesados} | 🚀 Negocios Listos: ${totalAptos}`);
    }

    console.log(`\n🏁 NORMALIZACIÓN COMPLETADA:`);
    console.log(`🌍 Total en Florida: ${totalProcesados}`);
    console.log(`🛰️ Listos para LAD Courier: ${totalAptos}`);
}

activacionRadarEliteTotal().catch(console.error);
