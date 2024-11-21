import { Controller, Get, HttpCode, Header } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('v1')
  getVersion(): object {
    return {
      version: '1.0.0',
      description: 'aca cloud engineering deep dive api',
    };
  }

  @Get('health')
  @Header('Cache-Control', 'no-cache, no-store, must-revalidate')
  @Header('Pragma', 'no-cache')
  @Header('Expires', '0')
  @HttpCode(200)
  getHealth(): object {
    return {
      status: 'ok',
    };
  }
}
