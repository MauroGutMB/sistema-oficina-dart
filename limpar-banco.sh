#!/usr/bin/env bash
#
# limpar-banco.sh — esvazia as tabelas do banco da oficina para testes.
#
#   ./limpar-banco.sh          esvazia as tabelas (rápido, mantém a estrutura)
#   ./limpar-banco.sh --seed   esvazia e insere dados de exemplo
#   ./limpar-banco.sh --reset  derruba tudo e reaplica as migrations do Prisma
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
  echo "Inserindo dados de exemplo..."

  mariadb_exec <<'SQL'
INSERT INTO Cliente (nome, cpf, telefone, endereco) VALUES
  ('Mauro Gutemberg', '12345678901', '89999990000', 'Rua A, 123 - Corrente/PI'),
  ('Ana Ribeiro',     '98765432100', '89988887777', 'Av. B, 45 - Corrente/PI');

INSERT INTO Veiculo (modelo, ano, placa, clienteId) VALUES
  ('Gol 1.0',   2015, 'ABC1D23', 1),
  ('Onix 1.4',  2019, 'XYZ9K87', 2);

INSERT INTO Peca (marca, valor, quantidade, pontoReposicao, descontinuada) VALUES
  ('Bosch - vela de ignição',  45.90, 10, 3, 0),
  ('Fram - filtro de óleo',    32.50,  2, 5, 0),
  ('NGK - cabo de vela',       89.00,  0, 2, 1);

INSERT INTO Servico (nome, valor, descricao) VALUES
  ('Troca de óleo',        120.00, 'Inclui filtro e mão de obra'),
  ('Alinhamento',           90.00, 'Alinhamento e balanceamento'),
  ('Revisão de freios',    250.00, 'Pastilhas, discos e fluido');
SQL

  echo "Dados inseridos: 2 clientes, 2 veículos, 3 peças, 3 serviços."
  echo "A peça 2 já está abaixo do ponto de reposição e a peça 3 está descontinuada."
fi
