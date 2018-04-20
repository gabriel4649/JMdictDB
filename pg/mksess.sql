-------------------------------------------------------------------------
--  This file is part of JMdictDB. 
--
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published 
--  by the Free Software Foundation; either version 2 of the License, 
--  or (at your option) any later version.
--
--  JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with JMdictDB; if not, write to the Free Software Foundation,
--  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
--
--  Copyright (c) 2008 Stuart McGraw 
---------------------------------------------------------------------------

-- Schema for JMdictDB users/sessions database.

-- Note: the gen_random_bytes() function used below is in the pgcrypto
-- extention which must be installed (one time only) before this script 
-- is executed.  It can be installed by a database superuser (e.g. user
-- "postgres") with the sql command:
--   CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- We don't install it here because this script may be run by a user
-- with insuffcient privilege.

\set ON_ERROR_STOP
\set updateid '''7375f3'''

-- Database update table (see comments in mktables.sql).
CREATE TABLE db (
    id INT PRIMARY KEY,
    active BOOLEAN DEFAULT TRUE,
    ts TIMESTAMP DEFAULT NOW());
INSERT INTO db(id) VALUES(x:updateid::INT);
CREATE OR REPLACE VIEW dbx AS (
    SELECT LPAD(TO_HEX(id),6,'0') AS id, active, ts
    FROM db
    ORDER BY ts DESC);

-- Users and sessions tables.

CREATE TABLE users (
	userid VARCHAR(64) PRIMARY KEY,
	fullname TEXT,
	email TEXT,
	pw TEXT,
	disabled BOOLEAN NOT NULL DEFAULT false,
        -- priv: null:user, 'E':editor, 'A':admin+editor.
 	priv CHAR(1) CHECK (strpos('EA', priv)>0),
	notes TEXT);

CREATE TABLE sessions (
	id TEXT PRIMARY KEY DEFAULT
          translate (encode (gen_random_bytes (12), 'base64'), '+/', '-_'),
	userid VARCHAR(64) REFERENCES users(userid),
	ts TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
        svc VARCHAR(64) DEFAULT NULL,
        state JSONB DEFAULT NULL);
CREATE INDEX sessions_userid ON sessions(userid);
CREATE INDEX sessions_ts ON sessions(ts);

-- Add an initial user.
INSERT INTO users VALUES ('admin', 'Admin User', 'admin@localhost',
                           crypt('admin', gen_salt('bf')), FALSE, 'A', NULL);
