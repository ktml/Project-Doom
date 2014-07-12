DROP TABLE IF EXISTS temp_aemkh_disasters;

CREATE TABLE temp_aemkh_disasters
(
  id integer NOT NULL,
  type character varying(50) NOT NULL,
  sub_type character varying(50) NOT NULL,
  name character varying(255) NOT NULL,
  description character varying(7500) NOT NULL,
  start_date character varying(50) NOT NULL,
  end_date character varying(50) NOT NULL,
  lat numeric(10,8) NOT NULL,
  long numeric(11,8) NOT NULL,
  evacuated integer NULL,
  homeless integer NULL,
  injuries integer NULL,
  deaths integer NULL,
  insured_cost money NULL,
  homes_damaged integer NULL,
  homes_destroyed integer NULL,
  regions character varying(50) NOT NULL,
  url character varying(255) NOT NULL,
  CONSTRAINT temp_aemkh_disasters_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE temp_aemkh_disasters OWNER TO postgres;

----Default is MDY
--set datestyle = 'ISO, MDY';

COPY temp_aemkh_disasters FROM 'C:\minus34\GitHub\Project-Doom\data/aemkh_disaster_event_extract_classified_Postgres_Input.csv' HEADER QUOTE '"' CSV;

UPDATE temp_aemkh_disasters
  SET start_date = case
                     when position(' ' in start_date) > 0 then left(start_date, position(' ' in start_date) - 1)
                     else start_date
                   end;

UPDATE temp_aemkh_disasters SET regions = 'AUS' where length(regions) > 21;

UPDATE temp_aemkh_disasters SET evacuated = null where evacuated = 0 ; -- 3
UPDATE temp_aemkh_disasters SET homeless = null where homeless = 0 ; -- 0
UPDATE temp_aemkh_disasters SET injuries = null where injuries = 0 ; -- 3
UPDATE temp_aemkh_disasters SET deaths = null where deaths = 0 ; -- 0
--UPDATE temp_aemkh_disasters SET insured_cost = null where insured_cost = 0 ;
UPDATE temp_aemkh_disasters SET homes_damaged = null where homes_damaged = 0 ; -- 1
UPDATE temp_aemkh_disasters SET homes_destroyed = null where homes_destroyed = 0 ; -- 0


DROP TABLE IF EXISTS aemkh_disasters;

CREATE TABLE aemkh_disasters
(
  id integer NOT NULL,
  type character varying(50) NOT NULL,
  sub_type character varying(50) NOT NULL,
  name character varying(255) NOT NULL,
  description character varying(7500) NOT NULL,
  year smallint NOT NULL,
  lat numeric(10,8) NOT NULL,
  long numeric(11,8) NOT NULL,
  evacuated integer NULL,
  homeless integer NULL,
  injuries integer NULL,
  deaths integer NULL,
  insured_cost money NULL,
  homes_damaged integer NULL,
  homes_destroyed integer NULL,
  regions character varying(50) NOT NULL,
  url character varying(255) NOT NULL,
  severity money NOT NULL,
  cost_2011 money NOT NULL,
  --geom geometry (POINT, 4326, 2),
  CONSTRAINT aemkh_disasters_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE aemkh_disasters OWNER TO postgres;


insert into aemkh_disasters
select id
      ,type
      ,sub_type
      ,name
      ,description
      ,right(start_date,4)::int
      ,lat
      ,long
      ,evacuated
      ,homeless
      ,injuries
      ,deaths
      ,insured_cost
      ,homes_damaged
      ,homes_destroyed
      ,regions
      ,url
      ,0
      ,0
      --,ST_SetSRID(ST_MakePoint(long, lat), 4326)
from temp_aemkh_disasters
where regions != 'Outside Australia'
and type not in ('Wartime', 'Maritime', 'Epidemic')
and sub_type not in ('Drought', 'Criminal')
and id not in (29, 46, 105, 513, 545, 250)
and (
  (type <> 'Natural' and deaths > 5)
  or
  type = 'Natural'
)
and (deaths > 0 or (COALESCE(deaths, 0) = 0 and (COALESCE(injuries, 0) > 100 or COALESCE(insured_cost::numeric(11,0), 0) > 0)));


update aemkh_disasters set sub_type = 'Storm/Hail' where sub_type IN ('Severe Storm', 'Hail', 'Tornado');
update aemkh_disasters set sub_type = 'Rail' where sub_type = 'Road/rail';
update aemkh_disasters set severity = COALESCE(insured_cost, 0::money) + COALESCE(deaths, 0) * 4000000::money + COALESCE(injuries, 0) * 500000::money + COALESCE(homeless, 0) * 100000::money + COALESCE(evacuated, 0) * 100000::money;

--select * from aemkh_disasters where (deaths > 0 or (COALESCE(deaths, 0) = 0 and (COALESCE(injuries, 0) > 100 or COALESCE(insured_cost::numeric(11,0), 0) > 0))) order by insured_cost desc;
--select * from aemkh_disasters order by severity desc; -- 344

COPY temp_aemkh_disasters TO 'C:\minus34\GitHub\Project-Doom\data/doom_stats.csv' HEADER CSV;


-- 
-- select * from aemkh_disasters where regions = 'AUS'
-- 
-- 
-- select * from aemkh_disasters where evacuated IS NOT NULL order by evacuated desc; -- 101 min
-- select * from aemkh_disasters where homeless IS NOT NULL order by homeless desc; -- 101 min
-- select * from aemkh_disasters where injuries IS NOT NULL order by injuries desc;
-- --select * from aemkh_disasters where deaths IS NOT NULL order by deaths desc;
-- select * from aemkh_disasters where insured_cost IS NOT NULL order by insured_cost desc;
-- select * from aemkh_disasters where homes_damaged IS NOT NULL order by homes_damaged desc;
-- select * from aemkh_disasters where homes_destroyed IS NOT NULL order by homes_destroyed desc;



SELECT Count(*), type, SUM(deaths) as deaths
  FROM aemkh_disasters
  group by type;

56;"Transport";940
32;"Man made";658
252;"Natural";5313


SELECT Count(*), type, SUM(deaths) as deaths, sub_type
  FROM aemkh_disasters
  group by type, sub_type
  order by type, sub_type;


Count, type, deaths, sub_type
12;Man made;148;Fire
20;Man made;510;Industrial
55;Natural;680;Bushfire
34;Natural;951;Cyclone
3;Natural;13;Earthquake
70;Natural;615;Flood
17;Natural;2887;Heatwave
4;Natural;38;Landslide
1;Natural;5;Riptide
68;Natural;124;Storm/Hail
21;Transport;327;Air
24;Transport;371;Rail
8;Transport;126;Road
3;Transport;116;Water


select * from aemkh_disasters where sub_type = 'Criminal';

