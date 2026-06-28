# --- Stage 1: Build Audiveris using an Official Java Image ---
FROM eclipse-temurin:17-jdk AS builder

ARG AUDIVERIS_VERSION=5.10.2

# Install system utilities needed to download and extract files
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and unpack the exact zip archive link
WORKDIR /build
RUN wget -q "https://github.com{AUDIVERIS_VERSION}.zip" -O audiveris.zip \
    && unzip -q audiveris.zip \
    && mv audiveris-${AUDIVERIS_VERSION} audiveris-src \
    && rm audiveris.zip

# Compile the standalone production bundle using the internal Gradle wrapper
WORKDIR /build/audiveris-src
RUN ./gradlew assembleDist

# Unpack the compiled application package distribution into /opt/audiveris
RUN mkdir -p /opt/audiveris && \
    unzip -q build/distributions/Audiveris-*.zip -d /opt/audiveris && \
    if [ -d /opt/audiveris/Audiveris-* ]; then mv /opt/audiveris/Audiveris-*/* /opt/audiveris/; fi


# --- Stage 2: Clean Python/Django Production Environment ---
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install standard runtime dependencies (Headless Java and Tesseract OCR)
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless \
    tesseract-ocr \
    tesseract-ocr-eng \
    && rm -rf /var/lib/apt/lists/*

# Pull only the compiled Audiveris binary assets from the builder stage
COPY --from=builder /opt/audiveris /opt/audiveris

# Expose the 'audiveris' command line execution globally to Django subprocess calls
RUN ln -s /opt/audiveris/bin/Audiveris /usr/local/bin/audiveris

# Install Python application modules
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Bundle app source code
COPY . .

# Setup entrypoint permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app/media /app/staticfiles
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
