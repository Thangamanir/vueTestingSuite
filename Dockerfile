FROM python:alpine

LABEL "com.github.actions.name"="lambda-github-actions"
LABEL "com.github.actions.description"="Deploy Lambda through GitHub Actions"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="purple"

RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
    && pip install cython \
    && apk del .build-deps 

RUN pip3 install awscli 

RUN apk add zip

RUN apk add --update nodejs npm
RUN apk add --update npm

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
