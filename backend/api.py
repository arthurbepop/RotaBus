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
    # Busca direto do banco de dados
    try:
        with db.conn.cursor() as cur:
            cur.execute('SELECT estacao, lat, lng FROM paradas_coords WHERE lat IS NOT NULL AND lng IS NOT NULL')
            results = cur.fetchall()
            paradas = [
                {'estacao': row[0], 'lat': float(row[1]), 'lng': float(row[2])}
                for row in results
            ]
        return jsonify(paradas)
    except Exception as e:
        return jsonify({'erro': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
