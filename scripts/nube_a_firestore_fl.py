import duckdb
import firebase_admin
from firebase_admin import credentials, firestore
import json

# --- CONFIGURACIÓN LAD ---
SERVICE_ACCOUNT_PATH = 'C:/src/lad_courier/LAD-COURIER/scripts/llave_maestra.json'
ESTADO = 'FL'
COLECCION = f'geodata_us_{ESTADO.lower()}'

def enriquecer_desde_la_nube():
    print(f"🌐 CONECTANDO CON EL CEREBRO DE OVERTURE MAPS (NUBE)...")

    # 1. Configurar Conexión a la Nube (S3)
    con = duckdb.connect()
    con.execute("INSTALL httpfs; LOAD httpfs;")

    # URL de la última versión estable de Overture
    overture_url = "s3://overturemaps-us-west-2/release/2024-11-13-alpha.0/theme=places/type=place/*.parquet"

    print(f"🔍 Filtrando Websites y Teléfonos de {ESTADO} directamente en S3...")

    # 2. Consultar solo lo necesario (ID, Websites, Phones)
    # Usamos try/except por si el acceso anónimo falla
    try:
        query = f"""
        SELECT
            id,
            CAST(websites AS VARCHAR) as web_list,
            CAST(phones AS VARCHAR) as phone_list
        FROM read_parquet('{overture_url}')
        WHERE (addresses[1].region = 'US-{ESTADO}' OR addresses[1].region = '{ESTADO}')
        AND (websites IS NOT NULL OR phones IS NOT NULL)
        """

        # 3. Traer los resultados a memoria (solo los links, pesan muy poco)
        df = con.execute(query).df()
        print(f"✅ ¡Éxito! Encontrados {len(df)} locales con datos para enriquecer.")

        # 4. Inicializar Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
            firebase_admin.initialize_app(cred)
        db = firestore.client()

        # 5. Inyección en lotes de 500 (Regla de Oro de Firestore)
        batch = db.batch()
        count = 0
        total = 0

        for _, row in df.iterrows():
            place_id = row['id']

            # Limpiar Website
            web = row['web_list'].replace('[', '').replace(']', '').replace('"', '').split(',')[0].strip()
            # Limpiar Phone
            phone = row['phone_list'].replace('[', '').replace(']', '').replace('"', '').split(',')[0].strip()

            update_data = {}
            if web and web.startswith('http'): update_data['website'] = web
            if phone and len(phone) > 5: update_data['phone'] = phone

            if update_data:
                doc_ref = db.collection(COLECCION).doc(place_id)
                # 🛡️ MERGE: TRUE para no borrar lo existente
                batch.set(doc_ref, {
                    **update_data,
                    'last_enriched_at': firestore.SERVER_TIMESTAMP,
                    'source': 'overture_cloud_stream'
                }, merge=True)

                count += 1
                total += 1

                if count == 450:
                    batch.commit()
                    print(f"   ⚡ Sincronizados {total} locales...")
                    batch = db.batch()
                    count = 0

        if count > 0: batch.commit()
        print(f"\n🏁 PROCESO FINALIZADO.")
        print(f"🏆 {total} locales de {ESTADO} ahora tienen Web y Teléfono.")

    except Exception as e:
        print(f"❌ ERROR: No se pudo conectar a la nube de Overture: {e}")

if __name__ == "__main__":
    enriquecer_enriquecer_desde_la_nube()
