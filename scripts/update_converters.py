import os
import re

def update_scripts_to_vacuum_mode():
    scripts_dir = 'scripts'
    if not os.path.exists(scripts_dir):
        print("❌ La carpeta scripts no existe.")
        return

    files = [f for f in os.listdir(scripts_dir) if f.startswith('convert_') and f.endswith('.py')]
    
    # Este regex busca todo el bloque del filtro de categorías (desde el AND hasta el final del paréntesis)
    # para eliminarlo y dejar solo el filtro geográfico y que el nombre no sea nulo.
    pattern = r"AND\s+\(\s+json_extract_string\(CAST\(categories AS JSON\), '\$.main'\) IN \(.*?\)\s+OR\s+json_extract_string\(CAST\(categories AS JSON\), '\$.alternate\[0\]'\) IN \(.*?\)\s+\)"
    
    replacement = "AND names IS NOT NULL"

    print(f"🔄 Activando MODO ASPIRADORA 🌪️ en {len(files)} scripts...")

    for filename in files:
        filepath = os.path.join(scripts_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Aplicar el reemplazo (usando flags=re.DOTALL por si hay saltos de línea)
        new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        
        # Actualizar el mensaje de éxito para que el usuario sepa que es la versión masiva
        new_content = new_content.replace(
            "print(\"🚀 COBERTURA TOTAL (UPS, FedEx, Farmacias, etc.)", 
            "print(\"🌪️ MODO ASPIRADORA ACTIVADO (Sin filtros de categoría)"
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"✅ {filename} potenciado al máximo.")

    print("\n✨ ¡Misión cumplida! Todos los scripts ahora aspiran TODOS los locales del mapa.")

if __name__ == "__main__":
    update_scripts_to_vacuum_mode()
