# --- Stage 1: Download Audiveris pre-built release ---
FROM eclipse-temurin:17-jdk AS builder

ARG AUDIVERIS_VERSION=5.10.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -q "https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/Audiveris-${AUDIVERIS_VERSION}.zip" \
         -O audiveris.zip \
    && unzip -q audiveris.zip -d audiveris-dist \
    && rm audiveris.zip

RUN mkdir -p /opt/audiveris && \
    mv audiveris-dist/Audiveris-*/* /opt/audiveris/ 2>/dev/null || \
    mv audiveris-dist/* /opt/audiveris/


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
