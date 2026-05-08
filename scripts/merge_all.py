import duckdb
import os
import glob
import time

def main():
    data_dir = 'scripts/data'
    output_file = os.path.join(data_dir, 'MASTER_GEODATA_TOTAL.csv')
    
    # Buscar todos los archivos CSV finales
    csv_files = glob.glob(os.path.join(data_dir, '*-final.csv'))
    
    if not csv_files:
        print("❌ No se encontraron archivos CSV finales para unir.")
        return

    print(f"📂 Encontrados {len(csv_files)} archivos para unir.")
    print("🚀 Iniciando el Gran Merge Final... Esto puede tardar unos segundos.")
    
    start_time = time.time()
    
    try:
        con = duckdb.connect()
        
        # Unir todos los CSVs en un solo comando COPY
        # Usamos union_by_name por si acaso hay pequeñas variaciones, aunque no debería
        sql = f"""
        COPY (
            SELECT * FROM read_csv_auto('{data_dir}/*-final.csv', union_by_name=True)
        ) TO '{output_file}' (FORMAT CSV, HEADER);
        """
        
        con.execute(sql)
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Obtener el conteo total de registros
        total_rows = con.execute(f"SELECT COUNT(*) FROM read_csv_auto('{output_file}')").fetchone()[0]
        
        print("\n" + "="*50)
        print("🏆 ¡MISIÓN CUMPLIDA! EL GRAN MAESTRO HA SIDO CREADO 🏆")
        print("="*50)
        print(f"✅ Archivo: {output_file}")
        print(f"📊 Total de registros: {total_rows:,}")
        print(f"⏱️  Tiempo de procesamiento: {duration:.2f} segundos")
        print("="*50)
        print("\n🔥 Tu base de datos logística 360° está lista para la acción.")
        
    except Exception as e:
        print(f"❌ Error durante la unión: {e}")

if __name__ == "__main__":
    main()
