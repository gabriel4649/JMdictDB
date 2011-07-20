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

-- $Revision$ $Date$

-- Schema for JMdictDB users/sessions database.

\set ON_ERROR_STOP 

CREATE TABLE users (
	userid VARCHAR(20) PRIMARY KEY,
	fullname VARCHAR(100),
	email VARCHAR(250),
	pw VARCHAR(50),
	disabled BOOLEAN NOT NULL DEFAULT false,
	notes TEXT);

CREATE TABLE sessions (
	id BIGINT PRIMARY KEY,
	userid VARCHAR(20),
	ts TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'));
CREATE INDEX sessions_userid ON sessions(userid);
CREATE INDEX sessions_ts ON sessions(ts);
ALTER TABLE sessions ADD CONSTRAINT sessions_userid_fkey FOREIGN KEY (userid) REFERENCES users(userid);


