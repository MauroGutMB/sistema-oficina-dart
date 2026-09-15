import {Router } from 'express';
import type {Request, Response} from 'express';

const router = Router();
var rotas: string[] = [];


router.get('/', (req: Request, res: Response) => {
  rotas.push(req.originalUrl);
  res.send(
    `<h1>API de Serviços Mecânicos v1.0</h1>
    <p>Lista de endpoints disponíveis: </p>
    <ul>
      ${rotas.map((rota) => `<li>${rota}</li>`).join('')}
    </ul>`
  );
  rotas = [];
});

export default router;

