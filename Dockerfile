FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Create a non-root user
RUN useradd --uid 1001 --create-home docker
# install sudo and add docker to sudoers
RUN apt-get update && \
    apt-get install -y sudo
RUN echo "docker ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

RUN mkdir /opt/workspace
WORKDIR /opt/workspace

RUN apt-get update -qq && \
apt-get install -y -qq software-properties-common && \
apt-add-repository universe && \
apt-get update -qq && \
apt-get install -qq -y --no-install-recommends \
bc \
build-essential \
curl \
gcc \
git \
gperf \
make \
python3-dev \
python3-pip \
unzip \
wget \
xz-utils

RUN python3 -m pip install --upgrade pip setuptools
RUN python3 -m pip install -U platformio

RUN python3 -V

# ESP32 & ESP8266 Arduino Frameworks for Platformio

RUN pio platform install espressif8266 \
 && pio platform install espressif32 \
 && cat /root/.platformio/platforms/espressif32/platform.py \
 && chmod 777 /root/.platformio/platforms/espressif32/platform.py \
 && sed -i 's/~2/>=1/g' /root/.platformio/platforms/espressif32/platform.py \
 && cat /root/.platformio/platforms/espressif32/platform.py

# ESP-IDF for projects containing `sdkconfig` or `*platform*espidf*` in platformio.ini

# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started-legacy/linux-setup.html

RUN mkdir -p /home/docker/esp \
 && cd /home/docker/esp \
 && wget https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz \
 && tar -xzf ./xtensa-*.tar.gz \
 && echo "export PATH=$PATH:/home/docker/esp/xtensa-esp32-elf/bin" > .profile \
 && echo "export IDF_PATH=/home/docker/esp/esp-idf" > .profile \
 && git clone https://github.com/espressif/esp-idf.git --recurse-submodules

# Build tests

RUN export PATH=$PATH:/home/docker/esp/xtensa-esp32-elf/bin \
 && export IDF_PATH=/home/docker/esp/esp-idf \
 && python3 -m pip install --user -r /home/docker/esp/esp-idf/requirements.txt

RUN export PATH=$PATH:/home/docker/esp/xtensa-esp32-elf/bin \
 && export IDF_PATH=/home/docker/esp/esp-idf \
 && cd /home/docker/esp/esp-idf/examples/get-started/hello_world \
 && ls -la \
 && ln -s $(which python3) /usr/bin/python \
 && make


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD /bin/bash
