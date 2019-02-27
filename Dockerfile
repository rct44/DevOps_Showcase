FROM python:3.4-alpine
ADD . /code
WORKDIR /code
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
#FROM httpd:2.4
#COPY ./web_pages/ /usr/local/apache2/htdocs/