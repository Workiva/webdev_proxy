FROM google/dart:2.13
WORKDIR /build/
ADD pubspec.yaml .
RUN pub get
FROM scratch
