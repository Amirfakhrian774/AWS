#!/bin/bash
set -e

# Initialize database
/opt/venv/bin/python /awx/manage.py migrate --noinput

# Collect static files
/opt/venv/bin/python /awx/manage.py collectstatic --noinput

# Create superuser if needed
if [ -n "$AWX_ADMIN_USER" ] && [ -n "$AWX_ADMIN_PASSWORD" ]; then
    echo "Creating admin user..."
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('$AWX_ADMIN_USER', 'admin@example.com', '$AWX_ADMIN_PASSWORD')" | \
    /opt/venv/bin/python /awx/manage.py shell
fi

exec "$@"