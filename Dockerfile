FROM drydock-prod.workiva.net/workiva/dart2_base_image:1
RUN apt-get update -qq && rm -rf /var/lib/apt/lists/*
WORKDIR /build/
ADD pubspec.yaml .
RUN pub get
FROM scratch
