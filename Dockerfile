FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# Install Audiveris
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip \
    && wget -q https://github.com/Audiveris/audiveris/releases/download/v5.3.1/audiveris-5.3.1.zip \
    && unzip audiveris-5.3.1.zip -d /opt/ \
    && rm audiveris-5.3.1.zip \
    && apt-get remove -y wget unzip \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=$PATH:/opt/audiveris-5.3.1/bin

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
