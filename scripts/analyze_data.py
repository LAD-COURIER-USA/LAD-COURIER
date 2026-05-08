import csv
import os
from collections import Counter

MASTER_FILE = 'C:/Users/13053/Documents/dev/lad_courier/scripts/data/MASTER_GEODATA_TOTAL.csv'

def audit_rd_and_pr():
    print("🇩🇴🇵🇷 BUSCANDO REP. DOMINICANA Y PUERTO RICO EN EL MASTER...")
    print("="*60)

    if not os.path.exists(MASTER_FILE):
        print("❌ Archivo maestro no encontrado.")
        return

    country_counts = Counter()
    state_counts = Counter()
    rd_samples = []

    try:
        with open(MASTER_FILE, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                country = str(row.get('country', '')).upper().strip()
                state = str(row.get('state', '')).upper().strip()

                country_counts[country] += 1
                state_counts[state] += 1

                # Si detectamos algo que parezca RD, guardamos un ejemplo
                if country in ['DO', 'DOM', 'REPUBLICA DOMINICANA'] or state in ['DO', 'DR', 'RD']:
                    if len(rd_samples) < 3:
                        rd_samples.append(row)

        print("\\n🌍 CONTEO POR PAÍS (Top 5):")
        for c, count in country_counts.most_common(5):
            print(f"📍 {c:10} | {count:,} locales")

        print("\\n📊 RESULTADOS ESPECÍFICOS:")
        print(f"🇵🇷 Puerto Rico (PR): {state_counts['PR']:,} locales")
        print(f"🇩🇴 Rep. Dom. (DO):   {country_counts['DO']:,} locales")
        print(f"🇩🇴 Rep. Dom. (DOM):  {country_counts['DOM']:,} locales")

        if rd_samples:
            print("\\n✨ EJEMPLO DE REGISTRO EN RD:")
            for sample in rd_samples:
                print(f"   - {sample.get('name')} | {sample.get('city')}, {sample.get('country')}")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    audit_rd_and_pr()
