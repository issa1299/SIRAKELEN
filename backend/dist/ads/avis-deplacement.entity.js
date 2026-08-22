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
exports.AvisDeplacement = exports.StatutAd = exports.RoleAd = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../users/user.entity");
var RoleAd;
(function (RoleAd) {
    RoleAd["CONDUCTEUR"] = "conducteur";
    RoleAd["PASSAGER"] = "passager";
})(RoleAd || (exports.RoleAd = RoleAd = {}));
var StatutAd;
(function (StatutAd) {
    StatutAd["ACTIF"] = "actif";
    StatutAd["EN_COURS_DE_FINALISATION"] = "en_cours_de_finalisation";
    StatutAd["TRAJET_ORGANISE"] = "trajet_organise";
    StatutAd["ANNULE"] = "annule";
})(StatutAd || (exports.StatutAd = StatutAd = {}));
let AvisDeplacement = class AvisDeplacement {
};
exports.AvisDeplacement = AvisDeplacement;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, (u) => u.ads),
    __metadata("design:type", user_entity_1.User)
], AvisDeplacement.prototype, "proprietaire", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: RoleAd }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "role", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 150 }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "depart", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 150 }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "destination", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "dateDeplacement", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 5 }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "heureDepart", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 40, nullable: true }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "moyenTransport", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', nullable: true }),
    __metadata("design:type", Number)
], AvisDeplacement.prototype, "placesDisponibles", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: StatutAd, default: StatutAd.ACTIF }),
    __metadata("design:type", String)
], AvisDeplacement.prototype, "statut", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], AvisDeplacement.prototype, "creeLe", void 0);
exports.AvisDeplacement = AvisDeplacement = __decorate([
    (0, typeorm_1.Entity)('avis_deplacement')
], AvisDeplacement);
//# sourceMappingURL=avis-deplacement.entity.js.map