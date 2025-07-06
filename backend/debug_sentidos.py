from database.db import PostgresDB
import psycopg.rows

# Teste para entender por que poucos sentidos são encontrados
db = PostgresDB()

# Primeiro, vamos ver todas as tabelas de horários
with db.conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
    cur.execute("""
        SELECT table_name FROM information_schema.tables 
        WHERE table_name LIKE 'horarios_%' 
        AND table_schema = 'public' 
        ORDER BY table_name
    """)
    all_tables = cur.fetchall()
    
    print(f"Total de tabelas de horários encontradas: {len(all_tables)}")
    print("\nPrimeiras 20 tabelas:")
    for i, table in enumerate(all_tables[:20]):
        table_name = table['table_name']
        print(f"  {i+1}. {table_name}")
        
        # Analisar como extrair sentido
        parts = table_name.split('_')
        if len(parts) >= 3:
            codigo = parts[1]
            sentido_completo = '_'.join(parts[2:])
            print(f"     -> Código: '{codigo}', Sentido: '{sentido_completo}'")
    
    print("\n" + "="*50)
    print("Testando a consulta SQL atual:")
    
    # Testar a consulta SQL modificada
    cur.execute("""
        SELECT DISTINCT 
            SUBSTRING(table_name FROM 'horarios_([^_]+)_.*') as codigo,
            SUBSTRING(table_name FROM 'horarios_[^_]+_(.*)') as sentido,
            table_name
        FROM information_schema.tables 
        WHERE table_name LIKE 'horarios_%'
        AND table_schema = 'public'
        ORDER BY codigo, sentido
    """)
    
    results = cur.fetchall()
    print(f"\nResultados da consulta SQL: {len(results)} linhas")
    for i, row in enumerate(results[:15]):
        print(f"  {i+1}. Código: '{row['codigo']}', Sentido: '{row['sentido']}', Tabela: '{row['table_name']}'")
