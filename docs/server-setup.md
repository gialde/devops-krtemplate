Настройка веб-сервера Nginx

8. Веб-сервер Nginx и HTTPS

8.1. Установка Nginx

Установить веб-сервер и проверить его состояние:

sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
systemctl is-active nginx

8.2. Каталог веб-ресурса

Создать каталог сайта:

sudo mkdir -p /var/www/devops-site
sudo chown -R devops:devops /var/www/devops-site
sudo chmod 755 /var/www/devops-site

Файлы сайта размещаются в /var/www/devops-site. Для каталогов устанавливаются права 755, для файлов — 644.

8.3. Конфигурация Nginx

Файл конфигурации сайта:

/etc/nginx/sites-available/devops-site

Активировать конфигурацию символической ссылкой:

sudo ln -s /etc/nginx/sites-available/devops-site /etc/nginx/sites-enabled/devops-site

Отключить стандартный сайт:

sudo rm -f /etc/nginx/sites-enabled/default

После изменения конфигурации проверить синтаксис и применить настройки:

sudo nginx -t
sudo systemctl reload nginx

8.4. TLS-сертификат

Сертификат:

/etc/ssl/certs/devops.crt

Закрытый ключ:

/etc/ssl/private/devops.key

Закрытый ключ должен принадлежать root и иметь права 600:

sudo chown root:root /etc/ssl/private/devops.key
sudo chmod 600 /etc/ssl/private/devops.key

Проверить сертификат:

openssl x509 -in /etc/ssl/certs/devops.crt -noout -subject -dates

8.5. Проверка HTTPS

Проверить конфигурацию и состояние службы:

sudo nginx -t
systemctl is-active nginx

Проверить доступность сайта:

curl -sk https://localhost/ -H "Host: devops.local"

8.6. Журналы Nginx

Журнал запросов:

/var/log/nginx/devops-site.access.log

Журнал ошибок:

/var/log/nginx/devops-site.error.log

Просмотр последних записей:

sudo tail -n 20 /var/log/nginx/devops-site.access.log
sudo tail -n 20 /var/log/nginx/devops-site.error.log

8.7. Доставка содержимого

Для синхронизации файлов сайта с хостовой машины используется rsync:

rsync -avz --delete --chmod=D755,F644 site/ devops:/var/www/devops-site/

8.8. Контроль конфигурации

Проверить службу, конфигурацию Nginx, срок действия сертификата, права файлов сайта и закрытого ключа:

systemctl is-active nginx
sudo nginx -t
openssl x509 -in /etc/ssl/certs/devops.crt -checkend 2592000
find /var/www/devops-site -perm -o+w
sudo stat -c '%a' /etc/ssl/private/devops.key

9. Контейнеризация
- **Способ установки Docker Engine и его версия:** Официальный репозиторий Docker, версия 27.x.x
- **Участники группы docker:** devops
- **Расположение проекта на сервере:** ~/app
- **Расположение файла .env и его права:** ~/app/.env, права 600
- **Публикуемые порты и адреса:** 127.0.0.1:5000 (приложение), порт СУБД не опубликован
- **Именованные тома:** db_data (для PostgreSQL)
- **Конфигурация обратного прокси-сервера:** Nginx проксирует запросы с https://devops.local/app/ на http://127.0.0.1:5000/ с передачей заголовков X-Forwarded-*
