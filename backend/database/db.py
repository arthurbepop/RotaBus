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
                        SUBSTRING(table_name FROM 'horarios_([^_]+)_([^_]+)') as codigo,
                        SUBSTRING(table_name FROM 'horarios_([^_]+)_([^_]+)') as nome,
                        SUBSTRING(table_name FROM 'horarios_[^_]+_([^_]+)') as sentido
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
                        'sentido': row['sentido']
                    } for row in results
                ]
        except Exception as e:
            print(f"Erro ao buscar linhas: {e}")
            return []

    def get_paradas(self, codigo):
        """Retorna paradas de uma linha específica (todos os sentidos)"""
        try:
            with self.conn.cursor(row_factory=dict_row) as cur:
                # Busca todas as tabelas de horários dessa linha
                cur.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_name LIKE %s AND table_schema = 'public'
                """, (f'horarios_{codigo}_%',))
                tables = cur.fetchall()
                paradas = set()
                for table in tables:
                    cur.execute(f'SELECT DISTINCT estacao FROM {table["table_name"]} WHERE estacao IS NOT NULL')
                    for row in cur.fetchall():
                        paradas.add(row['estacao'])
                return [{'nome': nome} for nome in sorted(paradas)]
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
                    sentido = table['table_name'].split('_')[-1]
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

