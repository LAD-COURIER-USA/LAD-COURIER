const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const geofire = require('geofire-common');
const serviceAccount = require("./llave_maestra.json");

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

function hasOnlineShoppingHeuristic(url) {
    if (!url) return false;
    const keywords = ['order', 'shop', 'checkout', 'cart', 'pedido', 'compra', 'menu', 'store', 'walmart', 'publix'];
    return keywords.some(key => url.toLowerCase().includes(key));
}

async function importStateData(filePath, stateCode) {
    console.log(`🚀 Iniciando importación de Fusión para: ${stateCode}...`);

    if (!fs.existsSync(filePath)) {
        console.error(`❌ Error: El archivo ${filePath} no existe.`);
        return;
    }

    const rawData = fs.readFileSync(filePath);
    const locations = JSON.parse(rawData);

    let processed = 0;
    let batch = db.batch();

    for (const loc of locations) {
        if (!loc.website || !loc.address) continue;
        if (stateCode && loc.state && loc.state !== stateCode) continue;

        const docId = `OV_${loc.id || Buffer.from(loc.name + loc.lat + loc.lng).toString('hex').substring(0, 15)}`;
        const docRef = db.collection('establishments').doc(docId);

        const lat = parseFloat(loc.lat);
        const lng = parseFloat(loc.lng);
        const hash = geofire.geohashForLocation([lat, lng]);

        const storeData = {
            id: docId,
            name: loc.name.toUpperCase(),
            category: loc.category || 'grocery',
            lat: lat,
            lng: lng,
            geohash: hash,
            address: loc.address,
            city: loc.city || "",
            state: loc.state || stateCode,
            zip: loc.zip || "",
            country_code: loc.country_code || "US",
            website: loc.website,
            hasOnlineShopping: hasOnlineShoppingHeuristic(loc.website),
            provider: "overture",
            active: true,
            // CAMPOS DE FUSIÓN REINSTALADOS:
            fusion_status: "base_only",
            contact: {
                email: loc.email || null,
                phone: loc.phone || null
            },
            metadata: {
                source: "overture_maps",
                imported_at: admin.firestore.FieldValue.serverTimestamp()
            },
            last_updated: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.set(docRef, storeData, { merge: true });
        processed++;

        if (processed % 500 === 0) {
            await batch.commit();
            console.log(`📦 Procesados ${processed} registros...`);
            batch = db.batch();
        }
    }

    await batch.commit();
    console.log(`✅ ¡Misión Cumplida! ${processed} negocios listos en Firestore.`);
}

const fileArg = process.argv[2] || './data/overture_fl.json';
const stateArg = process.argv[3] || 'FL';
importStateData(path.resolve(__dirname, fileArg), stateArg).catch(console.error);