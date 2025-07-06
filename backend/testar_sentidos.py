from database.db import PostgresDB

# Teste do método get_linhas para verificar se os sentidos estão corretos
db = PostgresDB()
linhas = db.get_linhas()

print("Linhas e sentidos encontrados:")
for linha in linhas[:10]:  # Mostrar apenas os primeiros 10
    print(f"  ID: {linha['id']}, Nome: {linha['nome']}, Sentido: '{linha['sentido']}'")
