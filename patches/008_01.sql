-- Update fld keywords per IS-212...
UPDATE kwfld SET kw='engr' WHERE kw='eng';
UPDATE kwfld SET kw='finc' WHERE kw='fin';
-- and add another new FLD keyword. 
INSERT INTO kwfld VALUES (28,'anat','anatomical term');
