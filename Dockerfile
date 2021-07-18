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

RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    curl \
    ca-certificates \
    libc-dev \
    ffmpeg \
    python \
    atomicparsley \
  && apt-get clean

RUN  set -ex; \
     \
     curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
     \
     fetch_deps='gcc libc-dev'; \
     apt-get update; \
     apt-get install -y --no-install-recommends $fetch_deps; \
     rm -rf /var/lib/apt/lists/*; \
     gcc -Wall \
         /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
     chown root:root /usr/local/bin/su-exec; \
     chmod 0755 /usr/local/bin/su-exec; \
     rm /usr/local/bin/su-exec.c; \
     \
     apt-get purge -y --auto-remove $fetch_deps

WORKDIR /app
COPY --chown=$UID:$GID [ "backend/package.json", "backend/package-lock.json", "/app/" ]
RUN npm install forever -g
RUN npm install && chown -R $UID:$GID ./

COPY --chown=$UID:$GID --from=frontend [ "/build/backend/public/", "/app/public/" ]
COPY --chown=$UID:$GID [ "/backend/", "/app/" ]

EXPOSE 17442
ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "forever", "app.js" ]
