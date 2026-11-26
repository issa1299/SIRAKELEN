import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SiteContenu } from './site-contenu.entity';
import { SiteNews } from './site-news.entity';
import { SiteFaq } from './site-faq.entity';

@Injectable()
export class SiteContenuService {
  constructor(
    @InjectRepository(SiteContenu) private readonly contenuRepo: Repository<SiteContenu>,
    @InjectRepository(SiteNews) private readonly newsRepo: Repository<SiteNews>,
    @InjectRepository(SiteFaq) private readonly faqRepo: Repository<SiteFaq>,
  ) {}

  // ---------- Textes, images, liens, paramètres ----------

  async findContenu(groupe?: string) {
    const where = groupe ? { where: { groupe } } : {};
    return this.contenuRepo.find({ ...where, order: { cle: 'ASC' } });
  }

  async getContenu(cle: string) {
    const c = await this.contenuRepo.findOne({ where: { cle } });
    return c?.valeur ?? null;
  }

  async setContenu(cle: string, valeur: string, groupe: string, type: string, adminId: string) {
    if (!cle || !cle.trim()) throw new NotFoundException('Clé requise');
    let c = await this.contenuRepo.findOne({ where: { cle: cle.trim() } });
    if (!c) {
      c = this.contenuRepo.create({ cle: cle.trim(), valeur, groupe, type });
    } else {
      c.valeur = valeur;
      if (groupe) c.groupe = groupe;
      if (type) c.type = type;
    }
    c.modifiePar = adminId;
    await this.contenuRepo.save(c);
    return c;
  }

  /** Publication publique : textes + actualités + FAQ en un seul appel. */
  async public() {
    const [contenu, news, faq] = await Promise.all([
      this.contenuRepo.find({ order: { cle: 'ASC' } }),
      this.newsRepo.find({
        where: { actif: true },
        order: { datePublication: 'DESC' },
        take: 20,
      }),
      this.faqRepo.find({ where: { actif: true }, order: { ordre: 'ASC' } }),
    ]);
    const textes: Record<string, string> = {};
    for (const c of contenu) textes[c.cle] = c.valeur;
    return { textes, actualites: news, faq };
  }

  // ---------- Actualités ----------

  async findNews() {
    return this.newsRepo.find({ order: { creeLe: 'DESC' }, take: 50 });
  }

  async creerNews(dto: {
    titre: string;
    contenu: string;
    imageUrl?: string;
    datePublication?: string;
    actif?: boolean;
  }) {
    const news = this.newsRepo.create({
      titre: dto.titre,
      contenu: dto.contenu,
      imageUrl: dto.imageUrl || null,
      datePublication: dto.datePublication ? new Date(dto.datePublication) : new Date(),
      actif: dto.actif !== false,
    });
    return this.newsRepo.save(news);
  }

  async modifierNews(id: string, dto: Partial<SiteNews>) {
    const news = await this.newsRepo.findOne({ where: { id } });
    if (!news) throw new NotFoundException('Actualité introuvable');
    Object.assign(news, dto);
    if (dto.datePublication) news.datePublication = new Date(dto.datePublication as any);
    return this.newsRepo.save(news);
  }

  async supprimerNews(id: string) {
    const news = await this.newsRepo.findOne({ where: { id } });
    if (!news) throw new NotFoundException('Actualité introuvable');
    await this.newsRepo.remove(news);
    return { supprime: true };
  }

  // ---------- FAQ ----------

  async findFaq() {
    return this.faqRepo.find({ order: { ordre: 'ASC' }, take: 100 });
  }

  async creerFaq(dto: { question: string; reponse: string; ordre?: number; actif?: boolean }) {
    return this.faqRepo.save(
      this.faqRepo.create({
        question: dto.question,
        reponse: dto.reponse,
        ordre: dto.ordre ?? 0,
        actif: dto.actif !== false,
      }),
    );
  }

  async modifierFaq(id: string, dto: Partial<SiteFaq>) {
    const faq = await this.faqRepo.findOne({ where: { id } });
    if (!faq) throw new NotFoundException('FAQ introuvable');
    Object.assign(faq, dto);
    return this.faqRepo.save(faq);
  }

  async supprimerFaq(id: string) {
    const faq = await this.faqRepo.findOne({ where: { id } });
    if (!faq) throw new NotFoundException('FAQ introuvable');
    await this.faqRepo.remove(faq);
    return { supprime: true };
  }
}
