\set ON_ERROR_STOP
BEGIN;

-- Add additional columns to "xref" table for Tatoeba examples support.

\set dbversion  '''1ef804'''  -- Update version applied by this update.
\set require    '''20c2fe'''  -- Database must be at this version in
                              --  order to apply this update.

\qecho Checking database version...
SELECT CASE WHEN (EXISTS (SELECT 1 FROM db WHERE id=x:require::INT)) THEN NULL 
    ELSE (SELECT err('Database at wrong update level, need version '||:require)) END;
INSERT INTO db(id) VALUES(x:dbversion::INT);
UPDATE db SET active=FALSE WHERE id!=x:dbversion::INT;


-- Do the update

ALTER TABLE xref 
      -- No specific target sense preferred.
    ADD COLUMN nosens BOOLEAN NOT NULL DEFAULT FALSE,
      -- Low priority xref.
    ADD COLUMN lowpri BOOLEAN NOT NULL DEFAULT FALSE;

COMMIT;
