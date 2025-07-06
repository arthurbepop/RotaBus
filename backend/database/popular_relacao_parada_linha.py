import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import psycopg
import json
from config import DATABASE_CONFIG

# Exemplo: popular a tabela parada_linha a partir dos dados já existentes
# (ajuste conforme sua estrutura real)

# Lê as paradas para obter os ids
conn = psycopg.connect(**DATABASE_CONFIG)
cur = conn.cursor()
cur.execute('SELECT id, estacao FROM paradas_coords')
paradas = {row[1]: row[0] for row in cur.fetchall()}

# Exemplo: para cada linha, associar manualmente algumas paradas e horários
# (na prática, você pode automatizar ou importar de outro lugar)
linhas = [
    {"linha_id": "01", "paradas": [
        {"estacao": "Terminal Central", "horarios": ["07:00", "13:00", "18:30"]},
        {"estacao": "UNISC", "horarios": ["07:10", "13:10", "18:40"]}
    ]},
    {"linha_id": "02", "paradas": [
        {"estacao": "Terminal Central", "horarios": ["08:00", "14:00", "19:30"]},
        {"estacao": "Shopping Santa Cruz", "horarios": ["08:15", "14:15", "19:45"]}
    ]}
]

for linha in linhas:
    for parada in linha["paradas"]:
        parada_id = paradas.get(parada["estacao"])
        if not parada_id:
            continue
        for horario in parada["horarios"]:
            cur.execute(
                'INSERT INTO parada_linha (parada_id, linha_id, horario) VALUES (%s, %s, %s)',
                (parada_id, linha["linha_id"], horario)
            )

conn.commit()
cur.close()
conn.close()
print('Tabela parada_linha populada com exemplos.')
