import sys
import os
import random
from datetime import time, timedelta, datetime
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import psycopg
from config import DATABASE_CONFIG

# Configurações
NUM_PARADAS = 5  # Quantas paradas associar
LINHAS = ["01", "02"]  # Linhas fictícias
HORARIOS_POR_PARADA = 3  # Quantos horários por parada/linha

# Gera horários aleatórios (exemplo entre 06:00 e 22:00)
def gerar_horarios(qtd):
    horarios = set()
    while len(horarios) < qtd:
        hora = random.randint(6, 21)
        minuto = random.choice([0, 10, 20, 30, 40, 50])
        horarios.add(f"{hora:02d}:{minuto:02d}")
    return sorted(horarios)

conn = psycopg.connect(**DATABASE_CONFIG)
cur = conn.cursor()

# Seleciona as primeiras paradas
cur.execute('SELECT id, estacao FROM paradas_coords ORDER BY id LIMIT %s', (NUM_PARADAS,))
paradas = cur.fetchall()

for parada_id, estacao in paradas:
    for linha_id in LINHAS:
        horarios = gerar_horarios(HORARIOS_POR_PARADA)
        for horario in horarios:
            cur.execute(
                'INSERT INTO parada_linha (parada_id, linha_id, horario) VALUES (%s, %s, %s)',
                (parada_id, linha_id, horario)
            )
        print(f"Associada parada '{estacao}' (id={parada_id}) à linha {linha_id} com horários: {horarios}")

conn.commit()
cur.close()
conn.close()
print('Tabela parada_linha populada automaticamente com exemplos reais.')
