
FROM node:22-alpine AS frontend
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps || npm install || true
COPY . .
RUN npm run build || mkdir -p public/build


FROM php:8.3-cli-alpine
WORKDIR /app

RUN apk add --no-cache git unzip libzip-dev sqlite-dev oniguruma-dev icu-dev libpng-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite zip mbstring intl bcmath gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .
COPY --from=frontend /app/public/build ./public/build

RUN rm -f .env \
    && composer install --no-interaction --ignore-platform-reqs --no-scripts \
    && mkdir -p database storage/framework/sessions storage/framework/views storage/framework/cache/data storage/logs bootstrap/cache \
    && touch database/database.sqlite \
    && chmod -R 777 storage bootstrap/cache database

EXPOSE 3000
CMD ["sh", "-c", "php artisan migrate --force || true; php artisan serve --host=0.0.0.0 --port=3000"]
