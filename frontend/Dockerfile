# ---- build ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Браузер ходит на тот же хост, nginx проксирует /api на бэкенд
ENV NODE_ENV=production \
    VUE_APP_API_URL=/api
RUN npm run build

# ---- runtime ----
FROM nginxinc/nginx-unprivileged:1.27-alpine
# *.template обрабатываются envsubst при старте контейнера
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
ENV BACKEND_URL=http://momo-backend:8081
EXPOSE 8080
