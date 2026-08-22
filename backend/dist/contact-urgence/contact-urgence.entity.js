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
exports.ContactUrgence = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../users/user.entity");
let ContactUrgence = class ContactUrgence {
};
exports.ContactUrgence = ContactUrgence;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], ContactUrgence.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.OneToOne)(() => user_entity_1.User, (u) => u.contactUrgence),
    (0, typeorm_1.JoinColumn)(),
    __metadata("design:type", user_entity_1.User)
], ContactUrgence.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 120 }),
    __metadata("design:type", String)
], ContactUrgence.prototype, "nomContact", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 20 }),
    __metadata("design:type", String)
], ContactUrgence.prototype, "telephoneContact", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 60, nullable: true }),
    __metadata("design:type", String)
], ContactUrgence.prototype, "lien", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], ContactUrgence.prototype, "creeLe", void 0);
exports.ContactUrgence = ContactUrgence = __decorate([
    (0, typeorm_1.Entity)('contact_urgence')
], ContactUrgence);
//# sourceMappingURL=contact-urgence.entity.js.map