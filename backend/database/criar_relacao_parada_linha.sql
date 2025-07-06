-- Cria tabela de relação entre paradas e linhas, incluindo horários
CREATE TABLE IF NOT EXISTS parada_linha (
    id SERIAL PRIMARY KEY,
    parada_id INTEGER NOT NULL,
    linha_id TEXT NOT NULL,
    horario TIME NOT NULL
);
-- Índices para busca rápida
CREATE INDEX IF NOT EXISTS idx_parada_linha_parada ON parada_linha(parada_id);
CREATE INDEX IF NOT EXISTS idx_parada_linha_linha ON parada_linha(linha_id);
