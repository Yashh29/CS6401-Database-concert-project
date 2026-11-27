USE cs6401_concerts;

-- TASK 3: VIEW v_concert_sales_summary

DROP VIEW IF EXISTS v_concert_sales_summary;

CREATE VIEW v_concert_sales_summary AS
SELECT
    c.concert_id,
    c.concert_title,
    c.location,
    c.date_of_concert,
    COUNT(ts.ticket_id) AS tickets_sold,
    SUM(ts.seats) AS seats_reserved,
    SUM(ts.ticket_price) AS total_revenue_eur,
    ROUND(
        SUM(ts.ticket_price) / NULLIF(SUM(ts.seats), 0), 2
    ) AS avg_price_per_seat_eur,
    MIN(ts.purchase_date) AS first_purchase_date,
    MAX(ts.purchase_date) AS last_purchase_date
FROM concerts AS c
JOIN (
    SELECT
        t.ticket_id,
        t.concert_id,
        t.purchase_date,
        t.ticket_price,
        COUNT(tf.fan_id) AS seats
    FROM tickets AS t
    LEFT JOIN ticket_fans AS tf
        ON tf.ticket_id = t.ticket_id
    GROUP BY
        t.ticket_id,
        t.concert_id,
        t.purchase_date,
        t.ticket_price
) AS ts
    ON ts.concert_id = c.concert_id
GROUP BY
    c.concert_id,
    c.concert_title,
    c.location,
    c.date_of_concert
HAVING SUM(ts.seats) >= 12;


-- TASK 4a: BEFORE INSERT trigger on tickets
-- Prevents ticket purchase after the concert date.

DROP TRIGGER IF EXISTS trg_tickets_before_insert;

DELIMITER $$

CREATE TRIGGER trg_tickets_before_insert
BEFORE INSERT ON tickets
FOR EACH ROW
BEGIN
    DECLARE v_concert_date DATE;

    SELECT date_of_concert
    INTO v_concert_date
    FROM concerts
    WHERE concert_id = NEW.concert_id;

    IF v_concert_date IS NOT NULL
       AND NEW.purchase_date > v_concert_date THEN

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Ticket purchase_date is after the concert date';
    END IF;
END$$

DELIMITER ;


-- TASK 4a (additional): BEFORE INSERT trigger on ticket_fans
-- Prevents the same fan reserving twice for one concert.

DROP TRIGGER IF EXISTS trg_ticket_fans_before_insert;

DELIMITER $$

CREATE TRIGGER trg_ticket_fans_before_insert
BEFORE INSERT ON ticket_fans
FOR EACH ROW
BEGIN
    DECLARE v_concert_id BIGINT UNSIGNED;
    DECLARE v_existing INT DEFAULT 0;

    SELECT concert_id
    INTO v_concert_id
    FROM tickets
    WHERE ticket_id = NEW.ticket_id;

    SELECT COUNT(*)
    INTO v_existing
    FROM ticket_fans AS tf
    JOIN tickets AS t
        ON t.ticket_id = tf.ticket_id
    WHERE t.concert_id = v_concert_id
      AND tf.fan_id = NEW.fan_id;

    IF v_existing > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Fan already has a reservation for this concert';
    END IF;
END$$

DELIMITER ;


-- TASK 4b: AFTER INSERT trigger on ticket_fans
-- Records each successful reservation in the audit table.

DROP TRIGGER IF EXISTS trg_ticket_fans_after_insert;

DELIMITER $$

CREATE TRIGGER trg_ticket_fans_after_insert
AFTER INSERT ON ticket_fans
FOR EACH ROW
BEGIN
    INSERT INTO reservation_audit
        (ticket_id, fan_id, action_type)
    VALUES
        (NEW.ticket_id, NEW.fan_id, 'RESERVATION_CREATED');
END$$

DELIMITER ;


-- TASK 5: FUNCTION fn_reserved_seats
-- Returns the number of reserved seats for a concert.
-- Returns 0 for an existing concert with no reservations.
-- Signals an error for a nonexistent concert.

DROP FUNCTION IF EXISTS fn_reserved_seats;

DELIMITER $$

CREATE FUNCTION fn_reserved_seats(
    p_concert_id BIGINT UNSIGNED
)
RETURNS BIGINT UNSIGNED
READS SQL DATA
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_seats BIGINT UNSIGNED DEFAULT 0;

    SELECT COUNT(*)
    INTO v_exists
    FROM concerts
    WHERE concert_id = p_concert_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Concert does not exist';
    END IF;

    SELECT COUNT(*)
    INTO v_seats
    FROM tickets AS t
    JOIN ticket_fans AS tf
        ON tf.ticket_id = t.ticket_id
    WHERE t.concert_id = p_concert_id;

    RETURN v_seats;
END$$

DELIMITER ;


-- TASK 6: PROCEDURE sp_link_song_to_album
-- Inserts a missing song-album association.
-- Updates the song release date if it is later than the
-- album release date, provided both dates are NOT NULL.

DROP PROCEDURE IF EXISTS sp_link_song_to_album;

DELIMITER $$

CREATE PROCEDURE sp_link_song_to_album(
    IN p_song_id BIGINT UNSIGNED,
    IN p_album_id BIGINT UNSIGNED,
    OUT p_association_added TINYINT,
    OUT p_date_updated TINYINT
)
BEGIN
    DECLARE v_song_exists INT DEFAULT 0;
    DECLARE v_album_exists INT DEFAULT 0;
    DECLARE v_linked INT DEFAULT 0;
    DECLARE v_song_date DATE;
    DECLARE v_album_date DATE;
    DECLARE v_next_track INT DEFAULT 1;

    SET p_association_added = 0;
    SET p_date_updated = 0;

    -- Check that the song exists.
    SELECT COUNT(*)
    INTO v_song_exists
    FROM songs
    WHERE song_id = p_song_id;

    IF v_song_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Song does not exist';
    END IF;

    -- Check that the album exists.
    SELECT COUNT(*)
    INTO v_album_exists
    FROM albums
    WHERE album_id = p_album_id;

    IF v_album_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Album does not exist';
    END IF;

    -- Retrieve the release dates.
    SELECT release_date
    INTO v_album_date
    FROM albums
    WHERE album_id = p_album_id;

    SELECT release_date
    INTO v_song_date
    FROM songs
    WHERE song_id = p_song_id;

    -- Check whether the association already exists.
    SELECT COUNT(*)
    INTO v_linked
    FROM album_songs
    WHERE album_id = p_album_id
      AND song_id = p_song_id;

    -- Insert the association only if it is missing.
    IF v_linked = 0 THEN

        SELECT COALESCE(MAX(track_number), 0) + 1
        INTO v_next_track
        FROM album_songs
        WHERE album_id = p_album_id;

        INSERT INTO album_songs
            (album_id, song_id, track_number)
        VALUES
            (p_album_id, p_song_id, v_next_track);

        SET p_association_added = 1;
    END IF;

    -- Update the song date only when both dates exist
    -- and the song date is later than the album date.
    IF v_song_date IS NOT NULL
       AND v_album_date IS NOT NULL
       AND v_song_date > v_album_date THEN

        UPDATE songs
        SET release_date = v_album_date
        WHERE song_id = p_song_id;

        SET p_date_updated = 1;
    END IF;

END$$

DELIMITER ;



