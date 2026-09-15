/*
peças: marca, valor, quantidade, ponto de reposição, descontinuada
clientes: nome, cpf, telefone, endereço
veículos: modelo, ano, placa, cliente (vinculado)
serviços: nome, valor, descrição
ordens de serviço: veículo, peças, serviços, valor total, status (aberta, aprovada, concluída), data/hora de abertura, data/hora de conclusão
*/

// ATENÇÃO
// deprecado pq eu decidi usar o prisma
// vai ficar fins de estudo, mas não vai ser usado no projeto final
// ./prisma/schema.prisma

class Peca {
    marca: string;
    valor: number;
    quantidade: number;
    pontoReposicao: number;
    descontinuada: boolean;

    constructor(marca: string, valor: number, quantidade: number, pontoReposicao: number, descontinuada: boolean) {
        this.marca = marca;
        this.valor = valor;
        this.quantidade = quantidade;
        this.pontoReposicao = pontoReposicao;
        this.descontinuada = descontinuada;
    }
}

class Cliente {
    nome: string;
    cpf: string;
    telefone: string;
    endereco: string;

    constructor(nome: string, cpf: string, telefone: string, endereco: string) {
        this.nome = nome;
        this.cpf = cpf;
        this.telefone = telefone;
        this.endereco = endereco;
    }
}

class Veiculo {
    modelo: string;
    ano: number;
    placa: string;
    cliente: Cliente;

    constructor(modelo: string, ano: number, placa: string, cliente: Cliente) {
        this.modelo = modelo;
        this.ano = ano;
        this.placa = placa;
        this.cliente = cliente;
    }
}

class Servico {
    nome: string;
    valor: number;
    descricao: string;

    constructor(nome: string, valor: number, descricao: string) {
        this.nome = nome;
        this.valor = valor;
        this.descricao = descricao;
    }
}

class OrdemDeServico {
    veiculo: Veiculo;
    pecas: Peca[];
    servicos: Servico[];
    valorTotal: number;
    status: 'aberta' | 'aprovada' | 'concluida';
    dataHoraAbertura: Date;
    dataHoraConclusao?: Date;

    constructor(veiculo: Veiculo, pecas: Peca[], servicos: Servico[], status: 'aberta' | 'aprovada' | 'concluida', dataHoraAbertura: Date, dataHoraConclusao?: Date) {
        this.veiculo = veiculo;
        this.pecas = pecas;
        this.servicos = servicos;
        this.valorTotal = this.calcularValorTotal();
        this.status = status;
        this.dataHoraAbertura = dataHoraAbertura;
        this.dataHoraConclusao = dataHoraConclusao;
    }

    private calcularValorTotal(): number {
        const valorPecas = this.pecas.reduce((total, peca) => total + peca.valor * peca.quantidade, 0);
        const valorServicos = this.servicos.reduce((total, servico) => total + servico.valor, 0);
        return valorPecas + valorServicos;
    }
}

export { Peca, Cliente, Veiculo, Servico, OrdemDeServico };
