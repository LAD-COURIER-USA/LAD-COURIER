import duckdb
import os

csv_path = 'scripts/data/geodata-FL-final.csv'

def main():
    if not os.path.exists(csv_path):
        print(f"❌ Error: No se encuentra el archivo {csv_path}")
        return

    try:
        con = duckdb.connect()
        print(f"📊 Analizando categorías en {csv_path}...")
        res = con.execute(f"SELECT category, COUNT(*) as count FROM read_csv_auto('{csv_path}') GROUP BY category ORDER BY count DESC LIMIT 20").fetchall()
        for row in res:
            print(f"- {row[0]}: {row[1]}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
