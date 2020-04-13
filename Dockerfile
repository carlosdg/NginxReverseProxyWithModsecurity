# References:
# - How to implement ModSecurity WAF with NGINX: https://medium.com/building-goalwise/how-to-implement-modsecurity-waf-with-nginx-15fdd42fa3
# - Compiling NGINX module as dynamic module for use in docker: https://gist.github.com/hermanbanken/96f0ff298c162a522ddbba44cad31081
# - Stackoverflow & Google for solving many errors

FROM nginx:1.16.1-alpine

# Add dependencies
RUN apk add git \
  gcc \
  g++ \
  make \
  automake \
  curl \
  autoconf \
  libtool \
  pcre \
  pcre-dev \
  libxml2 \
  libxml2-dev \
  linux-headers

# Compiling modsecurity code
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
  cd ModSecurity && \
  git submodule init && \
  git submodule update && \
  ./build.sh && \
  ./configure && \
  make && \
  make install

# Compiling modsecurity connector for nginx
RUN ORIGINAL_CONFIG=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
  wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  tar -xvzmf nginx.tar.gz && \
  cd "nginx-${NGINX_VERSION}" && \
  ./configure --with-compat $ORIGINAL_CONFIG --add-dynamic-module=../ModSecurity-nginx && \
  make modules && \
  cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

# Add config files
RUN rm -rf /etc/nginx/nginx.conf /etc/nginx/conf.d
COPY conf /etc/nginx/

# Configuration for when starting the container
WORKDIR /etc/nginx/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
