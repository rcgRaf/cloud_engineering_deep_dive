import { Injectable } from '@nestjs/common';
import { CreateTaskDto } from './dto/create-task.dto';
import { GetTasksQueryDto } from './dto/get-task-query.dto';
import { ConstantsService } from '../../common/config/constants/constants.service';
import { Task } from './task.interface';
@Injectable()
export class TaskService {
  private todos = [
    {
      id: '1',
      title: 'Complete project proposal',
      descriptions:
        'Draft and finalize the proposal for the new client project',
      dueDate: new Date('2024-03-15'),
      done: false,
    },
    {
      id: '2',
      title: 'Schedule dentist appointment',
      descriptions: "Call Dr. Smith's office for a routine check-up",
      dueDate: new Date('2024-02-28'),
      done: false,
    },
    {
      id: '3',
      title: 'Gym session',
      descriptions: 'Cardio and strength training at the local gym',
      dueDate: new Date('2024-01-10'),
      done: true,
    },
    {
      id: '4',
      title: 'Pay utility bills',
      descriptions:
        'Settle electricity, water, and internet bills for the month',
      dueDate: new Date('2024-01-25'),
      done: false,
    },
    {
      id: '5',
      title: 'Plan summer vacation',
      descriptions:
        'Research destinations and book flights for the family trip',
      dueDate: new Date('2024-04-30'),
      done: false,
    },
    {
      id: '6',
      title: 'Learn new programming language',
      descriptions: 'Start online course for Python programming',
      dueDate: new Date('2024-06-01'),
      done: false,
    },
    {
      id: '7',
      title: 'Organize garage',
      descriptions: 'Sort through items and declutter the garage space',
      dueDate: new Date('2024-02-15'),
      done: true,
    },
    {
      id: '8',
      title: 'Prepare tax documents',
      descriptions:
        'Gather and organize all necessary paperwork for tax filing',
      dueDate: new Date('2024-03-31'),
      done: false,
    },
    {
      id: '9',
      title: 'Birthday gift for Mom',
      descriptions: 'Shop for and purchase a thoughtful birthday present',
      dueDate: new Date('2024-05-10'),
      done: false,
    },
    {
      id: '10',
      title: 'Update resume',
      descriptions: 'Revise and modernize resume with recent accomplishments',
      dueDate: new Date('2024-02-20'),
      done: true,
    },
  ];
  constructor(private readonly constantsService: ConstantsService) {}

  create(createTaskDto: CreateTaskDto) {
    return createTaskDto;
  }

  async findAll(query: GetTasksQueryDto): Promise<Array<Task>> {
    const done = query.done;
    return this.todos.filter(
      (item) => done === undefined || item.done === done,
    );
  }

  findOne(id: number) {
    return `This action returns a #${id} task`;
  }

  update(id: number) {
    return `This action updates a #${id} task`;
  }

  remove(id: number) {
    return `This action removes a #${id} task`;
  }
}
