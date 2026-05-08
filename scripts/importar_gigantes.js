const admin = require('firebase-admin');
const serviceAccount = require("./llave_maestra.json");

if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

const gigantes = [
    // === USA 🇺🇸 ===
    { name: "Walmart", website: "https://www.walmart.com", category: "grocery", country: "US" },
    { name: "Publix", website: "https://www.publix.com", category: "grocery", country: "US" },
    { name: "Kroger", website: "https://www.kroger.com", category: "grocery", country: "US" },
    { name: "Winn-Dixie", website: "https://www.winndixie.com", category: "grocery", country: "US" },
    { name: "CVS Pharmacy", website: "https://www.cvs.com", category: "pharmacy", country: "US" },
    { name: "Walgreens", website: "https://www.walgreens.com", category: "pharmacy", country: "US" },
    { name: "Target", website: "https://www.target.com", category: "shopping", country: "US" },
    { name: "Best Buy", website: "https://www.bestbuy.com", category: "shopping", country: "US" },
    { name: "McDonald's", website: "https://www.mcdonalds.com", category: "restaurants", country: "US" },
    { name: "Starbucks", website: "https://www.starbucks.com", category: "restaurants", country: "US" },
    { name: "AutoZone", website: "https://www.autozone.com", category: "auto_parts", country: "US" },
    { name: "Advance Auto Parts", website: "https://www.advanceautoparts.com", category: "auto_parts", country: "US" },

    // === CANADÁ 🇨🇦 ===
    { name: "Loblaws", website: "https://www.loblaws.ca", category: "grocery", country: "CA" },
    { name: "Shoppers Drug Mart", website: "https://www.shoppersdrugmart.ca", category: "pharmacy", country: "CA" },
    { name: "Canadian Tire", website: "https://www.canadiantire.ca", category: "shopping", country: "CA" },
    { name: "Tim Hortons", website: "https://www.timhortons.ca", category: "restaurants", country: "CA" },

    // === MÉXICO 🇲🇽 ===
    { name: "Soriana", website: "https://www.soriana.com", category: "grocery", country: "MX" },
    { name: "Chedraui", website: "https://www.chedraui.com.mx", category: "grocery", country: "MX" },
    { name: "OXXO", website: "https://www.oxxo.com", category: "grocery", country: "MX" },
    { name: "Farmacias del Ahorro", website: "https://www.fahorro.com", category: "pharmacy", country: "MX" },

    // === BRASIL 🇧🇷 ===
    { name: "Pão de Açúcar", website: "https://www.paodeacucar.com", category: "grocery", country: "BR" },
    { name: "Lojas Americanas", website: "https://www.americanas.com.br", category: "shopping", country: "BR" },

    // === COLOMBIA/CENTROAMÉRICA 🇨🇴 🇵🇦 ===
    { name: "Almacenes Éxito", website: "https://www.exito.com", category: "grocery", country: "CO" },
    { name: "Super 99", website: "https://www.super99.com", category: "grocery", country: "PA" }
];

async function cargarGigantes() {
    console.log("🌎 INICIANDO DESPLIEGUE CONTINENTAL (USA, CA, MX, BR, CO, PA)...");
    const batch = db.batch();

    gigantes.forEach(tienda => {
        const docId = `${tienda.country}_${tienda.name.toLowerCase().replace(/\s/g, '_')}`;
        const docRef = db.collection('retailers_cache').doc(docId);

        batch.set(docRef, {
            name: tienda.name.toUpperCase(),
            website: tienda.website,
            category: tienda.category,
            country_code: tienda.country,
            is_global_giant: true,
            has_online_order: true,
            active: true,
            last_updated: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
    });

    try {
        await batch.commit();
        console.log(`✅ ¡MISIÓN CUMPLIDA! ${gigantes.length} gigantes continentales en posición.`);
        console.log("💡 El radar ahora detectará a estos gigantes en cualquier país.");
    } catch (e) {
        console.error("❌ ERROR EN LA CARGA:", e);
    }
    process.exit();
}

cargarGigantes();