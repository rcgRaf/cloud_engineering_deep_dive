import { Test, TestingModule } from '@nestjs/testing';
import { ConstantsService } from './constants.service';
import { ConfigService } from '@nestjs/config';
import { mockConstantsService } from '../../../../__mocks__/constants.mock';
describe('ConstantsService', () => {
  let service: ConstantsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConstantsService,
        {
          provide: ConfigService,
          useValue: mockConstantsService,
        },
      ],
    }).compile();

    service = module.get<ConstantsService>(ConstantsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
