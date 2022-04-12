FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

##
## Copy assets for inclusion in image
##
COPY assets /assets

# Update Ubuntu package management environment
# nano is just a convenient text editor for use within the container
# wget is needed for fetching the install script for CMake
RUN set -ex \
  && apt-get update \
  && apt-get -y upgrade \
  && apt-get install -y nano wget --no-install-recommends


##
## Development environment: compiler toolchain & supporting tools
##

# Install packages needed for ARM-based cross-compiling
RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends\
      gcc g++ \
      gcc-arm-none-eabi \
      libnewlib-arm-none-eabi \
      libglib2.0-0 \
      build-essential \
      gdb gdbserver

# Install Python3 and PIP
RUN set -ex \
  && apt-get install -y python3 python3-pip

# Install Ruby
RUN set -ex \
  # Install apt-add-repository command
  && apt-get install -y software-properties-common --no-install-recommends  \
  && apt-add-repository -y ppa:brightbox/ruby-ng \
  && apt-get update \
  && apt-get install -y ruby2.4 --no-install-recommends \
  && apt-get purge -y --auto-remove software-properties-common

# Install Ceedling, CMock, Unity
RUN set -ex \
  # Prevent documentation installation taking up space
  echo -e "---\ngem: --no-ri --no-rdoc\n...\n" > .gemrc \
  # Install Ceedling and related gems
  && gem install --force --local /assets/gems/*.gem \
  # Cleanup
  && rm -rf /assets \
  && rm .gemrc

# Install CMake
RUN set -ex \
  && wget -O cmakeInstallScript.sh \
  https://github.com/Kitware/CMake/releases/download/v3.21.0-rc3/cmake-3.21.0-rc3-linux-x86_64.sh --no-check-certificate \
  && bash cmakeInstallScript.sh --skip-license --prefix=/usr

# Install GCOVR 4.1 - tried 5.0 aswell but Report-Generation was broken with Ceedling
RUN set -ex \
  pip3 install --no-cache-dir --upgrade pip3 \
  && pip3 install --no-cache-dir gcovr==4.1

##
## Cleanup
##
RUN set -ex \
  # Clean up apt-get leftovers and package lists
  && apt-get autoremove \
  && apt-get clean all \
  && apt-get autoclean all \
  && rm -rf /var/lib/apt/lists/* \
  # Unneeded Debconf templates
  && rm /var/cache/debconf/*


# When the container launches, drop into a shell
ENTRYPOINT ["/bin/bash"]
