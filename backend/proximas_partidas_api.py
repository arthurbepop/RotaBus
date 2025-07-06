from flask import Flask, jsonify, request
import psycopg
import re
from backend.database.config import DATABASE_CONFIG

app = Flask(__name__)

def get_tabelas_horarios(conn):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_name LIKE 'horarios_%' AND table_schema = 'public'
        """)
        return [row[0] for row in cur.fetchall()]

def buscar_proximas_partidas(estacao, hora_atual):
    conn = psycopg.connect(**DATABASE_CONFIG)
    tabelas = get_tabelas_horarios(conn)
    partidas = []
    for tabela in tabelas:
        with conn.cursor() as cur:
            cur.execute(f"SELECT * FROM {tabela} WHERE estacao = %s", (estacao,))
            colnames = [desc[0] for desc in cur.description]
            for row in cur.fetchall():
                linha = row[colnames.index('onibus/linha')] if 'onibus/linha' in colnames else None
                sentido = row[colnames.index('sentido')] if 'sentido' in colnames else None
                # Pega todas as colunas de partida
                for col in colnames:
                    if col.startswith('partida'):
                        valor = row[colnames.index(col)]
                        if valor and valor > hora_atual:
                            partidas.append({
                                'linha': linha,
                                'sentido': sentido,
                                'horario': valor,
                                'tabela': tabela
                            })
    conn.close()
    # Ordena por horário
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
    app.run(debug=True)
