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

ALTER TABLE entr ADD FOREIGN KEY (src) REFERENCES kwsrc(id);
ALTER TABLE entr ADD FOREIGN KEY (stat) REFERENCES kwstat(id);
ALTER TABLE rdng ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kanj ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sens ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE gloss ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE gloss ADD FOREIGN KEY (lang) REFERENCES kwlang(id);
ALTER TABLE xref ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xref ADD FOREIGN KEY (xentr,xsens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xref ADD FOREIGN KEY (typ) REFERENCES kwxref(id);
ALTER TABLE hist ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE hist ADD FOREIGN KEY (stat) REFERENCES kwstat(id);
ALTER TABLE kfreq ADD FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kfreq ADD FOREIGN KEY (kw) REFERENCES kwfreq(id);
ALTER TABLE rfreq ADD FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE rfreq ADD FOREIGN KEY (kw) REFERENCES kwfreq(id);
ALTER TABLE audio ADD FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE dial ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE dial ADD FOREIGN KEY (kw) REFERENCES kwdial(id);
ALTER TABLE fld ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE fld ADD FOREIGN KEY (kw) REFERENCES kwfld(id);
ALTER TABLE kinf ADD FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kinf ADD FOREIGN KEY (kw) REFERENCES kwkinf(id);
ALTER TABLE lang ADD FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE lang ADD FOREIGN KEY (kw) REFERENCES kwlang(id);
ALTER TABLE misc ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE misc ADD FOREIGN KEY (kw) REFERENCES kwmisc(id);
ALTER TABLE pos ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE pos ADD FOREIGN KEY (kw) REFERENCES kwpos(id);
ALTER TABLE rinf ADD FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE rinf ADD FOREIGN KEY (kw) REFERENCES kwrinf(id);
ALTER TABLE restr ADD FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE restr ADD FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagr ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagr ADD FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagk ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagk ADD FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xresolv ADD FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xresolv ADD FOREIGN KEY (typ) REFERENCES kwxref(id);
