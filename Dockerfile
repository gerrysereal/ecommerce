FROM node:20-alpine AS frontend
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps || npm install
COPY . .
RUN npm run build

FROM php:8.3-cli-alpine
WORKDIR /app

RUN apk add --no-cache git unzip libzip-dev sqlite-dev oniguruma-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite zip mbstring

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .
COPY --from=frontend /app/public/build ./public/build

RUN rm -f .env \
    && (composer install --no-interaction --optimize-autoloader --no-dev || composer install --no-interaction --ignore-platform-reqs) \
    && touch database/database.sqlite

EXPOSE 3000
CMD ["sh", "-c", "php artisan migrate --force || true; php artisan serve --host=0.0.0.0 --port=3000"]
