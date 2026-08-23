# Stage 1: Build dependencies
FROM node:20-alpine AS builder
RUN apk update && apk upgrade --no-cache
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime image
FROM node:20-alpine
RUN apk update && apk upgrade --no-cache
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
EXPOSE 4000
CMD ["node", "src/index.js"]