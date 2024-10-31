import { Controller, Get } from '@nestjs/common';
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
}
