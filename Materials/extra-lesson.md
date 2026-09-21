# **Как смотрят схему и сохраняют результат**

На четырёх парах мы только читали данные. Здесь отдельно разберём, как посмотреть устройство таблицы в клиенте и как результат вообще появляется в базе.

Это дополнительный конспект, не четвёртая пара. Подключение `student` доступно только для чтения: команды записи ниже можно разобрать глазами, но выполнить их под `student` не получится. Домашнего задания у этого материала нет.

---

## **Сегодня пройдемся по этому плану:**

1. Чем `DDL` отличается от `DML`.
2. Как посмотреть объект: `\d`, `\d+` и соседние команды `psql`.
3. `CREATE TABLE`, типы, схема, `ALTER`, `DROP`.
4. `INSERT`, `UPDATE`, `DELETE`.
5. Ограничения таблицы.
6. Транзакции и ACID.
7. Индексы и `EXPLAIN`.

---



## **Часть 0. Два семейства команд**

До сих пор мы только читали данные через `SELECT`. Команды работы с таблицами делятся на две группы:

- **DDL** меняет структуру базы: `CREATE`, `ALTER`, `DROP`;
- **DML** меняет строки: `INSERT`, `UPDATE`, `DELETE`.

> **DDL** – Data Definition Language, язык описания объектов.
>
> **DML** – Data Manipulation Language, язык изменения строк.

Сначала научимся читать уже существующую таблицу. Создавать и менять – следующим шагом.

---



## **Часть I. Как посмотреть, что уже есть**

Прежде чем создавать таблицу, полезно уметь прочитать уже существующую.

В `psql` такие команды **не SQL**. Точка с запятой им не нужна. Полный список – `\?` или [документация psql](https://postgrespro.ru/docs/postgresql/current/app-psql).

В `pgAdmin` и `DBeaver` то же самое смотрят через свойства объекта или «View / Generate SQL». Клиенты равны: меняется только кнопка, не устройство таблицы.

### `\d` **– что за объект**

```text
\d course.daily_airport_metrics
```

Типичный ответ:

```text
                    Table "course.daily_airport_metrics"
    Column     |     Type      | Collation | Nullable | Default
---------------+---------------+-----------+----------+---------
 airport_code  | character(3)  |           | not null |
 report_date   | date          |           | not null |
 flight_count  | integer       |           | not null |
 revenue       | numeric(12,2) |           | not null |
Indexes:
    "daily_airport_metrics_pkey" PRIMARY KEY, btree (airport_code, report_date)
Check constraints:
    "daily_airport_metrics_flight_count_check" CHECK (flight_count >= 0)
    "daily_airport_metrics_revenue_check" CHECK (revenue >= 0)
```

`\d` показывает столбцы, типы, можно ли оставить пусто (`NULL` / `NOT NULL`). Ниже в том же выводе ещё ключи, ограничения и индексы – это правила и ускорители таблицы; как их задают, будет в следующих частях. Это снимок схемы, а не данные.

Без имени `\d` печатает список таблиц и view в текущем `search_path`.

### `\d+` **– то же плюс служебное**

```text
\d+ course.daily_airport_metrics
```

К выводу `\d` добавляются комментарии к таблице и столбцам, если их задавали, и размер на диске. Ещё несколько служебных строк про хранение можно не разбирать.

У `course.daily_airport_metrics` комментарий как раз есть: «стабильные дневные показатели аэропортов для изучения оконных функций». `\d` его не показывает, `\d+` – показывает.

### **Соседние команды**

Этого достаточно, чтобы осмотреться в клиенте:

| Команда          | Что показывает                   |
| ---------------- | -------------------------------- |
| `\d`             | объекты в текущем `search_path`  |
| `\d имя`         | столбцы, типы, ключи объекта     |
| `\d+ имя`        | то же плюс комментарии и размер  |
| `\dt bookings.*` | таблицы схемы `bookings`         |
| `\dn`            | список схем                      |
| `\?`             | справка по командам `psql`       |
| `\q`             | выход                            |

Пример сессии:

```text
demo=> \dn
demo=> \dt course.*
demo=> \d course.airports_master
demo=> \d+ course.daily_airport_metrics
demo=> SELECT * FROM course.daily_airport_metrics LIMIT 1;
demo=> \q
```

Если приглашение стало `demo->`, statement или кавычки не закрыты. Допишите `;` или прервите ввод: `Ctrl+C`.

В `pgAdmin`: дерево слева → таблица → колонки / ограничения / индексы, либо **Scripts → CREATE Script**.

В `DBeaver`: свойства таблицы, вкладки **Columns**, **Keys**, **Indexes**, либо **Generate SQL**.

---



## **Часть II. Из чего состоит** `CREATE TABLE`

Минимальная таблица:

```sql
CREATE TABLE extra_notes (
    flight_id integer,
    note text
);
```

Внутри скобок перечисляются столбцы. У каждого столбца есть:

```text
имя → тип данных → необязательные правила
```

В примере:

- `flight_id` – имя, `integer` – тип;
- `note` – имя, `text` – тип.

Запятая разделяет определения столбцов.

### **Частые типы данных**

| Тип                        | Что хранит               | Пример                    |
| -------------------------- | ------------------------ | ------------------------- |
| `integer` / `bigint`       | целые числа              | идентификатор, количество |
| `numeric(p, s)`            | точные числа             | деньги                    |
| `text`                     | текст произвольной длины | комментарий               |
| `boolean`                  | `TRUE` / `FALSE`         | признак                   |
| `date`                     | календарную дату         | `2026-09-17`              |
| `timestamp with time zone` | момент времени           | время создания строки     |

Тип выбирают по смыслу значения. Деньги лучше хранить в `numeric`, а не в приближённом `real`.

### **Имя схемы**

Полное имя состоит из схемы и таблицы:

```sql
SELECT *
FROM course.daily_airport_metrics;
```

Схему можно создать отдельно, а таблицу положить в неё:

```sql
CREATE SCHEMA extra_demo;

CREATE TABLE extra_demo.notes (
    note_id integer,
    note text
);
```

Схема помогает отделить объекты одного проекта от других. После создания её снова можно посмотреть через `\dn` и `\dt extra_demo.*`.

### `CREATE TABLE IF NOT EXISTS`

```text
CREATE TABLE IF NOT EXISTS table_name (...)
```

Форма не выдаёт ошибку, если объект уже существует. Но PostgreSQL не проверяет, что старая таблица имеет нужные столбцы. Поэтому `IF NOT EXISTS` не заменяет аккуратное изменение схемы.

### `CREATE TABLE AS SELECT`

Если структура уже получена запросом, её можно сохранить вместе со строками:

```sql
CREATE TABLE extra_airport_report AS
SELECT airport_code,
       report_date,
       revenue
FROM course.daily_airport_metrics;
```

`CREATE TABLE AS` берёт имена и типы колонок из результата `SELECT`. Ограничения, ключи и индексы исходных таблиц автоматически не копируются.

### **Временная таблица**

```text
CREATE TEMP TABLE table_name (...)
```

Временная таблица видна только в текущем подключении и удаляется, когда подключение закрывается. Она удобна для промежуточного расчёта и не заменяет постоянную таблицу.

### **Как изменить готовую таблицу**

Для изменения структуры используется `ALTER TABLE`. Возьмём ту же `extra_notes`:

```sql
ALTER TABLE extra_notes
ADD COLUMN created_at timestamp with time zone;
```

Частые действия:

```text
ADD COLUMN       → добавить столбец
DROP COLUMN      → удалить столбец
RENAME COLUMN    → переименовать столбец
ALTER COLUMN     → изменить правило столбца
```

Удаление столбца удаляет и данные в нём. Сначала смотрят, кто этим столбцом пользуется.

### **Как удалить таблицу**

```sql
CREATE TABLE extra_to_remove (
    id integer
);

DROP TABLE extra_to_remove;
```

`DROP TABLE` удаляет и структуру, и строки. `DELETE` удаляет строки, но оставляет таблицу. До `DELETE` мы ещё дойдём.

После `CREATE` / `ALTER` снова полезен `\d имя`: клиент покажет уже новую схему.

---



## **Часть III. Как изменяют строки**

Дальше таблица уже есть, меняем содержимое.

### `INSERT ... VALUES`

```sql
CREATE TABLE extra_flight_notes (
    flight_id bigint,
    note text
);

INSERT INTO extra_flight_notes (flight_id, note)
VALUES (1, 'Проверить рейс');

INSERT INTO extra_flight_notes (flight_id, note)
SELECT flight_id,
       'Прибывший рейс'
FROM flights
WHERE status = 'Arrived'
  AND flight_id <= 3;
```

В первом `INSERT` мы перечислили значения вручную. Во втором строки пришли из результата `SELECT`.

Перед списком значений лучше явно писать целевые столбцы:

```text
INSERT INTO table_name (column_1, column_2)
VALUES (value_1, value_2);
```

Так запрос не зависит от физического порядка колонок таблицы.

### `UPDATE`

```sql
CREATE TABLE extra_values (
    id integer,
    amount integer
);

INSERT INTO extra_values (id, amount)
VALUES (1, 100), (2, 200), (3, 300);

UPDATE extra_values
SET amount = amount + 50
WHERE id = 1
RETURNING *;
```

`SET` задаёт новое значение, `WHERE` выбирает изменяемые строки. `RETURNING *` сразу печатает изменённые строки – это тот же результат, который потом можно было бы прочитать через `SELECT`.

### `DELETE`

`UPDATE` или `DELETE` без `WHERE` затронет все строки таблицы. Ниже удаляем одну строку из той же `extra_values`:

```sql
DELETE FROM extra_values
WHERE id = 3
RETURNING *;
```

---



## **Часть IV. Ограничения таблицы**

Тип отвечает на вопрос «что можно хранить». Ограничение отвечает на вопрос «какие значения считаются допустимыми».

### `NOT NULL` **и** `DEFAULT`

```sql
CREATE TABLE extra_reviews (
    review_id bigint GENERATED ALWAYS AS IDENTITY,
    rating integer NOT NULL,
    created_at timestamp with time zone DEFAULT current_timestamp
);

INSERT INTO extra_reviews (rating)
VALUES (5)
RETURNING *;
```

- `NOT NULL` требует значение;
- `DEFAULT` подставляет значение, если колонку не указали;
- `GENERATED ... AS IDENTITY` выдаёт новый числовой идентификатор.

`DEFAULT` не является проверкой: пользователь всё ещё может явно передать другое допустимое значение.

### `CHECK`

Рейтинг должен находиться от 1 до 5:

```sql
CREATE TABLE extra_reviews (
    review_id bigint GENERATED ALWAYS AS IDENTITY,
    rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5)
);
```

Попытка вставить `rating = 10` завершится ошибкой ограничения.

### `PRIMARY KEY` **и** `UNIQUE`

```sql
CREATE TABLE extra_reviews (
    review_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_email text NOT NULL,
    flight_id integer NOT NULL,
    UNIQUE (author_email, flight_id)
);
```

- `PRIMARY KEY` однозначно определяет строку, запрещает `NULL` и повторы;
- `UNIQUE (author_email, flight_id)` запрещает повтор всей пары.

Первичный ключ бывает составным. Например, ключ `course.daily_airport_metrics` состоит из `airport_code` и `report_date`: один аэропорт не может получить две строки на одну дату. Это как раз то, что показал `\d`.

### `FOREIGN KEY`

Внешний ключ не даёт сослаться на несуществующий рейс:

```sql
CREATE TABLE extra_flight_reviews (
    review_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flight_id integer NOT NULL REFERENCES flights (flight_id),
    rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text text,
    author_email text NOT NULL,
    created_at timestamp with time zone DEFAULT current_timestamp,
    UNIQUE (flight_id, author_email)
);
```

Запись:

```text
REFERENCES flights (flight_id)
```

означает: значение `extra_flight_reviews.flight_id` должно существовать в первичном ключе `flights`.

### **Ограничение столбца и таблицы**

Правило одного столбца удобно писать рядом с типом:

```text
rating integer CHECK (rating BETWEEN 1 AND 5)
```

Правило нескольких столбцов пишут на уровне таблицы:

```text
UNIQUE (flight_id, author_email)
```

Название ограничения можно задать явно через `CONSTRAINT constraint_name`. Оно появится в сообщении об ошибке, в `\d` и облегчит поддержку схемы.

---



## **Часть V. Транзакции и ACID**

Пока что каждая команда жила сама по себе: выполнили `INSERT` – строка уже в таблице. Иногда несколько изменений должны пройти **вместе** или не пройти вовсе.

Представим перевод денег: списание со счёта A прошло, а зачисление на счёт B упало с ошибкой. Половина операции недопустима.

> **Транзакция** – набор операций, который подтверждается или отменяется как единое целое.

```text
BEGIN
→ изменение
→ проверка
→ COMMIT или ROLLBACK
```

- `BEGIN` открывает транзакцию;
- `COMMIT` подтверждает изменения;
- `ROLLBACK` отменяет все изменения после `BEGIN`.

```sql
BEGIN;

CREATE TABLE extra_balance (
    account_id integer PRIMARY KEY,
    amount numeric(12, 2) NOT NULL CHECK (amount >= 0)
);

INSERT INTO extra_balance (account_id, amount)
VALUES (1, 1000), (2, 500);

UPDATE extra_balance
SET amount = amount - 200
WHERE account_id = 1;

UPDATE extra_balance
SET amount = amount + 200
WHERE account_id = 2;

SELECT *
FROM extra_balance
ORDER BY account_id;

ROLLBACK;
```

После `ROLLBACK` не останется ни таблицы, ни перевода. Если вместо `ROLLBACK` написать `COMMIT`, оба обновления сохранятся вместе.

Четыре свойства транзакции:

- **Atomicity** – транзакция выполняется целиком или не выполняется;
- **Consistency** – ограничения базы остаются выполненными;
- **Isolation** – параллельные транзакции не должны ломать расчёты друг друга;
- **Durability** – подтверждённые изменения сохраняются после сбоя.

`CHECK (amount >= 0)` помогает consistency: некорректное отрицательное значение не проходит.

Уровни изоляции, блокировки и deadlock – отдельная большая тема. Здесь достаточно понимать границы `BEGIN`, `COMMIT`, `ROLLBACK`.

Если преподаватель показывает запись на учебной базе, как раз так и делают: `BEGIN`, команды, в конце `ROLLBACK`, чтобы не оставить лишние объекты.

---



## **Часть VI. Индексы**

Без индекса PostgreSQL может прочитать таблицу строка за строкой.

> **Индекс** – отдельный объект рядом с таблицей. Он хранит значения колонки в удобном для поиска порядке и ссылки на строки.

`EXPLAIN` показывает план, но не выполняет запрос:

```sql
EXPLAIN
SELECT flight_id
FROM flights
WHERE status = 'Scheduled';
```

Два названия, которые важно узнать:

- `Seq Scan` – последовательный просмотр;
- `Index Scan` – чтение через индекс.

Оптимизатор может выбрать `Seq Scan` даже при наличии индекса, если таблица маленькая или условию соответствует большая часть строк.

### **B-tree – индекс по умолчанию**

```text
CREATE INDEX index_name
ON table_name (column_name);
```

```sql
CREATE INDEX extra_notes_flight_idx
ON extra_notes (flight_id);
```

B-tree подходит для равенства, сравнений, диапазонов и сортировки. Это основной индекс PostgreSQL.

`PRIMARY KEY` и `UNIQUE` в PostgreSQL автоматически создают уникальные B-tree индексы. Их как раз видно в `\d`.

Настоящие индексы таблицы `flights` можно только посмотреть – создавать свои на общей таблице курса не нужно:

```sql
SELECT indexname,
       indexdef
FROM pg_indexes
WHERE schemaname = 'bookings'
  AND tablename = 'flights'
ORDER BY indexname;
```

В `psql` короче: `\di bookings.flights*` или снова `\d bookings.flights`.

`flights_pkey` – уникальный B-tree по `flight_id`.

Есть и другие методы индексов (Hash, GIN, GiST, BRIN) – они нужны под другие типы вопросов. Для равенства, диапазона и сортировки обычных чисел, дат и текста хватает B-tree. Остальное – в [документации по индексам](https://postgrespro.ru/docs/postgresql/current/indexes).

### **Составной индекс**

Составной индекс хранит несколько колонок в заданном порядке:

```sql
CREATE INDEX extra_notes_id_note_idx
ON extra_notes (flight_id, note);
```

Порядок колонок важен: индекс `(flight_id, note)` начинается с `flight_id`. Для поиска только по `note` такой индекс может быть менее полезен.

### **Уникальный индекс**

```text
CREATE UNIQUE INDEX index_name
ON table_name (column_name);
```

Он ускоряет поиск и запрещает повторы. Обычно бизнес-правило лучше выражать ограничением `UNIQUE`, чтобы намерение было видно в схеме.

### **Частичный индекс**

Индекс может хранить только нужную часть таблицы:

```sql
CREATE INDEX extra_notes_checked_idx
ON extra_notes (flight_id)
WHERE note = 'Проверить рейс';
```

Частичный индекс меньше полного и полезен, когда запросы используют такой же предикат.

### **Индекс по выражению**

Иногда запрос ищет результат функции:

```sql
CREATE INDEX extra_notes_note_lower_idx
ON extra_notes (lower(note));
```

Он помогает условию `WHERE lower(note) = 'проверить рейс'`. Без такого индекса PostgreSQL не сможет использовать обычный индекс по `note`.

### **Цена индекса**

Индекс:

- занимает место;
- обновляется при `INSERT`, `UPDATE`, `DELETE`;
- может замедлить массовую загрузку.

Индекс создают под реальные условия `WHERE`, связи `JOIN` и сортировки, а не на каждую колонку.

---



## **Шпаргалка**

| Вопрос                      | Конструкция                      |
| --------------------------- | -------------------------------- |
| посмотреть столбцы и ключи  | `\d имя` в `psql`                |
| плюс комментарии и размер   | `\d+ имя`                        |
| создать таблицу             | `CREATE TABLE ...`               |
| сохранить результат запроса | `CREATE TABLE ... AS SELECT ...` |
| добавить строки             | `INSERT INTO ...`                |
| изменить строки             | `UPDATE ... SET ... WHERE ...`   |
| удалить строки              | `DELETE FROM ... WHERE ...`      |
| всё или ничего              | `BEGIN` / `COMMIT` / `ROLLBACK`  |
| ускорить поиск              | `CREATE INDEX ...`               |

---

Запись данных – отдельный слой рядом с `SELECT`. На учебной роли `student` его можно только прочитать в этом конспекте; менять общие таблицы курса не нужно.

До встречи на следующей страничке!

## **Полезное**

- [Клиент](https://postgrespro.ru/docs/postgresql/current/app-psql) `psql`
- [CREATE TABLE](https://postgrespro.ru/docs/postgresql/current/sql-createtable)
- [INSERT](https://postgrespro.ru/docs/postgresql/current/sql-insert), [UPDATE](https://postgrespro.ru/docs/postgresql/current/sql-update), [DELETE](https://postgrespro.ru/docs/postgresql/current/sql-delete)
- [Транзакции](https://postgrespro.ru/docs/postgresql/current/tutorial-transactions)
- [Ограничения](https://postgrespro.ru/docs/postgresql/current/ddl-constraints)
- [Индексы](https://postgrespro.ru/docs/postgresql/current/indexes)
- [EXPLAIN](https://postgrespro.ru/docs/postgresql/current/sql-explain)
