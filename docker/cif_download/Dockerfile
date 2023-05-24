FROM alpine:3.18.0

RUN mkdir /root/CIF
RUN mkdir /root/app
ADD ./docker/cif_download/entrypoint.sh root/app/
ADD ./app/cif_download/fetch.sh root/app/

RUN tree /root
RUN ping -c 3 www.google.co.uk
RUN apk update

RUN apk add curl

ENTRYPOINT [ "/root/app/entrypoint.sh" ]
