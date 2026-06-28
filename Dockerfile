FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# Install Audiveris (try .deb first, fall back to generic .zip)
ARG AUDIVERIS_VERSION=5.10.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip default-jre-headless \
    && ( \
        wget -q "https://github.com/Audiveris/audiveris/releases/download/v${AUDIVERIS_VERSION}/audiveris-${AUDIVERIS_VERSION}-ubuntu-24.04-amd64.deb" \
             -O /tmp/audiveris.deb 2>/dev/null \
        && apt-get install -y --no-install-recommends /tmp/audiveris.deb \
        && rm /tmp/audiveris.deb \
    ) || ( \
        wget -q "https://github.com/Audiveris/audiveris/releases/download/v${AUDIVERIS_VERSION}/audiveris-${AUDIVERIS_VERSION}.zip" \
             -O /tmp/audiveris.zip \
        && unzip -q /tmp/audiveris.zip -d /opt/ \
        && rm /tmp/audiveris.zip \
        && ln -s /opt/audiveris-${AUDIVERIS_VERSION}/bin/audiveris /usr/local/bin/audiveris \
    ) \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app/media /app/staticfiles
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
