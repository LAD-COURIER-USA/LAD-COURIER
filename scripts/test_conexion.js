const admin = require('firebase-admin');
const serviceAccount = require("./llave_maestra.json");

// Inicializamos el acceso
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function probarPuente() {
  console.log("🚀 Probando conexión con Firebase...");
  try {
    // Intentamos escribir un pequeño registro
    await db.collection('sistema_lad').doc('test').set({
      mensaje: "Conexión establecida para Operación Overture",
      fecha: new Date().toISOString()
    });
    console.log("✅ ¡CONEXIÓN EXITOSA! El puente está abierto.");
  } catch (e) {
    console.error("❌ ERROR DE CONEXIÓN:", e);
    console.log("💡 Tip: Verifique que el archivo se llame exactamente 'llave_maestra.json'");
  }
  process.exit();
}

probarPuente();