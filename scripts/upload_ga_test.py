import csv
import json
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
CSV_FILE_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/geodata-GA-final.csv'
COLLECTION_NAME = 'geodata_us_ga'
LIMIT = 500  # Prueba inicial con 500 registros

# --- FUNCIONES DE ADN POSTAL ---
Launching lib\main.dart on SM S908U in debug mode...
Running Gradle task 'assembleDebug'...
lib/screens/messenger/active_order_details_page.dart:495:45: Error: The method 'registerNewValidatedStore' isn't defined for the type 'GeodataService'.
 - 'GeodataService' is from 'package:lad_courier/services/geodata_service.dart' ('lib/services/geodata_service.dart').
Try correcting the name to the name of an existing method, or defining a method named 'registerNewValidatedStore'.
                      await _geodataService.registerNewValidatedStore(
                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
Target kernel_snapshot_program failed: Exception


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildDebug'.
> Process 'command 'C:\src\flutter\bin\flutter.bat'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 1m 36s
Error: Gradle task assembleDebug failed with exit code 1
def split_address(full_address):
    """Separa el número de la calle del nombre de la calle."""
    if not full_address or full_address.lower() == 'no address':
        return "", ""
    # Busca el primer número al inicio de la cadena
    match = re.match(r'^(\d+)\s+(.*)$', full_address.strip())
    if match:
        return match.group(1), match.group(2).upper()
    return "", full_address.strip().upper()

def clean_zip(zip_str):
    """Normaliza el ZIP a 5 dígitos."""
    if not zip_str: return "00000"
    return zip_str.split('-')[0][:5]

# --- PROCESO DE CARGA ---

def upload_ga_data():
    print("🚀 Iniciando motor de carga LAD para Georgia...")
    
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        print(f"❌ Error: No se encontró la llave maestra en {SERVICE_ACCOUNT_PATH}")
        return

    # Inicializar Firebase
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    count = 0
    batch = db.batch()
    
    try:
        with open(CSV_FILE_PATH, mode='r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if count >= LIMIT:
                    break
                
                # Extraer y transformar
                raw_address = row.get('address', '')
                number, street = split_address(raw_address)
                
                # Si no hay número de calle, omitimos para mantener la calidad del ADN
                if not number:
                    continue
                    
                zip_code = clean_zip(row.get('zipcode', ''))
                state = row.get('state', 'GA').upper()
                country = row.get('country', 'US').upper()
                
                # Generar ID único Global (ADN LAD)
                doc_id = f"{country}_{state}_{zip_code}_{number}".replace(' ', '_').upper()
                
                # Mapear al modelo de GeodataService.dart
                data = {
                    'id': doc_id,
                    'name': row.get('name', '').upper(),
                    'active': True,
                    'category': (row.get('category') or row.get('basic_category') or 'NEGOCIO').upper(),
                    'is_verified': True,
                    'source': 'overture_master',
                    'address': {
                        'number': number,
                        'street': street,
                        'city': row.get('city', '').upper(),
                        'state': state,
                        'zip': zip_code,
                        'country': country,
                    },
                    'gps': {
                        'lat': float(row.get('lat', 0)) if row.get('lat') else 0.0,
                        'lon': float(row.get('lon', 0)) if row.get('lon') else 0.0,
                    },
                    'search_key': doc_id,
                }
                
                # Agregar al batch
                doc_ref = db.collection(COLLECTION_NAME).document(doc_id)
                batch.set(doc_ref, data)
                
                count += 1
                if count % 100 == 0:
                    batch.commit()
                    batch = db.batch()
                    print(f"✅ {count} locales inyectados en Firestore...")

        # Finalizar carga
        batch.commit()
        print(f"\n--- PRUEBA COMPLETADA ---")
        print(f"📍 Estado: GEORGIA (GA)")
        print(f"📦 Registros: {count}")
        print(f"🔥 Colección: {COLLECTION_NAME}")
        print(f"🚀 Listos para probar con el OCR de la App.")

    except Exception as e:
        print(f"❌ Error durante la carga: {e}")

if __name__ == "__main__":
    upload_ga_data()
