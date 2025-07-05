import os, re, urllib.parse as up
import psycopg2
from psycopg2.extras import execute_values


def _slug(txt: str) -> str:
    txt = (
        txt.lower()
        .replace("ç", "c")
        .encode("ascii", "ignore")
        .decode()
    )
    return re.sub(r"[^a-z0-9]+", "_", txt).strip("_")


class PostgresDB:
    """
    Para cada (linha, sentido) cria/usa a tabela:
        horarios_<linha>_<slug_sentido>
    com colunas fixas
        id, onibus, sentido, estacao
    e colunas partida1..N adicionadas sob demanda.
    """
    def __init__(self, dsn: str | None = None):
        dsn = dsn or os.getenv("DATABASE_URL") or (
            "dbname=RotaBus user=postgres password=12345 host=localhost port=5432"
        )

        if dsn.startswith(("postgres://", "postgresql://")):
            url = up.urlparse(dsn)
            self.conn = psycopg2.connect(
                dbname=url.path.lstrip("/"),
                user=up.unquote(url.username or ""),
                password=up.unquote(url.password or ""),
                host=url.hostname,
                port=url.port or 5432,
            )
        else:
            self.conn = psycopg2.connect(dsn)

        self.conn.autocommit = True

    def _ensure_table(self, table: str, n_partidas: int):
        with self.conn.cursor() as cur:
            # cria tabela se não existir, já com colunas onibus e sentido
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
            # garante colunas partida1..N
            cur.execute(
                f"""
                SELECT column_name
                FROM   information_schema.columns
                WHERE  table_name = %s
                  AND  column_name LIKE 'partida%%';
                """,
                (table,),
            )
            existentes = {r[0] for r in cur.fetchall()}
            for i in range(1, n_partidas + 1):
                col = f"partida{i}"
                if col not in existentes:
                    cur.execute(f'ALTER TABLE {table} ADD COLUMN {col} TEXT;')

    def save_schedule(self, linha: str, sentido: str, df):
        """
        Grava DataFrame inteiro na tabela específica de (linha, sentido).
        """
        tabela = f'horarios_{_slug(linha)}_{_slug(sentido)}'
        partida_cols = sorted(
            [c for c in df.columns if c.lower().startswith("partida")],
            key=lambda x: int(re.search(r"\d+", x).group())
        )
        self._ensure_table(tabela, len(partida_cols))

        registros = []
        for _, row in df.iterrows():
            linha_tuple = [
                linha,                      # onibus
                sentido,                    # sentido
                row["Estação"],             # estacao
            ] + [row.get(c) or None for c in partida_cols]
            registros.append(tuple(linha_tuple))

        col_names = ["onibus", "sentido", "estacao"] + partida_cols
        placeholder = "(" + ", ".join(["%s"] * len(col_names)) + ")"

        with self.conn.cursor() as cur:
            cur.execute(f"TRUNCATE {tabela};")  # zera antes de inserir
            execute_values(
                cur,
                f"INSERT INTO {tabela} ({', '.join(col_names)}) VALUES %s;",
                registros,
                template=placeholder,
            )

        print(
            f"✔ Gravado {len(df)} estações na tabela '{tabela}' "
            f"(ônibus={linha}, sentido='{sentido}')."
        )
