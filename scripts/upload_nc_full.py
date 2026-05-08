import csv
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
CSV_FILE_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/geodata-NC-final.csv'
COLLECTION_NAME = 'geodata_us_nc'
STATE_CODE = 'NC'

def split_address(full_address):
    if not full_address or full_address.lower() == 'no address':
        return "", ""

    # Buscamos cualquier número al principio, permitiendo espacios o guiones
    # Ejemplo: "2950", "123-A", "75"
    match = re.match(r'^(\d+)\s*(.*)$', full_address.strip())
    if match:
        num = match.group(1)
        rest = match.group(2).upper()
        return num, rest
    return "", full_address.strip().upper()

def clean_zip(zip_str):
    if not zip_str: return "00000"
    return zip_str.split('-')[0][:5]

def upload_nc_standard():
    print(f"🚀 INICIANDO CARGA NC (ESTILO FLORIDA) EN {COLLECTION_NAME}...")

    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    count = 0
    skipped_no_number = 0
    batch = db.batch()

    try:
        with open(CSV_FILE_PATH, mode='r', encoding='utf-8') as csvfile:
            # Primero contamos total de líneas para saber el universo
            total_lines = sum(1 for line in csvfile) - 1
            csvfile.seek(0)
            print(f"📊 El archivo tiene un total de {total_lines} registros.")

            reader = csv.DictReader(csvfile)
            for row in reader:
                place_id = row.get('place_id')
                raw_address = row.get('address', '')
                number, street = split_address(raw_address)

                if not number:
                    skipped_no_number += 1
                    continue

                zip_code = clean_zip(row.get('zipcode', ''))
                dna_key = f"US_{STATE_CODE}_{zip_code}_{number}".upper()

                data = {
                    'id': place_id,
                    'name': row.get('name', '').upper(),
                    'active': True,
                    'is_verified': True,
                    'source': 'overture_master_v1',
                    'address': {
                        'number': number,
                        'street': street,
                        'city': row.get('city', '').upper(),
                        'state': STATE_CODE,
                        'zip': zip_code,
                        'country': 'US',
                        'full': f"{number} {street}, {row.get('city', '').upper()}, {STATE_CODE} {zip_code}".upper()
                    },
                    'gps': {
                        'lat': float(row.get('lat', 0)) if row.get('lat') else 0.0,
                        'lon': float(row.get('lon', 0)) if row.get('lon') else 0.0,
                    },
                    'search_key': dna_key,
                }

                doc_ref = db.collection(COLLECTION_NAME).document(place_id)
                batch.set(doc_ref, data)

                count += 1
                if count % 1000 == 0:
                    batch.commit()
                    batch = db.batch()
                    print(f"⚡ {count} inyectados... (Saltados por falta de número: {skipped_no_number})")

        batch.commit()
        print(f"\\n✅ FINALIZADO:")
        print(f"🔹 Total en archivo: {total_lines}")
        print(f"🔹 Inyectados con éxito: {count}")
        print(f"🔹 Descartados (sin número): {skipped_no_number}")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    upload_nc_standard()
