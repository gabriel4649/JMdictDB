-- Descr: Add POS tags 'adj-ii', 'cop', 'vq1k-i' and conjugations (IS-226).
-- Note: This script does not change the pos tags on any entries; that
--  needs to be done by hand after this script has been applied (see
--  (IS-226 for sql to do that.)
-- Trans: 12->13

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(13);

INSERT INTO kwpos VALUES (7,  'adj-ii','yoi/ii i-adjective');
INSERT INTO kwpos VALUES (15, 'cop',   'copula');
INSERT INTO kwpos VALUES (29, 'v1k-i', 'Ichidan verb - kureru special class');

INSERT INTO copos VALUES (7,1);
INSERT INTO copos VALUES (15,1);
INSERT INTO copos VALUES (29,1);

\copy conjo FROM stdin DELIMITER E'\t' CSV
7	1	False	False	1	い			
7	1	False	True	1	いです			
7	1	True	False	1	くない	よ		
7	1	True	True	1	くないです	よ		
7	1	True	True	2	くありません	よ		
7	2	False	False	1	かった	よ		
7	2	False	True	1	かったです	よ		
7	2	True	False	1	くなかった	よ		
7	2	True	True	1	くなかったです	よ		
7	2	True	True	2	くありませんでした	よ		
7	3	False	False	1	くて	よ		
7	3	True	False	1	くなくて	よ		
7	4	False	False	1	ければ	よ		
7	4	True	False	1	くなければ	よ		
7	7	False	False	1	くさせる	よ		
7	9	False	False	1	かろう	よ		
7	9	False	True	1	いでしょう			
7	11	False	False	1	かったら	よ		
7	11	True	False	1	くなかったら	よ		
7	12	False	False	1	かったり	よ		
15	1	False	False	1	だ			
15	1	False	True	1	です			
15	1	True	False	1	ではない			
15	1	True	True	1	ではありません			
15	1	True	True	2	ではないです			
15	2	False	False	1	だった			
15	2	False	True	1	でした			
15	2	True	False	1	ではなかった			
15	2	True	True	1	ではありませんでした			
15	3	False	False	1	で			
15	3	False	True	1	でありまして			
15	3	True	False	1	ではなくて			
15	4	False	False	1	なら			
15	4	False	False	2	ならば			
15	4	False	False	3	であれば			
15	9	False	False	1	だろう			
15	9	False	True	1	でしょう			
15	10	False	False	1	であれ			
15	11	False	False	1	だったら			
15	11	False	True	1	でしたら			
15	11	True	False	1	ではなかったら			
15	11	True	True	1	ではありませんでしたら			
15	12	False	False	1	だったり			
29	1	False	False	1	る			
29	1	False	True	1	ます			
29	1	True	False	1	ない			
29	1	True	True	1	ました			
29	2	False	False	1	た			
29	2	False	True	1	ました			
29	2	True	False	1	なかった			
29	2	True	True	1	ませんでした			
29	3	False	False	1	て			
29	3	False	True	1	まして			
29	3	True	False	1	なくて			
29	3	True	False	2	ないで			
29	3	True	True	1	ませんで			
29	4	False	False	1	れば			
29	4	False	True	1	ますなら			
29	4	False	True	2	ますならば			
29	4	True	False	1	なければ			
29	4	True	True	1	ませんなら			
29	4	True	True	2	ませんならば			
29	5	False	False	1	られる			
29	5	False	False	2	れる			
29	5	False	True	1	られます			
29	5	False	True	2	れます			
29	5	True	False	1	られない			
29	5	True	False	2	れない			
29	5	True	True	1	られません			
29	5	True	True	2	れません			
29	6	False	False	1	られる			
29	6	False	True	1	られます			
29	6	True	False	1	られない			
29	6	True	True	1	られません			
29	7	False	False	1	させる			
29	7	False	False	2	さす			
29	7	False	True	1	させます			
29	7	False	True	2	さします			
29	7	True	False	1	させない			
29	7	True	False	2	ささない			
29	7	True	True	1	させません			
29	7	True	True	2	さしません			
29	8	False	False	1	させられる			
29	8	False	True	1	させられます			
29	8	True	False	1	させられない			
29	8	True	True	1	させられません			
29	9	False	False	1	よう			
29	9	False	True	1	ましょう			
29	9	True	False	1	まい			
29	9	True	True	1	ますまい			
29	10	False	False	1	""			
29	10	False	True	1	なさい			
29	10	True	False	1	るな			
29	10	True	True	1	なさるな			
29	11	False	False	1	たら			
29	11	False	True	1	ましたら			
29	11	True	False	1	なかったら			
29	11	True	True	1	ませんでしたら			
29	12	False	False	1	たり			
29	12	False	True	1	ましたり			
29	12	True	False	1	なかったり			
29	12	True	True	1	ませんでしたり			
29	13	False	False	1	""			
\.

\copy conjo_notes FROM stdin DELIMITER E'\t' CSV
15	1	t	f	1	3
15	1	t	t	1	3
15	1	t	t	2	3
15	2	t	f	1	3
15	2	t	t	1	3
15	3	t	f	1	3
15	4	f	f	1	2
15	11	t	f	1	3
15	11	t	t	1	3
29	5	f	f	2	6
29	5	f	t	2	6
29	5	t	f	2	6
29	5	t	t	2	6
29	9	t	f	1	5
29	9	t	t	1	5
29	10	f	f	1	1
\.

COMMIT;
