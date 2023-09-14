FROM mcr.microsoft.com/devcontainers/python:3.11

# Install system dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential aria2 zstd unixodbc-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Quarto
RUN curl -sL $(curl https://quarto.org/docs/download/_download.json | grep -oP "(?<=\"download_url\":\s\")https.*${ARCH}\.deb") --output /tmp/quarto.deb \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb

# Install mssql driver (msodbc18) - this needs testing with a clean build
RUN curl -k https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc \
    # && curl -k https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor - | sudo tee /usr/share/keyrings/microsoft.gpg
    && curl -k https://packages.microsoft.com/config/debian/11/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list \
    && sudo sed -i 's/https/http/g' /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Configure Workspace
WORKDIR /workspaces/datadex
ENV DBT_PROFILES_DIR=/workspaces/datadex/dbt
ENV DAGSTER_HOME=/home/vscode/
ENV PYTHONPATH="${PYTHONPATH}:/workspaces/datadex/dbt"
ENV DATA_DIR=/workspaces/datadex/data
ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Add files to workspace
COPY . /workspaces/datadex

# Install Python Dependencies
RUN pip install -e ".[dev]"

# configure git
RUN git config --global user.email "scottincrypto@gmail.com" && config --global user.name "scott simpson"
