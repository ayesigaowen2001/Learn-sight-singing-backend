# --- Stage 1: Build Audiveris from source ---
FROM eclipse-temurin:17-jdk AS builder

ARG AUDIVERIS_VERSION=5.10.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -q "https://github.com/Audiveris/audiveris/archive/refs/tags/${AUDIVERIS_VERSION}.zip" \
         -O audiveris.zip \
    && unzip -q audiveris.zip \
    && rm audiveris.zip

# Just change your working directory to the unpacked folder for the next steps
WORKDIR /build/audiveris-${AUDIVERIS_VERSION}

RUN chmod +x gradlew && ./gradlew assembleDist --no-daemon -q

RUN mkdir -p /opt/audiveris \
    && unzip -q build/distributions/Audiveris-*.zip -d /opt/audiveris \
    && mv /opt/audiveris/Audiveris-*/* /opt/audiveris/ \
    && rm -rf /opt/audiveris/Audiveris-*


# --- Stage 2: Python/Django production image ---
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/audiveris /opt/audiveris
RUN ln -s /opt/audiveris/bin/Audiveris /usr/local/bin/audiveris

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app/media /app/staticfiles
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
