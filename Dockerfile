FROM node
WORKDIR /app
ADD . /app
COPY package.json .
COPY index.js .
RUN npm install --quiet
RUN npm i express
RUN npm  install mysql
ENV PORT 3000
ENV IP "172.17.0.3"

