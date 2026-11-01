FROM php:8.4-cli-alpine
WORKDIR /app

RUN apk add --no-cache git unzip libzip-dev sqlite-dev oniguruma-dev icu-dev libpng-dev nodejs npm \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite zip mbstring intl bcmath gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .

RUN rm -f .env \
    && composer install --no-interaction --ignore-platform-reqs --no-scripts \
    && php artisan package:discover --ansi || true

RUN (npm install --legacy-peer-deps || npm install) \
    && npm run build


RUN mkdir -p database storage/framework/sessions storage/framework/views storage/framework/cache/data storage/logs bootstrap/cache \
    && touch database/database.sqlite \
    && chmod -R 777 storage bootstrap/cache database public/build

EXPOSE 3000
CMD ["sh", "-c", "php artisan livewire:publish --assets || true; php artisan storage:link || true; php artisan migrate --seed --force || true; php artisan serve --host=0.0.0.0 --port=3000"]
