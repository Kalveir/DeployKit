FROM alpine:latest

# Install dependencies & PHP extensions
RUN apk update && apk upgrade && \
    apk add curl git unzip php82 php82-pdo php82-pdo_pgsql php82-openssl php82-mbstring php82-tokenizer php82-json php82-fileinfo php82-ctype php82-curl php82-phar php82-session php82-dom php82-xml php82-xmlwriter openrc && \
    rm -rf /var/cache/apk/*

# Create openrc
RUN mkdir -p /run/openrc
RUN touch /run/openrc/softlevel

# Symbolic link php
RUN ln -s /usr/bin/php82 /usr/bin/php

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
    
# Set working directory
RUN mkdir -p /app
WORKDIR /app

# Copy application source
COPY . .
# Copy entrypoint script
RUN mv deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create Folder Frankenphp
RUN mkdir -p /usr/local/frankenphp

# Install Frankenphp
RUN curl -L -o franken https://github.com/dunglas/frankenphp/releases/download/v1.2.1/frankenphp-linux-x86_64 && \
mv franken /usr/local/frankenphp && \
chmod +x /usr/local/frankenphp/franken

CMD ["/entrypoint.sh"]
