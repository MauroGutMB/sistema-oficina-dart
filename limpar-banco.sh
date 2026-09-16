#!/usr/bin/env bash
#
# limpar-banco.sh — esvazia as tabelas do banco da oficina para testes.
#
#   ./limpar-banco.sh             esvazia as tabelas (rápido, mantém a estrutura)
#   ./limpar-banco.sh --seed      esvazia e insere dados de exemplo realistas: nomes de
#                                 verdade, veículos/placas plausíveis e ordens cobrindo
#                                 os três status (aberta, aprovada, concluída)
#   ./limpar-banco.sh --seed-nuke NÃO esvazia — soma mais uma leva de dados genéricos
#                                 (10 mil clientes e o resto proporcional) em cima do
#                                 que já existe. Incremental: roda de novo pra crescer
#                                 ainda mais, simulando um banco que só aumenta de verdade
#   ./limpar-banco.sh --reset     derruba tudo e reaplica as migrations do Prisma
#
set -euo pipefail

# carrega DATABASE_* do .env, ignorando comentários e linhas vazias
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source <(grep -E '^[A-Z_]+=' .env)
  set +a
fi

DB_HOST="${DATABASE_HOST:-localhost}"
DB_PORT="${DATABASE_PORT:-3306}"
DB_USER="${DATABASE_USER:-oficina}"
DB_PASS="${DATABASE_PASSWORD:-}"
DB_NAME="${DATABASE_NAME:-oficina}"

# ordem não importa: as FKs são desligadas durante o truncate
TABELAS=(OrdemPeca OrdemServico Ordem Veiculo Cliente Peca Servico)

mariadb_exec() {
  mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" ${DB_PASS:+-p"$DB_PASS"} "$DB_NAME" "$@"
}

case "${1:-}" in
  --reset)
    echo "Derrubando o banco e reaplicando as migrations..."
    npx prisma migrate reset --force
    echo "Pronto. Banco recriado do zero."
    exit 0
    ;;
  --seed-nuke)
    echo "Somando mais uma leva de dados genéricos (incremental, não apaga nada)..."

    # Cada bloco insere em cima do que já existe (base = MAX(id) atual) e
    # depois referencia as linhas recém-criadas por POSIÇÃO (ROW_NUMBER via
    # join), nunca por aritmética direta sobre o id. Isso importa porque o
    # MariaDB pode deixar buracos no autoincrement num INSERT...SELECT vindo
    # de CTE recursivo (ele reserva um lote de ids sem saber de antemão
    # quantas linhas vão sair) — então "base + n" pode não ser um id real.
    # Assim dá pra rodar isso quantas vezes quiser: sempre soma outra leva,
    # nunca quebra por causa de um buraco de uma leva anterior.
    mariadb_exec <<'SQL'
SET SESSION max_recursive_iterations = 100000;

SET @cliente_base = (SELECT COALESCE(MAX(id), 0) FROM Cliente);
INSERT INTO Cliente (nome, cpf, telefone, endereco)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
  CONCAT('Cliente Teste ', LPAD(@cliente_base + n, 6, '0')),
  LPAD(@cliente_base + n, 11, '0'),
  CONCAT('8699', LPAD(@cliente_base + n, 7, '0')),
  CONCAT('Rua Teste ', @cliente_base + n, ', ', (n % 500) + 1, ' - Corrente/PI')
FROM seq;
SET @cliente_count = (SELECT COUNT(*) FROM Cliente WHERE id > @cliente_base);

-- placa é VARCHAR(8) e o prefixo "CAR" só deixa 5 dígitos livres, então tem
-- um teto de ~100 mil veículos únicos nesse esquema; o MOD evita estourar
-- a coluna, mas rodando o nuke ~6x+ (100k+ veículos) as placas recomeçam
-- a se repetir — aceitável pra dado sintético de stress-test.
SET @veiculo_base = (SELECT COALESCE(MAX(id), 0) FROM Veiculo);
INSERT INTO Veiculo (modelo, ano, placa, clienteId)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 17500
),
clientes_novos AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM Cliente WHERE id > @cliente_base
)
SELECT
  CONCAT('Modelo ', LPAD(@veiculo_base + seq.n, 6, '0')),
  2005 + (seq.n % 20),
  CONCAT('CAR', LPAD(MOD(@veiculo_base + seq.n, 100000), 5, '0')),
  cn.id
FROM seq
JOIN clientes_novos cn ON cn.rn = ((seq.n - 1) % @cliente_count) + 1;
SET @veiculo_count = (SELECT COUNT(*) FROM Veiculo WHERE id > @veiculo_base);

SET @peca_base = (SELECT COALESCE(MAX(id), 0) FROM Peca);
INSERT INTO Peca (marca, valor, quantidade, pontoReposicao, descontinuada)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 3000
)
SELECT
  CONCAT('Peça Teste ', LPAD(@peca_base + n, 5, '0')),
  ROUND(10 + MOD(n * 337, 20000) / 100, 2),
  MOD(n * 7, 30),
  5 + MOD(n, 10),
  (MOD(n, 9) = 0)
FROM seq;
SET @peca_count = (SELECT COUNT(*) FROM Peca WHERE id > @peca_base);

SET @servico_base = (SELECT COALESCE(MAX(id), 0) FROM Servico);
INSERT INTO Servico (nome, valor, descricao)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 2000
)
SELECT
  CONCAT('Serviço Teste ', LPAD(@servico_base + n, 5, '0')),
  ROUND(50 + MOD(n * 550, 30000) / 100, 2),
  CONCAT('Descrição de exemplo do serviço ', @servico_base + n)
FROM seq;
SET @servico_count = (SELECT COUNT(*) FROM Servico WHERE id > @servico_base);

SET @ordem_base = (SELECT COALESCE(MAX(id), 0) FROM Ordem);
INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura, dataHoraConclusao)
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 25000
),
veiculos_novos AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM Veiculo WHERE id > @veiculo_base
)
SELECT
  vn.id,
  ROUND(80 + MOD(seq.n * 1370, 90000) / 100, 2),
  ELT(1 + MOD(seq.n, 3), 'aberta', 'aprovada', 'concluida'),
  NOW() - INTERVAL (seq.n * 7) MINUTE,
  CASE WHEN MOD(seq.n, 3) = 2 THEN NOW() - INTERVAL (seq.n * 3) MINUTE ELSE NULL END
FROM seq
JOIN veiculos_novos vn ON vn.rn = ((seq.n - 1) % @veiculo_count) + 1;

-- uma peça por ordem nova, sempre
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario)
SELECT o.id, pn.id, 1 + (o.id % 4), ROUND(20 + MOD(o.id * 210, 15000) / 100, 2)
FROM Ordem o
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM Peca WHERE id > @peca_base) pn
  ON pn.rn = ((o.id - @ordem_base - 1) % @peca_count) + 1
WHERE o.id > @ordem_base;

-- uma segunda peça (deslocada na metade da leva, nunca colide com a primeira) pras ordens novas de id par
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario)
SELECT o.id, pn.id, 1 + (o.id % 3), ROUND(15 + MOD(o.id * 130, 10000) / 100, 2)
FROM Ordem o
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM Peca WHERE id > @peca_base) pn
  ON pn.rn = (((o.id - @ordem_base - 1) + FLOOR(@peca_count / 2)) % @peca_count) + 1
WHERE o.id > @ordem_base AND o.id % 2 = 0;

-- um serviço pra maioria das ordens novas (menos as múltiplas de 3)
INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario)
SELECT o.id, sn.id, ROUND(60 + MOD(o.id * 440, 25000) / 100, 2)
FROM Ordem o
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM Servico WHERE id > @servico_base) sn
  ON sn.rn = ((o.id - @ordem_base - 1) % @servico_count) + 1
WHERE o.id > @ordem_base AND o.id % 3 != 0;

SELECT
  (SELECT COUNT(*) FROM Cliente)  AS total_clientes,
  (SELECT COUNT(*) FROM Veiculo)  AS total_veiculos,
  (SELECT COUNT(*) FROM Peca)     AS total_pecas,
  (SELECT COUNT(*) FROM Servico)  AS total_servicos,
  (SELECT COUNT(*) FROM Ordem)    AS total_ordens;
SQL

    echo "Leva somada: +10.000 clientes, +17.500 veículos, +3.000 peças, +2.000 serviços, +25.000 ordens."
    echo "Totais atuais no banco (acima ↑)."
    exit 0
    ;;
esac

echo "Esvaziando as tabelas de '$DB_NAME'..."

{
  echo "SET FOREIGN_KEY_CHECKS = 0;"
  for tabela in "${TABELAS[@]}"; do
    echo "TRUNCATE TABLE \`$tabela\`;"
  done
  echo "SET FOREIGN_KEY_CHECKS = 1;"
} | mariadb_exec

echo "Tabelas esvaziadas e ids reiniciados em 1."

if [[ "${1:-}" == "--seed" ]]; then
  echo "Inserindo dados de exemplo realistas..."

  # Nomes, veículos e histórico pensados pra formar um cenário plausível de
  # oficina de verdade: um cliente com mais de um carro, peças em estoque
  # normal/baixo/descontinuado, e ordens passando pelos três status
  # (aberta, aprovada, concluída) com itens e serviços combinados.
  mariadb_exec <<'SQL'
INSERT INTO Cliente (nome, cpf, telefone, endereco) VALUES
  ('Mauro Gutemberg Magalhães Barros', '12345678901', '89999990000', 'Rua A, 123 - Corrente/PI'),
  ('Ana Ribeiro Costa',                '98765432100', '89988887777', 'Av. B, 45 - Corrente/PI'),
  ('Carlos Eduardo Silva',             '11122233344', '89987654321', 'Rua das Flores, 200 - Corrente/PI'),
  ('Fernanda Oliveira Santos',         '22233344455', '89976543210', 'Av. Getúlio Vargas, 88 - Corrente/PI'),
  ('João Pedro Almeida',               '33344455566', '89965432109', 'Rua Piauí, 15 - Corrente/PI'),
  ('Juliana Ferreira Lima',            '44455566677', '89954321098', 'Rua Bahia, 302 - Corrente/PI'),
  ('Ricardo Souza Pereira',            '55566677788', '89943210987', 'Av. Brasil, 501 - Corrente/PI'),
  ('Patrícia Rodrigues Nunes',         '66677788899', '89932109876', 'Rua Ceará, 77 - Corrente/PI');

-- Carlos (id 3) tem dois carros — cenário comum de cliente recorrente
INSERT INTO Veiculo (modelo, ano, placa, clienteId) VALUES
  ('Gol 1.0',    2015, 'ABC1D23', 1),
  ('Onix 1.4',   2019, 'XYZ9K87', 2),
  ('HB20 1.6',   2021, 'QWE4R56', 3),
  ('Corolla 2.0',2022, 'QWE4R57', 3),
  ('Civic 1.5',  2018, 'JKL2M34', 4),
  ('Fiesta 1.6', 2013, 'RTY5U78', 5),
  ('Compass 1.3',2020, 'POI3O21', 6),
  ('Kwid 1.0',   2022, 'LKJ8H90', 7),
  ('Tracker 1.0',2023, 'MNB6V54', 8);

INSERT INTO Peca (marca, valor, quantidade, pontoReposicao, descontinuada) VALUES
  ('Bosch - vela de ignição',        45.90, 10, 3, 0),
  ('Fram - filtro de óleo',          32.50,  2, 5, 0), -- abaixo do ponto de reposição
  ('NGK - cabo de vela',             89.00,  0, 2, 1), -- descontinuada
  ('Continental - correia dentada', 120.00,  6, 4, 0),
  ('Cofap - amortecedor dianteiro', 210.00,  1, 4, 0), -- abaixo do ponto de reposição
  ('Wega - bomba de combustível',   340.00,  3, 2, 0),
  ('Delphi - kit de embreagem',     480.00,  0, 3, 1), -- descontinuada, usada numa ordem antiga
  ('Monroe - amortecedor traseiro', 195.00,  8, 4, 0);

INSERT INTO Servico (nome, valor, descricao) VALUES
  ('Troca de óleo',              120.00, 'Inclui filtro e mão de obra'),
  ('Alinhamento e balanceamento', 90.00, 'Alinhamento e balanceamento das 4 rodas'),
  ('Revisão de freios',          250.00, 'Pastilhas, discos e fluido'),
  ('Troca de correia dentada',   180.00, 'Inclui tensor'),
  ('Diagnóstico eletrônico',     150.00, 'Leitura de código de falha via scanner'),
  ('Troca de embreagem',         600.00, 'Kit completo + mão de obra');

-- Ordem 1: aberta, aguardando aprovação do orçamento (Gol do Mauro)
INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura) VALUES
  (1, 152.50, 'aberta', NOW() - INTERVAL 2 DAY);
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario) VALUES (1, 2, 1, 32.50);
INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario) VALUES (1, 1, 120.00);

-- Ordem 2: aprovada, aguardando execução (Onix da Ana)
INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura) VALUES
  (2, 640.00, 'aprovada', NOW() - INTERVAL 5 DAY);
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario) VALUES (2, 8, 2, 195.00);
INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario) VALUES (2, 3, 250.00);

-- Ordem 3: concluída (HB20 do Carlos) — troca de correia com diagnóstico
INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura, dataHoraConclusao) VALUES
  (3, 450.00, 'concluida', NOW() - INTERVAL 10 DAY, NOW() - INTERVAL 9 DAY);
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario) VALUES (3, 4, 1, 120.00);
INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario) VALUES
  (3, 4, 180.00),
  (3, 5, 150.00);

-- Ordem 4: concluída há mais tempo (Civic da Fernanda) — usou o kit de
-- embreagem quando ele ainda estava em estoque, antes de ser descontinuado
INSERT INTO Ordem (veiculoId, valorTotal, status, dataHoraAbertura, dataHoraConclusao) VALUES
  (5, 1080.00, 'concluida', NOW() - INTERVAL 20 DAY, NOW() - INTERVAL 18 DAY);
INSERT INTO OrdemPeca (ordemId, pecaId, quantidade, valorUnitario) VALUES (4, 7, 1, 480.00);
INSERT INTO OrdemServico (ordemId, servicoId, valorUnitario) VALUES (4, 6, 600.00);
SQL

  echo "Dados inseridos: 8 clientes, 9 veículos, 8 peças, 6 serviços, 4 ordens"
  echo "(uma aberta, uma aprovada e duas concluídas, com itens e serviços de verdade)."
  echo "Peça 2 e 5 estão abaixo do ponto de reposição; peças 3 e 7 estão descontinuadas."
fi

