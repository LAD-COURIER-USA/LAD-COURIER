import duckdb
import os

db_path = 'scripts/data/geodata-GA.parquet'

def main():
    if not os.path.exists(db_path):
        print(f"❌ Error: No se encuentra el archivo {db_path}")
        return

    con = duckdb.connect()
    # Get schema information
    print("--- Column names and types ---")
    res = con.execute(f"DESCRIBE SELECT * FROM read_parquet('{db_path}') LIMIT 0").fetchall()
    for row in res:
        print(row)

    print("\n--- Sample data from addresses ---")
    try:
        sample = con.execute(f"SELECT addresses FROM read_parquet('{db_path}') LIMIT 5").fetchall()
        for s in sample:
            print(s)
    except Exception as e:
        print(f"Error sampling addresses: {e}")

if __name__ == "__main__":
    main()
