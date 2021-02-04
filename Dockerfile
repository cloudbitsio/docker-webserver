FROM ubuntu:20.04

# Update Lists
RUN apt-get clean && apt-get -y update 

# Set timezone, locale and install essentials
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && DEBIAN_FRONTEND=noninteractive apt-get install  --no-install-recommends --no-install-suggests --yes --quiet \
        software-properties-common apt-transport-https ca-certificates \
        sudo wget bash gnupg2 git curl nano zip unzip locales tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && locale-gen en_US.UTF-8
ENV LANG C.UTF-8 \
    LANGUAGE C.UTF-8 \
    LC_ALL C.UTF-8
RUN /usr/sbin/update-locale

# Get the latest nginx from repo and install
RUN add-apt-repository ppa:ondrej/nginx \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --yes --quiet \
    nginx \
    php7.4-dom php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-common php7.4-curl php7.4-zip php7.4-redis \
    php7.4-opcache php7.4-cgi php7.4-dev php7.4-fpm php7.4-gd php7.4-gmp php7.4-imap php7.4-intl \
    php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-xml php7.4-simplexml php7.4-imagick \
    mysql-client lvm2

## Install Composer
RUN curl https://getcomposer.org/installer > composer-setup.php \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && rm composer-setup.php 

## Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# ## Configure the php-fpm.conf and fpm/php.ini
RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php\/php7.4-fpm.pid/" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini

## Override the default PHP configs
COPY ./php/cli.ini /etc/php/7.4/mods-available/custom-cli.ini
COPY ./php/fpm.ini /etc/php/7.4/mods-available/custom-fpm.ini
RUN ln -s /etc/php/7.4/mods-available/custom-cli.ini /etc/php/7.4/fpm/conf.d/30-cli.ini
RUN ln -s /etc/php/7.4/mods-available/custom-fpm.ini /etc/php/7.4/fpm/conf.d/30-fpm.ini

# Clean the package manager caches
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Nginx forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]
EXPOSE 80 443

CMD service php7.4-fpm start && nginx -g "daemon off;"
