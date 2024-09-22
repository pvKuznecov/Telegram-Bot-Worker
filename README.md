# Telegram-Bot-Worker
Simple worker from Telegram.

## How it works
Key points to know:
<ul>
  <li>Getting updates via the "getUpdates" method (but nothing prevents you from switching to webhooks).</li>
  <li>All data required to communicate with the Telegram API is located in the "config_data.rkt" file (the file is added to the .gitignore exception list).</li>
  <li>Script part of the bot (processing incoming messages): in the "../scn_*botName*" directory (the folder is created automatically when the worker starts; it should always be there).</li>
  <li>Account storage: in the "../auth_*botName*" directory (the folder is created automatically when the worker starts; it should always be there).</li>
  <li>User session data storage: in the "../session_*botName*" directory (the folder is created automatically when the worker starts; it should always be there).</li>
</ul>

<hr>
Простой воркер для бота Telegram (без БД).

## Принцип работы
Основные моменты, которые следует знать:
<ul>
  <li>Получение обновлений по методу "getUpdates" (но ничего не мешает заменить его на вебхуки).</li>
  <li>Все данные, необходимые для осуществления связи с Telegram-API располагаются в файле "config_data.rkt" (файл добавлени в список исключений .gitignore).</li>
  <li>Сценарная часть бота (обработка входящих сообщений): в директории "../scn_*botName*" (папка создается автоматически при запуске воркера; должна быть всегда).</li>
  <li>Хранилище учетных записей: в директории "../auth_*botName*" (папка создается автоматически при запуске воркера; должна быть всегда).</li>
  <li>Хранилище данных сессии пользователя: в директории "../session_*botName*" (папка создается автоматически при запуске воркера; должна быть всегда).</li>
</ul>
