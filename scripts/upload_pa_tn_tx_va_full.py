import csv
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
DATA_DIR = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/'

def split_address_smart(addr):
    if not addr or addr.lower() in ['no address', '']:
        return "", ""
    addr = addr.strip()
    match_start = re.match(r'^(\d+)\s+(.*)$', addr)
    if match_start:
        return match_start.group(1), match_start.group(2).upper()
    match_any = re.search(r'(\d+)', addr)
    if match_any:
        return match_any.group(1), addr.upper()
    return "", addr.upper()

def clean_zip(zip_str):
    if not zip_str: return "00000"
    match = re.search(r'(\d{5})', zip_str)
    return match.group(1) if match else "00000"

def upload_task(name, file_name, collection, state_code):
    file_path = DATA_DIR + file_name
    print(f"\n📦 PROCESANDO: {name} ({state_code}) -> {collection}")

    if not os.path.exists(file_path):
        print(f"❌ Error: No se encontró el archivo {file_path}")
        return

    db = firestore.client()
    count = 0
    batch = db.batch()

    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            place_id = row.get('place_id')
            num, street = split_address_smart(row.get('address', ''))

            if not num: continue

            zip_code = clean_zip(row.get('zipcode', ''))
            dna_key = f"US_{state_code}_{zip_code}_{num}".upper()

            data = {
                'id': place_id,
                'name': row.get('name', '').upper(),
                'active': True,
                'is_verified': True,
                'source': 'overture_batch_v2_smart',
                'address': {
                    'number': num,
                    'street': street,
                    'city': row.get('city', '').upper(),
                    'state': state_code,
                    'zip': zip_code,
                    'country': 'US',
                    'full': f"{num} {street}, {row.get('city', '').upper()}, {state_code} {zip_code}".upper()
                },
                'gps': {
                    'lat': float(row.get('lat', 0)) if row.get('lat') else 0.0,
                    'lon': float(row.get('lon', 0)) if row.get('lon') else 0.0,
                },
                'search_key': dna_key,
            }

            doc_ref = db.collection(collection).document(place_id)
            batch.set(doc_ref, data)
            count += 1

            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                print(f"  ⚡ {count} locales inyectados...")

        batch.commit()
    print(f"✅ {name} FINALIZADO: {count} locales.")

def main():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    tasks = [
        {'name': 'Pennsylvania', 'file': 'geodata-PA-final.csv', 'coll': 'geodata_us_pa', 'code': 'PA'},
        {'name': 'Tennessee', 'file': 'geodata-TN-final.csv', 'coll': 'geodata_us_tn', 'code': 'TN'},
        {'name': 'Texas', 'file': 'geodata-TX-final.csv', 'coll': 'geodata_us_tx', 'code': 'TX'},
        {'name': 'Virginia', 'file': 'geodata-VA-final.csv', 'coll': 'geodata_us_va', 'code': 'VA'},
    ]

    for t in tasks:
        upload_task(t['name'], t['file'], t['coll'], t['code'])

if __name__ == "__main__":
    main()