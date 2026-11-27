CREATE DATABASE IF NOT EXISTS cs6401_concerts;
USE cs6401_concerts;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS reservation_audit;
DROP TABLE IF EXISTS ticket_fans;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS fan_favourite_artists;
DROP TABLE IF EXISTS concert_songs;
DROP TABLE IF EXISTS concert_artists;
DROP TABLE IF EXISTS album_songs;
DROP TABLE IF EXISTS song_artists;
DROP TABLE IF EXISTS album_artists;
DROP TABLE IF EXISTS fans;
DROP TABLE IF EXISTS concerts;
DROP TABLE IF EXISTS songs;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS artists;

SET FOREIGN_KEY_CHECKS = 1;

-- Artists (solo artists and bands)
CREATE TABLE artists (
    artist_id   BIGINT UNSIGNED AUTO_INCREMENT,
    artist_name VARCHAR(128) NOT NULL,
    genre       VARCHAR(64),
    debut_year  YEAR,

    CONSTRAINT pk_artists PRIMARY KEY (artist_id),
    CONSTRAINT uq_artists_name UNIQUE (artist_name)
) ENGINE = InnoDB;

-- Albums (artists are in album_artists)
CREATE TABLE albums (
    album_id     BIGINT UNSIGNED AUTO_INCREMENT,
    album_title  VARCHAR(256) NOT NULL,
    release_date DATE,

    CONSTRAINT pk_albums PRIMARY KEY (album_id)
) ENGINE = InnoDB;

-- Song recordings. duration_seconds is in whole SECONDS.
CREATE TABLE songs (
    song_id          BIGINT UNSIGNED AUTO_INCREMENT,
    song_title       VARCHAR(128) NOT NULL,
    duration_seconds INT UNSIGNED NOT NULL,
    release_date     DATE,

    CONSTRAINT pk_songs PRIMARY KEY (song_id),
    CONSTRAINT chk_song_duration CHECK (duration_seconds > 0)
) ENGINE = InnoDB;

-- Artists on albums (many-to-many)
CREATE TABLE album_artists (
    album_id  BIGINT UNSIGNED NOT NULL,
    artist_id BIGINT UNSIGNED NOT NULL,

    CONSTRAINT pk_album_artists PRIMARY KEY (album_id, artist_id),
    CONSTRAINT fk_album_artists_album
        FOREIGN KEY (album_id) REFERENCES albums(album_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_album_artists_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Artists on recordings (many-to-many)
CREATE TABLE song_artists (
    song_id   BIGINT UNSIGNED NOT NULL,
    artist_id BIGINT UNSIGNED NOT NULL,

    CONSTRAINT pk_song_artists PRIMARY KEY (song_id, artist_id),
    CONSTRAINT fk_song_artists_song
        FOREIGN KEY (song_id) REFERENCES songs(song_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_song_artists_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Recordings on albums (many-to-many: same recording on several albums)
CREATE TABLE album_songs (
    album_id     BIGINT UNSIGNED NOT NULL,
    song_id      BIGINT UNSIGNED NOT NULL,
    track_number SMALLINT UNSIGNED NOT NULL,

    CONSTRAINT pk_album_songs PRIMARY KEY (album_id, song_id),
    CONSTRAINT uq_album_track UNIQUE (album_id, track_number),
    CONSTRAINT chk_track_number CHECK (track_number > 0),
    CONSTRAINT fk_album_songs_album
        FOREIGN KEY (album_id) REFERENCES albums(album_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_album_songs_song
        FOREIGN KEY (song_id) REFERENCES songs(song_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_album_songs_song (song_id)
) ENGINE = InnoDB;

-- Concerts
CREATE TABLE concerts (
    concert_id      BIGINT UNSIGNED AUTO_INCREMENT,
    concert_title   VARCHAR(256) NOT NULL,
    location        VARCHAR(256) NOT NULL,
    date_of_concert DATE NOT NULL,

    CONSTRAINT pk_concerts PRIMARY KEY (concert_id),
    INDEX idx_concert_date (date_of_concert)
) ENGINE = InnoDB;

-- Artists performing at concerts (many-to-many)
CREATE TABLE concert_artists (
    concert_id BIGINT UNSIGNED NOT NULL,
    artist_id  BIGINT UNSIGNED NOT NULL,

    CONSTRAINT pk_concert_artists PRIMARY KEY (concert_id, artist_id),
    CONSTRAINT fk_concert_artists_concert
        FOREIGN KEY (concert_id) REFERENCES concerts(concert_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_concert_artists_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Songs performed at concerts
CREATE TABLE concert_songs (
    concert_id        BIGINT UNSIGNED NOT NULL,
    song_id           BIGINT UNSIGNED NOT NULL,
    performance_order SMALLINT UNSIGNED NOT NULL,

    CONSTRAINT pk_concert_songs PRIMARY KEY (concert_id, song_id),
    CONSTRAINT uq_concert_performance_order UNIQUE (concert_id, performance_order),
    CONSTRAINT chk_performance_order CHECK (performance_order > 0),
    CONSTRAINT fk_concert_songs_concert
        FOREIGN KEY (concert_id) REFERENCES concerts(concert_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_concert_songs_song
        FOREIGN KEY (song_id) REFERENCES songs(song_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_concert_songs_song (song_id)
) ENGINE = InnoDB;

-- Fans (stored once, regardless of how many tickets they hold)
CREATE TABLE fans (
    fan_id    BIGINT UNSIGNED AUTO_INCREMENT,
    fan_name  VARCHAR(128) NOT NULL,
    fan_email VARCHAR(254) NOT NULL,
    age       TINYINT UNSIGNED,

    CONSTRAINT pk_fans PRIMARY KEY (fan_id),
    CONSTRAINT uq_fan_email UNIQUE (fan_email),
    CONSTRAINT chk_fan_age CHECK (age IS NULL OR age <= 120)
) ENGINE = InnoDB;

--  Multiple favourite artists per fan
CREATE TABLE fan_favourite_artists (
    fan_id    BIGINT UNSIGNED NOT NULL,
    artist_id BIGINT UNSIGNED NOT NULL,

    CONSTRAINT pk_fan_favourite_artists PRIMARY KEY (fan_id, artist_id),
    CONSTRAINT fk_favourites_fan
        FOREIGN KEY (fan_id) REFERENCES fans(fan_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_favourites_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tickets. Each ticket is for exactly one concert.

CREATE TABLE tickets (
    ticket_id     BIGINT UNSIGNED AUTO_INCREMENT,
    concert_id    BIGINT UNSIGNED NOT NULL,
    purchase_date DATE NOT NULL,
    ticket_price  DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_tickets PRIMARY KEY (ticket_id),
    CONSTRAINT uq_ticket_concert UNIQUE (ticket_id, concert_id),
    CONSTRAINT chk_ticket_price CHECK (ticket_price >= 0),
    INDEX idx_tickets_concert (concert_id),

    CONSTRAINT fk_tickets_concert
        FOREIGN KEY (concert_id) REFERENCES concerts(concert_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

--  Reserved seats: one row = one fan = one seat under a ticket.

CREATE TABLE ticket_fans (
    ticket_id   BIGINT UNSIGNED NOT NULL,
    concert_id  BIGINT UNSIGNED NOT NULL,
    fan_id      BIGINT UNSIGNED NOT NULL,
    seat_zone   VARCHAR(16) NOT NULL,
    seat_number VARCHAR(16) NOT NULL,

    CONSTRAINT pk_ticket_fans PRIMARY KEY (ticket_id, fan_id),
    CONSTRAINT uq_concert_seat UNIQUE (concert_id, seat_zone, seat_number),
    CONSTRAINT uq_concert_fan  UNIQUE (concert_id, fan_id),
    INDEX idx_ticket_fans_fan (fan_id),

    CONSTRAINT fk_ticket_fans_ticket
        FOREIGN KEY (ticket_id, concert_id)
        REFERENCES tickets(ticket_id, concert_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_ticket_fans_fan
        FOREIGN KEY (fan_id) REFERENCES fans(fan_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

--  Audit log for reservation events (filled by the AFTER trigger in
-- code.sql).
CREATE TABLE reservation_audit (
    audit_id    BIGINT UNSIGNED AUTO_INCREMENT,
    ticket_id   BIGINT UNSIGNED NOT NULL,
    fan_id      BIGINT UNSIGNED NOT NULL,
    action_type VARCHAR(32) NOT NULL,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_reservation_audit PRIMARY KEY (audit_id),
    INDEX idx_reservation_audit_ticket (ticket_id),
    INDEX idx_reservation_audit_fan (fan_id)
) ENGINE = InnoDB;




