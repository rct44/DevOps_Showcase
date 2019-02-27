FROM python:3.4-alpine
ADD ./requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt
ADD . /code
WORKDIR /code
CMD ["python", "app.py"]
#FROM httpd:2.4
#COPY ./web_pages/ /usr/local/apache2/htdocs/
