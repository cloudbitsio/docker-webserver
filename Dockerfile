FROM ubuntu:20.04

# Update Lists
RUN sed -i 's|http://us.|http://|g' /etc/apt/sources.list && \
    apt-get clean && \
    apt-get -y update 

# Set timezone, locale and install essentials
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && DEBIAN_FRONTEND=noninteractive apt-get install  --no-install-recommends --no-install-suggests --yes --quiet \
        software-properties-common apt-transport-https ca-certificates build-essential libpcre3 libpcre3-dev \
        sudo wget bash gnupg2 git curl nano zip unzip locales tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && locale-gen en_US.UTF-8
ENV LANG C.UTF-8 \
    LANGUAGE C.UTF-8 \
    LC_ALL C.UTF-8
RUN /usr/sbin/update-locale

RUN add-apt-repository ppa:ondrej/nginx \
   && apt-get install --no-install-recommends --no-install-suggests --yes --quiet \
   nginx

# # Get NAXSI
# RUN export NAXSI_VER=1.3 && \
#     wget https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz -O naxsi_$NAXSI_VER.tar.gz && \
#     tar vxf naxsi_$NAXSI_VER.tar.gz

# # Get Cache PURGE
# RUN export PURGE_VER=2.3.1 && \
#     wget https://github.com/torden/ngx_cache_purge/archive/v$PURGE_VER.tar.gz -O purge_$PURGE_VER.tar.gz && \
#     tar vxf purge_$PURGE_VER.tar.gz

# # Get Nginx and make
# RUN export NGINX_VER=1.18.0 && \
#     wget https://nginx.org/download/nginx-$NGINX_VER.tar.gz -O nginx_$NGINX_VER.tar.gz && \
#     tar vxf nginx_$NGINX_VER.tar.gz && \
#     # Build NAXSI and PURGE as a dynamic extension
#     cd nginx-$NGINX_VER && \
#     ./configure && \
#         --add-dynamic-module=../naxsi_$NAXSI_VER/naxsi_src/ && \
#         --add-dynamic-module=../purge_$PURGE_VER/ --with-compat && \
#     make modules && make 

# Get the latest PHP from repo and install
RUN add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --yes --quiet \
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
