import type { Request, Response, NextFunction } from 'express';

// middleware próprio para logar as requisições
// app.use((req: Request, res: Response, next: NextFunction) => {
//   console.log(`${req.method} ${req.originalUrl}`);
//   next();
// });
//

// cores em codigo ANSI
const cores = {
  reset: '\x1b[0m',
  verde: '\x1b[32m',
  amarelo: '\x1b[31m', // vermelho pq amarelo não aparece bem no terminal
  vermelho: '\x1b[31m',
  ciano : '\x1b[36m'
};

function corStatus(status: number): string {
  if (status >= 200 && status < 300) {
    return cores.verde;
  } else if (status >= 400 && status < 500) {
    return cores.amarelo;
  } else if (status >= 500) {
    return cores.vermelho;
  } else if (status >= 300 && status < 400){
    return cores.ciano; // ciano para redirecionamentos
  }
  else {
    return cores.reset;
  }
}

// logger middleware da api em express
export function logger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const statusColor = corStatus(res.statusCode);
    console.log(
      `${req.method} ${req.originalUrl} ${statusColor}${res.statusCode}${cores.reset} - ${duration}ms`
    );
  });
  next();
}
