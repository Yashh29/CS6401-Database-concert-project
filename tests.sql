USE cs6401_concerts;
-- Cleanup of any earlier test rows.
DELETE FROM reservation_audit      WHERE ticket_id  >= 9000;
DELETE FROM ticket_fans            WHERE ticket_id  >= 9000;
DELETE FROM tickets                WHERE ticket_id  >= 9000;
DELETE FROM fan_favourite_artists  WHERE fan_id     >= 9000;
DELETE FROM fans                   WHERE fan_id     >= 9000;
DELETE FROM concert_artists        WHERE concert_id >= 9000;
DELETE FROM concert_songs          WHERE concert_id >= 9000;
DELETE FROM concerts               WHERE concert_id >= 9000;
DELETE FROM album_songs            WHERE album_id   >= 9000;
DELETE FROM album_songs            WHERE song_id    >= 9000;
DELETE FROM song_artists           WHERE song_id    >= 9000;
DELETE FROM songs                  WHERE song_id    >= 9000;
DELETE FROM album_artists          WHERE album_id   >= 9000;
DELETE FROM albums                 WHERE album_id   >= 9000;
DELETE FROM artists                WHERE artist_id  >= 9000;
-- Baseline: row counts must match data.sql exactly.
-- Purpose: confirm that the schema and data.sql were loaded correctly.
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'B01' AS test_id, 'Row count: artists' AS purpose, '40' AS expected,
           CAST((SELECT COUNT(*) FROM artists) AS CHAR) AS actual
    UNION ALL SELECT 'B02', 'Row count: albums', '60',
           CAST((SELECT COUNT(*) FROM albums) AS CHAR)
    UNION ALL SELECT 'B03', 'Row count: songs', '360',
           CAST((SELECT COUNT(*) FROM songs) AS CHAR)
    UNION ALL SELECT 'B04', 'Row count: album_artists', '120',
           CAST((SELECT COUNT(*) FROM album_artists) AS CHAR)
    UNION ALL SELECT 'B05', 'Row count: song_artists', '720',
           CAST((SELECT COUNT(*) FROM song_artists) AS CHAR)
    UNION ALL SELECT 'B06', 'Row count: album_songs', '362',
           CAST((SELECT COUNT(*) FROM album_songs) AS CHAR)
    UNION ALL SELECT 'B07', 'Row count: concerts', '51',
           CAST((SELECT COUNT(*) FROM concerts) AS CHAR)
    UNION ALL SELECT 'B08', 'Row count: concert_artists', '102',
           CAST((SELECT COUNT(*) FROM concert_artists) AS CHAR)
    UNION ALL SELECT 'B09', 'Row count: concert_songs', '300',
           CAST((SELECT COUNT(*) FROM concert_songs) AS CHAR)
    UNION ALL SELECT 'B10', 'Row count: fans', '650',
           CAST((SELECT COUNT(*) FROM fans) AS CHAR)
    UNION ALL SELECT 'B11', 'Row count: fan_favourite_artists', '1300',
           CAST((SELECT COUNT(*) FROM fan_favourite_artists) AS CHAR)
    UNION ALL SELECT 'B12', 'Row count: tickets', '300',
           CAST((SELECT COUNT(*) FROM tickets) AS CHAR)
    UNION ALL SELECT 'B13', 'Row count: ticket_fans', '600',
           CAST((SELECT COUNT(*) FROM ticket_fans) AS CHAR)
    UNION ALL SELECT 'B14', 'Row count: reservation_audit is empty (data.sql was loaded before code.sql)', '0',
           CAST((SELECT COUNT(*) FROM reservation_audit) AS CHAR)
) AS r;
-- Fixtures (IDs 9001+). They are used only by the tests below.
INSERT INTO artists (artist_id, artist_name, genre, debut_year) VALUES
    (9001, 'Test Artist A', 'Test', 2020),
    (9002, 'Test Artist B', 'Test', 2021);
INSERT INTO albums (album_id, album_title, release_date) VALUES
    (9001, 'Test Album Dated',       '2022-01-01'),
    (9002, 'Test Album Null Date',   NULL),
    (9003, 'Test Album Constraints', '2022-01-01');
INSERT INTO songs (song_id, song_title, duration_seconds, release_date) VALUES
    (9001, 'Test Song Later Than Album',   200, '2023-05-05'),
    (9002, 'Test Song Earlier Than Album', 200, '2020-01-01'),
    (9003, 'Test Song Linked, Later',      200, '2024-01-01'),
    (9004, 'Test Song Linked, Same Date',  200, '2022-01-01'),
    (9005, 'Test Song Null Date',          200, NULL),
    (9006, 'Test Song For Null Album',     200, '2024-01-01'),
    (9007, 'Test Song Constraint A',       200, '2021-01-01'),
    (9008, 'Test Song Constraint B',       200, '2021-01-01');
-- Songs 9003 and 9004 are already on album 9001 (tracks 1 and 2).
INSERT INTO album_songs (album_id, song_id, track_number) VALUES
    (9001, 9003, 1),
    (9001, 9004, 2);
INSERT INTO fans (fan_id, fan_name, fan_email, age) VALUES
    (9001, 'Test Fan One',   'test9001@example.com', 30),
    (9002, 'Test Fan Two',   'test9002@example.com', 31),
    (9003, 'Test Fan Three', 'test9003@example.com', 32),
    (9004, 'Test Fan Four',  'test9004@example.com', 33),
    (9005, 'Test Fan Five',  'test9005@example.com', 34),
    (9006, 'Test Fan Six',   'test9006@example.com', 35);

INSERT INTO concerts (concert_id, concert_title, location, date_of_concert) VALUES
    (9001, 'Test Concert Triggers',   'Limerick', '2027-06-01'),
    (9002, 'Test Concert Function',   'Cork',     '2027-07-01'),
    (9003, 'Test Concert No Tickets', 'Galway',   '2027-08-01');

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'S01' AS test_id, 'Fixtures created: 2 artists, 3 albums, 8 songs, 6 fans, 3 concerts, 2 album_songs' AS purpose,
           '2,3,8,6,3,2' AS expected,
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM artists     WHERE artist_id  >= 9000),
               (SELECT COUNT(*) FROM albums      WHERE album_id   >= 9000),
               (SELECT COUNT(*) FROM songs       WHERE song_id    >= 9000),
               (SELECT COUNT(*) FROM fans        WHERE fan_id     >= 9000),
               (SELECT COUNT(*) FROM concerts    WHERE concert_id >= 9000),
               (SELECT COUNT(*) FROM album_songs WHERE album_id   >= 9000)) AS actual
) AS r;

-- 1: TESTS EXPECTED TO SUCCEED

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'R01' AS test_id,
           'Req 1: album 1 has two artists' AS purpose, '2' AS expected,
           CAST((SELECT COUNT(*) FROM album_artists WHERE album_id = 1) AS CHAR) AS actual
    UNION ALL SELECT 'R02',
           'Req 1: song (recording) 1 has two artists', '2',
           CAST((SELECT COUNT(*) FROM song_artists WHERE song_id = 1) AS CHAR)
    UNION ALL SELECT 'R03',
           'Req 1: concert 1 has three artists', '3',
           CAST((SELECT COUNT(*) FROM concert_artists WHERE concert_id = 1) AS CHAR)
    UNION ALL SELECT 'R04',
           'Req 1: no concert in 2..50 has other than two artists (count of exceptions)', '0',
           CAST((SELECT COUNT(*) FROM (
                    SELECT concert_id FROM concert_artists
                    WHERE concert_id BETWEEN 2 AND 50
                    GROUP BY concert_id HAVING COUNT(*) <> 2) AS x) AS CHAR)
    UNION ALL SELECT 'R05',
           'Req 2: fan 1 has two favourite artists', '2',
           CAST((SELECT COUNT(*) FROM fan_favourite_artists WHERE fan_id = 1) AS CHAR)
    UNION ALL SELECT 'R06',
           'Req 3: ticket 1 is one ticket row covering three fans (3 ticket_fans rows)', '3',
           CAST((SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 1) AS CHAR)
    UNION ALL SELECT 'R07',
           'Req 3: the three fans on ticket 1 are different people with different seats', '3,3',
           CONCAT_WS(',',
               (SELECT COUNT(DISTINCT fan_id) FROM ticket_fans WHERE ticket_id = 1),
               (SELECT COUNT(DISTINCT seat_zone, seat_number) FROM ticket_fans WHERE ticket_id = 1))
    UNION ALL SELECT 'R08',
           'Req 4: recording 1 appears on two different albums', '2',
           CAST((SELECT COUNT(DISTINCT album_id) FROM album_songs WHERE song_id = 1) AS CHAR)
    UNION ALL SELECT 'R09',
           'Req 4: recording 5 appears on two different albums', '2',
           CAST((SELECT COUNT(DISTINCT album_id) FROM album_songs WHERE song_id = 5) AS CHAR)
    UNION ALL SELECT 'R10',
           'Two different recordings share the title Open Roads (different song_id and duration)', '2,2',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM songs WHERE song_title = 'Open Roads'),
               (SELECT COUNT(DISTINCT duration_seconds) FROM songs WHERE song_title = 'Open Roads'))
    UNION ALL SELECT 'R11',
           'Release date is the earliest date: recording 1 predates both albums it appears on', '2',
           CAST((SELECT COUNT(*)
                 FROM album_songs als
                 JOIN songs s  ON s.song_id  = als.song_id
                 JOIN albums a ON a.album_id = als.album_id
                 WHERE s.song_id = 1 AND s.release_date < a.release_date) AS CHAR)
    UNION ALL SELECT 'R12',
           'A fan can hold seats for different concerts: fan 1 is on tickets for 2 concerts', '2',
           CAST((SELECT COUNT(DISTINCT concert_id) FROM ticket_fans WHERE fan_id = 1) AS CHAR)
) AS r;

-- Valid data and referential actions

INSERT INTO album_songs (album_id, song_id, track_number) VALUES (9003, 9007, 1);

-- K02: a test album with TWO artists (composite primary key allows it).
INSERT INTO albums (album_id, album_title, release_date)
VALUES (9004, 'Test Album Cascade', '2022-01-01');
INSERT INTO album_artists (album_id, artist_id) VALUES (9004, 9001), (9004, 9002);

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'K01' AS test_id,
           'Valid album_songs row (album 9003, song 9007, track 1) is stored' AS purpose,
           '1,1' AS expected,
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM album_songs WHERE album_id = 9003 AND song_id = 9007),
               (SELECT track_number FROM album_songs WHERE album_id = 9003 AND song_id = 9007)) AS actual
    UNION ALL SELECT 'K02',
           'Valid insert: album 9004 stored with two artists', '2',
           CAST((SELECT COUNT(*) FROM album_artists WHERE album_id = 9004) AS CHAR)
) AS r;

-- K03/K04: ON DELETE CASCADE removes the album's artist links but not the artists.
DELETE FROM albums WHERE album_id = 9004;

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'K03' AS test_id,
           'Deleting album 9004 cascades to album_artists (0 links left)' AS purpose,
           '0' AS expected,
           CAST((SELECT COUNT(*) FROM album_artists WHERE album_id = 9004) AS CHAR) AS actual
    UNION ALL SELECT 'K04',
           'The artists 9001 and 9002 still exist after the cascade', '2',
           CAST((SELECT COUNT(*) FROM artists WHERE artist_id IN (9001, 9002)) AS CHAR)
) AS r;

-- 1C. Triggers: accepted operations
-- BEFORE INSERT trigger on tickets (trg_tickets_before_insert):
--   G01: purchase_date before the concert date (concert 9001 = 2027-06-01) is accepted.
--   G02: purchase_date equal to the concert date is accepted (rule is "after").
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9001, 9001, '2027-05-01', 80.00);
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9002, 9001, '2027-06-01', 55.50);

-- G03 is checked BEFORE any seat is reserved on ticket 9001.
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'G01' AS test_id,
           'BEFORE trigger accepts a purchase date before the concert' AS purpose,
           '1' AS expected,
           CAST((SELECT COUNT(*) FROM tickets WHERE ticket_id = 9001) AS CHAR) AS actual
    UNION ALL SELECT 'G02',
           'BEFORE trigger accepts a purchase date equal to the concert date (boundary)', '1',
           CAST((SELECT COUNT(*) FROM tickets WHERE ticket_id = 9002) AS CHAR)
    UNION ALL SELECT 'G03',
           'Inserting a ticket alone writes no audit row (AFTER trigger is on ticket_fans)', '0',
           CAST((SELECT COUNT(*) FROM reservation_audit WHERE ticket_id IN (9001, 9002)) AS CHAR)
) AS r;

-- AFTER INSERT trigger on ticket_fans (trg_ticket_fans_after_insert):
-- one multi-row INSERT reserving two seats must create two audit rows.
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number) VALUES
    (9001, 9001, 9001, 'A', '01'),
    (9001, 9001, 9002, 'A', '02');

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'G04' AS test_id,
           'AFTER trigger: two reserved seats give two audit rows for ticket 9001' AS purpose,
           '2' AS expected,
           CAST((SELECT COUNT(*) FROM reservation_audit WHERE ticket_id = 9001) AS CHAR) AS actual
    UNION ALL SELECT 'G05',
           'Audit rows name the right fans (9001 and 9002)', '2',
           CAST((SELECT COUNT(*) FROM reservation_audit
                 WHERE ticket_id = 9001 AND fan_id IN (9001, 9002)) AS CHAR)
    UNION ALL SELECT 'G06',
    'Every audit row has action_type RESERVATION_CREATED (count of other values)',
    '0',
    CAST((SELECT COUNT(*) FROM reservation_audit
          WHERE ticket_id = 9001
          AND action_type <> 'RESERVATION_CREATED') AS CHAR)
    UNION ALL SELECT 'G07',
           'Ticket 9002 has no reserved seats yet, so no audit rows', '0',
           CAST((SELECT COUNT(*) FROM reservation_audit WHERE ticket_id = 9002) AS CHAR)
) AS r;

-- 1D. Function fn_reserved_seats(concert_id)
-- Fixture concert 9002 gets tickets of 3, 1 and 2 fans, one at a time.
-- F00: concert 9002 exists but has no tickets yet.
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'F00' AS test_id,
           'Existing concert 9002 with no tickets yet returns 0' AS purpose,
           '0' AS expected,
           CAST(fn_reserved_seats(9002) AS CHAR) AS actual
) AS r;

-- Ticket 9011 covers THREE fans.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9011, 9002, '2027-06-15', 120.00);
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number) VALUES
    (9011, 9002, 9001, 'A', '01'),
    (9011, 9002, 9002, 'A', '02'),
    (9011, 9002, 9003, 'A', '03');

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'F01' AS test_id,
           'Ticket 9011 has three fans, so concert 9002 has 3 seats (ticket 9011 contributes 3)' AS purpose,
           '3,3' AS expected,
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9011),
               fn_reserved_seats(9002)) AS actual
) AS r;

-- Ticket 9012 covers ONE fan.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9012, 9002, '2027-06-16', 40.00);
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
VALUES (9012, 9002, 9004, 'B', '01');

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'F02' AS test_id,
           'Second ticket (one fan) adds one seat: 3 + 1 = 4' AS purpose,
           '4' AS expected,
           CAST(fn_reserved_seats(9002) AS CHAR) AS actual
) AS r;

-- Ticket 9013 covers TWO fans.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9013, 9002, '2027-06-17', 70.00);
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number) VALUES
    (9013, 9002, 9005, 'C', '01'),
    (9013, 9002, 9006, 'C', '02');

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'F03' AS test_id,
           'Three distinct tickets (3 + 1 + 2 fans) give 6 seats' AS purpose,
           '6' AS expected,
           CAST(fn_reserved_seats(9002) AS CHAR) AS actual
    UNION ALL SELECT 'F04',
           'Seats per ticket 9011, 9012, 9013 are 3, 1 and 2', '3,1,2',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9011),
               (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9012),
               (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9013))
    UNION ALL SELECT 'F05',
           'Function equals an independent join count (tickets JOIN ticket_fans) for concert 9002', '6',
           CAST((SELECT COUNT(*) FROM tickets t
                 JOIN ticket_fans tf ON tf.ticket_id = t.ticket_id
                 WHERE t.concert_id = 9002) AS CHAR)
    UNION ALL SELECT 'F06',
           'Existing concert 9003 with no tickets returns 0 (and not NULL)', '0',
           CAST(fn_reserved_seats(9003) AS CHAR)
    
    UNION ALL SELECT 'F07',
           'Seed concert 51 has no tickets and returns 0', '0',
           CAST(fn_reserved_seats(51) AS CHAR)
    UNION ALL SELECT 'F10',
           'Seed concert 1 (ticket 1 has 3 fans, ticket 2 has 2, six generated tickets have 2 each): 17 seats', '17',
           CAST(fn_reserved_seats(1) AS CHAR)
    UNION ALL SELECT 'F11',
           'Function agrees with the independent join count for EVERY concert (count of mismatches)', '0',
           CAST((SELECT COUNT(*) FROM concerts c
                 WHERE fn_reserved_seats(c.concert_id) <>
                       (SELECT COUNT(*) FROM tickets t
                        JOIN ticket_fans tf ON tf.ticket_id = t.ticket_id
                        WHERE t.concert_id = c.concert_id)) AS CHAR)
) AS r;

-- F08: Expected error - nonexistent concert
SELECT fn_reserved_seats(99999999);

-- F09: Expected error - NULL concert ID
SELECT fn_reserved_seats(NULL);


-- 1E. View v_concert_sales_summary (HAVING SUM(seats) >= 12)
-- Seed data: concerts 2 and 6 have exactly 12 seats (boundary, kept),
-- concert 1 has 17 seats (kept), concerts 3, 4, 5 have 11, 10 and 10 seats
-- (removed by HAVING), concert 51 has no tickets (no group at all).
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'V01' AS test_id,
           'View returns 47 concerts (50 concerts with tickets minus 3 below the threshold)' AS purpose,
           '47' AS expected,
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary) AS CHAR) AS actual
    UNION ALL SELECT 'V02',
           'Groups that satisfy HAVING appear: concert 1 (17 seats), 2 and 6 (exactly 12 seats)', '3',
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary
                 WHERE concert_id IN (1, 2, 6)) AS CHAR)
    UNION ALL SELECT 'V03',
           'Groups that fail HAVING do not appear: concerts 3, 4, 5', '0',
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary
                 WHERE concert_id IN (3, 4, 5)) AS CHAR)
    UNION ALL SELECT 'V04',
           'Those excluded concerts do have tickets, with 1 to 11 seats each (so HAVING removed them)', '3',
           CAST((SELECT COUNT(*) FROM concerts
                 WHERE concert_id IN (3, 4, 5)
                   AND fn_reserved_seats(concert_id) BETWEEN 1 AND 11) AS CHAR)
    UNION ALL SELECT 'V05',
           'Concert 51 (no tickets) and fixture concerts 9001-9003 (fewer than 12 seats) are absent', '0',
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary
                 WHERE concert_id IN (51, 9001, 9002, 9003)) AS CHAR)
    UNION ALL SELECT 'V06',
           'Concert 1 row: 8 tickets and 17 seats', '8,17',
           CONCAT_WS(',',
               (SELECT tickets_sold    FROM v_concert_sales_summary WHERE concert_id = 1),
               (SELECT seats_reserved  FROM v_concert_sales_summary WHERE concert_id = 1))
    UNION ALL SELECT 'V07',
           'Revenue for concert 1 equals SUM(ticket_price) over tickets (each ticket counted once)',
           CAST((SELECT SUM(ticket_price) FROM tickets WHERE concert_id = 1) AS CHAR),
           CAST((SELECT total_revenue_eur FROM v_concert_sales_summary WHERE concert_id = 1) AS CHAR)
    UNION ALL SELECT 'V08',
           'A naive tickets JOIN ticket_fans sum would overstate revenue (join fan-out); view value is lower', '1',
           CAST((SELECT IF((SELECT total_revenue_eur FROM v_concert_sales_summary WHERE concert_id = 1) <
                           (SELECT SUM(t.ticket_price)
                            FROM tickets t
                            JOIN ticket_fans tf ON tf.ticket_id = t.ticket_id
                            WHERE t.concert_id = 1), 1, 0)) AS CHAR)
    UNION ALL SELECT 'V09',
           'avg_price_per_seat_eur for concert 1 = ROUND(revenue / seats, 2)',
           CAST((SELECT ROUND(SUM(ticket_price) /
                              (SELECT COUNT(*) FROM ticket_fans WHERE concert_id = 1), 2)
                 FROM tickets WHERE concert_id = 1) AS CHAR),
           CAST((SELECT avg_price_per_seat_eur FROM v_concert_sales_summary WHERE concert_id = 1) AS CHAR)
    UNION ALL SELECT 'V10',
           'Every row of the view has at least 12 seats (count of rows below 12)', '0',
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary WHERE seats_reserved < 12) AS CHAR)
    UNION ALL SELECT 'V11',
           'View row count equals an independent GROUP BY / HAVING count on the base tables',
           CAST((SELECT COUNT(*) FROM (
                    SELECT t.concert_id
                    FROM tickets t
                    JOIN ticket_fans tf ON tf.ticket_id = t.ticket_id
                    GROUP BY t.concert_id
                    HAVING COUNT(*) >= 12) AS x) AS CHAR),
           CAST((SELECT COUNT(*) FROM v_concert_sales_summary) AS CHAR)
) AS r;

-- 1F. Procedure sp_link_song_to_album(song_id, album_id, OUT added, OUT updated)
-- Album 9001 (release 2022-01-01) already holds songs 9003 (track 1) and 9004 (track 2).
-- Album 9002 has NO release date.
-- P01: missing association, song date (2023-05-05) later than album date -> insert AND update.
CALL sp_link_song_to_album(9001, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P01a' AS test_id, 'Missing association: OUT added = 1' AS purpose,
           '1' AS expected, CAST(@added AS CHAR) AS actual
    UNION ALL SELECT 'P01b', 'Song date later than album date: OUT updated = 1',
           '1', CAST(@updated AS CHAR)
    UNION ALL SELECT 'P01c', 'Song release_date now equals the album release_date',
           '2022-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9001) AS CHAR)
    UNION ALL SELECT 'P01d', 'New row takes the next free track number (tracks 1 and 2 were used)',
           '3', CAST((SELECT track_number FROM album_songs
                      WHERE album_id = 9001 AND song_id = 9001) AS CHAR)
) AS r;

-- P02: repeating the same call -> no duplicate, nothing changes.
CALL sp_link_song_to_album(9001, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P02a' AS test_id, 'Repeated call: OUT added = 0' AS purpose,
           '0' AS expected, CAST(@added AS CHAR) AS actual
    UNION ALL SELECT 'P02b', 'Repeated call: date already equal, OUT updated = 0',
           '0', CAST(@updated AS CHAR)
    UNION ALL SELECT 'P02c', 'Still exactly one (album 9001, song 9001) row',
           '1', CAST((SELECT COUNT(*) FROM album_songs
                      WHERE album_id = 9001 AND song_id = 9001) AS CHAR)
    UNION ALL SELECT 'P02d', 'Song date unchanged by the repeated call',
           '2022-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9001) AS CHAR)
) AS r;

-- P03: missing association, song date (2020-01-01) EARLIER than album date -> insert, no update.
CALL sp_link_song_to_album(9002, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P03a' AS test_id, 'Missing association: OUT added = 1' AS purpose,
           '1' AS expected, CAST(@added AS CHAR) AS actual
    UNION ALL SELECT 'P03b', 'Song date earlier than album date: OUT updated = 0',
           '0', CAST(@updated AS CHAR)
    UNION ALL SELECT 'P03c', 'Earlier song date is kept (not overwritten)',
           '2020-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9002) AS CHAR)
    UNION ALL SELECT 'P03d', 'Next free track number is 4',
           '4', CAST((SELECT track_number FROM album_songs
                      WHERE album_id = 9001 AND song_id = 9002) AS CHAR)
) AS r;

-- P04: repeating P03 -> no duplicate, no change.
CALL sp_link_song_to_album(9002, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P04a' AS test_id, 'Repeated call: OUT added = 0 and OUT updated = 0' AS purpose,
           '0,0' AS expected, CONCAT_WS(',', @added, @updated) AS actual
    UNION ALL SELECT 'P04b', 'Still exactly one (album 9001, song 9002) row',
           '1', CAST((SELECT COUNT(*) FROM album_songs
                      WHERE album_id = 9001 AND song_id = 9002) AS CHAR)
) AS r;

-- P05: association ALREADY exists, song date (2024-01-01) later than album -> no insert, update.
CALL sp_link_song_to_album(9003, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P05a' AS test_id, 'Existing association: OUT added = 0' AS purpose,
           '0' AS expected, CAST(@added AS CHAR) AS actual
    UNION ALL SELECT 'P05b', 'Date later than album date: OUT updated = 1',
           '1', CAST(@updated AS CHAR)
    UNION ALL SELECT 'P05c', 'Song release_date now equals the album release_date',
           '2022-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9003) AS CHAR)
    UNION ALL SELECT 'P05d', 'Still one row and the original track number 1 is unchanged',
           '1,1', CONCAT_WS(',',
               (SELECT COUNT(*) FROM album_songs WHERE album_id = 9001 AND song_id = 9003),
               (SELECT track_number FROM album_songs WHERE album_id = 9001 AND song_id = 9003))
) AS r;

-- P06: association exists and the dates are EQUAL -> boundary: no update.
CALL sp_link_song_to_album(9004, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P06a' AS test_id, 'Existing association, equal dates: OUT added = 0 and OUT updated = 0' AS purpose,
           '0,0' AS expected, CONCAT_WS(',', @added, @updated) AS actual
    UNION ALL SELECT 'P06b', 'Equal date unchanged',
           '2022-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9004) AS CHAR)
) AS r;

-- P07: song with NULL release_date (permitted) -> inserted, no update, date stays NULL.
CALL sp_link_song_to_album(9005, 9001, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P07a' AS test_id, 'NULL song date: association inserted, no date update' AS purpose,
           '1,0' AS expected, CONCAT_WS(',', @added, @updated) AS actual
    UNION ALL SELECT 'P07b', 'Song release_date is still NULL',
           CAST(NULL AS CHAR), CAST((SELECT release_date FROM songs WHERE song_id = 9005) AS CHAR)
    UNION ALL SELECT 'P07c', 'Next free track number is 5',
           '5', CAST((SELECT track_number FROM album_songs
                      WHERE album_id = 9001 AND song_id = 9005) AS CHAR)
) AS r;

-- P08: album with NULL release_date (permitted) -> inserted, no update.
CALL sp_link_song_to_album(9006, 9002, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P08a' AS test_id, 'NULL album date: association inserted, no date update' AS purpose,
           '1,0' AS expected, CONCAT_WS(',', @added, @updated) AS actual
    UNION ALL SELECT 'P08b', 'Song date (2024-01-01) is not changed',
           '2024-01-01', CAST((SELECT release_date FROM songs WHERE song_id = 9006) AS CHAR)
    UNION ALL SELECT 'P08c', 'First track on an empty album gets track number 1',
           '1', CAST((SELECT track_number FROM album_songs
                      WHERE album_id = 9002 AND song_id = 9006) AS CHAR)
) AS r;

-- P09: both dates NULL -> inserted, no update.
CALL sp_link_song_to_album(9005, 9002, @added, @updated);
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P09a' AS test_id, 'Both dates NULL: association inserted, no date update' AS purpose,
           '1,0' AS expected, CONCAT_WS(',', @added, @updated) AS actual
    UNION ALL SELECT 'P09b', 'Song release_date is still NULL',
           CAST(NULL AS CHAR), CAST((SELECT release_date FROM songs WHERE song_id = 9005) AS CHAR)
    UNION ALL SELECT 'P09c', 'Second track on album 9002 gets track number 2',
           '2', CAST((SELECT track_number FROM album_songs
                      WHERE album_id = 9002 AND song_id = 9005) AS CHAR)
) AS r;

-- P10: overall state; also shows the same recording on two albums (requirement 4).
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'P10a' AS test_id,
           'Album 9001 has exactly 5 songs (9003, 9004 pre-linked; 9001, 9002, 9005 added)' AS purpose,
           '5' AS expected,
           CAST((SELECT COUNT(*) FROM album_songs WHERE album_id = 9001) AS CHAR) AS actual
    UNION ALL SELECT 'P10b',
           'No duplicate songs and no duplicate track numbers on album 9001', '5,5',
           CONCAT_WS(',',
               (SELECT COUNT(DISTINCT song_id)      FROM album_songs WHERE album_id = 9001),
               (SELECT COUNT(DISTINCT track_number) FROM album_songs WHERE album_id = 9001))
    UNION ALL SELECT 'P10c',
           'Recording 9005 is now on two albums (9001 and 9002)', '2',
           CAST((SELECT COUNT(DISTINCT album_id) FROM album_songs WHERE song_id = 9005) AS CHAR)
) AS r;

-- PART 2: TESTS EXPECTED TO FAIL
-- Have to Run each statement SEPARATELY .
-- Each one MUST raise the error named in the comment above it.
-- Part 1 must have been run first because some tests use its rows.

-- E01 Purpose: duplicate PRIMARY KEY on artists.
-- Expected: ERROR 1062 (23000) Duplicate entry '1' for key 'artists.PRIMARY'.
INSERT INTO artists (artist_id, artist_name) VALUES (1, 'Duplicate PK Artist');

-- E02 Purpose: UNIQUE artist_name.
-- Expected: ERROR 1062 (23000) Duplicate entry 'Aurora Lane' for key 'artists.uq_artists_name'.
INSERT INTO artists (artist_id, artist_name) VALUES (9101, 'Aurora Lane');

-- E03 Purpose: UNIQUE fan_email.
-- Expected: ERROR 1062 (23000) Duplicate entry for key 'fans.uq_fan_email'.
INSERT INTO fans (fan_id, fan_name, fan_email, age)
SELECT 9101, 'Duplicate Email', fan_email, 30
FROM fans
WHERE fan_id = 1;
-- E04 Purpose: CHECK duration_seconds > 0.
-- Expected: ERROR 3819 (HY000) Check constraint 'chk_song_duration' is violated.
INSERT INTO songs (song_id, song_title, duration_seconds, release_date)
VALUES (9101, 'Zero Duration', 0, NULL);

-- E05 Purpose: CHECK ticket_price >= 0 (the BEFORE trigger passes: date is valid).
-- Expected: ERROR 3819 (HY000) Check constraint 'chk_ticket_price' is violated.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9101, 9001, '2027-05-01', -5.00);

-- E06 Purpose: CHECK age <= 120.
-- Expected: ERROR 3819 (HY000) Check constraint 'chk_fan_age' is violated.
INSERT INTO fans (fan_id, fan_name, fan_email, age)
VALUES (9102, 'Too Old', 'too.old@example.com', 121);

-- E07 Purpose: CHECK track_number > 0.
-- Expected: ERROR 3819 (HY000) Check constraint 'chk_track_number' is violated.
INSERT INTO album_songs (album_id, song_id, track_number) VALUES (9003, 9008, 0);

-- E08 Purpose: UNIQUE (album_id, track_number): track 1 of album 9003 is taken by K01.
-- Expected: ERROR 1062 (23000) Duplicate entry '9003-1' for key 'album_songs.uq_album_track'.
INSERT INTO album_songs (album_id, song_id, track_number) VALUES (9003, 9008, 1);

-- E09 Purpose: composite PRIMARY KEY (album_id, song_id): song 9007 is already on album 9003.
-- Expected: ERROR 1062 (23000) Duplicate entry '9003-9007' for key 'album_songs.PRIMARY'.
INSERT INTO album_songs (album_id, song_id, track_number) VALUES (9003, 9007, 2);

-- E10 Purpose: FOREIGN KEY, child row with no parent artist.
-- Expected: ERROR 1452 (23000) Cannot add or update a child row: a foreign key constraint fails.
INSERT INTO album_artists (album_id, artist_id) VALUES (9001, 99999999);

-- E11 Purpose: ON DELETE RESTRICT: artist 1 is referenced by album_artists and others.
-- Expected: ERROR 1451 (23000) Cannot delete or update a parent row: a foreign key constraint fails.
DELETE FROM artists WHERE artist_id = 1;

-- E12 Purpose: ON DELETE RESTRICT: song 9003 is on album 9001.
-- Expected: ERROR 1451 (23000) Cannot delete or update a parent row: a foreign key constraint fails.
DELETE FROM songs WHERE song_id = 9003;

-- E13 Purpose: a seat can be reserved once per concert. Ticket 9002 is for concert 9001,
--              and seat A-01 of concert 9001 is held by ticket 9001. No audit row may be written.
-- Expected: ERROR 1062 (23000) Duplicate entry '9001-A-01' for key 'ticket_fans.uq_concert_seat'.
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
VALUES (9002, 9001, 9003, 'A', '01');

-- E14 Purpose: a fan holds at most one seat per concert. Fan 9001 already has a seat at concert 9001.
-- Expected: ERROR 1062 (23000) Duplicate entry '9001-9001' for key 'ticket_fans.uq_concert_fan'.
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
VALUES (9002, 9001, 9001, 'B', '05');

-- E15 Purpose: composite FOREIGN KEY (ticket_id, concert_id): ticket 9001 belongs to concert 9001,
--              not 9002, so a reservation claiming concert 9002 must be rejected.
-- Expected: ERROR 1452 (23000) Cannot add or update a child row: a foreign key constraint fails.
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
VALUES (9001, 9002, 9004, 'D', '01');

-- E16 Purpose: ticket for a concert that does not exist (BEFORE trigger lets it through,
--              the foreign key rejects it).
-- Expected: ERROR 1452 (23000) Cannot add or update a child row: a foreign key constraint fails.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9102, 99999999, '2027-05-01', 10.00);

-- E17 Purpose: BEFORE INSERT trigger rejects a purchase date after the concert date
--              (concert 9001 is on 2027-06-01).
-- Expected: ERROR 1644 (45000) Ticket purchase_date is after the concert date.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
VALUES (9103, 9001, '2027-06-02', 50.00);

-- E18 Purpose: procedure with a nonexistent song_id.
-- Expected: ERROR 1644 (45000) Song does not exist.
CALL sp_link_song_to_album(99999999, 9001, @added, @updated);

-- E19 Purpose: procedure with a nonexistent album_id.
-- Expected: ERROR 1644 (45000) Album does not exist.
CALL sp_link_song_to_album(9001, 99999999, @added, @updated);

-- E20 Purpose: procedure with a NULL song_id.
-- Expected: ERROR 1644 (45000) Song does not exist.
CALL sp_link_song_to_album(NULL, 9001, @added, @updated);

-- E21 Purpose: procedure with a NULL album_id.
-- Expected: ERROR 1644 (45000) Album does not exist.
CALL sp_link_song_to_album(9001, NULL, @added, @updated);

-- PART 2V: VERIFY THAT THE FAILED STATEMENTS CHANGED NOTHING
-- Should be Run after PART 2 (Alt+X). 
SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'E01v' AS test_id,
           'E01: no duplicate-PK artist inserted and artist 1 is unchanged (count of problems)' AS purpose,
           '0' AS expected,
           CAST((SELECT COUNT(*) FROM artists WHERE artist_name = 'Duplicate PK Artist')
              + (SELECT COUNT(*) FROM artists WHERE artist_id = 1 AND artist_name <> 'Aurora Lane') AS CHAR) AS actual
    UNION ALL SELECT 'E02v', 'E02: artist 9101 was not inserted', '0',
           CAST((SELECT COUNT(*) FROM artists WHERE artist_id = 9101) AS CHAR)
    UNION ALL SELECT 'E03v', 'E03: fan 9101 was not inserted', '0',
           CAST((SELECT COUNT(*) FROM fans WHERE fan_id = 9101) AS CHAR)
    UNION ALL SELECT 'E04v', 'E04: song 9101 was not inserted', '0',
           CAST((SELECT COUNT(*) FROM songs WHERE song_id = 9101) AS CHAR)
    UNION ALL SELECT 'E05v', 'E05: ticket 9101 was not inserted', '0',
           CAST((SELECT COUNT(*) FROM tickets WHERE ticket_id = 9101) AS CHAR)
    UNION ALL SELECT 'E06v', 'E06: fan 9102 was not inserted', '0',
           CAST((SELECT COUNT(*) FROM fans WHERE fan_id = 9102) AS CHAR)
    UNION ALL SELECT 'E07-09v',
           'E07-E09: album 9003 still has only the valid K01 row (song 9007, track 1)', '1,9007,1',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM album_songs WHERE album_id = 9003),
               (SELECT MIN(song_id) FROM album_songs WHERE album_id = 9003),
               (SELECT MIN(track_number) FROM album_songs WHERE album_id = 9003))
    UNION ALL SELECT 'E10v', 'E10: no album_artists row for artist 99999999', '0',
           CAST((SELECT COUNT(*) FROM album_artists WHERE artist_id = 99999999) AS CHAR)
    UNION ALL SELECT 'E11v', 'E11: artist 1 still exists (RESTRICT blocked the delete)', '1',
           CAST((SELECT COUNT(*) FROM artists WHERE artist_id = 1) AS CHAR)
    UNION ALL SELECT 'E12v', 'E12: song 9003 still exists (RESTRICT blocked the delete)', '1',
           CAST((SELECT COUNT(*) FROM songs WHERE song_id = 9003) AS CHAR)
    UNION ALL SELECT 'E13-14v',
           'E13-E14: ticket 9002 has no seats; concert 9001 still has only the 2 seats of ticket 9001', '0,2',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9002),
               (SELECT COUNT(*) FROM ticket_fans WHERE concert_id = 9001))
    UNION ALL SELECT 'G08',
           'AFTER trigger: rejected reservations E13/E14 left no audit row (ticket 9002: 0, ticket 9001: 2)', '0,2',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM reservation_audit WHERE ticket_id = 9002),
               (SELECT COUNT(*) FROM reservation_audit WHERE ticket_id = 9001))
    UNION ALL SELECT 'E15v', 'E15: fan 9004 has no seat on ticket 9001', '0',
           CAST((SELECT COUNT(*) FROM ticket_fans WHERE ticket_id = 9001 AND fan_id = 9004) AS CHAR)
    UNION ALL SELECT 'E16v', 'E16: no ticket exists for concert 99999999', '0',
           CAST((SELECT COUNT(*) FROM tickets WHERE concert_id = 99999999) AS CHAR)
    UNION ALL SELECT 'E17v', 'E17: ticket 9103 (late purchase) was rejected by the BEFORE trigger', '0',
           CAST((SELECT COUNT(*) FROM tickets WHERE ticket_id = 9103) AS CHAR)
    UNION ALL SELECT 'E18-21v',
           'E18-E21: album 9001 still has exactly 5 songs and song 9001 is on one album only', '5,1',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM album_songs WHERE album_id = 9001),
               (SELECT COUNT(*) FROM album_songs WHERE song_id = 9001))
) AS r;

-- PART 3: CLEANUP AND FINAL CHECK
-- Removes all test rows and proves the seed data is back to its baseline.
DELETE FROM reservation_audit      WHERE ticket_id  >= 9000;
DELETE FROM ticket_fans            WHERE ticket_id  >= 9000;
DELETE FROM tickets                WHERE ticket_id  >= 9000;
DELETE FROM fan_favourite_artists  WHERE fan_id     >= 9000;
DELETE FROM fans                   WHERE fan_id     >= 9000;
DELETE FROM concert_artists        WHERE concert_id >= 9000;
DELETE FROM concert_songs          WHERE concert_id >= 9000;
DELETE FROM concerts               WHERE concert_id >= 9000;
DELETE FROM album_songs            WHERE album_id   >= 9000;
DELETE FROM album_songs            WHERE song_id    >= 9000;
DELETE FROM song_artists           WHERE song_id    >= 9000;
DELETE FROM songs                  WHERE song_id    >= 9000;
DELETE FROM album_artists          WHERE album_id   >= 9000;
DELETE FROM albums                 WHERE album_id   >= 9000;
DELETE FROM artists                WHERE artist_id  >= 9000;

SELECT test_id, purpose, expected, actual,
       IF(actual <=> expected, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'X01' AS test_id,
           'Cleanup: no test rows (ID 9000 or above) remain in any table' AS purpose,
           '0' AS expected,
           CAST((SELECT COUNT(*) FROM artists     WHERE artist_id  >= 9000)
              + (SELECT COUNT(*) FROM albums      WHERE album_id   >= 9000)
              + (SELECT COUNT(*) FROM songs       WHERE song_id    >= 9000)
              + (SELECT COUNT(*) FROM album_artists WHERE album_id >= 9000)
              + (SELECT COUNT(*) FROM album_songs WHERE album_id   >= 9000 OR song_id >= 9000)
              + (SELECT COUNT(*) FROM concerts    WHERE concert_id >= 9000)
              + (SELECT COUNT(*) FROM fans        WHERE fan_id     >= 9000)
              + (SELECT COUNT(*) FROM tickets     WHERE ticket_id  >= 9000)
              + (SELECT COUNT(*) FROM ticket_fans WHERE ticket_id  >= 9000)
              + (SELECT COUNT(*) FROM reservation_audit WHERE ticket_id >= 9000) AS CHAR) AS actual
    UNION ALL SELECT 'X02', 'Row counts back to baseline: artists, albums, songs, album_artists, song_artists', '40,60,360,120,720',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM artists),
               (SELECT COUNT(*) FROM albums),
               (SELECT COUNT(*) FROM songs),
               (SELECT COUNT(*) FROM album_artists),
               (SELECT COUNT(*) FROM song_artists))
    UNION ALL SELECT 'X03', 'Row counts back to baseline: album_songs, concerts, concert_artists, concert_songs', '362,51,102,300',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM album_songs),
               (SELECT COUNT(*) FROM concerts),
               (SELECT COUNT(*) FROM concert_artists),
               (SELECT COUNT(*) FROM concert_songs))
    UNION ALL SELECT 'X04', 'Row counts back to baseline: fans, fan_favourite_artists, tickets, ticket_fans, reservation_audit', '650,1300,300,600,0',
           CONCAT_WS(',',
               (SELECT COUNT(*) FROM fans),
               (SELECT COUNT(*) FROM fan_favourite_artists),
               (SELECT COUNT(*) FROM tickets),
               (SELECT COUNT(*) FROM ticket_fans),
               (SELECT COUNT(*) FROM reservation_audit))
) AS r;


