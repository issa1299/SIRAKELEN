import {
  Controller,
  Post,
  Param,
  UploadedFile,
  UseInterceptors,
  Body,
  Get,
  Res,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { Response } from 'express';
import { randomUUID } from 'crypto';

@Controller('upload')
export class UploadController {
  @Post('photo/:userId')
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: diskStorage({
        destination: './uploads/photos',
        filename: (_req, file, cb) => {
          const unique = randomUUID();
          let ext = extname(file.originalname);
          if (!ext) {
            const parType: Record<string, string> = {
              'image/jpeg': '.jpg',
              'image/png': '.png',
              'image/webp': '.webp',
              'image/heic': '.heic',
              'image/heif': '.heif',
              'image/gif': '.gif',
              'image/bmp': '.bmp',
            };
            ext = parType[file.mimetype] ?? '';
          }
          cb(null, `${unique}${ext}`);
        },
      }),
      // Aucun filtre : tous les fichiers sont acceptes (l'appareil photo
      // envoie parfois un mimetype generique selon l'appareil).
    }),
  )
  async uploadPhoto(
    @Param('userId') userId: string,
    @UploadedFile() file: any,
  ) {
    if (!file) {
      throw new BadRequestException('Aucun fichier reçu. Reessaie.');
    }
    const filename = file.filename;
    const url = `/upload/photos/${filename}`;
    return { url, filename };
  }

  @Get('photos/:filename')
  servePhoto(@Param('filename') filename: string, @Res() res: Response) {
    return res.sendFile(join(process.cwd(), 'uploads', 'photos', filename));
  }
}
