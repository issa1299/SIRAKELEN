import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { spawnSync } from 'child_process';
import { createGzip } from 'zlib';
import { createWriteStream, existsSync, mkdirSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { Readable } from 'stream';
import { pipeline } from 'stream/promises';

/**
 * Sauvegardes PostgreSQL. Les fichiers restent sur le serveur : AUCUN endpoint
 * ne les expose publiquement. Sur Render le disque est éphémère : l'état le
 * signale clairement dans le rapport.
 */
@Injectable()
export class SauvegardesService {
  private readonly logger = new Logger(SauvegardesService.name);
  private readonly dossier: string;

  constructor(private readonly config: ConfigService) {
    this.dossier = this.config.get<string>('BACKUP_DIR') || join(process.cwd(), 'backups');
  }

  private pgDumpDisponible(): boolean {
    const r = spawnSync('pg_dump', ['--version'], { encoding: 'utf8' });
    return r.status === 0;
  }

  etat() {
    const url = this.config.get<string>('DATABASE_URL');
    let dossierAccessible = false;
    let fichiers: Array<{ nom: string; tailleOctets: number; date: Date }> = [];
    try {
      if (!existsSync(this.dossier)) mkdirSync(this.dossier, { recursive: true });
      dossierAccessible = true;
      fichiers = readdirSync(this.dossier)
        .filter((f) => f.endsWith('.sql.gz'))
        .map((f) => {
          const s = statSync(join(this.dossier, f));
          return { nom: f, tailleOctets: s.size, date: s.mtime };
        })
        .sort((a, b) => b.date.getTime() - a.date.getTime())
        .slice(0, 20);
    } catch (e) {
      this.logger.warn(`Dossier backups inaccessible : ${(e as Error).message}`);
    }
    return {
      baseConfiguree: !!url,
      pgDumpDisponible: this.pgDumpDisponible(),
      dossierAccessible,
      stockagePermanent: false,
      avertissement:
        'Sur Render, le système de fichiers est éphémère : les fichiers de sauvegarde ne persistent pas après redéploiement. Les fichiers ne sont jamais exposés publiquement.',
      sauvegardes: fichiers,
    };
  }

  async lancer() {
    const etat = this.etat();
    if (!etat.baseConfiguree || !etat.pgDumpDisponible || !etat.dossierAccessible) {
      throw new ServiceUnavailableException(
        'Sauvegarde impossible : vérifiez DATABASE_URL, pg_dump et BACKUP_DIR sur le serveur.',
      );
    }
    const url = new URL(this.config.get<string>('DATABASE_URL'));
    const nom = `sirakelen-${new Date().toISOString().replace(/[:.]/g, '-')}.sql.gz`;
    const chemin = join(this.dossier, nom);

    const env = {
      ...process.env,
      PGHOST: decodeURIComponent(url.hostname),
      PGPORT: url.port || '5432',
      PGUSER: decodeURIComponent(url.username),
      PGPASSWORD: decodeURIComponent(url.password),
      PGDATABASE: decodeURIComponent(url.pathname.slice(1)),
      PGSSLMODE: 'require',
    };

    const dump = spawnSync('pg_dump', ['--no-owner', '--clean', '--if-exists'], {
      env,
      encoding: 'buffer',
      maxBuffer: 200 * 1024 * 1024,
    });
    if (dump.status !== 0) {
      const erreur = (dump.stderr?.toString() || '').slice(0, 300);
      this.logger.warn(`pg_dump échec : ${erreur}`);
      throw new ServiceUnavailableException(`Échec pg_dump : ${erreur}`);
    }

    await pipeline(Readable.from(dump.stdout as Buffer), createGzip(), createWriteStream(chemin));
    const s = statSync(chemin);
    return {
      nom,
      tailleOctets: s.size,
      date: s.mtime,
      message: 'Sauvegarde créée sur le serveur (non téléchargeable publiquement).',
    };
  }
}
