from flask import Flask, jsonify, request
import os
import json
from backend.database.db import PostgresDB
import psycopg
from backend.config import DATABASE_CONFIG
import difflib

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
            cur.execute('SELECT id, estacao, lat, lng FROM paradas_coords WHERE lat IS NOT NULL AND lng IS NOT NULL')
            results = cur.fetchall()
            paradas = [
                {'id': row[0], 'estacao': row[1], 'lat': float(row[2]), 'lng': float(row[3])}
                for row in results
            ]
        return jsonify(paradas)
    except Exception as e:
        return jsonify({'erro': str(e)}), 500

@app.route('/paradas/<int:parada_id>/linhas', methods=['GET'])
def get_linhas_por_parada(parada_id):
    try:
        with db.conn.cursor() as cur:
            cur.execute('''
                SELECT linha_id, horario FROM parada_linha
                WHERE parada_id = %s
                ORDER BY horario
            ''', (parada_id,))
            results = cur.fetchall()
            linhas = {}
            for row in results:
                linha = row[0]
                horario = str(row[1])
                if linha not in linhas:
                    linhas[linha] = []
                linhas[linha].append(horario)
            # Retorna lista de linhas com horários
            return jsonify([
                {"linha_id": linha, "horarios": horarios}
                for linha, horarios in linhas.items()
            ])
    except Exception as e:
        return jsonify({'erro': str(e)}), 500

def get_tabelas_horarios(conn):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
        """)
        return [row[0] for row in cur.fetchall()]

def hora_em_minutos(hora_str):
    try:
        if not hora_str or not isinstance(hora_str, str):
            return None
        partes = hora_str.strip().split(':')
        if len(partes) != 2:
            return None
        h, m = map(int, partes)
        return h * 60 + m
    except Exception:
        return None

def buscar_proximas_partidas(estacao, hora_atual):
    conn = psycopg.connect(**DATABASE_CONFIG)
    tabelas = get_tabelas_horarios(conn)
    partidas = []
    minutos_atual = hora_em_minutos(hora_atual)
    minutos_inicio = (minutos_atual - 30) % (24*60)
    minutos_fim = (minutos_atual + 30) % (24*60)
    estacao_normalizada = estacao.strip().lower()
    # Coletar todas as estações possíveis
    todas_estacoes = set()
    for tabela in tabelas:
        with conn.cursor() as cur:
            cur.execute(f"SELECT DISTINCT estacao FROM {tabela} WHERE estacao IS NOT NULL")
            todas_estacoes.update([str(row[0]).strip().lower() for row in cur.fetchall()])
    # Buscar a estação mais próxima
    estacao_mais_proxima = difflib.get_close_matches(estacao_normalizada, todas_estacoes, n=1, cutoff=0.6)
    if not estacao_mais_proxima:
        conn.close()
        return []
    estacao_alvo = estacao_mais_proxima[0]
    for tabela in tabelas:
        with conn.cursor() as cur:
            cur.execute(f"SELECT * FROM {tabela}")
            colnames = [desc[0] for desc in cur.description]
            for row in cur.fetchall():
                estacao_row = str(row[colnames.index('estacao')]).strip().lower() if 'estacao' in colnames else ''
                if estacao_row != estacao_alvo:
                    continue
                linha = row[colnames.index('onibus')] if 'onibus' in colnames else None
                sentido = row[colnames.index('sentido')] if 'sentido' in colnames else None
                for col in colnames:
                    if col.startswith('partida'):
                        valor = row[colnames.index(col)]
                        minutos_partida = hora_em_minutos(valor)
                        if minutos_partida is None:
                            continue
                        if minutos_inicio < minutos_fim:
                            dentro = minutos_inicio <= minutos_partida <= minutos_fim
                        else:
                            dentro = minutos_partida >= minutos_inicio or minutos_partida <= minutos_fim
                        if dentro:
                            partidas.append({
                                'linha': linha,
                                'sentido': sentido,
                                'horario': valor,
                                'tabela': tabela
                            })
    conn.close()
    partidas.sort(key=lambda x: x['horario'])
    return partidas

@app.route('/paradas/<estacao>/proximas_partidas')
def proximas_partidas(estacao):
    hora = request.args.get('hora')
    if not hora:
        return jsonify({'erro': 'Informe o parâmetro hora=HH:MM'}), 400
    partidas = buscar_proximas_partidas(estacao, hora)
    return jsonify(partidas)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
