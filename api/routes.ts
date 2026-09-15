import { Router } from 'express';
import type { Request, Response } from 'express';
import {
  clienteService,
  veiculoService,
  pecaService,
  servicoService,
  ordemService,
} from './service.ts';

const router = Router();

const rotas: string[] = [
  '/clientes',
  '/veiculos',
  '/pecas',
  '/servicos',
  '/ordens',
];

const subRotas: Record<string, string[]> = {
  '/clientes': ['/clientes/:id'],
  '/veiculos': ['/veiculos/:id'],
  '/pecas': ['/pecas/:id', '/pecas/repor', '/pecas/:id/repor', '/pecas/:id/descontinuar'],
  '/servicos': ['/servicos/:id'],
  '/ordens': ['/ordens/:id', '/ordens/:id/aprovar', '/ordens/:id/concluir'],
};

const metodosSubrotas: Record<string, string[]> = {
  '/clientes/:id': ['GET', 'DELETE'],
  '/veiculos/:id': ['GET', 'DELETE'],
  '/pecas/:id': ['GET'],
  '/pecas/repor': ['GET'],
  '/pecas/:id/repor': ['PATCH'],
  '/pecas/:id/descontinuar': ['PATCH'],
  '/servicos/:id': ['GET', 'DELETE'],
  '/ordens/:id': ['GET', 'DELETE'],
  '/ordens/:id/aprovar': ['PATCH'],
  '/ordens/:id/concluir': ['PATCH'],
};

const metodos = {
  '/clientes': ['GET', 'POST', 'DELETE'],
  '/veiculos': ['GET', 'POST', 'DELETE'],
  '/pecas': ['GET', 'POST', 'PATCH'],
  '/servicos': ['GET', 'POST', 'DELETE'],
  '/ordens': ['GET', 'POST', 'PATCH', 'DELETE'],
};

// rotas com seus respectivos metodos
router.get('/', (_req: Request, res: Response) => {
  res.status(200).send(
    `<h1>API de Serviços Mecânicos v1.0</h1>
    <p>Lista de endpoints disponíveis: </p>
    
    <ul>
      ${rotas
        .map(
          (rota) =>
            `<li>${rota} - Métodos: ${metodos[rota].join(', ')}${
              subRotas[rota]
                ? `<ul>${subRotas[rota]
                    .map(
                      (subRota) =>
                        `<li>${subRota} - Métodos: ${metodosSubrotas[subRota].join(', ')}</li>`
                    )
                    .join('')}</ul>`
                : ''
            }</li>`
        )
        .join('')}
    </ul>
  ` 

  );
});

// ---------- clientes ----------

router.get('/clientes', async (_req: Request, res: Response) => {
  res.json(await clienteService.listar());
});

router.get('/clientes/:id', async (req: Request, res: Response) => {
  const cliente = await clienteService.buscarPorId(Number(req.params.id));

  if (!cliente) {
    return res.status(404).json({ erro: 'Cliente não encontrado' });
  }

  res.json(cliente);
});

router.post('/clientes', async (req: Request, res: Response) => {
  const { nome, cpf, telefone, endereco } = req.body;

  if (!nome || !cpf) {
    return res.status(400).json({ erro: 'nome e cpf são obrigatórios' });
  }

  try {
    const cliente = await clienteService.criar({ nome, cpf, telefone, endereco });
    res.status(201).json(cliente);
  } catch (e) {
    res.status(409).json({ erro: (e as Error).message });
  }
});

router.delete('/clientes/:id', async (req: Request, res: Response) => {
  try {
    await clienteService.remover(Number(req.params.id));
    res.status(204).end();
  } catch (e) {
    res.status(409).json({ erro: (e as Error).message });
  }
});

// ---------- veiculos ----------

router.get('/veiculos', async (_req: Request, res: Response) => {
  res.json(await veiculoService.listar());
});

router.get('/veiculos/:id', async (req: Request, res: Response) => {
  const veiculo = await veiculoService.buscarPorId(Number(req.params.id));

  if (!veiculo) {
    return res.status(404).json({ erro: 'Veículo não encontrado' });
  }

  res.json(veiculo);
});

router.post('/veiculos', async (req: Request, res: Response) => {
  const { modelo, ano, placa, clienteId } = req.body;

  if (!modelo || !placa || ano == null || clienteId == null) {
    return res.status(400).json({ erro: 'modelo, ano, placa e clienteId são obrigatórios' });
  }

  try {
    const veiculo = await veiculoService.criar({
      modelo,
      ano: Number(ano),
      placa,
      clienteId: Number(clienteId),
    });
    res.status(201).json(veiculo);
  } catch (e) {
    res.status(409).json({ erro: (e as Error).message });
  }
});

router.delete('/veiculos/:id', async (req: Request, res: Response) => {
  try {
    await veiculoService.remover(Number(req.params.id));
    res.status(204).end();
  } catch (e) {
    res.status(409).json({ erro: (e as Error).message });
  }
});

// ---------- pecas ----------

router.get('/pecas', async (_req: Request, res: Response) => {
  res.json(await pecaService.listar());
});

// precisa vir antes de /pecas/:id, senão "repor" é lido como um id
router.get('/pecas/repor', async (_req: Request, res: Response) => {
  res.json(await pecaService.paraRepor());
});

router.get('/pecas/:id', async (req: Request, res: Response) => {
  const peca = await pecaService.buscarPorId(Number(req.params.id));

  if (!peca) {
    return res.status(404).json({ erro: 'Peça não encontrada' });
  }

  res.json(peca);
});

router.post('/pecas', async (req: Request, res: Response) => {
  const { marca, valor, quantidade, pontoReposicao } = req.body;

  // valor == null e não !valor: zero é um valor válido
  if (!marca || valor == null) {
    return res.status(400).json({ erro: 'marca e valor são obrigatórios' });
  }

  const peca = await pecaService.criar({
    marca,
    valor: Number(valor),
    quantidade: quantidade == null ? undefined : Number(quantidade),
    pontoReposicao: pontoReposicao == null ? undefined : Number(pontoReposicao),
  });

  res.status(201).json(peca);
});

router.patch('/pecas/:id/repor', async (req: Request, res: Response) => {
  const { quantidade } = req.body;

  if (quantidade == null) {
    return res.status(400).json({ erro: 'quantidade é obrigatória' });
  }

  try {
    const peca = await pecaService.repor(Number(req.params.id), Number(quantidade));
    res.json(peca);
  } catch (e) {
    res.status(400).json({ erro: (e as Error).message });
  }
});

router.patch('/pecas/:id/descontinuar', async (req: Request, res: Response) => {
  try {
    const peca = await pecaService.descontinuar(Number(req.params.id));
    res.json(peca);
  } catch (e) {
    res.status(404).json({ erro: 'Peça não encontrada' });
  }
});

// ---------- servicos ----------

router.get('/servicos', async (_req: Request, res: Response) => {
  res.json(await servicoService.listar());
});

router.get('/servicos/:id', async (req: Request, res: Response) => {
  const servico = await servicoService.buscarPorId(Number(req.params.id));

  if (!servico) {
    return res.status(404).json({ erro: 'Serviço não encontrado' });
  }

  res.json(servico);
});

router.post('/servicos', async (req: Request, res: Response) => {
  const { nome, valor, descricao } = req.body;

  if (!nome || valor == null) {
    return res.status(400).json({ erro: 'nome e valor são obrigatórios' });
  }

  const servico = await servicoService.criar({ nome, valor: Number(valor), descricao });
  res.status(201).json(servico);
});

router.delete('/servicos/:id', async (req: Request, res: Response) => {
  try {
    await servicoService.remover(Number(req.params.id));
    res.status(204).end();
  } catch (e) {
    res.status(409).json({ erro: (e as Error).message });
  }
});

// ---------- ordens ----------

router.get('/ordens', async (_req: Request, res: Response) => {
  res.json(await ordemService.listar());
});

router.get('/ordens/:id', async (req: Request, res: Response) => {
  const ordem = await ordemService.buscarPorId(Number(req.params.id));

  if (!ordem) {
    return res.status(404).json({ erro: 'Ordem não encontrada' });
  }

  res.json(ordem);
});

router.post('/ordens', async (req: Request, res: Response) => {
  const { placa, itens, servicoIds } = req.body;

  if (!placa) {
    return res.status(400).json({ erro: 'placa é obrigatória' });
  }

  try {
    const ordem = await ordemService.abrir({ placa, itens, servicoIds });
    res.status(201).json(ordem);
  } catch (e) {
    res.status(400).json({ erro: (e as Error).message });
  }
});

router.patch('/ordens/:id/aprovar', async (req: Request, res: Response) => {
  try {
    const ordem = await ordemService.aprovar(Number(req.params.id));
    res.json(ordem);
  } catch (e) {
    res.status(400).json({ erro: (e as Error).message });
  }
});

router.patch('/ordens/:id/concluir', async (req: Request, res: Response) => {
  try {
    const ordem = await ordemService.concluir(Number(req.params.id));
    res.json(ordem);
  } catch (e) {
    res.status(400).json({ erro: (e as Error).message });
  }
});

router.delete('/ordens/:id', async (req: Request, res: Response) => {
  try {
    await ordemService.cancelar(Number(req.params.id));
    res.status(204).end();
  } catch (e) {
    res.status(400).json({ erro: (e as Error).message });
  }
});

export default router;
