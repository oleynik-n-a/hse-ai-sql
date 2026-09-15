-- HW 2. Скопируйте файл и переименуйте по почте: avivanov@edu.hse.ru → avivanov_hw2.sql
-- Правила – ../README.md, условия – README.md в этой папке.

-- >>> Q01
-- сколько рейсов всего
SELECT COUNT(*) AS flight_count
FROM flights;


-- >>> Q02
-- крайние плановые вылеты
SELECT
    MIN(scheduled_departure) AS earliest_departure,
    MAX(scheduled_departure) AS latest_departure
FROM flights;


-- >>> Q03
-- агрегаты по срезу сегментов, одна строка
SELECT
    COUNT(*) AS segment_count,
    ROUND(AVG(price), 2) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM segments
WHERE flight_id <= 5000;


-- >>> Q04
-- рейсы по статусам
SELECT
    status,
    COUNT(*) AS flight_count
FROM flights
GROUP BY status
ORDER BY flight_count DESC, status;


-- >>> Q05
-- цена по классу тарифа
SELECT
    fare_conditions,
    COUNT(*) AS segment_count,
    ROUND(AVG(price), 2) AS avg_price,
    MAX(price) AS max_price
FROM segments
GROUP BY fare_conditions
ORDER BY fare_conditions;


-- >>> Q06
-- страны с большой сетью
SELECT
    country,
    COUNT(*) AS airport_count
FROM airports
GROUP BY country
HAVING COUNT(*) >= 30
ORDER BY airport_count DESC, country;


-- >>> Q07
-- направления с более чем 100 рейсами
SELECT
    departure_airport,
    arrival_airport,
    COUNT(*) AS flight_count
FROM timetable
GROUP BY departure_airport, arrival_airport
HAVING COUNT(*) > 100
ORDER BY flight_count DESC, departure_airport, arrival_airport;


-- >>> Q08
-- будущие Scheduled по аэропорту
SELECT
    departure_airport,
    COUNT(*) AS scheduled_count
FROM timetable
WHERE status = 'Scheduled'
  AND scheduled_departure > bookings.now()
GROUP BY departure_airport
HAVING COUNT(*) >= 15
ORDER BY scheduled_count DESC, departure_airport;


-- >>> Q09
-- последний вылет в статусе
SELECT
    status,
    COUNT(*) AS flight_count,
    MAX(scheduled_departure) AS latest_scheduled_departure
FROM flights
GROUP BY status
ORDER BY flight_count DESC, status;


-- >>> Q10
-- самые загруженные дни
SELECT
    scheduled_departure::date AS departure_date,
    COUNT(*) AS flight_count
FROM flights
GROUP BY scheduled_departure::date
HAVING COUNT(*) >= 192
ORDER BY flight_count DESC, departure_date;


-- >>> Q11
-- вылетели и всего по статусу
SELECT
    status,
    COUNT(*) AS flight_count,
    COUNT(*) FILTER (WHERE actual_departure IS NOT NULL) AS departed_count
FROM flights
GROUP BY status
ORDER BY status;


-- >>> Q12
-- классы дороже общего среднего
SELECT
    fare_conditions,
    ROUND(AVG(price), 2) AS avg_price
FROM segments
GROUP BY fare_conditions
HAVING AVG(price) > (
    SELECT AVG(price)
    FROM segments
)
ORDER BY avg_price DESC, fare_conditions;


-- >>> Q13
-- 4 сегмента и sum(price) > 220000
SELECT
    ticket_no,
    COUNT(*) AS segment_count
FROM segments
WHERE flight_id <= 5000
GROUP BY ticket_no
HAVING COUNT(*) = 4
   AND SUM(price) > 220000
ORDER BY ticket_no;


-- >>> Q14
-- статистика суммы билета (подзапрос во FROM)
SELECT
    ROUND(AVG(total_price), 2) AS avg_ticket_price,
    MIN(total_price) AS min_ticket_price,
    MAX(total_price) AS max_ticket_price
FROM (
    SELECT
        ticket_no,
        SUM(price) AS total_price
    FROM segments
    WHERE flight_id <= 5000
    GROUP BY ticket_no
) AS ticket_prices;


-- >>> Q15
-- book_ref с max ticket_count в срезе
WITH booking_ticket_counts AS (
    SELECT
        book_ref,
        COUNT(*) AS ticket_count
    FROM tickets
    WHERE book_ref < '100000'
    GROUP BY book_ref
)
SELECT
    book_ref,
    ticket_count
FROM booking_ticket_counts
WHERE ticket_count = (
    SELECT MAX(ticket_count)
    FROM booking_ticket_counts
)
ORDER BY ticket_count DESC, book_ref;


-- >>> Q16
-- средняя задержка (interval) по аэропорту
SELECT
    departure_airport,
    COUNT(*) AS arrived_count,
    AVG(actual_arrival - scheduled_arrival) AS avg_delay
FROM timetable
WHERE status = 'Arrived'
GROUP BY departure_airport
HAVING COUNT(*) >= 100
ORDER BY avg_delay DESC, departure_airport;


-- >>> Q17
-- дорогие билеты и их классы
SELECT
    ticket_no,
    STRING_AGG(fare_conditions, ', ' ORDER BY fare_conditions) AS fare_classes,
    SUM(price) AS total_price
FROM segments
WHERE flight_id <= 5000
GROUP BY ticket_no
HAVING SUM(price) > 250000
ORDER BY total_price DESC, ticket_no;
