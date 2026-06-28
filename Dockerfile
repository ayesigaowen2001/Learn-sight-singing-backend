# --- Stage 1: Build Audiveris using an Official Java Image ---
FROM eclipse-temurin:17-jdk AS builder

ARG AUDIVERIS_VERSION=5.10.2

# Install minimal tools needed for source retrieval
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and unpack Audiveris Source Code
WORKDIR /build
RUN wget -q "https://github.com{AUDIVERIS_VERSION}.zip" -O audiveris.zip \
    && unzip -q audiveris.zip \
    && mv audiveris-${AUDIVERIS_VERSION} audiveris-src \
    && rm audiveris.zip

# Compile the production application package distribution
WORKDIR /build/audiveris-src
RUN ./gradlew assembleDist

# Cleanly unpack the compiled application into /opt/audiveris
RUN mkdir -p /opt/audiveris && \
    unzip -q build/distributions/Audiveris-*.zip -d /opt/audiveris && \
    if [ -d /opt/audiveris/Audiveris-* ]; then mv /opt/audiveris/Audiveris-*/* /opt/audiveris/; fi


# --- Stage 2: Clean Python/Django Production Environment ---
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install standard runtime dependencies (Guaranteed naming convention in slim)
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless \
    tesseract-ocr \
    tesseract-ocr-eng \
    && rm -rf /var/lib/apt/lists/*

# Pull the compiled Audiveris core assets from the builder stage
COPY --from=builder /opt/audiveris /opt/audiveris

# Expose 'audiveris' command line execution globally to Django subprocess calls
RUN ln -s /opt/audiveris/bin/Audiveris /usr/local/bin/audiveris

# Manage Python modules
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Bundle app source code
COPY . .

# Wire up the execution scripts
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /app/media /app/staticfiles
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
