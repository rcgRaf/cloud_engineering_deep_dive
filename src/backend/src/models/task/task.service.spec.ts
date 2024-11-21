import { Test, TestingModule } from '@nestjs/testing';
import { TaskService } from './task.service';
import { ConstantsService } from '../../common/config/constants/constants.service';

describe('TaskService', () => {
  let service: TaskService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TaskService,
        {
          provide: ConstantsService,
          useValue: {
            // Mock the methods of ConstantsService that TaskService uses
            // For example:
            // getAuthConfig: jest.fn().mockReturnValue({ /* mock auth config */ }),
          },
        },
      ],
    }).compile();

    service = module.get<TaskService>(TaskService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
