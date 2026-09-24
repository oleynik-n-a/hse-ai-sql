-- HW 3. Скопируйте файл и переименуйте по почте: avivanov@edu.hse.ru → avivanov_hw3.sql
-- Правила – ../README.md, условия – README.md в этой папке.

-- >>> Q01
-- JOIN справочника и выгрузки
SELECT m.airport_code,
       m.airport_name,
       d.departure_id
FROM course.airports_master AS m
JOIN course.departures_feed AS d
  ON m.airport_code = d.airport_code
ORDER BY m.airport_code, d.departure_id;


-- >>> Q02
-- тот же JOIN через USING
SELECT airport_code,
       m.airport_name,
       d.departure_id
FROM course.airports_master AS m
JOIN course.departures_feed AS d USING (airport_code)
ORDER BY airport_code, d.departure_id;


-- >>> Q03
-- все аэропорты справочника через LEFT JOIN
SELECT m.airport_code,
       m.airport_name,
       d.departure_id
FROM course.airports_master AS m
LEFT JOIN course.departures_feed AS d
  ON m.airport_code = d.airport_code
ORDER BY m.airport_code, d.departure_id;


-- >>> Q04
-- перестановка Q03 через RIGHT JOIN
SELECT m.airport_code,
       m.airport_name,
       d.departure_id
FROM course.departures_feed AS d
RIGHT JOIN course.airports_master AS m
  ON d.airport_code = m.airport_code
ORDER BY m.airport_code, d.departure_id;


-- >>> Q05
-- все строки обеих сторон через FULL JOIN
SELECT m.airport_code AS master_airport,
       m.airport_name,
       d.airport_code AS feed_airport,
       d.departure_id
FROM course.airports_master AS m
FULL JOIN course.departures_feed AS d
  ON m.airport_code = d.airport_code
ORDER BY master_airport, feed_airport, d.departure_id;


-- >>> Q06
-- аэропорты без пары: left anti join
SELECT m.airport_code,
       m.airport_name
FROM course.airports_master AS m
LEFT JOIN course.departures_feed AS d
  ON m.airport_code = d.airport_code
WHERE d.airport_code IS NULL
ORDER BY m.airport_code;


-- >>> Q07
-- уникальные аэропорты на обоих концах через UNION
SELECT departure_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
UNION
SELECT arrival_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
ORDER BY airport_code;


-- >>> Q08
-- все комбинации аэропортов и классов
SELECT m.airport_code,
       f.fare_conditions
FROM course.airports_master AS m
CROSS JOIN course.fare_classes AS f
ORDER BY m.airport_code, f.fare_conditions;


-- >>> Q09
-- все появления аэропортов на концах через UNION ALL
SELECT departure_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
UNION ALL
SELECT arrival_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
ORDER BY airport_code;


-- >>> Q10
-- коды и отправления, и прибытия через INTERSECT
SELECT departure_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
INTERSECT
SELECT arrival_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
ORDER BY airport_code;


-- >>> Q11
-- отправления, которых нет среди прибытий, через EXCEPT
SELECT departure_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
EXCEPT
SELECT arrival_airport AS airport_code
FROM timetable
WHERE flight_id <= 20
ORDER BY airport_code;


-- >>> Q12
-- билеты и сегменты бронирования
SELECT t.ticket_no,
       t.passenger_name,
       s.flight_id,
       s.price
FROM tickets AS t
JOIN segments AS s
  ON t.ticket_no = s.ticket_no
WHERE t.book_ref = '0000EG'
ORDER BY t.ticket_no, s.flight_id;


-- >>> Q13
-- рейс, аэропорт отправления и самолёт
SELECT t.flight_id,
       a.airport_name AS departure_airport_name,
       p.model AS airplane_model
FROM timetable AS t
JOIN airports AS a
  ON t.departure_airport = a.airport_code
JOIN airplanes AS p
  ON t.airplane_code = p.airplane_code
WHERE t.flight_id <= 10
ORDER BY t.flight_id;


-- >>> Q14
-- первые рейсы и найденные сегменты через LEFT JOIN
SELECT f.flight_id,
       f.status,
       s.ticket_no,
       s.price
FROM flights AS f
LEFT JOIN segments AS s
  ON f.flight_id = s.flight_id
 AND s.price >= 20000
WHERE f.flight_id <= 10
ORDER BY f.flight_id, s.ticket_no;


-- >>> Q15
-- билет, сегмент и рейс через два LEFT JOIN
SELECT t.ticket_no,
       t.passenger_name,
       s.flight_id,
       f.status AS flight_status
FROM tickets AS t
LEFT JOIN segments AS s
  ON t.ticket_no = s.ticket_no
LEFT JOIN flights AS f
  ON s.flight_id = f.flight_id
WHERE t.book_ref = '0000EG'
ORDER BY t.ticket_no, s.flight_id;


-- >>> Q16
-- поток плановых и фактических событий через UNION ALL
SELECT flight_id,
       scheduled_departure AS event_time,
       'scheduled_departure' AS event_type
FROM flights
WHERE status = 'Arrived'
  AND flight_id <= 10
UNION ALL
SELECT flight_id,
       actual_departure AS event_time,
       'actual_departure' AS event_type
FROM flights
WHERE status = 'Arrived'
  AND flight_id <= 10
  AND actual_departure IS NOT NULL
ORDER BY flight_id, event_type;
