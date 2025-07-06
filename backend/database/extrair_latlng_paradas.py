import json
import requests
import time

API_KEY = 'AIzaSyCOWu0MT0lWGlcyjMSVNNhQs1JUWcffz8I'  # Sua chave Google
CIDADE = 'Santa Cruz do Sul, RS'

# Carrega todas as paradas únicas extraídas do banco
with open('todas_paradas.json', 'r', encoding='utf-8') as f:
    paradas = json.load(f)

paradas_com_coords = []

for parada in paradas:
    endereco = parada.get('estacao')
    if not endereco:
        continue
    query = f"{endereco}, {CIDADE}"
    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={requests.utils.quote(query)}&key={API_KEY}"
    resp = requests.get(url)
    data = resp.json()
    if data['results']:
        location = data['results'][0]['geometry']['location']
        parada['lat'] = location['lat']
        parada['lng'] = location['lng']
        print(f"OK: {endereco} -> {location['lat']}, {location['lng']}")
    else:
        parada['lat'] = None
        parada['lng'] = None
        print(f"ERRO: {endereco}")
    paradas_com_coords.append(parada)
    time.sleep(0.2)  # Evita limite da API

# Salva o resultado, removendo as paradas com coordenadas inválidas
paradas_filtradas = [p for p in paradas_com_coords if not (p.get('lat') == -29.7144977 and p.get('lng') == -52.4293936)]

with open('paradas_com_coords.json', 'w', encoding='utf-8') as f:
    json.dump(paradas_filtradas, f, ensure_ascii=False, indent=2)

print(f'Finalizado! Paradas salvas: {len(paradas_filtradas)}')
