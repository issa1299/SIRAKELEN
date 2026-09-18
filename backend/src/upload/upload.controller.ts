import {
  Controller,
  Post,
  Param,
  UploadedFile,
  UseInterceptors,
  Body,
  Get,
  Res,
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
          cb(null, `${unique}${extname(file.originalname)}`);
        },
      }),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          cb(new Error('Seuls les formats jpg, png, webp sont acceptés'), false);
        } else {
          cb(null, true);
        }
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadPhoto(
    @Param('userId') userId: string,
    @UploadedFile() file: any,
  ) {
    const filename = file.filename;
    const url = `/upload/photos/${filename}`;
    return { url, filename };
  }

  @Get('photos/:filename')
  servePhoto(@Param('filename') filename: string, @Res() res: Response) {
    return res.sendFile(join(process.cwd(), 'uploads', 'photos', filename));
  }
}
