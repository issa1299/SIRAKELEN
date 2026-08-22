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
exports.User = void 0;
const typeorm_1 = require("typeorm");
const contact_urgence_entity_1 = require("../contact-urgence/contact-urgence.entity");
const avis_deplacement_entity_1 = require("../ads/avis-deplacement.entity");
const demande_entity_1 = require("../demandes/demande.entity");
let User = class User {
};
exports.User = User;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], User.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 80 }),
    __metadata("design:type", String)
], User.prototype, "prenom", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 80 }),
    __metadata("design:type", String)
], User.prototype, "nom", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 20, unique: true }),
    __metadata("design:type", String)
], User.prototype, "telephone", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 120 }),
    __metadata("design:type", String)
], User.prototype, "quartier", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "photoUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: false }),
    __metadata("design:type", Boolean)
], User.prototype, "verifie", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], User.prototype, "creeLe", void 0);
__decorate([
    (0, typeorm_1.OneToOne)(() => contact_urgence_entity_1.ContactUrgence, (c) => c.user, { nullable: true }),
    __metadata("design:type", contact_urgence_entity_1.ContactUrgence)
], User.prototype, "contactUrgence", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => avis_deplacement_entity_1.AvisDeplacement, (ad) => ad.proprietaire),
    __metadata("design:type", Array)
], User.prototype, "ads", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => demande_entity_1.Demande, (d) => d.demandeur),
    __metadata("design:type", Array)
], User.prototype, "demandesEnvoyees", void 0);
exports.User = User = __decorate([
    (0, typeorm_1.Entity)('users')
], User);
//# sourceMappingURL=user.entity.js.map