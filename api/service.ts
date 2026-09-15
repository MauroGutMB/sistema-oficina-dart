import { prisma } from './db.ts';

/* Clientes                                                            */
export type CriarClienteDTO = {
  nome: string;
  cpf: string;
  telefone?: string;
  endereco?: string;
};

export const clienteService = {
  listar: () => prisma.cliente.findMany({ orderBy: { nome: 'asc' } }),

  buscarPorId: (id: number) =>
    prisma.cliente.findUnique({ where: { id }, include: { veiculos: true } }),

  async criar(dados: CriarClienteDTO) {
    const existente = await prisma.cliente.findUnique({ where: { cpf: dados.cpf } });
    if (existente) throw new Error('Já existe um cliente com esse CPF');

    return prisma.cliente.create({ data: dados });
  },

  async atualizar(id: number, dados: Partial<Omit<CriarClienteDTO, 'cpf'>>) {
    const cliente = await prisma.cliente.findUnique({ where: { id } });
    if (!cliente) throw new Error('Cliente não encontrado');

    return prisma.cliente.update({ where: { id }, data: dados });
  },

  async remover(id: number) {
    const veiculos = await prisma.veiculo.count({ where: { clienteId: id } });
    if (veiculos > 0) {
      throw new Error('Não é possível remover um cliente com veículos cadastrados');
    }

    return prisma.cliente.delete({ where: { id } });
  },
};

/* Veículos                                                            */
export type CriarVeiculoDTO = {
  modelo: string;
  ano: number;
  placa: string;
  clienteId: number;
};

export const veiculoService = {
  listar: () => prisma.veiculo.findMany({ include: { cliente: true } }),

  buscarPorId: (id: number) =>
    prisma.veiculo.findUnique({ where: { id }, include: { cliente: true, ordens: true } }),

  buscarPorPlaca: (placa: string) =>
    prisma.veiculo.findUnique({ where: { placa }, include: { cliente: true } }),

  async criar(dados: CriarVeiculoDTO) {
    const cliente = await prisma.cliente.findUnique({ where: { id: dados.clienteId } });
    if (!cliente) throw new Error('Cliente não encontrado');

    const existente = await prisma.veiculo.findUnique({ where: { placa: dados.placa } });
    if (existente) throw new Error('Já existe um veículo com essa placa');

    return prisma.veiculo.create({ data: dados });
  },

  async remover(id: number) {
    const ordens = await prisma.ordem.count({ where: { veiculoId: id } });
    if (ordens > 0) throw new Error('Não é possível remover um veículo com ordens');

    return prisma.veiculo.delete({ where: { id } });
  },
};

/* Peças                                                               */
export type CriarPecaDTO = {
  marca: string;
  valor: number;
  quantidade?: number;
  pontoReposicao?: number;
};

export const pecaService = {
  listar: () => prisma.peca.findMany({ orderBy: { marca: 'asc' } }),

  buscarPorId: (id: number) => prisma.peca.findUnique({ where: { id } }),

  criar: (dados: CriarPecaDTO) =>
    prisma.peca.create({
      data: {
        marca: dados.marca,
        valor: dados.valor,
        quantidade: dados.quantidade ?? 0,
        pontoReposicao: dados.pontoReposicao ?? 0,
      },
    }),

  async repor(id: number, quantidade: number) {
    if (quantidade <= 0) throw new Error('A quantidade deve ser positiva');

    const peca = await prisma.peca.findUnique({ where: { id } });
    if (!peca) throw new Error('Peça não encontrada');
    if (peca.descontinuada) throw new Error('Não é possível repor uma peça descontinuada');

    return prisma.peca.update({
      where: { id },
      data: { quantidade: { increment: quantidade } },
    });
  },

  descontinuar: (id: number) =>
    prisma.peca.update({ where: { id }, data: { descontinuada: true } }),

  // peças ativas que chegaram no ponto de reposição
  async paraRepor() {
    const pecas = await prisma.peca.findMany({ where: { descontinuada: false } });
    return pecas.filter((p) => p.quantidade <= p.pontoReposicao);
  },
};

/* Serviços                                                            */
export type CriarServicoDTO = {
  nome: string;
  valor: number;
  descricao?: string;
};

export const servicoService = {
  listar: () => prisma.servico.findMany({ orderBy: { nome: 'asc' } }),

  buscarPorId: (id: number) => prisma.servico.findUnique({ where: { id } }),

  criar: (dados: CriarServicoDTO) => prisma.servico.create({ data: dados }),

  async remover(id: number) {
    const usos = await prisma.ordemServico.count({ where: { servicoId: id } });
    if (usos > 0) throw new Error('Serviço já usado em ordens e não pode ser removido');

    return prisma.servico.delete({ where: { id } });
  },
};

/* Ordens de serviço                                                   */
export type ItemPecaDTO = { pecaId: number; quantidade: number };

export type AbrirOrdemDTO = {
  placa: string;
  itens?: ItemPecaDTO[];
  servicoIds?: number[];
};

const ordemCompleta = {
  veiculo: { include: { cliente: true } },
  itens: { include: { peca: true } },
  servicos: { include: { servico: true } },
} as const;

export const ordemService = {
  listar: () =>
    prisma.ordem.findMany({ include: ordemCompleta, orderBy: { dataHoraAbertura: 'desc' } }),

  buscarPorId: (id: number) =>
    prisma.ordem.findUnique({ where: { id }, include: ordemCompleta }),

  /**
   * Valida estoque, calcula o total, cria a ordem e dá baixa nas peças.
   * Tudo em uma transação: se qualquer passo falhar, nada é gravado.
   */
  async abrir({ placa, itens = [], servicoIds = [] }: AbrirOrdemDTO) {
    if (itens.length === 0 && servicoIds.length === 0) {
      throw new Error('A ordem precisa de ao menos uma peça ou um serviço');
    }

    return prisma.$transaction(async (tx) => {
      const veiculo = await tx.veiculo.findUnique({ where: { placa } });
      if (!veiculo) throw new Error('Veículo não encontrado');

      const pecas = await tx.peca.findMany({
        where: { id: { in: itens.map((i) => i.pecaId) } },
      });

      // valida tudo antes de alterar qualquer estoque
      for (const item of itens) {
        const peca = pecas.find((p) => p.id === item.pecaId);

        if (!peca) throw new Error(`Peça ${item.pecaId} não encontrada`);
        if (item.quantidade <= 0) throw new Error(`Quantidade inválida para ${peca.marca}`);
        if (peca.descontinuada) throw new Error(`A peça ${peca.marca} está descontinuada`);
        if (peca.quantidade < item.quantidade) {
          throw new Error(
            `Estoque insuficiente de ${peca.marca}: ${peca.quantidade} em estoque, ${item.quantidade} solicitadas`,
          );
        }
      }

      const servicos = await tx.servico.findMany({ where: { id: { in: servicoIds } } });
      if (servicos.length !== servicoIds.length) {
        throw new Error('Algum serviço informado não existe');
      }

      // Decimal não soma com "+", por isso o Number()
      const totalPecas = itens.reduce((total, item) => {
        const peca = pecas.find((p) => p.id === item.pecaId)!;
        return total + Number(peca.valor) * item.quantidade;
      }, 0);

      const totalServicos = servicos.reduce((total, s) => total + Number(s.valor), 0);

      const ordem = await tx.ordem.create({
        data: {
          veiculoId: veiculo.id,
          valorTotal: totalPecas + totalServicos,
          status: 'aberta',
          itens: {
            create: itens.map((item) => ({
              pecaId: item.pecaId,
              quantidade: item.quantidade,
              // congela o preço do momento da abertura
              valorUnitario: pecas.find((p) => p.id === item.pecaId)!.valor,
            })),
          },
          servicos: {
            create: servicos.map((s) => ({ servicoId: s.id, valorUnitario: s.valor })),
          },
        },
        include: ordemCompleta,
      });

      for (const item of itens) {
        await tx.peca.update({
          where: { id: item.pecaId },
          data: { quantidade: { decrement: item.quantidade } },
        });
      }

      return ordem;
    });
  },

  async aprovar(id: number) {
    const ordem = await prisma.ordem.findUnique({ where: { id } });
    if (!ordem) throw new Error('Ordem não encontrada');
    if (ordem.status !== 'aberta') throw new Error('Só é possível aprovar uma ordem aberta');

    return prisma.ordem.update({
      where: { id },
      data: { status: 'aprovada' },
      include: ordemCompleta,
    });
  },

  async concluir(id: number) {
    const ordem = await prisma.ordem.findUnique({ where: { id } });
    if (!ordem) throw new Error('Ordem não encontrada');
    if (ordem.status !== 'aprovada') throw new Error('Só é possível concluir uma ordem aprovada');

    return prisma.ordem.update({
      where: { id },
      data: { status: 'concluida', dataHoraConclusao: new Date() },
      include: ordemCompleta,
    });
  },

  /** Cancelar devolve as peças ao estoque, por isso também vai em transação. */
  async cancelar(id: number) {
    return prisma.$transaction(async (tx) => {
      const ordem = await tx.ordem.findUnique({ where: { id }, include: { itens: true } });
      if (!ordem) throw new Error('Ordem não encontrada');
      if (ordem.status === 'concluida') {
        throw new Error('Não é possível cancelar uma ordem concluída');
      }

      for (const item of ordem.itens) {
        await tx.peca.update({
          where: { id: item.pecaId },
          data: { quantidade: { increment: item.quantidade } },
        });
      }

      return tx.ordem.delete({ where: { id } });
    });
  },
};
