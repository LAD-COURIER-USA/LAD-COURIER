import duckdb
import os

db_path = 'scripts/data/geodata-GA.parquet'

def main():
    if not os.path.exists(db_path):
        print(f"❌ Error: No se encuentra el archivo {db_path}")
        return

    con = duckdb.connect()
    print("--- Esquema de categories ---")
    try:
        # Intentamos ver la estructura de la columna categories
        res = con.execute(f"SELECT categories FROM read_parquet('{db_path}') LIMIT 1").fetchone()
        print(res)
        
        print("\n--- Columnas del archivo ---")
        con.execute(f"DESCRIBE SELECT * FROM read_parquet('{db_path}')").show()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
