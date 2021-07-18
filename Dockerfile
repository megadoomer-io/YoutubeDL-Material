FROM node:12-slim as frontend

RUN npm install -g @angular/cli

WORKDIR /build
COPY [ "package.json", "package-lock.json", "/build/" ]
RUN npm install

COPY [ "angular.json", "tsconfig.json", "/build/" ]
COPY [ "src/", "/build/src/" ]
RUN ng build --prod

#--------------#

FROM node:12-slim

ENV UID=1000 \
  GID=1000 \
  USER=youtube

ENV NO_UPDATE_NOTIFIER=true
ENV FOREVER_ROOT=/app/.forever

# Skip this since UID/GID 1000 are already in our base image. Names don't match though!
# RUN addgroup -S $USER -g $GID && adduser -D -S $USER -G $USER -u $UID

RUN apt-get update \
  && apt-get install -y \
    ffmpeg \
    python \
    apache2-suexec-custom \
    atomicparsley \
  && apt-get clean

WORKDIR /app
COPY --chown=$UID:$GID [ "backend/package.json", "backend/package-lock.json", "/app/" ]
RUN npm install forever -g
RUN npm install && chown -R $UID:$GID ./

COPY --chown=$UID:$GID --from=frontend [ "/build/backend/public/", "/app/public/" ]
COPY --chown=$UID:$GID [ "/backend/", "/app/" ]

EXPOSE 17442
ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "forever", "app.js" ]
