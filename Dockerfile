FROM sunbird/openjdk-java11-alpine:latest
MAINTAINER "S M Y ALTAMASH <smy.altamash@gmail.com>"
USER root
RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache unzip curl chromium \
    font-noto-gujarati font-noto-kannada font-noto-avestan font-noto-osage font-noto-kayahli font-noto-oriya font-noto-telugu font-noto-tamil font-noto-bengali font-noto-malayalam font-noto-arabic font-noto-extra \
    && adduser -u 1001 -h /home/sunbird/ -D sunbird \
    && mkdir -p /home/sunbird/ \
    && fc-cache -f \
    && rm -rf /var/cache/apk/*

ADD ./cert-service-1.2.0-dist.zip /home/sunbird/
RUN unzip /home/sunbird/cert-service-1.2.0-dist.zip -d /home/sunbird/ \
    && chown -R sunbird:sunbird /home/sunbird

USER sunbird
EXPOSE 9000
WORKDIR /home/sunbird/
CMD java -XX:+PrintFlagsFinal $JAVA_OPTIONS -cp '/home/sunbird/cert-service-1.2.0/lib/*' -Dlogger.file=/home/sunbird/cert-service-1.2.0/config/logback.xml play.core.server.ProdServerStart  /home/sunbird/cert-service-1.2.0