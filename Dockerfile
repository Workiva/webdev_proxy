FROM google/dart:2.3
RUN apt-get update -qq && rm -rf /var/lib/apt/lists/*
WORKDIR /build/
ADD pubspec.yaml .
RUN pub get
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock

FROM scratch
