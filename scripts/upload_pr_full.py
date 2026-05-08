import csv
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
CSV_FILE_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/geodata-PR-final.csv'
COLLECTION_NAME = 'geodata_us_pr'
STATE_CODE = 'PR'

def split_address(full_address):
    if not full_address or full_address.lower() == 'no address':
        return "", ""

    # 1. Intentar número al principio (Ej: 992 Ave Hostos)
    match_start = re.match(r'^(\d+)\s+(.*)$', full_address.strip())
    if match_start:
        return match_start.group(1), match_start.group(2).upper()

    # 2. Si no empieza por número, buscar el primer número que aparezca (Ej: Carr 123 -> 123)
    # Esto ayuda con las direcciones de PR que son carreteras
    match_any = re.search(r'(\d+)', full_address)
    if match_any:
        return match_any.group(1), full_address.upper()

    return "", full_address.strip().upper()

def clean_zip(zip_str):
    if not zip_str: return "00000"
    z = zip_str.split('-')[0].strip()
    return z.zfill(5) if z.isdigit() else z[:5]

def upload_pr():
    print(f"🚀 INICIANDO CARGA DE PUERTO RICO ({STATE_CODE})...")

    if not os.path.exists(CSV_FILE_PATH):
        print(f"❌ Error: No se encontró el archivo en {CSV_FILE_PATH}")
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    count = 0
    skipped = 0
    batch = db.batch()

    try:
        with open(CSV_FILE_PATH, mode='r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                place_id = row.get('place_id')
                raw_address = row.get('address', '')
                number, street = split_address(raw_address)

                if not number:
                    skipped += 1
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

                db.collection(COLLECTION_NAME).document(place_id).set(data)
                count += 1
                if count % 500 == 0:
                    print(f"⚡ {count} locales de PR inyectados...")

        print(f"\\n✅ FINALIZADO:")
        print(f"🔹 Inyectados con éxito: {count}")
        print(f"🔹 Saltados (sin número): {skipped}")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    upload_pr()
