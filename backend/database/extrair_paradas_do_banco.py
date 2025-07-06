import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import psycopg
import json
from config import DATABASE_CONFIG

# Conecta ao banco
conn = psycopg.connect(**DATABASE_CONFIG)
cur = conn.cursor()

# Busca todas as tabelas de horários
cur.execute("""
    SELECT table_name FROM information_schema.tables 
    WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
""")
tabelas = [row[0] for row in cur.fetchall()]

paradas_unicas = {}

for tabela in tabelas:
    cur.execute(f'SELECT DISTINCT estacao FROM {tabela} WHERE estacao IS NOT NULL')
    for row in cur.fetchall():
        nome = row[0]
        if nome and nome not in paradas_unicas:
            paradas_unicas[nome] = {"estacao": nome}

cur.close()
conn.close()

# Salva todas as paradas únicas em um arquivo
with open('todas_paradas.json', 'w', encoding='utf-8') as f:
    json.dump(list(paradas_unicas.values()), f, ensure_ascii=False, indent=2)

print(f"Total de paradas únicas extraídas: {len(paradas_unicas)}")
