# backend/database/db.py
import os
import re
import urllib.parse as up
import pandas as pd  # se você usa DataFrame para tipagem/IDE
import psycopg
from psycopg.extras import execute_values


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

    def __init__(self, dsn: str | None = None):
        """
        dsn pode ser:
        - URL:  postgresql://user:pass@host:5432/dbname
        - DSN:  dbname=... user=... host=...
        - None: lê da variável de ambiente DATABASE_URL.
        """
        dsn = (
            dsn
            or os.getenv("DATABASE_URL")
            or "dbname=RotaBus user=postgres password=12345 host=localhost port=5432"
        )

        # O psycopg3 aceita tanto URL quanto DSN; não precisamos parsear.
        self.conn = psycopg.connect(dsn, autocommit=True)

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
        Persistir o DataFrame `df` inteiro na tabela correspondente
        a (linha, sentido). Se já existir conteúdo, ele é truncado.

        Parâmetros
        ----------
        linha : str
            Identificador / nome do ônibus.
        sentido : str
            Sentido (ex.: "Centro", "Bairro").
        df : pandas.DataFrame
            Deve conter a coluna "Estação" e colunas "partida1", "partida2"...
        """
        tabela = f'horarios_{_slug(linha)}_{_slug(sentido)}'

        partida_cols = sorted(
            [c for c in df.columns if c.lower().startswith("partida")],
            key=lambda x: int(re.search(r"\d+", x).group())
        )

        self._ensure_table(tabela, len(partida_cols))

        # monta lista de tuplas na mesma ordem das colunas a inserir
        registros = []
        for _, row in df.iterrows():
            registros.append(
                (
                    linha,
                    sentido,
                    row["Estação"],
                    *[row.get(c) or None for c in partida_cols],
                )
            )

        col_names = ["onibus", "sentido", "estacao"] + partida_cols
        placeholders = "(" + ", ".join(["%s"] * len(col_names)) + ")"

        with self.conn.cursor() as cur:
            cur.execute(f"TRUNCATE {tabela};")  # limpa antes de inserir
            execute_values(
                cur,
                f"INSERT INTO {tabela} ({', '.join(col_names)}) VALUES %s;",
                registros,
                template=placeholders,
            )

        print(
            f"✔ Gravado {len(df)} estações na tabela '{tabela}' "
            f"(ônibus={linha}, sentido='{sentido}')."
        )
