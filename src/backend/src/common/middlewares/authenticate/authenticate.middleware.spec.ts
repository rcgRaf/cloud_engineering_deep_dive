import { Test, TestingModule } from '@nestjs/testing';
import { AuthenticateMiddleware } from './authenticate.middleware';
import { ConstantsService } from '../../config/constants/constants.service';
import { mockConstantsService } from '../../../../__mocks__/constants.mock';

describe('AuthenticateMiddleware', () => {
  let authenticateMiddleware: AuthenticateMiddleware;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthenticateMiddleware,
        { provide: ConstantsService, useValue: mockConstantsService },
      ],
    }).compile();

    authenticateMiddleware = module.get<AuthenticateMiddleware>(
      AuthenticateMiddleware,
    );
  });

  it('should be defined', () => {
    expect(authenticateMiddleware).toBeDefined();
  });
});
