FROM python:3.11-alpine
COPY ./requirements.txt .
RUN pip install -r requirements.txt
RUN mkdir app
COPY ./app/api/ /app/
COPY ./docker/api/entrypoint.sh /app/
COPY ./app/db/ /app/db/
COPY ./app/dal/ /app/dal/
COPY ./app/models/cif_header.py /app/models/cif_header.py
RUN ls app/
ENTRYPOINT [ "/app/entrypoint.sh" ]