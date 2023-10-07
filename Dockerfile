ARG NGINX_VERSION="1.24.0"

FROM nginx:${NGINX_VERSION}-alpine as build

ARG VTS_VERSION="0.2.2"

RUN apk add --no-cache \
  curl \
  g++ \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev

RUN curl -sOL "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
  && tar -C /tmp -xzvf nginx-${NGINX_VERSION}.tar.gz

RUN curl -OL "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v${VTS_VERSION}.zip"  \
  && ls -al ; unzip "v${VTS_VERSION}.zip" -d /tmp/

WORKDIR /tmp/nginx-${NGINX_VERSION}

RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  ./configure --with-compat --with-http_ssl_module --add-dynamic-module=/tmp/nginx-module-vts-${VTS_VERSION} ${NGINX_ARGS} \
  && make modules


FROM nginx:${NGINX_VERSION}-alpine

COPY --from=build /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_vhost_traffic_status_module.so /usr/lib/nginx/modules/
COPY ./assets/nginx.conf /etc/nginx/nginx.conf
COPY ./assets/nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
