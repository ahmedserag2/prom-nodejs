FROM node:18-alpine As builder

WORKDIR /app

COPY --chown=node:node package*.json ./

# get node_mu
RUN npm install

COPY --chown=node:node . .





FROM node:18-alpine

USER node

WORKDIR /app

COPY --chown=node:node --from=builder /app /app

EXPOSE 3000

CMD [ "node", "app.js" ]
