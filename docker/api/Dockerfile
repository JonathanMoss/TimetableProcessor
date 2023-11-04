FROM python:3.11-alpine
COPY ./requirements.txt .
RUN pip install -r requirements.txt
RUN mkdir app
COPY ./app/api/ /app/
COPY ./docker/api/entrypoint.sh /app/
ENTRYPOINT [ "/app/entrypoint.sh" ]