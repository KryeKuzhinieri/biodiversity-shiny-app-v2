# Base image https://hub.docker.com/u/rocker/shiny:4.4
FROM rocker/shiny:4.4

# Install system requirements for R as needed
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    git-core \
    libssl-dev \
    curl \
    libmagick++-dev \
    libsodium-dev \
    libxml2-dev \
    libicu-dev \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
    cmake \
    build-essential \
    gfortran \
    r-base-dev \
    libblas-dev \
    liblapack-dev \
    libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('dotenv')"

# Custom shiny-server.conf file. Configuration details here:
# https://docs.posit.co/shiny-server
COPY shiny-server.conf /etc/shiny-server

WORKDIR /srv/shiny-server

# Removes all demo files from shiny server.
RUN rm -r *

COPY /biodiversity_shiny_app .
COPY .env .

# Change ownership of the application directory and renv directory to the shiny user
RUN chown -R shiny:shiny /srv/shiny-server
RUN chown -R shiny:shiny /srv/shiny-server/renv
RUN chown -R shiny:shiny /etc/shiny-server

USER shiny
