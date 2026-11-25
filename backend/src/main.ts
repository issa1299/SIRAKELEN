import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { setDefaultResultOrder } from 'node:dns';
import { AppModule } from './app.module';
import * as compression from 'compression';
import * as express from 'express';

// Force IPv4 en premier : certains hebergeurs (Render) n'ont pas
// de sortie IPv6 alors que les hotes Supabase directs se resolvent en IPv6.
setDefaultResultOrder('ipv4first');

// --- Rate limiter en memoire (simple, sans dependance externe) ---
interface Bucket {
  count: number;
  resetAt: number;
}
const buckets = new Map<string, Bucket>();

function rateLimit(
  fenetreMs: number,
  maxRequetes: number,
): express.RequestHandler {
  return (req, res, next) => {
    const ip = (req.ip || req.socket?.remoteAddress || 'unknown') as string;
    const cle = `${ip}:${req.path}`;
    const now = Date.now();
    let b = buckets.get(cle);
    if (!b || now > b.resetAt) {
      b = { count: 0, resetAt: now + fenetreMs };
      buckets.set(cle, b);
    }
    b.count++;
    if (b.count > maxRequetes) {
      res.status(429).json({
        statusCode: 429,
        code: 'TROP_DE_REQUETES',
        message: 'Trop de requetes. Reessaie dans quelques minutes.',
      });
      return;
    }
    next();
  };
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // --- Compression HTTP (gzip) ---
  app.use(compression());

  // --- CORS restreint aux domaines autorises ---
  const corsOrigins = process.env.CORS_ORIGINS;
  const origines = corsOrigins
    ? corsOrigins.split(',').map((o) => o.trim())
    : true; // true = reflechit l'origine de la requete (dev)
  app.enableCors({
    origin: origines,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization',
    credentials: !!corsOrigins,
  });

  // --- Rate limiting global (60 req/min par IP) ---
  app.use(rateLimit(60_000, 60));

  // --- Rate limiting strict sur auth (10 req/5min par IP) ---
  app.use('/auth', rateLimit(300_000, 10));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
    }),
  );

  await app.listen(process.env.PORT ?? 8080);
  console.log(`[Nest] Serveur demarre sur le port ${process.env.PORT ?? 8080}`);
}
bootstrap();