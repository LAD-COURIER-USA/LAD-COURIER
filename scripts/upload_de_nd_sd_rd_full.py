import csv
import firebase_admin
from firebase_admin import credentials, firestore
import re
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'
MASTER_FILE = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/MASTER_GEODATA_TOTAL.csv'
DATA_DIR = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/'

def split_address_smart(row, country='US'):
    addr = row.get('address', '').strip()
    zip_f = row.get('zipcode', '').strip()

    # 🇩🇴 Lógica Especial para RD: Si el zip parece una calle, los intercambiamos
    if country == 'DO' and (not addr or addr.lower() in ['dominican republic', 'no address']):
        if len(zip_f) > 8: # Definitivamente es una dirección, no un zip
            addr = zip_f

    if not addr or addr.lower() in ['no address', 'dominican republic', '']:
        return "", ""

    # 1. Buscar formato #77 o No. 2764 (Muy común en RD)
    match_hash = re.search(r'(?:#|No\.?)\s*(\d+)', addr, re.IGNORECASE)
    if match_hash:
        return match_hash.group(1), addr.upper()

    # 2. Formato US: Número al inicio (32 Carretera...)
    match_start = re.match(r'^(\d+)\s+(.*)$', addr)
    if match_start:
        return match_start.group(1), match_start.group(2).upper()

    # 3. Formato RD: Número al final (Ave. Sarasota 77)
    match_end = re.search(r'(\d+)$', addr)
    if match_end:
        return match_end.group(1), addr[:match_end.start()].strip().upper()

    # 4. Último recurso: El primer número que aparezca para generar el ADN
    match_any = re.search(r'(\d+)', addr)
    if match_any:
        return match_any.group(1), addr.upper()

    return "", addr.upper()

def clean_zip(zip_str):
    if not zip_str or not any(c.isdigit() for c in zip_str):
        return "00000"
    # Tomar solo los dígitos del inicio
    match = re.search(r'(\d+)', zip_str)
    return match.group(1).zfill(5) if match else "00000"

def upload_task(name, file_path, collection, state_filter=None):
    print(f"\n📦 PROCESANDO: {name} -> {collection}")
    db = firestore.client()
    count = 0

    if not os.path.exists(file_path):
        print(f"❌ Error: No se encontró el archivo {file_path}")
        return

    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if state_filter and row.get('state') != state_filter:
                continue

            country = row.get('country', 'US').upper()
            place_id = row.get('place_id')
            state = row.get('state', state_filter if state_filter else 'RD').upper()

            num, street = split_address_smart(row, country)
            if not num: continue # Sin número no hay ADN exacto

            zip_code = clean_zip(row.get('zipcode', ''))
            dna_key = f"{country}_{state}_{zip_code}_{num}".upper()

            data = {
                'id': place_id,
                'name': row.get('name', '').upper(),
                'active': True,
                'is_verified': True,
                'source': 'overture_batch_v2_smart',
                'address': {
                    'number': num, 'street': street,
                    'city': row.get('city', '').upper(),
                    'state': state, 'zip': zip_code, 'country': country,
                    'full': f"{num} {street}, {row.get('city', '').upper()}, {state}".upper()
                },
                'gps': {
                    'lat': float(row.get('lat', 0)) if row.get('lat') else 0.0,
                    'lon': float(row.get('lon', 0)) if row.get('lon') else 0.0,
                },
                'search_key': dna_key,
            }
            db.collection(collection).document(place_id).set(data)
            count += 1
            if count % 500 == 0:
                print(f"  ⚡ {count} inyectados...")

    print(f"✅ {name} FINALIZADO: {count} locales.")

def main():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    tasks = [
        {'name': 'Delaware (DE)', 'file': MASTER_FILE, 'coll': 'geodata_us_de', 'filter': 'DE'},
        {'name': 'North Dakota (ND)', 'file': DATA_DIR + 'geodata-ND-final.csv', 'coll': 'geodata_us_nd'},
        {'name': 'South Dakota (SD)', 'file': DATA_DIR + 'geodata-SD-final.csv', 'coll': 'geodata_us_sd'},
        {'name': 'Rep. Dominicana (RD)', 'file': DATA_DIR + 'geodata-RD-final.csv', 'coll': 'geodata_do'},
    ]

    for t in tasks:
        upload_task(t['name'], t['file'], t['coll'], t.get('filter'))

if __name__ == "__main__":
    main()