Bike Rental Lab 4

Модульний застосунок для обліку прокату велосипедів, реалізований мовою Dart.

Можливості

- Додавання, пошук і перегляд оренд через CLI.
- Фільтрація оренд за станцією прокату.
- Збереження та завантаження записів у JSON.
- Потокове читання текстових файлів.
- Отримання демонстраційних даних із зовнішнього REST API.
- HTTP-сервер на основі shelf і shelf_router.
- Обробка помилок і журналювання HTTP-запитів.
- Автоматизоване тестування.

Використані технології

Dart SDK 3.13.4, пакети args, path, http, shelf, shelf_router, test`.

Встановлення

dart pub get

Командний інтерфейс

Перегляд довідки:

dart run bin/bike_rental_lab4.dart --help

Перегляд усіх оренд:

dart run bin/bike_rental_lab4.dart list

Фільтрація за станцією:

dart run bin/bike_rental_lab4.dart list --station Центр

Додавання оренди:

dart run bin/bike_rental_lab4.dart add --id RENT-005 --station Парк --type city --duration 60 --price 120

Пошук за ID:

dart run bin/bike_rental_lab4.dart get --id RENT-001

Отримання зовнішніх даних:

dart run bin/bike_rental_lab4.dart fetch

HTTP-сервер

Запуск:

dart run bin/server.dart

Адреса сервера: http://127.0.0.1:8080.

Маршрути:

| Метод | Шлях | Призначення |
|---|---|---|
| GET | /items | Отримати всі оренди |
| GET | /items?station=Центр | Фільтрація за станцією |
| GET | /items/RENT-001 | Отримати оренду за ID |
| POST | /items | Створити нову оренду |

HTTP-сервіс повертає JSON із кодуванням UTF-8. Підтримуються статуси 200, 201, 400, 404 і 409.

Перевірка

dart format .
dart analyze
dart test --reporter expanded
dart fix --dry-run

Компіляція

dart compile exe bin/bike_rental_lab4.dart -o build\bike_rental_lab4.exe

Структура проєкту

- bin/ — точки входу CLI та HTTP-сервера.
- lib/src/models/ — моделі предметної області.
- lib/src/repositories/ — файлове сховище.
- lib/src/services/ — зовнішній HTTP-клієнт.
- lib/src/cli/ — командний інтерфейс.
- lib/src/server/ — маршрути HTTP-сервера.
- test/ — автоматизовані тести.
- data/ — локальні JSON-дані.

Особливості

Зовнішній сервіс JSONPlaceholder використовується для навчальної демонстрації HTTP-запитів. Отримані користувачі перетворюються на умовні записи оренди; ці записи не є реальними операціями прокату.

Файлове сховище призначене для локальної демонстрації та не забезпечує транзакційного захисту від одночасного запису кількома процесами.