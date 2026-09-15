import express from 'express';
import router from './routes.ts';
import { logger } from './middleware_logger.ts';
import type { Request, Response, NextFunction } from 'express';

const app = express();
const PORT = 3000;

app.use(logger);
app.use(express.json());

app.use('/', router);

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

