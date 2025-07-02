Esse é o início do projeto destinado a criar a integração das rotas de Ônibus de Santa Cruz do Sul em um aplicativo, para o projeto da disciplina de Fábrica de Software.

## Segurança da chave da API do Google Maps

**Atenção:** Nunca faça commit do arquivo `AndroidManifest.xml` contendo a chave real da API do Google Maps.

### Como usar a chave de API de forma segura

1. **Armazene sua chave no arquivo `.env`**  
   Exemplo de conteúdo do arquivo `.env` (não versionado):
   ```
   GOOGLE_MAPS_API_KEY=sua_chave_aqui
   ```

2. **Atualize o `AndroidManifest.xml` antes de rodar o app**  
   Execute o comando abaixo para copiar a chave do `.env` para o `AndroidManifest.xml`:
   ```
   dart tools/update_manifest.dart
   ```

3. **Após rodar o app, restaure o placeholder**  
   Antes de fazer commit, sempre volte o valor da chave no `AndroidManifest.xml` para o placeholder, por exemplo:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="SUA_CHAVE_AQUI" />
   ```
   Isso evita que a chave real seja publicada no repositório.

4. **Nunca faça commit do arquivo `AndroidManifest.xml` com a chave real!**
