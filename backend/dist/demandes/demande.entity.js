"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Demande = exports.StatutDemande = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../users/user.entity");
const avis_deplacement_entity_1 = require("../ads/avis-deplacement.entity");
var StatutDemande;
(function (StatutDemande) {
    StatutDemande["EN_ATTENTE"] = "en_attente";
    StatutDemande["ACCEPTEE"] = "acceptee";
    StatutDemande["REFUSEE"] = "refusee";
    StatutDemande["ANNULEE"] = "annulee";
})(StatutDemande || (exports.StatutDemande = StatutDemande = {}));
let Demande = class Demande {
};
exports.Demande = Demande;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Demande.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => avis_deplacement_entity_1.AvisDeplacement),
    __metadata("design:type", avis_deplacement_entity_1.AvisDeplacement)
], Demande.prototype, "ad", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, (u) => u.demandesEnvoyees),
    __metadata("design:type", user_entity_1.User)
], Demande.prototype, "demandeur", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: StatutDemande, default: StatutDemande.EN_ATTENTE }),
    __metadata("design:type", String)
], Demande.prototype, "statut", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Demande.prototype, "creeLe", void 0);
exports.Demande = Demande = __decorate([
    (0, typeorm_1.Entity)('demandes')
], Demande);
//# sourceMappingURL=demande.entity.js.map