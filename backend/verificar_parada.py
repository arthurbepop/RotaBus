#!/usr/bin/env python3
"""
Script para verificar se a parada foi realmente removida do banco
"""
import sys
sys.path.append('.')
from backend.database.db import PostgresDB
import psycopg
from psycopg.rows import dict_row

def verificar_parada(estacao_nome):
    """Verifica se a parada ainda existe no banco"""
    try:
        db = PostgresDB()
        
        with db.conn.cursor(row_factory=dict_row) as cur:
            # Verificar na tabela paradas_coords
            cur.execute("SELECT * FROM paradas_coords WHERE estacao = %s", (estacao_nome,))
            coords_result = cur.fetchall()
            print(f"Registros em paradas_coords: {len(coords_result)}")
            for row in coords_result:
                print(f"  {dict(row)}")
            
            # Verificar na tabela paradas_coords com LIKE para variações
            cur.execute("SELECT * FROM paradas_coords WHERE estacao LIKE %s", (f"%{estacao_nome}%",))
            coords_like = cur.fetchall()
            print(f"\nRegistros similares em paradas_coords: {len(coords_like)}")
            for row in coords_like:
                print(f"  {dict(row)}")
                
    except Exception as e:
        print(f"❌ Erro ao verificar parada: {e}")

if __name__ == "__main__":
    estacao = "Rsc-471,578-726"
    print(f"Verificando parada: {estacao}")
    verificar_parada(estacao)
