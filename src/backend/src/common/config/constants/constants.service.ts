import { Injectable } from '@nestjs/common';
import { Constants, Env } from './constants.interface';
import { ConfigService } from '@nestjs/config';
@Injectable()
export class ConstantsService {
  private readonly config: Constants;
  private pathCache = new Map<string, unknown>();

  constructor(private configService: ConfigService) {
    this.config = {
      env: this.configService.get<Env>('NODE_ENV', Env.LOCAL),
      auth: {
        basic: {
          username: this.configService.get<string>('BASIC_AUTH_USERNAME'),
          password: this.configService.get<string>('BASIC_AUTH_PASSWORD'),
        },
      },
    };
  }

  get<T>(path: string): T {
    if (this.pathCache[path]) return this.pathCache[path] as T;
    const value = path
      .split('.')
      .reduce((config, key) => config && config[key], this.config) as T;
    this.pathCache[path] = value;
    return value;
  }
}
