FROM alpine:3.18.0

RUN mkdir /root/CIF
RUN mkdir /root/app

RUN apk update
RUN apk add bash jq curl gawk

ADD ./docker/cif_processing/entrypoint.sh root/app/
ADD ./app/cif_processing/process.sh root/app/
ADD ./app/cif_processing/cif_convert.awk root/app/

RUN ls root/app/

ENTRYPOINT [ "/root/app/entrypoint.sh" ]
