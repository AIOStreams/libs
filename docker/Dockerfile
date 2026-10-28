# The tools ../build.sh needs, for docker/build.sh.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    autoconf automake autopoint bison build-essential clang cmake curl flex gettext git gperf \
    help2man libtool libtool-bin lld nasm ninja-build openjdk-21-jdk pkg-config python3 \
    python3-pip texinfo unzip yasm zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# mbedtls' generators need jsonschema and jinja2.
RUN pip3 install --break-system-packages meson==1.12.1 jsonschema jinja2

ENV HOME=/home/mpvbuilder
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH=/home/mpvbuilder/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

WORKDIR /home/mpvbuilder/libs
COPY entrypoint.sh /home/mpvbuilder/
RUN chmod +x /home/mpvbuilder/entrypoint.sh
ENTRYPOINT ["/home/mpvbuilder/entrypoint.sh"]
