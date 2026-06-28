# --- Stage 1: Build Audiveris from source ---
# # --- Stage 1: Build Audiveris from source ---
FROM eclipse-temurin:25-jdk AS builder

ARG AUDIVERIS_VERSION=5.10.2

# 1. Install git (and unzip for later distribution unpacking)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 2. Clone the repository at the specific tag instead of downloading a zip
RUN git clone --depth 1 --branch v${AUDIVERIS_VERSION} https://github.com/Audiveris/audiveris.git

# 3. Change directory into the cloned git repository folder
WORKDIR /build/audiveris

# 4. Run your build smoothly
RUN chmod +x gradlew && ./gradlew assembleDist --no-daemon

RUN mkdir -p /opt/audiveris \
    && unzip -q build/distributions/Audiveris-*.zip -d /opt/audiveris \
    && mv /opt/audiveris/Audiveris-*/* /opt/audiveris/ \
    && rm -rf /opt/audiveris/Audiveris-*

# --- Stage 2: Python/Django production image ---
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# NOTE: default-jre-headless in Debian stable/testing might still pull Java 17 or 21.
# If Audiveris throws a runtime version error when your Django app calls it,
# change "default-jre-headless" below to "openjdk-25-jre-headless"
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