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

COPY temp_aemkh_disasters FROM 'C:\minus34\govhack2014\data/aemkh_disaster_event_extract_classified_Postgres_Input.csv' HEADER QUOTE '"' CSV;

UPDATE temp_aemkh_disasters
  SET start_date = case
                     when position(' ' in start_date) > 0 then left(start_date, position(' ' in start_date) - 1)
                     else start_date
                   end;

UPDATE temp_aemkh_disasters SET regions = 'AUS' where length(regions) > 21;


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
  geom geometry (POINT, 4326, 2),
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
      ,ST_SetSRID(ST_MakePoint(long, lat), 4326)
from temp_aemkh_disasters
where regions != 'Outside Australia'
and type not in ('Wartime', 'Maritime')
and sub_type != 'Drought'
and id not in (29, 46, 105, 513, 545);



select id, regions, length(regions), * from aemkh_disasters order by length(regions) desc;

