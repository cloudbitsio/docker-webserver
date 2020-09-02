FROM ubuntu:20.04

# Update Lists
RUN apt-get clean && apt-get -y update 

# Set timezone, locale and install essentials
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && DEBIAN_FRONTEND=noninteractive apt-get install  --no-install-recommends --no-install-suggests --yes --quiet \
        software-properties-common apt-transport-https ca-certificates \
        sudo wget gnupg2 git curl nano locales tzdata \
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
    php7.4-dom php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-common php7.4-curl php7.4-zip \
    php7.4-opcache php7.4-cgi php7.4-dev php7.4-fpm php7.4-gd php7.4-gmp php7.4-imap php7.4-intl \
    php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-xml php7.4-simplexml php7.4-imagick

## Install Composer
RUN curl https://getcomposer.org/installer > composer-setup.php \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && rm composer-setup.php 

## Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

## Configure the php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.4/cli/php.ini && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.4/fpm/php.ini && \
    sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.4/fpm/php.ini && \
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 12M/" /etc/php/7.4/fpm/php.ini && \
    sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.4/fpm/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini && \
    # FPM
    sed -i -e "s/pid =.*/pid = \/var\/run\/php\/php7.4-fpm.pid/" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf && \
    sed -i "s/listen = .*/listen = \/var\/run\/php\/php7.4-fpm.sock/" /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.4/fpm/pool.d/www.conf

# Clean the package manager caches
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Nginx forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]
EXPOSE 80 443 9000

CMD service php7.4-fpm start && nginx -g "daemon off;"
