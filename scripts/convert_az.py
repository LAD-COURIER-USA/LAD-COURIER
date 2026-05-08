import duckdb
import os

db_path = 'scripts/data/geodata-AZ.parquet'
csv_output = 'scripts/data/geodata-AZ-final.csv'

def main():
    if not os.path.exists(db_path):
        print(f"❌ Error: No se encuentra el archivo {db_path}")
        return

    print("🚀 Iniciando purificación y conversión de ARIZONA...")
    print("🌪️ MODO ASPIRADORA ACTIVADO (Sin filtros de categoría)\nFiltro geográfico: Estricto (Solo locales dentro de Arizona).")

    try:
        con = duckdb.connect()
        con.execute("INSTALL spatial; LOAD spatial;")

        sql = f"""
        COPY (
            SELECT 
                id AS place_id,
                UPPER(json_extract_string(CAST(names AS JSON), '$.primary')) AS name,
                COALESCE(json_extract_string(CAST(brand AS JSON), '$.names.primary'), '') AS brand,
                COALESCE(
                    json_extract_string(CAST(categories AS JSON), '$.main'), 
                    json_extract_string(CAST(categories AS JSON), '$.alternate[0]')
                ) AS basic_category,
                COALESCE(
                    json_extract_string(CAST(categories AS JSON), '$.main'), 
                    json_extract_string(CAST(categories AS JSON), '$.alternate[0]')
                ) AS category,
                CAST(categories.alternate AS VARCHAR) AS alternate_categories,
                COALESCE(
                    json_extract_string(CAST(addresses AS JSON), '$[0].freeform'),
                    json_extract_string(CAST(addresses AS JSON), '$[0].street'),
                    'No Address'
                ) AS address,
                UPPER(COALESCE(
                    json_extract_string(CAST(addresses AS JSON), '$[0].locality'), 
                    'ARIZONA'
                )) AS city,
                json_extract_string(CAST(addresses AS JSON), '$[0].region') AS state,
                json_extract_string(CAST(addresses AS JSON), '$[0].postcode') AS zipcode,
                'US' AS country,
                ST_Y(geometry) AS lat,
                ST_X(geometry) AS lon,
                CAST(websites AS VARCHAR) AS websites,
                CAST(phones AS VARCHAR) AS phones,
                '[]' AS facebook,
                'open' AS operating_status,
                1 AS location_count,
                'Arizona' AS market_name,
                CAST(emails AS VARCHAR) AS extracted_emails,
                '[]' AS extracted_instagram,
                strftime(now(), '%Y-%m-%dT%H:%M:%S.%f+00:00') AS extracted_at
            FROM read_parquet('{db_path}')
            WHERE 
                -- Filtro Geográfico para Arizona (AZ)
                (
                    json_extract_string(CAST(addresses AS JSON), '$[0].region') IN ('US-AZ', 'AZ')
                )
                AND 
                -- Filtro de Categorías Logísticas
                (
                    json_extract_string(CAST(categories AS JSON), '$.main') IN ('shopping', 'food_and_drink', 'restaurant', 'grocery_store', 'professional_services', 'public_service', 'health_and_medical', 'automotive', 'accommodation', 'beauty_and_personal_care') OR
                    json_extract_string(CAST(categories AS JSON), '$.alternate[0]') IN ('shopping', 'food_and_drink', 'restaurant', 'grocery_store', 'professional_services', 'public_service', 'health_and_medical', 'automotive', 'accommodation', 'beauty_and_personal_care')
                )
        ) TO '{csv_output}' (FORMAT CSV, HEADER);
        """

        con.execute(sql)
        print(f"✅ ¡Éxito! Arizona ha sido purificada. Archivo creado en: {csv_output}")
        
    except Exception as e:
        print(f"❌ Error durante la conversión: {e}")

if __name__ == "__main__":
    main()
