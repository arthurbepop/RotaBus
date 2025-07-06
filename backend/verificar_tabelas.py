import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database.db import PostgresDB
import psycopg.rows

db = PostgresDB()
cur = db.conn.cursor(row_factory=psycopg.rows.dict_row)
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'horarios_%' AND table_schema = 'public' ORDER BY table_name LIMIT 15")
tables = [row['table_name'] for row in cur.fetchall()]
print("Tabelas de horários encontradas:")
for table in tables:
    print(f"  {table}")
    # Extrair o sentido da forma atual
    parts = table.split('_')
    if len(parts) >= 3:
        sentido_atual = parts[-1]
        sentido_completo = '_'.join(parts[2:])  # Tudo após 'horarios_CODIGO_'
        print(f"    Sentido atual: '{sentido_atual}' -> Deveria ser: '{sentido_completo}'")
