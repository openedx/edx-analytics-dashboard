"""Common developpment settings"""

import os

from analytics_dashboard.settings.base import *
from analytics_dashboard.settings.logger import get_logger_config

########## DEBUG CONFIGURATION
# See: https://docs.djangoproject.com/en/dev/ref/settings/#debug
DEBUG = True
########## END DEBUG CONFIGURATION


########## EMAIL CONFIGURATION
# See: https://docs.djangoproject.com/en/dev/ref/settings/#email-backend
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
########## END EMAIL CONFIGURATION

########## CACHE CONFIGURATION
# See: https://docs.djangoproject.com/en/dev/ref/settings/#caches
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'
    }
}
########## END CACHE CONFIGURATION


########## TOOLBAR CONFIGURATION
# See: http://django-debug-toolbar.readthedocs.org/en/latest/installation.html#explicit-setup

if os.environ.get('ENABLE_DJANGO_TOOLBAR', '').lower() in ('true', 't', '1'):
    INSTALLED_APPS += (
        'debug_toolbar',
    )

    MIDDLEWARE += [
        'debug_toolbar.middleware.DebugToolbarMiddleware',
    ]

    DEBUG_TOOLBAR_PATCH_SETTINGS = False

# http://django-debug-toolbar.readthedocs.org/en/latest/installation.html
INTERNAL_IPS = ('127.0.0.1',)
########## END TOOLBAR CONFIGURATION

LMS_COURSE_SHORTCUT_BASE_URL = 'https://example.com/courses'
CMS_COURSE_SHORTCUT_BASE_URL = 'https://studio.example.com/course'

########## BRANDING
PLATFORM_NAME = 'Open edX'
APPLICATION_NAME = 'Insights'
FULL_APPLICATION_NAME = f'{PLATFORM_NAME} {APPLICATION_NAME}'
########## END BRANDING


########## AUTHENTICATION/AUTHORIZATION
ENABLE_AUTO_AUTH = True

# Uncomment the line below to avoid having to worry about course permissions
ENABLE_COURSE_PERMISSIONS = False
########## END AUTHENTICATION/AUTHORIZATION

########## FEEDBACK AND SUPPORT
HELP_URL = '#'
########## END FEEDBACK

########## SEGMENT.IO
# 'None' disables tracking.  This will be turned on for test and production.
SEGMENT_IO_KEY = os.environ.get('SEGMENT_WRITE_KEY')
########## END SEGMENT.IO

GRADING_POLICY_API_URL = 'http://127.0.0.1:18000/api/grades/v1/'
COURSE_API_URL = 'http://127.0.0.1:18000/api/courses/v1/'

LOGGING = get_logger_config(debug=DEBUG, dev_env=True, local_loglevel='DEBUG')

########## MODULE_PREVIEW
MODULE_PREVIEW_URL = 'http://127.0.0.1:18000/xblock'
########## END MODULE_PREVIEW

########## REST FRAMEWORK CONFIGURATION
REST_FRAMEWORK['DEFAULT_RENDERER_CLASSES'] = (
    'rest_framework.renderers.JSONRenderer',
    'rest_framework.renderers.BrowsableAPIRenderer',
)
########## END REST FRAMEWORK CONFIGURATION

########## DATA API CONFIGURATION
DATA_API_AUTH_TOKEN = 'edx'
########## END DATA API CONFIGURATION

ENABLE_AUTO_AUTH = True
ENABLE_COURSE_PERMISSIONS = False
SOCIAL_AUTH_EDX_OAUTH2_KEY = "insights-sso-key"
SOCIAL_AUTH_EDX_OAUTH2_SECRET = "insights-sso-secret"
SOCIAL_AUTH_EDX_OAUTH2_ISSUER = "http://localhost:18000"
SOCIAL_AUTH_EDX_OAUTH2_URL_ROOT = "http://localhost:18000"
SOCIAL_AUTH_EDX_OAUTH2_LOGOUT_URL = "http://localhost:18000/logout"

BACKEND_SERVICE_EDX_OAUTH2_KEY = "insights-backend-service-key"
BACKEND_SERVICE_EDX_OAUTH2_SECRET = "insights-backend-service-secret"
BACKEND_SERVICE_EDX_OAUTH2_PROVIDER_URL = "http://localhost:18000/oauth2"

########## SECRET CONFIGURATION
# See: https://docs.djangoproject.com/en/dev/ref/settings/#secret-key
# Note: This key should only be used for development and testing.
SECRET_KEY = os.environ.get("ANALYTICS_SECRET_KEY", "insecure-secret-key")
########## END SECRET CONFIGURATION

########## SESSION COOKIE
# See: https://docs.djangoproject.com/en/dev/ref/settings/#session-cookie-name
SESSION_COOKIE_NAME = 'sessionid'
######### END SESSION COOKIE
