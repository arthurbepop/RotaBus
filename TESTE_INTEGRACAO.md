# Guia de Teste da Integração Flutter + Backend

## Passo 1: Configurar o Banco de Dados

1. **Abra o PgAdmin** e anote as informações de conexão:
   - Host: geralmente `localhost`
   - Port: geralmente `5432`
   - Database: nome do banco que você criou
   - User: geralmente `postgres`
   - Password: a senha que você definiu

2. **Edite o arquivo `backend/test_connection.py`** e substitua:
   ```python
   DATABASE_CONFIG = {
       "host": "localhost",
       "port": 5432,
       "database": "SEU_BANCO_AQUI",  # Nome do seu banco
       "user": "SEU_USER_AQUI",       # Seu usuário
       "password": "SUA_SENHA_AQUI"   # Sua senha
   }
   ```

## Passo 2: Instalar Dependências e Testar Conexão

```bash
# Instalar dependências do Python
pip install flask psycopg[binary]

# Testar conexão com o banco
cd backend
python test_connection.py
```

Se aparecer "✅ Teste de conexão concluído com sucesso!", continue para o próximo passo.

## Passo 3: Configurar IP no Flutter

1. **Descubra o IP do seu computador:**
   - Windows: `ipconfig` no cmd
   - Procure por "IPv4 Address" (ex: 192.168.0.10)

2. **Edite `frontend_flutter/lib/servicos/api_linhas.dart`:**
   ```dart
   final String baseUrl = 'http://SEU_IP_AQUI:5000';
   ```

## Passo 4: Rodar o Backend

```bash
cd backend
python api.py
```

Deve aparecer: "Running on http://0.0.0.0:5000"

## Passo 5: Testar a API no Navegador

Abra no navegador: `http://localhost:5000/linhas`

Deve retornar um JSON com as linhas do banco.

## Passo 6: Rodar o App Flutter

```bash
cd frontend_flutter
flutter run
```

## Passo 7: Testar no App

1. Abra o app no emulador/dispositivo
2. Toque em "Linhas de Ônibus"
3. Deve carregar as linhas do banco de dados

## Solução de Problemas

- **Erro de conexão com banco**: Verifique credenciais no `test_connection.py`
- **Erro "No route to host"**: Verifique o IP no `api_linhas.dart`
- **Timeout no app**: Certifique-se de que backend está rodando
- **Lista vazia**: Verifique se há dados nas tabelas do banco