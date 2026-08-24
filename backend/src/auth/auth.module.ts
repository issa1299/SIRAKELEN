import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { SmsService } from './sms.service';
import { CodeVerification } from './code-verification.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([CodeVerification]), UsersModule],
  controllers: [AuthController],
  providers: [AuthService, SmsService],
})
export class AuthModule {}
