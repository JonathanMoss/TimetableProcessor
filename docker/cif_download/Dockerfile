FROM alpine:3.18.0

RUN mkdir /root/CIF
RUN mkdir /root/app

RUN apk update
RUN apk add curl
RUN apk add bash
RUN apk add pcre-tools
RUN apk add coreutils
RUN apk add lz4

ADD ./docker/cif_download/entrypoint.sh root/app/
ADD ./app/cif_download/fetch.sh root/app/
ADD ./app/cif_download/strip_schedules.sh root/app/
ADD ./app/cif_download/convert_cif_to_csv.sh root/app/

RUN ls root/app/

ENTRYPOINT [ "/root/app/entrypoint.sh" ]
