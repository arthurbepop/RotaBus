# backend/database/db.py
import os
import re
import urllib.parse as up
import pandas as pd  # se você usa DataFrame para tipagem/IDE
import psycopg
from psycopg import sql
from psycopg.rows import dict_row
from backend.config import DATABASE_CONFIG


def _slug(txt: str) -> str:
    """
    Converte um texto arbitrário em slug: minúsculo, ASCII, separado por "_".
    Ex.: "Av. São João (Centro)" -> "av_sao_joao_centro"
    """
    txt = (
        txt.lower()
        .replace("ç", "c")
        .encode("ascii", "ignore")
        .decode()
    )
    return re.sub(r"[^a-z0-9]+", "_", txt).strip("_")


class PostgresDB:
    """
    Cada combinação (linha, sentido) grava em uma tabela:
        horarios_<linha>_<slug_sentido>

    Colunas fixas:
        id (SERIAL PK), onibus, sentido, estacao

    As colunas partida1..N são criadas dinamicamente conforme
    o DataFrame recebido em `save_schedule`.
    """

    def __init__(self):
        """
        dsn pode ser:
        - URL:  postgresql://user:pass@host:5432/dbname
        - DSN:  dbname=... user=... host=...
        - None: lê da variável de ambiente DATABASE_URL.
        """
        try:
            # Estabelece conexão com PostgreSQL usando configurações
            self.conn = psycopg.connect(**DATABASE_CONFIG)
            print("✅ Conexão com banco estabelecida com sucesso!")
        except Exception as e:
            print(f"❌ Erro ao conectar com o banco: {e}")
            print("🔧 Verifique as credenciais em backend/config.py")
            raise

    # ---------- helpers internos ---------- #

    def _ensure_table(self, table: str, n_partidas: int) -> None:
        """
        Cria a tabela se não existir e garante colunas partida1..N.
        """
        with self.conn.cursor() as cur:
            cur.execute(
                f"""
                CREATE TABLE IF NOT EXISTS {table} (
                    id       SERIAL PRIMARY KEY,
                    onibus   TEXT,
                    sentido  TEXT,
                    estacao  TEXT
                );
                """
            )

            # Colunas 'partida%' já existentes
            cur.execute(
                """
                SELECT column_name
                FROM   information_schema.columns
                WHERE  table_name = %s
                  AND  column_name LIKE 'partida%%';
                """,
                (table,),
            )
            existentes = {r[0] for r in cur.fetchall()}

            # Adiciona as que faltam
            for i in range(1, n_partidas + 1):
                col = f"partida{i}"
                if col not in existentes:
                    cur.execute(f'ALTER TABLE {table} ADD COLUMN {col} TEXT;')

    # ---------- API pública ---------- #

    def save_schedule(self, linha: str, sentido: str, df: "pd.DataFrame") -> None:
        """
        Persiste o DataFrame `df` na tabela específica de (linha, sentido).
        Se já existir conteúdo, ele é truncado.

        Parâmetros
        ----------
        linha : str
            Identificador / nome do ônibus.
        sentido : str
            Sentido (ex.: "Centro", "Bairro").
        df : pandas.DataFrame
            Deve conter a coluna "Estação" e colunas "partida1", "partida2", …
        """
        tabela = f"horarios_{_slug(linha)}_{_slug(sentido)}"

        # todas as colunas partidaN presentes ordenadas numericamente
        partida_cols = sorted(
            [c for c in df.columns if c.lower().startswith("partida")],
            key=lambda x: int(re.search(r"\d+", x).group()),
        )

        # cria/atualiza a estrutura da tabela
        self._ensure_table(tabela, len(partida_cols))

        # transforma o DataFrame em lista de tuplas na ordem das colunas-alvo
        registros = [
            (
                linha,
                sentido,
                row["Estação"],
                *[row.get(c) or None for c in partida_cols],
            )
            for _, row in df.iterrows()
        ]

        col_names = ["onibus", "sentido", "estacao"] + partida_cols
        placeholders = "(" + ", ".join(["%s"] * len(col_names)) + ")"

        from psycopg import sql  # import local para evitar custo se método não for usado

        with self.conn.cursor() as cur:
            # limpa tabela
            cur.execute(sql.SQL("TRUNCATE {}").format(sql.Identifier(tabela)))

            # insere em lote com executemany (psycopg3 já otimiza internamente)
            cur.executemany(
                f"INSERT INTO {tabela} ({', '.join(col_names)}) VALUES {placeholders}",
                registros,
            )

        print(
            f"✔ Gravado {len(df)} estações na tabela '{tabela}' "
            f"(ônibus={linha}, sentido='{sentido}')."
        )

    def get_linhas(self):
        """Retorna lista de todas as linhas de ônibus e sentidos"""
        try:
            with self.conn.cursor(row_factory=dict_row) as cur:
                # Busca linhas e sentidos únicos das tabelas de horários
                cur.execute("""
                    SELECT DISTINCT 
                        SUBSTRING(table_name FROM 'horarios_([^_]+)_.*') as codigo,
                        SUBSTRING(table_name FROM 'horarios_([^_]+)_.*') as nome,
                        SUBSTRING(table_name FROM 'horarios_[^_]+_(.*)') as sentido
                    FROM information_schema.tables 
                    WHERE table_name LIKE 'horarios_%'
                    AND table_schema = 'public'
                    ORDER BY codigo, sentido
                """)
                results = cur.fetchall()
                return [
                    {
                        'id': row['codigo'],
                        'nome': f"Linha {row['codigo']}",
                        'sentido': row['sentido'].replace('_', ' ') if row['sentido'] else ''
                    } for row in results
                ]
        except Exception as e:
            print(f"Erro ao buscar linhas: {e}")
            return []

    def get_paradas(self, codigo):
        """Retorna paradas de uma linha específica (todos os sentidos) com coordenadas"""
        try:
            with self.conn.cursor(row_factory=dict_row) as cur:
                # Busca todas as tabelas de horários dessa linha
                cur.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_name LIKE %s AND table_schema = 'public'
                """, (f'horarios_{codigo}_%',))
                tables = cur.fetchall()
                paradas_nomes = set()
                
                # Coleta todos os nomes únicos de estações
                for table in tables:
                    table_name = table["table_name"]
                    cur.execute(f'SELECT DISTINCT estacao FROM {table_name} WHERE estacao IS NOT NULL AND estacao != \'\'')
                    rows = cur.fetchall()
                    for row in rows:
                        estacao = row['estacao']
                        # Filtrar entradas que não são nomes de estações válidos (como horários)
                        if estacao and len(estacao) > 3 and not estacao.replace(':', '').replace('-', '').isdigit():
                            paradas_nomes.add(estacao)
                
                # Busca coordenadas para cada parada
                paradas_com_coords = []
                for nome in sorted(paradas_nomes):
                    cur.execute("""
                        SELECT estacao, lat, lng FROM paradas_coords 
                        WHERE estacao = %s AND lat IS NOT NULL AND lng IS NOT NULL
                    """, (nome,))
                    coord_result = cur.fetchone()
                    if coord_result:
                        paradas_com_coords.append({
                            'nome': coord_result['estacao'],
                            'lat': float(coord_result['lat']),
                            'lng': float(coord_result['lng'])
                        })
                    else:
                        # Se não tem coordenadas, inclui só o nome
                        paradas_com_coords.append({'nome': nome})
                
                return paradas_com_coords
        except Exception as e:
            print(f"Erro ao buscar paradas: {e}")
            return []

    def get_horarios(self, codigo):
        """Retorna horários de uma linha específica (todos os sentidos)"""
        try:
            with self.conn.cursor(row_factory=dict_row) as cur:
                cur.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_name LIKE %s AND table_schema = 'public'
                """, (f'horarios_{codigo}_%',))
                tables = cur.fetchall()
                all_horarios = []
                for table in tables:
                    # Extrair sentido completo: tudo após 'horarios_CODIGO_'
                    table_name = table['table_name']
                    sentido = '_'.join(table_name.split('_')[2:])  # Pega tudo após os dois primeiros underscores
                    cur.execute(f'SELECT * FROM {table["table_name"]}')
                    rows = cur.fetchall()
                    for row in rows:
                        horario_data = dict(row)
                        horario_data['sentido'] = sentido
                        all_horarios.append(horario_data)
                return all_horarios
        except Exception as e:
            print(f"Erro ao buscar horários: {e}")
            return []

