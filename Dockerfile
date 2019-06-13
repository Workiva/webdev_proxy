FROM google/dart:2.3

RUN apt-get update -qq
RUN apt-get update && apt-get install -y \
    # wget is used to install chrome and chromedriver
    wget \
    # unzip is used to unzip chromedriver
    unzip \
    # xvfb is used to run chromedriver headless
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -qq update && apt-get install -y google-chrome-stable
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome
RUN sed -i --follow-symlinks -e 's/\"\$HERE\/chrome\"/\"\$HERE\/chrome\" --no-sandbox/g' /usr/bin/google-chrome

# Install chromedriver
WORKDIR /chromedriver/
RUN wget http://chromedriver.storage.googleapis.com/2.46/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/bin/chromedriver
ENV CHROMEDRIVER_BINARY="/usr/bin/google-chrome"
ENV CHROMEDRIVER_ARGS="--no-sandbox"
ENV DISPLAY=":99.0"
RUN Xvfb :99.0 -screen 0 800x600x16 &

RUN /usr/bin/google-chrome --version

WORKDIR /build/
ADD pubspec.yaml .
RUN pub get
ADD . .
RUN dartanalyzer .
RUN dartfmt -n --set-exit-if-changed .
RUN pub run test

ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
