import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import psycopg
import json
from config import DATABASE_CONFIG

# Lê o arquivo de coordenadas tratadas
table_file = 'paradas_com_coords_tratadas.json'
if not os.path.exists(table_file):
    table_file = 'paradas_com_coords.json'

with open(table_file, 'r', encoding='utf-8') as f:
    paradas = json.load(f)

conn = psycopg.connect(**DATABASE_CONFIG)
cur = conn.cursor()

# Cria a tabela se não existir
cur.execute('''
    CREATE TABLE IF NOT EXISTS paradas_coords (
        id SERIAL PRIMARY KEY,
        estacao TEXT UNIQUE,
        lat DOUBLE PRECISION,
        lng DOUBLE PRECISION
    )
''')

# Insere ou atualiza as paradas
for parada in paradas:
    nome = parada.get('estacao') or parada.get('nome')
    lat = parada.get('lat')
    lng = parada.get('lng')
    if not nome or lat is None or lng is None:
        continue
    cur.execute('''
        INSERT INTO paradas_coords (estacao, lat, lng)
        VALUES (%s, %s, %s)
        ON CONFLICT (estacao) DO UPDATE SET lat = EXCLUDED.lat, lng = EXCLUDED.lng
    ''', (nome, float(lat), float(lng)))

conn.commit()
cur.close()
conn.close()
print('Paradas salvas/atualizadas na tabela paradas_coords.')
