
import duckdb

csv_path = 'scripts/data/geodata-FL-final.csv'

def check():
    con = duckdb.connect()
    print(f"--- Verificando contenido en {csv_path} ---")
    
    # Buscar UPS, FedEx, Post Office, Pharmacy
    targets = ['UPS', 'FEDEX', 'POST OFFICE', 'PHARMACY', 'AUTO PARTS', 'BAKERY']
    
    for target in targets:
        count = con.execute(f"SELECT count(*) FROM read_csv_auto('{csv_path}') WHERE name LIKE '%{target}%'").fetchone()[0]
        print(f"🔍 {target}: {count} encontrados")

    # Ver categorías únicas para ver qué se nos escapó
    print("\n--- Top Categorías en el archivo ---")
    print(con.execute(f"SELECT category, count(*) as total FROM read_csv_auto('{csv_path}') GROUP BY category ORDER BY total DESC LIMIT 10").df())

if __name__ == "__main__":
    check()
