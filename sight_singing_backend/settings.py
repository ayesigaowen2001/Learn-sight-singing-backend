"""
Django settings for sight_singing_backend project.
"""
import os as _os
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Load .env file into os.environ (does not override existing vars)
_env_path = BASE_DIR / '.env'
if _env_path.exists():
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith('#') and '=' in _line:
                _key, _, _val = _line.partition('=')
                _key = _key.strip()
                _val = _val.strip().strip('"').strip("'")
                if _key not in _os.environ:
                    _os.environ[_key] = _val

SECRET_KEY = _os.environ.get('SECRET_KEY', 'django-insecure-change-me-in-production')
DEBUG = _os.environ.get('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = _os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'omr',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'sight_singing_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'sight_singing_backend.wsgi.application'

# Database: prefer DATABASE_URL, fall back to individual DB_* vars
DB_URL = _os.environ.get('DATABASE_URL', '')
if DB_URL:
    _db_match = re.match(r'postgres://(.+):(.+)@(.+):(\d+)/(.+)', DB_URL)
    if _db_match:
        DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME = _db_match.groups()
    else:
        DB_USER = DB_PASSWORD = DB_HOST = DB_PORT = DB_NAME = ''
else:
    DB_NAME = _os.environ.get('DB_NAME', 'sight_singing')
    DB_USER = _os.environ.get('DB_USER', 'postgres')
    DB_PASSWORD = _os.environ.get('DB_PASSWORD', 'postgres')
    DB_HOST = _os.environ.get('DB_HOST', 'localhost')
    DB_PORT = _os.environ.get('DB_PORT', '5432')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': DB_NAME,
        'USER': DB_USER,
        'PASSWORD': DB_PASSWORD,
        'HOST': DB_HOST,
        'PORT': DB_PORT,
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

CORS_ALLOW_ALL_ORIGINS = _os.environ.get('CORS_ALLOW_ALL_ORIGINS', 'True') == 'True'
if not CORS_ALLOW_ALL_ORIGINS:
    CORS_ALLOWED_ORIGINS = _os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DATA_UPLOAD_MAX_MEMORY_SIZE = 50 * 1024 * 1024

CELERY_BROKER_URL = _os.environ.get('CELERY_BROKER_URL', 'redis://redis:6379/0')
CELERY_RESULT_BACKEND = _os.environ.get('CELERY_RESULT_BACKEND', 'redis://redis:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
