-- Add constraint to enforce only one "active" entr per seq#.
CREATE UNIQUE INDEX ON entr(seq,stat,unap) WHERE stat=2 AND NOT unap;
