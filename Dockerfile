# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set environment variable for dcm2niix v1.0.20240202
ENV PATH="/opt/dcm2niix-v1.0.20240202/bin:$PATH"

# Install dependencies and dcm2niix
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           cmake \
           curl \
           g++ \
           gcc \
           git \
           make \
           pigz \
           zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/rordenlab/dcm2niix /tmp/dcm2niix \
    && cd /tmp/dcm2niix \
    && git fetch --tags \
    && git checkout v1.0.20240202 \
    && mkdir /tmp/dcm2niix/build \
    && cd /tmp/dcm2niix/build \
    && cmake  -DCMAKE_INSTALL_PREFIX:PATH=/opt/dcm2niix-v1.0.20240202 .. \
    && make \
    && make install \
    && rm -rf /tmp/dcm2niix

# Install jq v1.6
RUN apt-get update && apt-get install -y jq

# Install deno v2.0.6
RUN curl -fsSL https://deno.land/install.sh | sh

# Compile bids-validator v2.0.0
RUN deno compile -ERN -o bids-validator jsr:@bids/validator

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Run the application
CMD ["functions/mpn_dcm2bids.py"]