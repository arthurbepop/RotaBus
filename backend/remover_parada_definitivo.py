#!/usr/bin/env python3
"""
Script para remover definitivamente uma parada específica
"""
import sys
sys.path.append('.')
from backend.database.db import PostgresDB
import psycopg
from psycopg.rows import dict_row

def remover_parada_definitivo(estacao_nome):
    """Remove uma parada específica definitivamente"""
    try:
        db = PostgresDB()
        
        with db.conn.cursor() as cur:
            print(f"Removendo '{estacao_nome}' definitivamente...")
            
            # 1. Remover da tabela paradas_coords usando o nome exato
            print("1. Removendo de paradas_coords...")
            cur.execute("DELETE FROM paradas_coords WHERE estacao = %s", (estacao_nome,))
            removed_coords = cur.rowcount
            print(f"   {removed_coords} registros removidos")
            
            # 2. Buscar e remover de todas as tabelas de horários
            print("2. Buscando tabelas de horários...")
            cur.execute("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
            """)
            tables = cur.fetchall()
            print(f"   Encontradas {len(tables)} tabelas de horários")
            
            total_removed_horarios = 0
            for table in tables:
                table_name = table[0]
                print(f"   Verificando tabela {table_name}...")
                cur.execute(f"DELETE FROM {table_name} WHERE estacao = %s", (estacao_nome,))
                removed = cur.rowcount
                if removed > 0:
                    print(f"     {removed} registros removidos")
                    total_removed_horarios += removed
            
            # Confirmar as alterações
            print("3. Confirmando alterações...")
            db.conn.commit()
            
            print(f"\n✅ Parada '{estacao_nome}' removida definitivamente!")
            print(f"   Registros removidos de paradas_coords: {removed_coords}")
            print(f"   Registros removidos de tabelas de horários: {total_removed_horarios}")
            
            # Verificar se realmente foi removida
            print("\n4. Verificando remoção...")
            cur.execute("SELECT COUNT(*) FROM paradas_coords WHERE estacao = %s", (estacao_nome,))
            count = cur.fetchone()[0]
            if count == 0:
                print("   ✅ Parada não encontrada em paradas_coords - removida com sucesso!")
            else:
                print(f"   ❌ Ainda existem {count} registros em paradas_coords")
                
    except Exception as e:
        print(f"❌ Erro ao remover parada: {e}")
        if 'db' in locals():
            db.conn.rollback()

if __name__ == "__main__":
    estacao = "Rsc-471,578-726"
    print(f"Iniciando remoção definitiva da parada: {estacao}")
    remover_parada_definitivo(estacao)
