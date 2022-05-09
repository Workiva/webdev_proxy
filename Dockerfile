FROM google/dart:2.13
WORKDIR /build/
ADD pubspec.yaml .
RUN dart pub get
FROM scratch
