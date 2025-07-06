import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config import DATABASE_CONFIG

import psycopg

def get_tabelas_horarios(conn):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
        """)
        return [row[0] for row in cur.fetchall()]

def listar_estacoes():
    conn = psycopg.connect(**DATABASE_CONFIG)
    tabelas = get_tabelas_horarios(conn)
    for tabela in tabelas:
        with conn.cursor() as cur:
            cur.execute(f"SELECT DISTINCT estacao FROM {tabela} WHERE estacao IS NOT NULL")
            estacoes = [row[0] for row in cur.fetchall()]
            print(f"Tabela: {tabela}")
            for estacao in estacoes:
                print(f"  - {estacao}")
    conn.close()

if __name__ == "__main__":
    listar_estacoes()
