FROM alpine:3.18.0

RUN mkdir /root/CIF
RUN mkdir /root/app

RUN apk update
RUN apk add curl
RUN apk add bash

ADD ./docker/cif_download/entrypoint.sh root/app/
ADD ./app/cif_download/fetch.sh root/app/
RUN tree /root

ENTRYPOINT [ "/root/app/entrypoint.sh" ]
