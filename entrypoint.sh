#!/bin/sh
set -e

echo "==> Running database migrations..."
python manage.py migrate --noinput

# OPTIONAL: Keep this ONLY if you remove "collectstatic" from your Dockerfile. 
# Otherwise, delete these two lines to speed up your container boot time:
echo "==> Collecting static files..."
python manage.py collectstatic --noinput

echo "==> Starting Gunicorn..."
# Reduced workers from 4 to 2 (or 1) to conserve RAM for heavy Java/Audiveris tasks.
exec gunicorn sight_singing_backend.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --timeout 300 \
    --access-logfile - \
    --error-logfile -
