#!/bin/bash
set -e

echo "Starting PostgreSQL..."
# راه‌اندازی سرویس PostgreSQL
/etc/init.d/postgresql start

echo "Starting Redis..."
# راه‌اندازی سرویس Redis
/etc/init.d/redis-server start

# انتظار برای آماده شدن PostgreSQL
until pg_isready -h localhost -p 5432 -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "Configuring AWX Database..."
# تنظیم دیتابیس و کاربر برای AWX (فقط اگر وجود نداشته باشد)
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='awx'" | grep -q 1 || sudo -u postgres createuser awx
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='awx'" | grep -q 1 || sudo -u postgres createdb -O awx awx
# تنظیم پسورد برای کاربر awx
sudo -u postgres psql -c "ALTER USER awx WITH PASSWORD 'awxpass';"

echo "Setting up AWX environment..."
# فعال کردن محیط مجازی Python
source /opt/awx/venv/bin/activate

# تنظیم متغیرهای محیطی ضروری برای AWX
export DJANGO_SETTINGS_MODULE=awx.settings.development
export DATABASE_NAME=awx
export DATABASE_USER=awx
export DATABASE_PASSWORD=awxpass
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export REDIS_HOST=localhost
export REDIS_PORT=6379
export SECRET_KEY=$(pwgen -N1 -s 30)
export AWX_RECEPTOR_LOG_LEVEL=debug

echo "Running AWX database migrations..."
# اجرای migration های دیتابیس برای ساخت جداول
awx-manage migrate

echo "Collecting static files..."
# جمع‌آوری فایل‌های استاتیک (UI)
awx-manage collectstatic --noinput --clear

echo "Creating AWX admin user..."
# ایجاد کاربر ادمین (فقط اگر از قبل وجود نداشته باشد)
awx-manage createsuperuser --username admin --email admin@example.com --noinput || echo "Admin user already exists."
# تنظیم پسورد برای کاربر ادمین
echo "from django.contrib.auth.models import User; u = User.objects.get(username='admin'); u.set_password('password'); u.save()" | awx-manage shell

echo "Starting AWX Task Processor..."
# اجرای پردازشگر وظایف AWX در پس‌زمینه
nohup awx-manage run_dispatcher > /var/log/awx/dispatcher.log 2>&1 &
echo "Dispatcher started with PID $!"

echo "Starting AWX Web Server..."
# اجرای سرور وب AWX (که در foreground باقی می‌ماند تا کانتینر خاموش نشود)
exec awx-manage runserver 0.0.0.0:8052
