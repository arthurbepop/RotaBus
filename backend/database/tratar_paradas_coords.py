import json
import unicodedata

def normalizar_nome(nome):
    # Remove acentos, espaços extras e padroniza para título
    nome = unicodedata.normalize('NFKD', nome).encode('ASCII', 'ignore').decode('ASCII')
    nome = ' '.join(nome.strip().split())
    return nome.title()

def coordenada_invalida(lat, lng):
    # Adicione outros pares inválidos conforme necessário
    lat = round(float(lat), 7)
    lng = round(float(lng), 7)
    if (lat, lng) == (-29.7144977, -52.4293936):
        return True
    return False

with open('paradas_com_coords.json', 'r', encoding='utf-8') as f:
    paradas = json.load(f)

tratadas = {}
for parada in paradas:
    nome = parada.get('estacao') or parada.get('nome')
    lat = parada.get('lat')
    lng = parada.get('lng')
    if not nome or lat is None or lng is None:
        continue
    if coordenada_invalida(lat, lng):
        continue
    nome_norm = normalizar_nome(nome)
    key = (nome_norm, round(float(lat), 6), round(float(lng), 6))
    if key not in tratadas:
        tratadas[key] = {
            'estacao': nome_norm,
            'lat': float(lat),
            'lng': float(lng)
        }

# Salva o resultado tratado
with open('paradas_com_coords_tratadas.json', 'w', encoding='utf-8') as f:
    json.dump(list(tratadas.values()), f, ensure_ascii=False, indent=2)

print(f"Total de paradas tratadas: {len(tratadas)}")
