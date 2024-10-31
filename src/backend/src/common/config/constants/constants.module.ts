import { Global, Module } from '@nestjs/common';
import { ConstantsService } from './constants.service';
import { ConfigModule } from '@nestjs/config';
import { Env } from './constants.interface';
import * as Joi from 'joi';

@Global()
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: false,
      validationSchema: Joi.object({
        NODE_ENV: Joi.string()
          .valid(...Object.values(Env))
          .optional(),
        PORT: Joi.number().optional(),
        BASIC_AUTH_USERNAME: Joi.string().required(),
        BASIC_AUTH_PASSWORD: Joi.string().required(),
      }),
      validationOptions: {
        allowUnknown: true,
        abortEarly: false,
      },
    }),
  ],
  providers: [ConstantsService],
  exports: [ConstantsService],
})
export class ConstantsModule {}
