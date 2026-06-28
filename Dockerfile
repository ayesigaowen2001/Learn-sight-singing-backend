# --- Stage 1: Build Audiveris ---
FROM python:3.11-slim AS builder

ARG AUDIVERIS_VERSION=5.10.2

# Install dependencies needed to download and compile Audiveris
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and extract the source release code
WORKDIR /build
RUN wget -q "https://github.com{AUDIVERIS_VERSION}.zip" -O audiveris.zip \
    && unzip -q audiveris.zip \
    && mv audiveris-${AUDIVERIS_VERSION} audiveris-src \
    && rm audiveris.zip

# Compile Audiveris using its internal Gradle wrapper
WORKDIR /build/audiveris-src
RUN ./gradlew assembleDist

# Locate and extract the compiled distribution bundle
RUN mkdir -p /opt/audiveris && \
    unzip -q build/distributions/Audiveris-*.zip -d /opt/audiveris && \
    # Move files up one folder if nested inside a version sub-directory
    if [ -d /opt/audiveris/Audiveris-* ]; then mv /opt/audiveris/Audiveris-*/* /opt/audiveris/; fi

# --- Stage 2: Final Runtime Environment ---
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime tools (Java Runtime and Tesseract OCR)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    tesseract-ocr \
    tesseract-ocr-eng \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled application distribution from Stage 1
COPY --from=builder /opt/audiveris /opt/audiveris

# Create a symlink to easily execute via command line
RUN ln -s /opt/audiveris/bin/Audiveris /usr/local/bin/audiveris

# Setup python application dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django code
COPY . .

# Entrypoint setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app/media /app/staticfiles
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
