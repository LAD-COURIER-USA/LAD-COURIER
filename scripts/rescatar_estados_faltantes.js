const fs = require('fs');
const path = require('path');
const readline = require('readline');

// --- CONFIGURACIÓN LAD ---
const MASTER_FILE = path.join(__dirname, 'data', 'MASTER_GEODATA_TOTAL.csv');
const TARGET_STATES = ['DE', 'MS', 'DC'];
const DATA_DIR = path.join(__dirname, 'data');

async function rescatarEstados() {
    console.log("🔦 INICIANDO RESCATE DE ESTADOS FALTANTES (DE, MS, DC)...");
    console.log("⏳ Escaneando el Archivo Maestro (esto puede tardar unos minutos)...");

    const streams = {};
    TARGET_STATES.forEach(state => {
        const filePath = path.join(DATA_DIR, `geodata-${state}-final.csv`);
        streams[state] = fs.createWriteStream(filePath);
    });

    const rl = readline.createInterface({
        input: fs.createReadStream(MASTER_FILE),
        crlfDelay: Infinity
    });

    let header = "";
    let count = 0;
    let foundCounts = { 'DE': 0, 'MS': 0, 'DC': 0 };

    for await (const line of rl) {
        if (count === 0) {
            header = line;
            // Escribir el header en cada archivo nuevo
            TARGET_STATES.forEach(state => streams[state].write(header + '\n'));
            count++;
            continue;
        }

        // Buscamos el código del estado en la línea (usualmente está entre comas o comillas)
        // Intentamos detectar ",DE," o ",MS," o ",DC,"
        for (const state of TARGET_STATES) {
            if (line.includes(`,${state},`) || line.includes(`"${state}"`)) {
                streams[state].write(line + '\n');
                foundCounts[state]++;
            }
        }

        count++;
        if (count % 50000 === 0) {
            process.stdout.write(`   🚜 Analizadas ${count.toLocaleString()} líneas...\r`);
        }
    }

    TARGET_STATES.forEach(state => streams[state].end());

    console.log("\n\n🏁 RESCATE COMPLETADO:");
    TARGET_STATES.forEach(state => {
        console.log(`✅ ${state}: ${foundCounts[state].toLocaleString()} locales rescatados.`);
    });
    console.log("\n🏆 ¡Álbum de USA completo! Ya puedes correr la aspiradora universal.");
}

rescatarEstados().catch(console.error);
