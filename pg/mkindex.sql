-------------------------------------------------------------------------
--  This file is part of JMdictDB.  
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--   JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--  You should have received a copy of the GNU General Public License
--  along with Foobar; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
--
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

  CREATE INDEX entr_seq ON entr(seq);
  CREATE INDEX entr_stat ON entr(stat) WHERE stat!=2;
  CREATE INDEX rdng_txt ON rdng(txt);
  -- CREATE UNIQUE INDEX rdng_txt1 ON rdng(entr,txt);
  CREATE INDEX kanj_txt ON kanj(txt);
  -- CREATE UNIQUE INDEX kanj_txt1 ON kanj(entr,txt);
  CREATE INDEX gloss_txt ON gloss(txt);
  -- CREATE UNIQUE INDEX gloss_txt1 ON gloss(sens,txt);
  CREATE INDEX xref_xentr ON xref(xentr,xsens);
  CREATE INDEX hist_entr ON hist(entr);
  CREATE INDEX hist_dt ON hist(dt);
  CREATE INDEX hist_who ON hist(who);
  CREATE INDEX audio_entr ON audio(entr);
  CREATE INDEX audio_fname ON audio(fname);
  CREATE INDEX xresolv_sens ON xresolv(entr,sens);
  CREATE INDEX xresolv_txt ON xresolv(txt);
  CREATE INDEX editor_email ON editor(email);
  CREATE UNIQUE INDEX editor_name ON editor(name);

