#!/usr/bin/env python3
"""
Script para remover uma parada específica do banco de dados
"""
import sys
sys.path.append('.')
from backend.database.db import PostgresDB
from backend.config import DATABASE_CONFIG
import psycopg

def remover_parada(estacao_nome):
    """Remove uma parada específica das tabelas do banco"""
    try:
        db = PostgresDB()
        
        with db.conn.cursor() as cur:
            # 1. Remover da tabela paradas_coords
            print(f"Removendo '{estacao_nome}' da tabela paradas_coords...")
            cur.execute("DELETE FROM paradas_coords WHERE estacao = %s", (estacao_nome,))
            removed_coords = cur.rowcount
            print(f"  {removed_coords} registros removidos de paradas_coords")
            
            # 2. Buscar e remover de todas as tabelas de horários
            cur.execute("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
            """)
            tables = cur.fetchall()
            
            total_removed_horarios = 0
            for table in tables:
                table_name = table[0]
                cur.execute(f"DELETE FROM {table_name} WHERE estacao = %s", (estacao_nome,))
                removed = cur.rowcount
                if removed > 0:
                    print(f"  {removed} registros removidos de {table_name}")
                    total_removed_horarios += removed
            
            # 3. Remover da tabela parada_linha se existir
            try:
                cur.execute("DELETE FROM parada_linha WHERE estacao = %s", (estacao_nome,))
                removed_parada_linha = cur.rowcount
                if removed_parada_linha > 0:
                    print(f"  {removed_parada_linha} registros removidos de parada_linha")
            except Exception as e:
                print(f"  Tabela parada_linha não encontrada ou erro: {e}")
            
            # Confirmar as alterações
            db.conn.commit()
            
            print(f"\n✅ Parada '{estacao_nome}' removida com sucesso!")
            print(f"   Total de registros removidos: {removed_coords + total_removed_horarios}")
            
    except Exception as e:
        print(f"❌ Erro ao remover parada: {e}")
        if 'db' in locals():
            db.conn.rollback()

if __name__ == "__main__":
    estacao = "Rsc-471,578-726"
    print(f"Removendo parada: {estacao}")
    remover_parada(estacao)
