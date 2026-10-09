# Наблюдаемость Nginx: Prometheus, Vector, Loki, Grafana Alerting

Практическая работа: стек мониторинга и логирования для Nginx на виртуальной машине.

## Состав репозитория

| Файл / папка | Что это |
|---|---|
| `prometheus.yml` | Конфигурация Prometheus: два job (`node_exporter`, `nginx`) |
| `vector.yaml` | Конфигурация Vector: чтение логов Nginx, парсинг, поле `log_type`, вывод в Loki |
| `screenshots/` | Скриншоты Grafana, правил алертинга и уведомлений |

## Этап 1. Сбор метрик

В `prometheus.yml` настроены два таргета:

- `node_exporter` (`127.0.0.1:9100`) - метрики хоста (CPU, RAM);
- `nginx` (`127.0.0.1:9113`) - метрики `nginx_exporter`, который читает `stub_status`.

Примечание: `stub_status` в Nginx слушает отдельный адрес `127.0.0.1:8080/stub_status`, экспортёр берёт данные оттуда.

![Prometheus: запрос up](screenshots/01-prometheus-up.png)

На скриншоте запрос `up` возвращает два значения со значением 1: `job="nginx"` и `job="node_exporter"`.

## Этап 2. Сбор и парсинг логов

В `vector.yaml`:

- два источника (`file`): `/var/log/nginx/access.log` и `/var/log/nginx/error.log`;
- `access.log` парсится через `parse_nginx_log` (формат `combined`), добавляется поле `log_type = "access"`;
- для `error.log` добавляется поле `log_type = "error"`;
- sink типа `loki` с меткой `job: "vector"`, кодировка `json`.

Для чтения логов пользователь `vector` добавлен в группу `adm` (файлы логов имеют права `640`, владелец `www-data:adm`).

Проверка доставки в Loki: `logcli query '{job="vector"}'` возвращает записи с полями `log_type`, `client`, `status` и др.

## Этап 3. Визуализация

Источники данных в Grafana: Prometheus (`http://localhost:9090`) и Loki (`http://localhost:3100`), оба в статусе OK.

![Источники данных](screenshots/02-datasources.png)
![Prometheus: Successfully queried](screenshots/03-datasource-prometheus-ok.png)
![Loki: successfully connected](screenshots/04-datasource-loki-ok.png)

Дашборд **Nginx Overview**:

| Панель | Источник | Запрос | Что показывает |
|---|---|---|---|
| Nginx Status | Prometheus | `nginx_up` | Состояние Nginx: 1 - работает, 0 - остановлен |
| CPU Load | Prometheus | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)` | Загрузка процессора, % |
| RAM Usage | Prometheus | `(1 - node_memory_MemAvailable_bytes{job="node_exporter"} / node_memory_MemTotal_bytes{job="node_exporter"}) * 100` | Использование памяти, % |
| RPS | Prometheus | `rate(nginx_http_requests_total[1m])` | Запросов в секунду к Nginx |
| Error Logs | Loki | `{job="vector"} \| json \| log_type = "error"` | Логи ошибок Nginx |
| Top 10 IPs | Loki | `topk(10, sum(count_over_time(({job="vector"} \| json \| log_type="access")[1h])) by (client))` | Топ адресов по числу запросов (Pie chart) |

В запросе Top 10 IPs группировка идёт по полю `client`, которое создаёт `parse_nginx_log`, и используется тип запроса Instant.

![Дашборд Nginx Overview после нагрузки](screenshots/05-dashboard-after-load.png)

После генерации нагрузки (`curl` к `/` и к несуществующей странице `/nope`): на RPS виден всплеск, в Top 10 IPs появился адрес `::1`, Nginx Status равен 1. «Ступенька» на Nginx Status - период, когда Nginx был остановлен для проверки алерта.

![Дашборд во время остановки Nginx](screenshots/06-dashboard-nginx-stopped.png)

На этом скриншоте Nginx остановлен: Nginx Status показывает 0.

## Этап 4. Алертинг

Contact point типа Email создан в Grafana, кнопка Test выполнена успешно.

![Test contact point](screenshots/07-contact-point-test.png)

Правила (папка `nginx`, evaluation group `nginx-1m`, интервал 1m):

| Правило | Запрос | Условие | Pending period |
|---|---|---|---|
| `NginxDown` | `nginx_up` | Threshold IS BELOW 1 (метрика равна 0) | 1m |
| `InstanceDown` | `up{job="node_exporter"}` | Threshold IS BELOW 1 (метрика не равна 1) | 2m |

Цепочка выражений: запрос A -> Reduce B (Last) -> Threshold C (alert condition). Метрики `nginx_up` и `up` принимают только значения 0 и 1, поэтому `IS BELOW 1` равносильно `== 0` и `!= 1`.

![Список правил алертинга](screenshots/08-alert-rules-list.png)

## Этап 5. Проверка работоспособности

1. `sudo systemctl stop nginx` - через 1-2 минуты правило `NginxDown` перешло в состояние Firing.

   ![NginxDown в состоянии Firing](screenshots/09-alert-firing.png)

2. Уведомления по почте.

   > Примечание: на ВМ нет доступа к внешнему SMTP-серверу, поэтому Grafana настроена на локальный SMTP-приёмник на самой ВМ (`localhost:1025`, `python3 -m aiosmtpd -n -l localhost:1025`). Письма не уходят во внешнюю почту, но целиком принимаются и выводятся в терминал приёмника. Ниже скриншоты этого вывода: тема, отправитель и получатель.

   ![Письмо FIRING](screenshots/10-mail-firing.png)
   ![Письмо RESOLVED](screenshots/11-mail-resolved.png)

3. `sudo systemctl start nginx` - Nginx восстановлен, правило вернулось в Normal, пришло письмо `RESOLVED`.
4. Нагрузка: цикл `curl` к `/` и `/nope`. Результат виден на дашборде (скриншот выше): рост на RPS, адрес в Top 10 IPs.

## Использованные настройки Grafana для почты

В `grafana.ini` (файл в репозиторий не включён) в секции `[smtp]` указано:

```ini
[smtp]
enabled = true
host = localhost:1025
from_address = grafana@example.com
from_name = Grafana
startTLS_policy = NoStartTLS
```
