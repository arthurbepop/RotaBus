from flask import Flask, jsonify, request
import os
import json
from backend.database.db import PostgresDB

app = Flask(__name__)
db = PostgresDB()

@app.route('/linhas', methods=['GET'])
def get_linhas():
    # Exemplo: SELECT DISTINCT codigo, nome FROM linhas (ajuste conforme seu schema)
    linhas = db.get_linhas()  # Implemente esse método no db.py
    return jsonify(linhas)

@app.route('/linhas/<codigo>/paradas', methods=['GET'])
def get_paradas(codigo):
    # Exemplo: SELECT * FROM paradas WHERE linha_codigo = codigo
    paradas = db.get_paradas(codigo)  # Implemente esse método no db.py
    return jsonify(paradas)

@app.route('/linhas/<codigo>/horarios', methods=['GET'])
def get_horarios(codigo):
    # Exemplo: SELECT * FROM horarios WHERE linha_codigo = codigo
    horarios = db.get_horarios(codigo)  # Implemente esse método no db.py
    return jsonify(horarios)

@app.route('/paradas', methods=['GET'])
def get_all_paradas():
    # Lê o arquivo tratado com as paradas e coordenadas
    path = os.path.join(os.path.dirname(__file__), 'database', 'paradas_com_coords_tratadas.json')
    with open(path, 'r', encoding='utf-8') as f:
        paradas = json.load(f)
    # Filtra apenas as que têm lat/lng
    paradas = [p for p in paradas if p.get('lat') and p.get('lng')]
    return jsonify(paradas)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
