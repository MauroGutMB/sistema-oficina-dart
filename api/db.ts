import 'dotenv/config';
import { env } from 'prisma/config';
import { PrismaClient } from '../generated/prisma/client.ts';
import { PrismaMariaDb } from '@prisma/adapter-mariadb';

const adapter = new PrismaMariaDb({
  host: env('DATABASE_HOST'),
  port: parseInt(env('DATABASE_PORT')),
  user: env('DATABASE_USER'),
  password: env('DATABASE_PASSWORD'),
  database: env('DATABASE_NAME'),
});

export const prisma = new PrismaClient({ adapter });
