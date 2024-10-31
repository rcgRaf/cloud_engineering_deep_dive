export enum Env {
  LOCAL = 'local',
  DEV = 'dev',
}

export interface AuthConfig {
  basic: {
    username: string;
    password: string;
  };
}

export interface Constants {
  env: Env;
  auth: AuthConfig;
}
