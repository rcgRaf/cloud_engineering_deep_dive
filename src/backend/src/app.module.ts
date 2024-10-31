import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TaskModule } from './models/task/task.module';
import { AuthenticateMiddleware } from './common/middlewares/authenticate/authenticate.middleware';
import { ConstantsModule } from './common/config/constants/constants.module';
@Module({
  imports: [TaskModule, ConstantsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(AuthenticateMiddleware).exclude('/v1').forRoutes('*');
  }
}
