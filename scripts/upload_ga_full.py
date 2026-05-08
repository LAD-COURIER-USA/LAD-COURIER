import csv
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
CSV_FILE_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/geodata-GA-final.csv'
COLLECTION_NAME = 'geodata_us_ga'
STATE_CODE = 'GA'

def split_address(full_address):
    if not full_address or full_address.lower() == 'no address':
        return "", ""
    # Busca números al inicio de la cadena
    match = re.match(r'^(\d+)\s+(.*)$', full_address.strip())
    if match:
        return match.group(1), match.group(2).upper()
    return "", full_address.strip().upper()

def clean_zip(zip_str):
    if not zip_str: return "00000"
    return zip_str.split('-')[0][:5]

def upload_ga_full():
    print(f"🚀 INICIANDO CARGA TOTAL DE {STATE_CODE} (METODOLOGÍA FLORIDA)...")

    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    count = 0
    batch = db.batch()

    try:
        with open(CSV_FILE_PATH, mode='r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                place_id = row.get('place_id')
                if not place_id: continue

                raw_address = row.get('address', '')
                number, street = split_address(raw_address)

                if not number: continue

                zip_code = clean_zip(row.get('zipcode', ''))
                country = row.get('country', 'US').upper()

                # ADN LAD
                dna_key = f"{country}_{STATE_CODE}_{zip_code}_{number}".upper()

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
                        'country': country,
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
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
                    print(f"⚡ {count} locales de Georgia inyectados...")

        batch.commit()
        print(f"\n✅ ÉXITO: {count} locales inyectados en {COLLECTION_NAME}.")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    upload_ga_full()