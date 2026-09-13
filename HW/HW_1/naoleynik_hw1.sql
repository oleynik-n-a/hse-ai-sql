-- HW 1. Скопируйте файл и переименуйте по почте: avivanov@edu.hse.ru → avivanov_hw1.sql
-- Правила – ../README.md, условия – README.md в этой папке.

-- >>> Q01
-- парк самолётов как есть
SELECT airplane_code, model, range, speed
FROM airplanes
ORDER BY airplane_code;

-- >>> Q02
-- карточка типа
SELECT airplane_code, model, range
FROM airplanes
ORDER BY airplane_code;

-- >>> Q03
-- от ближних к дальним
SELECT airplane_code, model, range
FROM airplanes
ORDER BY range ASC, airplane_code ASC;

-- >>> Q04
-- три типа с наибольшей дальностью
SELECT airplane_code, model, range
FROM airplanes
ORDER BY range DESC, airplane_code ASC
LIMIT 3;

-- >>> Q05
-- начало справочника аэропортов
SELECT airport_code, airport_name, city
FROM airports
ORDER BY airport_code
LIMIT 10;

-- >>> Q06
-- строки 11–20 после сортировки по коду
SELECT airport_code, airport_name, city
FROM airports
ORDER BY airport_code
LIMIT 10 OFFSET 10;

-- >>> Q07
-- страны A→Z, города Z→A
SELECT airport_code, city, country
FROM airports
ORDER BY country ASC, city DESC, airport_code ASC
LIMIT 20;

-- >>> Q08
-- немецкая сеть
SELECT airport_code, airport_name, city
FROM airports
WHERE country = 'Germany'
ORDER BY city, airport_code;

-- >>> Q09
-- кто дотянет за 4000 км
SELECT airplane_code, model, range
FROM airplanes
WHERE range >= 4000
ORDER BY range DESC, airplane_code ASC;

-- >>> Q10
-- столичные точки Москвы
SELECT airport_code, airport_name, city, timezone
FROM airports
WHERE country = 'Russia'
  AND city = 'Moscow'
ORDER BY airport_code;

-- >>> Q11
-- рабочая дальность
SELECT airplane_code, model, range, speed
FROM airplanes
WHERE range BETWEEN 2000 AND 8000
ORDER BY range ASC, airplane_code ASC;

-- >>> Q12
-- южный контур Европы
SELECT airport_code, city, country
FROM airports
WHERE country IN ('France', 'Italy', 'Spain')
ORDER BY country, city, airport_code;

-- >>> Q13
-- статусы рейсов без повторов
SELECT DISTINCT status
FROM flights
ORDER BY status;

-- >>> Q14
-- ближайшие три часа дня bookings.now()
SELECT flight_id,
       route_no,
       scheduled_departure,
       scheduled_departure::date AS departure_date
FROM flights
WHERE scheduled_departure::date = bookings.now()::date
  AND scheduled_departure >= bookings.now()
  AND scheduled_departure < bookings.now() + INTERVAL '3 hours'
ORDER BY scheduled_departure, flight_id;

-- >>> Q15
-- русские названия московских аэропортов
SELECT airport_code,
       airport_name ->> 'ru' AS name_ru,
       city ->> 'ru' AS city_ru
FROM airports_data
WHERE city ->> 'en' = 'Moscow'
ORDER BY airport_code;

-- >>> Q16
-- кто сейчас в воздухе
SELECT flight_id,
       route_no,
       actual_departure,
       actual_arrival
FROM flights
WHERE actual_departure IS NOT NULL
  AND actual_arrival IS NULL
ORDER BY actual_departure, flight_id;

-- >>> Q17
-- билеты туда, имя на My
SELECT ticket_no,
       passenger_id,
       passenger_name
FROM tickets
WHERE outbound = TRUE
  AND passenger_name ILIKE 'My%'
ORDER BY passenger_name, ticket_no;

-- >>> Q18
-- плечо парка: short / medium / long
SELECT airplane_code,
       model,
       range,
       CASE
           WHEN range < 3000 THEN 'short'
           WHEN range < 8000 THEN 'medium'
           ELSE 'long'
       END AS haul
FROM airplanes
ORDER BY range DESC, airplane_code;

-- >>> Q19
-- длинные рейсы аэропорта «Внуково»
SELECT flight_id,
       route_no,
       departure_airport,
       arrival_airport,
       scheduled_departure,
       scheduled_arrival - scheduled_departure AS planned_duration
FROM timetable
WHERE status = 'Scheduled'
  AND scheduled_departure >= bookings.now()
  AND (departure_airport = 'VKO' OR arrival_airport = 'VKO')
  AND scheduled_arrival - scheduled_departure > INTERVAL '3 hours'
ORDER BY planned_duration DESC, flight_id
LIMIT 50;
