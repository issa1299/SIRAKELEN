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
exports.Signalement = exports.StatutSignalement = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../users/user.entity");
var StatutSignalement;
(function (StatutSignalement) {
    StatutSignalement["EN_ATTENTE"] = "en_attente";
    StatutSignalement["TRAITE"] = "traite";
})(StatutSignalement || (exports.StatutSignalement = StatutSignalement = {}));
let Signalement = class Signalement {
};
exports.Signalement = Signalement;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Signalement.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User),
    __metadata("design:type", user_entity_1.User)
], Signalement.prototype, "utilisateurSignale", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User),
    __metadata("design:type", user_entity_1.User)
], Signalement.prototype, "auteur", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255 }),
    __metadata("design:type", String)
], Signalement.prototype, "motif", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: StatutSignalement,
        default: StatutSignalement.EN_ATTENTE,
    }),
    __metadata("design:type", String)
], Signalement.prototype, "statut", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Signalement.prototype, "creeLe", void 0);
exports.Signalement = Signalement = __decorate([
    (0, typeorm_1.Entity)('signalements')
], Signalement);
//# sourceMappingURL=signalement.entity.js.map