import {
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { AuthConfig } from '../../config/constants/constants.interface';
import { ConstantsService } from '../../config/constants/constants.service';

@Injectable()
export class AuthenticateMiddleware implements NestMiddleware {
  constructor(private readonly constantsService: ConstantsService) {}
  use(req: Request, res: Response, next: NextFunction) {
    const { username, password } =
      this.constantsService.get<AuthConfig['basic']>('auth.basic');
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Authorization header is missing');
    }
    const [authType, authToken] = authHeader.split(' ');

    if (authType !== 'Basic') {
      throw new UnauthorizedException('Invalid authorization type');
    }

    const credentials = Buffer.from(authToken, 'base64').toString('utf-8');
    if (`${username}:${password}` !== credentials) {
      throw new UnauthorizedException('Invalid credentials');
    }

    next();
  }
}
