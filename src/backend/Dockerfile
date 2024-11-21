FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

RUN ls -la dist

EXPOSE 4444

WORKDIR /usr/src/app/dist/src

CMD ["node", "main.js"]