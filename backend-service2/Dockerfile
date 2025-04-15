FROM node:18-alpine

WORKDIR /app

COPY package.json .
COPY server.js .

RUN npm install

EXPOSE 8082

CMD ["node", "server.js"] 
