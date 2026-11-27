USE cs6401_concerts;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reservation_audit;
TRUNCATE TABLE ticket_fans;
TRUNCATE TABLE tickets;
TRUNCATE TABLE fan_favourite_artists;
TRUNCATE TABLE concert_songs;
TRUNCATE TABLE concert_artists;
TRUNCATE TABLE album_songs;
TRUNCATE TABLE song_artists;
TRUNCATE TABLE album_artists;
TRUNCATE TABLE fans;
TRUNCATE TABLE concerts;
TRUNCATE TABLE songs;
TRUNCATE TABLE albums;
TRUNCATE TABLE artists;
SET FOREIGN_KEY_CHECKS = 1;
--  Artists: 40 (4 named + 36 generated)
INSERT INTO artists (artist_id, artist_name, genre, debut_year) VALUES
    (1, 'Aurora Lane',        'Indie Pop',        2015),
    (2, 'The Northern Lights','Alternative Rock', 2012),
    (3, 'Maya Rivers',        'Pop',              2018),
    (4, 'Echo Harbour',       'Electronic',       2016);

INSERT INTO artists (artist_id, artist_name, genre, debut_year)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 36
)
SELECT n + 4,
       CONCAT('Artist ', LPAD(n + 4, 4, '0')),
       ELT(MOD(n, 8) + 1, 'Pop', 'Rock', 'Indie', 'Electronic',
           'Jazz', 'Folk', 'Alternative', 'R&B'),
       1980 + MOD(n * 7, 45)
FROM seq;

--  Albums: 60 (4 named + 56 generated). Album 4 has no release date.
INSERT INTO albums (album_id, album_title, release_date) VALUES
    (1, 'Midnight Skies',      '2022-05-10'),
    (2, 'Live at the Harbour', '2023-08-20'),
    (3, 'Acoustic Sessions',   '2024-02-15'),
    (4, 'Unreleased Demos',    NULL);

INSERT INTO albums (album_id, album_title, release_date)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 56
)
SELECT n + 4,
       CONCAT('Album Collection ', LPAD(n + 4, 4, '0')),
       DATE_ADD('2010-01-01', INTERVAL MOD(n * 37, 5500) DAY)
FROM seq;

-- Songs (recordings): 360 (7 named + 353 generated).
-- Songs 1 and 4 are two different recordings of 'Open Roads'.
-- Song 7 has no release date.
INSERT INTO songs (song_id, song_title, duration_seconds, release_date) VALUES
    (1, 'Open Roads',    215, '2021-11-12'),
    (2, 'City Lights',   198, '2022-01-20'),
    (3, 'Northern Wind', 242, '2022-04-01'),
    (4, 'Open Roads',    220, '2022-03-15'),
    (5, 'Quiet Harbour', 205, '2022-04-05'),
    (6, 'Falling Stars', 230, '2022-05-01'),
    (7, 'Hidden Track',  187, NULL);

-- Generated recordings: release date is 1-30 days BEFORE the date of the
-- album they are placed on (item 6 puts song s on album (s-1) DIV 6 + 1),
-- or 2015-01-01 when that album has no date.
INSERT INTO songs (song_id, song_title, duration_seconds, release_date)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 353
)
SELECT n + 7,
       CONCAT('Song Recording ', LPAD(n + 7, 5, '0')),
       150 + MOD(n * 17, 240),
       COALESCE(DATE_SUB(a.release_date, INTERVAL MOD(n, 30) + 1 DAY),
                '2015-01-01')
FROM seq
JOIN albums a ON a.album_id = (n + 6) DIV 6 + 1;

-- Album artists: two different artists per album (120 rows).
INSERT INTO album_artists (album_id, artist_id)
SELECT album_id, MOD(album_id - 1, 40) + 1 FROM albums;

INSERT INTO album_artists (album_id, artist_id)
SELECT album_id, MOD(album_id + 16, 40) + 1 FROM albums;

--  Song artists: two different artists per recording (720 rows).
INSERT INTO song_artists (song_id, artist_id)
SELECT song_id, MOD(song_id - 1, 40) + 1 FROM songs;

INSERT INTO song_artists (song_id, artist_id)
SELECT song_id, MOD(song_id + 22, 40) + 1 FROM songs;

--  Album tracks: six recordings per album, track numbers 1..6 (360 rows).
INSERT INTO album_songs (album_id, song_id, track_number)
SELECT (song_id - 1) DIV 6 + 1, song_id, MOD(song_id - 1, 6) + 1
FROM songs;

-- The SAME recording on several albums (requirement 4).
INSERT INTO album_songs (album_id, song_id, track_number) VALUES
    (2, 1, 7),    -- 'Open Roads' (song 1) also on album 2
    (3, 5, 7);    -- 'Quiet Harbour' (song 5) also on album 3

--  Concerts: 51 (3 named + 47 generated + concert 51 with no tickets).
INSERT INTO concerts (concert_id, concert_title, location, date_of_concert) VALUES
    (1, 'Autumn Sound Festival', 'Limerick', '2026-11-15'),
    (2, 'Harbour Nights',        'Galway',   '2026-12-05'),
    (3, 'Acoustic Evening',      'Dublin',   '2027-01-20');

INSERT INTO concerts (concert_id, concert_title, location, date_of_concert)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 47
)
SELECT n + 3,
       CONCAT('Concert Event ', LPAD(n + 3, 4, '0')),
       ELT(MOD(n, 8) + 1, 'Limerick', 'Galway', 'Dublin', 'Cork',
           'Waterford', 'Kilkenny', 'Athlone', 'Sligo'),
       DATE_ADD('2026-01-01', INTERVAL MOD(n * 13, 900) DAY)
FROM seq;

INSERT INTO concerts (concert_id, concert_title, location, date_of_concert) VALUES
    (51, 'Winter Gala (no tickets sold)', 'Limerick', '2027-12-31');

--  Concert artists: two per concert for 1..50, a third for concert 1,
-- one for concert 51 (102 rows).
INSERT INTO concert_artists (concert_id, artist_id)
SELECT concert_id, MOD(concert_id - 1, 40) + 1
FROM concerts WHERE concert_id <= 50;

INSERT INTO concert_artists (concert_id, artist_id)
SELECT concert_id, MOD(concert_id + 17, 40) + 1
FROM concerts WHERE concert_id <= 50;

INSERT INTO concert_artists (concert_id, artist_id) VALUES
    (1, 3),       -- concert 1 has three artists (1, 19, 3)
    (51, 2);

--  Songs performed: six per concert for concerts 1..50 (300 rows).
INSERT INTO concert_songs (concert_id, song_id, performance_order)
SELECT MOD(song_id - 1, 50) + 1, song_id, (song_id - 1) DIV 50 + 1
FROM songs
WHERE song_id <= 300;

--  Fans: 650 (5 named + 645 generated).
INSERT INTO fans (fan_id, fan_name, fan_email, age) VALUES
    (1, 'Yash Modi',  'yash.modi@gmail.com',  24),
    (2, 'Sumit singh',  'sumit.singh@gmail.com',  27),
    (3, 'Taylor sharma', 'taylor.sharma@gmail.com', 22),
    (4, 'Morgan Chen',  'morgan.chen@gmail.com',  29),
    (5, 'Casey Walsh',  'casey.walsh@gmail.com',  25);

INSERT INTO fans (fan_id, fan_name, fan_email, age)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 645
)
SELECT n + 5,
       CONCAT('Fan ', LPAD(n + 5, 5, '0')),
       CONCAT('fan', LPAD(n + 5, 5, '0'), '@example.com'),
       CASE WHEN MOD(n, 17) = 0 THEN NULL ELSE 18 + MOD(n * 11, 63) END
FROM seq;

--  Two different favourite artists per fan (1,300 rows).
INSERT INTO fan_favourite_artists (fan_id, artist_id)
SELECT fan_id, MOD(fan_id - 1, 40) + 1 FROM fans;

INSERT INTO fan_favourite_artists (fan_id, artist_id)
SELECT fan_id, MOD(fan_id + 11, 40) + 1 FROM fans;

--  Tickets: 300 (4 named + 296 generated), concerts 1..50 only.
-- Generated purchase_date is 1-90 days BEFORE the concert date.
INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price) VALUES
    (1, 1, '2026-09-10', 90.00),
    (2, 1, '2026-09-12', 60.00),
    (3, 2, '2026-09-15', 75.00),
    (4, 3, '2026-09-20', 45.00);

INSERT INTO tickets (ticket_id, concert_id, purchase_date, ticket_price)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 296
)
SELECT n + 4,
       c.concert_id,
       DATE_SUB(c.date_of_concert, INTERVAL MOD(n * 3, 90) + 1 DAY),
       25.00 + MOD(n * 19, 176) + MOD(n, 2) * 0.50
FROM seq
JOIN concerts c ON c.concert_id = MOD(n + 4, 50) + 1;

--  Reserved seats (one row = one fan = one seat).
-- Seed tickets:
--   ticket 1 (concert 1): fans 1,2,3  -> THREE seats
--   ticket 2 (concert 1): fans 4,5
--   ticket 3 (concert 2): fans 1,2    (fans 1 and 2 attend two concerts)
--   ticket 4 (concert 3): fan 3       (fan 3 attends two concerts)
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number) VALUES
    (1, 1, 1, 'A',   '01'),
    (1, 1, 2, 'A',   '02'),
    (1, 1, 3, 'A',   '03'),
    (2, 1, 4, 'B',   '01'),
    (2, 1, 5, 'B',   '02'),
    (3, 2, 1, 'A',   '10'),
    (3, 2, 2, 'A',   '11'),
    (4, 3, 3, 'VIP', '01');

-- Generated tickets (ids 5..300) get two fans each: fans 2t and 2t+1.
-- Fan ids are unique across generated tickets, and the seat number is the
-- ticket id, so no fan or seat repeats within a concert.
INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
SELECT ticket_id,
       concert_id,
       2 * ticket_id,
       ELT(MOD(ticket_id, 2) + 1, 'A', 'C'),
       LPAD(ticket_id, 3, '0')
FROM tickets
WHERE ticket_id > 4;

INSERT INTO ticket_fans (ticket_id, concert_id, fan_id, seat_zone, seat_number)
SELECT ticket_id,
       concert_id,
       2 * ticket_id + 1,
       ELT(MOD(ticket_id, 2) + 1, 'B', 'VIP'),
       LPAD(ticket_id, 3, '0')
FROM tickets
WHERE ticket_id > 4;

-- reservation_audit is intentionally empty here; the AFTER trigger in
-- code.sql fills it when reservations are inserted later (e.g. in tests.sql).
