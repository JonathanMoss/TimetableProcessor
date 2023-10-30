FROM alpine:3.18.0

RUN mkdir /root/CIF
RUN mkdir /root/app

RUN apk update
RUN apk add bash

ADD ./docker/cif_processing/entrypoint.sh root/app/
ADD ./app/cif_processing/convert_cif_to_csv.sh root/app/

RUN ls root/app/

ENTRYPOINT [ "/root/app/entrypoint.sh" ]
