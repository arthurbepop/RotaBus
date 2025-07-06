import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import psycopg
from config import DATABASE_CONFIG

# Conecta ao banco
def listar_estacoes():
    conn = psycopg.connect(**DATABASE_CONFIG)
    cur = conn.cursor()
    cur.execute('SELECT estacao FROM paradas_coords ORDER BY estacao;')
    estacoes = [row[0] for row in cur.fetchall()]
    cur.close()
    conn.close()
    print('Estações encontradas:')
    for estacao in estacoes:
        print(estacao)

if __name__ == "__main__":
    listar_estacoes()
