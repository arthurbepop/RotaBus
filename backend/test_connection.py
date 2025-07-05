#!/usr/bin/env python3
"""
Script de teste para verificar a conexão com o banco de dados.
Execute este script antes de testar a API para garantir que tudo está funcionando.
"""

import sys
import os
sys.path.append(os.path.dirname(__file__))

try:
    import psycopg
    print("✅ Biblioteca psycopg instalada")
except ImportError:
    print("❌ Biblioteca psycopg não instalada")
    print("🔧 Execute: pip install psycopg[binary]")
    sys.exit(1)

# Configurações do banco - AJUSTE AQUI
DATABASE_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "RotaBus",  # SUBSTITUA pelo nome do seu banco
    "user": "postgres",      # SUBSTITUA pelo seu usuário
    "password": "12345"      # SUBSTITUA pela sua senha
}

def test_connection():
    """Testa a conexão com o banco de dados"""
    try:
        print("🔄 Tentando conectar ao banco...")
        conn = psycopg.connect(**DATABASE_CONFIG)
        print("✅ Conexão com banco estabelecida com sucesso!")
        
        # Testa uma query simples
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            version = cur.fetchone()[0]
            print(f"📊 Versão do PostgreSQL: {version}")
        
        # Lista as tabelas
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name LIKE 'horarios_%'
                LIMIT 5
            """)
            tables = cur.fetchall()
            print(f"📋 Encontradas {len(tables)} tabelas de horários")
            for table in tables:
                print(f"   - {table[0]}")
        
        conn.close()
        print("✅ Teste de conexão concluído com sucesso!")
        return True
        
    except Exception as e:
        print(f"❌ Erro na conexão: {e}")
        print("\n🔧 Dicas para resolver:")
        print("1. Verifique se o PostgreSQL está rodando")
        print("2. Confirme as credenciais (usuário, senha, banco)")
        print("3. Verifique se o PgAdmin consegue conectar")
        return False

if __name__ == "__main__":
    print("=== TESTE DE CONEXÃO COM BANCO ===")
    if test_connection():
        print("\n🚀 Pronto para testar a API!")
    else:
        print("\n⚠️  Configure o banco antes de continuar")