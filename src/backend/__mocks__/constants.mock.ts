export const mockConstantsService = {
    get: jest.fn().mockImplementation((key: string) => {
      switch (key) {
        case 'auth.basic':
          return { username: 'testuser', password: 'testpass' };
        default:
          return undefined;
      }
    }),
  };
  
