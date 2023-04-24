FROM --platform=linux/amd64 python:3.10-slim 
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
ENTRYPOINT [ "python" ]
CMD [ "app.py" ]
EXPOSE 8090