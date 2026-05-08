import firebase_admin
from firebase_admin import credentials, firestore
import os

# --- CONFIGURACIÓN ---
SERVICE_ACCOUNT_PATH = 'C:/Users/13053/Documents/dev/lad_courier/scripts/llave_maestra.json'

def main():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    db = firestore.client()

    # Lista completa de estados + PR y RD
    states = [
        'AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
        'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD',
        'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH',
        'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
        'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY',
        'PR', 'RD'
    ]

    print(f"{'ESTADO':<10} | {'COLECCIÓN':<20} | {'CONTEO'}")
    print("-" * 50)

    total_global = 0

    for code in states:
        coll_name = f"geodata_us_{code.lower()}"
        # Para República Dominicana es geodata_rd
        if code == 'RD': coll_name = "geodata_rd"
        # Para Puerto Rico es geodata_pr
        if code == 'PR': coll_name = "geodata_pr"

        try:
            # Usamos count() que es mucho más rápido y barato que traer los documentos
            count_query = db.collection(coll_name).count().get()
            count = count_query[0][0].value

            status = "✅" if count > 0 else "❌ VACÍO"
            print(f"{code:<10} | {coll_name:<20} | {count:,} {status}")
            total_global += count
        except Exception as e:
            print(f"{code:<10} | {coll_name:<20} | ⚠️ Error o no existe")

    print("-" * 50)
    print(f"TOTAL GLOBAL DE LOCALES: {total_global:,}")

if __name__ == "__main__":
    main()