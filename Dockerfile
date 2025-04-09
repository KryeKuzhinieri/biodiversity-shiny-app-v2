# Base image https://hub.docker.com/u/rocker/
FROM rocker/shiny:4.4

# Install system requirements for R as needed
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    git-core \
    libssl-dev \
    libcurl4-gnutls-dev \
    curl \
    libmagick++-dev \
    libsodium-dev \
    libxml2-dev \
    libicu-dev \
    cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Custom shiny-server.conf file. Configuration details here:
# https://docs.posit.co/shiny-server
COPY shiny-server.conf /etc/shiny-server

# create container folder for caching packages
RUN mkdir -p renv/cache
ENV RENV_PATHS_CACHE=/renv/cache

WORKDIR /srv/shiny-server

# Removes all demo files from shiny server.
RUN rm -r *

COPY /Invivogen .

# Give permissions to shiny user for shiny-server and to static/graphs to all
# users.
RUN chown -R shiny:shiny /srv/shiny-server/
