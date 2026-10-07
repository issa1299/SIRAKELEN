# Backend SIRA KELEN (NestJS) — image de production.
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
# Dossier des photos uploadees (ephemere sur offre gratuite).
RUN mkdir -p uploads/photos
EXPOSE 8080
CMD ["node", "dist/main"]
