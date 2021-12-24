DROP DATABASE IF EXISTS ref;
CREATE DATABASE ref;

GRANT ALL PRIVILEGES ON ref.* TO 'mysqluser'@'%' WITH GRANT OPTION;

USE ref;

DROP table IF EXISTS ref_table;
DROP table IF EXISTS ref_value;
DROP table IF EXISTS value_locale;
DROP table IF EXISTS relation_type;
DROP table IF EXISTS relation;


CREATE TABLE ref_table (
  table_id             VARCHAR(160) NOT NULL,
  table_name           VARCHAR(80) NOT NULL,
  table_desc           VARCHAR(1024) NULL,
  host                 VARCHAR(32) NULL,
  active               VARCHAR(1) NOT NULL DEFAULT 'Y',
  editable             VARCHAR(1) NOT NULL DEFAULT 'Y',
  common               VARCHAR(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY(table_id)
);


CREATE TABLE ref_value (
  value_id              VARCHAR(160) NOT NULL,
  table_id              VARCHAR(160) NOT NULL,
  value_code            VARCHAR(80) NOT NULL,
  start_time            TIMESTAMP NULL,
  end_time              TIMESTAMP NULL,
  display_order         INT,
  active                VARCHAR(1) NOT NULL,
  PRIMARY KEY(value_id)
);


CREATE TABLE value_locale (
  value_id              VARCHAR(160) NOT NULL,
  language              VARCHAR(2) NOT NULL,
  value_desc            VARCHAR(256) NULL,
  PRIMARY KEY(value_id,language)
);



CREATE TABLE relation_type (
  relation_id           VARCHAR(10) NOT NULL,
  relation_name         VARCHAR(32) NOT NULL,
  relation_desc         VARCHAR(256) NOT NULL,
  PRIMARY KEY(relation_id)
);



CREATE TABLE relation (
  relation_id           VARCHAR(10) NOT NULL,
  value_id_from         VARCHAR(160) NOT NULL,
  value_id_to           VARCHAR(160) NOT NULL,
  active                VARCHAR(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY(relation_id, value_id_from, value_id_to)
);

-- populate data from the script in light-reference
-- alter table relation_type modify relation_id VARCHAR(32) NOT NULL;
-- alter table relation modify relation_id VARCHAR(32) NOT NULL;

-- ref table update statements
DELETE FROM relation;
DELETE FROM relation_type;
DELETE FROM value_locale;
DELETE FROM ref_value;
DELETE FROM ref_table;

INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('country', 'country', 'ISO country', 'lightapi.net');
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('province', 'province', 'Province or State', 'lightapi.net');
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('city', 'city', 'City', 'lightapi.net');
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('language', 'language', 'Language', 'lightapi.net');



INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('CAN', 'country', 'CAN', 100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('USA', 'country', 'USA', 200, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('France', 'country', 'FRA', 300, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('China', 'country', 'CHN', 400, 'Y');


INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ON', 'province', 'ON', 100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('QC', 'province', 'QC', 200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NS', 'province', 'NS', 300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NB', 'province', 'NB', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MB', 'province', 'MB', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('BC', 'province', 'BC', 600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('PE', 'province', 'PE', 700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('SK', 'province', 'SK', 800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AB', 'province', 'AB', 900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NL', 'province', 'NL', 1000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NT', 'province', 'NT', 1100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('YT', 'province', 'YT', 1200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NU', 'province', 'NU', 1300, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AL', 'province', 'AL', 100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AK', 'province', 'AK', 200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AZ', 'province', 'AZ', 300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AR', 'province', 'AR', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('CA', 'province', 'CA', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('CO', 'province', 'CO', 600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('CT', 'province', 'CT', 700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('DE', 'province', 'DE', 800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('DC', 'province', 'DC', 900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('FL', 'province', 'FL', 1000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('GA', 'province', 'GA', 1100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('HI', 'province', 'HI', 1200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ID', 'province', 'ID', 1300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('IL', 'province', 'IL', 1400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('IN', 'province', 'IN', 1500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('IA', 'province', 'IA', 1600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('KS', 'province', 'KS', 1700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('KY', 'province', 'KY', 1800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('LA', 'province', 'LA', 1900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ME', 'province', 'ME', 2000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MD', 'province', 'MD', 2100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MA', 'province', 'MA', 2200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MI', 'province', 'MI', 2300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MN', 'province', 'MN', 2400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MS', 'province', 'MS', 2500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MO', 'province', 'MO', 2600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MT', 'province', 'MT', 2700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NE', 'province', 'NE', 2800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NV', 'province', 'NV', 2900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NH', 'province', 'NH', 3000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NJ', 'province', 'NJ', 3100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NM', 'province', 'NM', 3200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NY', 'province', 'NY', 3300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NC', 'province', 'NC', 3400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ND', 'province', 'ND', 3500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('OH', 'province', 'OH', 3600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('OK', 'province', 'OK', 3700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('OR', 'province', 'OR', 3800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('PA', 'province', 'PA', 3900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('RI', 'province', 'RI', 4000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('SC', 'province', 'SC', 4100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('SD', 'province', 'SD', 4200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('TN', 'province', 'TN', 4300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('TX', 'province', 'TX', 4400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('UT', 'province', 'UT', 4500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('VT', 'province', 'VT', 4600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('VA', 'province', 'VA', 4700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('WA', 'province', 'WA', 4800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('WV', 'province', 'WV', 4900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('WI', 'province', 'WI', 5000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('WY', 'province', 'WY', 5100, 'Y');

-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Orleanais', 'province', 'Orleanais', 400, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Liaoning', 'province', 'Liaoning', 500, 'Y');


INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Toronto', 'city', 'Toronto', 110, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Peel', 'city', 'Peel', 120, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Halton', 'city', 'Halton', 130, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('York', 'city', 'York', 140, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Durham', 'city', 'Durham', 150, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Dufferin', 'city', 'Dufferin', 160, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Simcoe', 'city', 'Simcoe', 170, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('East', 'city', 'East', 180, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('West', 'city', 'West', 190, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('North', 'city', 'North', 200, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Edmonton', 'city', 'Edmonton', 210, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Victoria', 'city', 'Victoria', 300, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Winnipeg', 'city', 'Winnipeg', 220, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Fredericton', 'city', 'Fredericton', 230, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('St. Johns', 'city', 'St. Johns', 240, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Yellowknife', 'city', 'Yellowknife', 250, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Halifax', 'city', 'Halifax', 260, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Iqaluit', 'city', 'Iqaluit', 270, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Charlottetown', 'city', 'Charlottetown', 270, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Quebec City', 'city', 'Quebec City', 270, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Regina', 'city', 'Regina', 270, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Whitehorse', 'city', 'Whitehorse', 270, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Montgomery', 'city', 'Montgomery', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Juneau', 'city', 'Juneau', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Phoenix', 'city', 'Phoenix', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Little Rock', 'city', 'Little Rock', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Sacramento', 'city', 'Sacramento', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Denver', 'city', 'Denver', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Hartford', 'city', 'Hartford', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Washington', 'city', 'Washington', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Dover', 'city', 'Dover', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Tallahassee', 'city', 'Tallahassee', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Atlanta', 'city', 'Atlanta', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Honolulu', 'city', 'Honolulu', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Boise', 'city', 'Boise', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Springfield', 'city', 'Springfield', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Indianapolis', 'city', 'Indianapolis', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Des Moines', 'city', 'Des Moines', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Topeka', 'city', 'Topeka', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Frankfort', 'city', 'Frankfort', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Baton Rouge', 'city', 'Baton Rouge', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Augusta', 'city', 'Augusta', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Annapolis', 'city', 'Annapolis', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Boston', 'city', 'Boston', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Lansing', 'city', 'Lansing', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Saint Paul', 'city', 'Saint Paul', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Jackson', 'city', 'Jackson', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Jefferson City', 'city', 'Jefferson City', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Helena', 'city', 'Helena', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Lincoln', 'city', 'Lincoln', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Carson City', 'city', 'Carson City', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Concord', 'city', 'Concord', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Trenton', 'city', 'Trenton', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Santa Fe', 'city', 'Santa Fe', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Albany', 'city', 'Albany', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Raleigh', 'city', 'Raleigh', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Bismarck', 'city', 'Bismarck', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Columbus', 'city', 'Columbus', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Oklahoma City', 'city', 'Oklahoma City', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Salem', 'city', 'Salem', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Harrisburg', 'city', 'Harrisburg', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Providence', 'city', 'Providence', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Columbia', 'city', 'Columbia', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Pierre', 'city', 'Pierre', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Nashville', 'city', 'Nashville', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Austin', 'city', 'Austin', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Salt Lake City', 'city', 'Salt Lake City', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Montpelier', 'city', 'Montpelier', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Richmond', 'city', 'Richmond', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Olympia', 'city', 'Olympia', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Charleston', 'city', 'Charleston', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Madison', 'city', 'Madison', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Cheyenne', 'city', 'Cheyenne', 400, 'Y');


-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Orleans', 'city', 'Orleans', 500, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Dalian', 'city', 'Dalian', 600, 'Y');


-- country
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('CAN', 'en', 'Canada');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Canada', 'fr', 'Canada');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Canada', 'zh', '加拿大');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('USA', 'en', 'USA');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('USA', 'fr', 'USA');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('USA', 'zh', '美国');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('France', 'en', 'France');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('France', 'fr', 'France');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('France', 'zh', '法国');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('China', 'en', 'China');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('China', 'fr', 'Chine');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('China', 'zh', '中国');

-- province
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ON', 'en', 'Ontario');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('QC', 'en', 'Quebec');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NS', 'en', 'Nova Scotia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NB', 'en', 'New Brunswick');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MB', 'en', 'Manitoba');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('BC', 'en', 'British Columbia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('PE', 'en', 'Prince Edward Island');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('SK', 'en', 'Saskatchewan');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AB', 'en', 'Alberta');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NL', 'en', 'Newfoundland and Labrador');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NT', 'en', 'Northwest Territories');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('YT', 'en', 'Yukon');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NU', 'en', 'Nunavut');

-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ON', 'fr', 'Ontario');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ON', 'zh', '安大略省');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('BC', 'fr', 'British Columbia');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('BC', 'zh', '不列颠哥伦比亚省');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AL', 'en', 'Alabama');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AK', 'en', 'Alaska');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AZ', 'en', 'Arizona');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AR', 'en', 'Arkansas');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('CA', 'en', 'California');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('CO', 'en', 'Colorado');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('CT', 'en', 'Connecticut');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('DE', 'en', 'Delaware');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('DC', 'en', 'District of Columbia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('FL', 'en', 'Florida');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('GA', 'en', 'Georgia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('HI', 'en', 'Hawaii');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ID', 'en', 'Idaho');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('IL', 'en', 'Illinois');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('IN', 'en', 'Indiana');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('IA', 'en', 'Iowa');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('KS', 'en', 'Kansas');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('KY', 'en', 'Kentucky');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('LA', 'en', 'Louisiana');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ME', 'en', 'Maine');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MD', 'en', 'Maryland');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MA', 'en', 'Massachusetts');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MI', 'en', 'Michigan');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MN', 'en', 'Minnesota');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MS', 'en', 'Mississippi');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MO', 'en', 'Missouri');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MT', 'en', 'Montana');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NE', 'en', 'Nebraska');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NV', 'en', 'Nevada');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NH', 'en', 'New Hampshire');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NJ', 'en', 'New Jersey');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NM', 'en', 'New Mexico');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NY', 'en', 'New York');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NC', 'en', 'North Carolina');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ND', 'en', 'North Dakota');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('OH', 'en', 'Ohio');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('OK', 'en', 'Oklahoma');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('OR', 'en', 'Oregon');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('PA', 'en', 'Pennsylvania');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('RI', 'en', 'Rhode Island');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('SC', 'en', 'South Carolina');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('SD', 'en', 'South Dakota');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('TN', 'en', 'Tennessee');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('TX', 'en', 'Texas');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('UT', 'en', 'Utah');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('VT', 'en', 'Vermont');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('VA', 'en', 'Virginia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('WA', 'en', 'Washington');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('WV', 'en', 'West Virginia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('WI', 'en', 'Wisconsin');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('WY', 'en', 'Wyoming');

-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NY', 'fr', 'NY');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NY', 'zh', '纽约州');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleanais', 'en', 'Orléanais');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleanais', 'fr', 'Orléanais');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleanais', 'zh', '奥尔良');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Liaoning', 'en', 'Liaoning');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Liaoning', 'fr', 'Liaoning');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Liaoning', 'zh', '辽宁');

-- city
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Toronto', 'en', 'Toronto');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Peel', 'en', 'Peel');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Halton', 'en', 'Halton');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('York', 'en', 'York');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Durham', 'en', 'Durham');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Dufferin', 'en', 'Dufferin');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Simcoe', 'en', 'Simcoe');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('East', 'en', 'East');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('West', 'en', 'West');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('North', 'en', 'North');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Edmonton', 'en', 'Edmonton');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Victoria', 'en', 'Victoria');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Winnipeg', 'en', 'Winnipeg');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Fredericton', 'en', 'Fredericton');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('St. Johns', 'en', 'St. Johns');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Yellowknife', 'en', 'Yellowknife');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Halifax', 'en', 'Halifax');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Iqaluit', 'en', 'Iqaluit');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Charlottetown', 'en', 'Charlottetown');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Quebec City', 'en', 'Quebec City');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Regina', 'en', 'Regina');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Whitehorse', 'en', 'Whitehorse');


-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Toronto', 'fr', 'Toronto');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Toronto', 'zh', '多伦多');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Mississauga', 'fr', 'Mississauga');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Mississauga', 'zh', '密西沙加');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Vancouver', 'fr', 'Vancouver');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Vancouver', 'zh', '温哥华');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Montgomery', 'en', 'Montgomery');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Juneau', 'en', 'Juneau');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Phoenix', 'en', 'Phoenix');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Little Rock', 'en', 'Little Rock');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Sacramento', 'en', 'Sacramento');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Denver', 'en', 'Denver');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Hartford', 'en', 'Hartford');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Washington', 'en', 'Washington');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Dover', 'en', 'Dover');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Tallahassee', 'en', 'Tallahassee');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Atlanta', 'en', 'Atlanta');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Honolulu', 'en', 'Honolulu');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Boise', 'en', 'Boise');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Springfield', 'en', 'Springfield');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Indianapolis', 'en', 'Indianapolis');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Des Moines', 'en', 'Des Moines');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Topeka', 'en', 'Topeka');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Frankfort', 'en', 'Frankfort');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Baton Rouge', 'en', 'Baton Rouge');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Augusta', 'en', 'Augusta');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Annapolis', 'en', 'Annapolis');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Boston', 'en', 'Boston');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Lansing', 'en', 'Lansing');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Saint Paul', 'en', 'Saint Paul');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Jackson', 'en', 'Jackson');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Jefferson City', 'en', 'Jefferson City');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Helena', 'en', 'Helena');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Lincoln', 'en', 'Lincoln');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Carson City', 'en', 'Carson City');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Concord', 'en', 'Concord');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Trenton', 'en', 'Trenton');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Santa Fe', 'en', 'Santa Fe');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Albany', 'en', 'Albany');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Raleigh', 'en', 'Raleigh');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Bismarck', 'en', 'Bismarck');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Columbus', 'en', 'Columbus');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Oklahoma City', 'en', 'Oklahoma City');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Salem', 'en', 'Salem');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Harrisburg', 'en', 'Harrisburg');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Providence', 'en', 'Providence');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Columbia', 'en', 'Columbia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Pierre', 'en', 'Pierre');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Nashville', 'en', 'Nashville');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Austin', 'en', 'Austin');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Salt Lake City', 'en', 'Salt Lake City');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Montpelier', 'en', 'Montpelier');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Richmond', 'en', 'Richmond');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Olympia', 'en', 'Olympia');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Charleston', 'en', 'Charleston');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Madison', 'en', 'Madison');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Cheyenne', 'en', 'Cheyenne');

-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('New York City', 'fr', 'New York City');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('New York City', 'zh', '纽约市');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleans', 'en', 'Orleans');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleans', 'fr', 'Orleans');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Orleans', 'zh', '奥尔良');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Dalian', 'en', 'Dalian');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Dalian', 'fr', 'Dalian');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Dalian', 'zh', '大连');

-- relation type
INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('ctry-prov', 'country-province', 'country province dropdown');
INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('prov-city', 'province-city', 'province city dropdown');

-- relation
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'ON');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'QC');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'NS');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'NB');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'MB');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'BC');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'PE');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'SK');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'AB');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'NL');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'NT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'YT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'CAN', 'NU');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'AL');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'AK');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'AZ');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'AR');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'CA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'CO');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'CT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'DE');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'DC');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'FL');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'GA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'HI');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'ID');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'IL');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'IN');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'IA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'KS');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'KY');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'LA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'ME');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MD');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MI');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MN');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MS');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MO');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'MT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NE');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NV');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NH');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NJ');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NM');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NY');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'NC');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'ND');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'OH');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'OK');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'OR');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'PA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'RI');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'SC');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'SD');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'TN');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'TX');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'UT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'VT');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'VA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'WA');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'WV');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'WI');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'USA', 'WY');

-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'France', 'Orleanais');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('ctry-prov', 'China', 'Liaoning');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Toronto');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Peel');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Halton');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'York');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Durham');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Dufferin');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'Simcoe');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'East');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'West');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ON', 'North');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'AB', 'Edmonton');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'BC', 'Victoria');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MB', 'Winnipeg');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NB', 'Fredericton');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NL', 'St. Johns');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NT', 'Yellowknife');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NS', 'Halifax');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NU', 'Iqaluit');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'PE', 'Charlottetown');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'QC', 'Quebec City');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'SK', 'Regina');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'YT', 'Whitehorse');


INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'AL', 'Montgomery');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'AK', 'Juneau');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'AZ', 'Phoenix');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'AR', 'Little Rock');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'CA', 'Sacramento');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'CO', 'Denver');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'CT', 'Hartford');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'DE', 'Dover');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'DC', 'Washington');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'FL', 'Tallahassee');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'GA', 'Atlanta');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'HI', 'Honolulu');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ID', 'Boise');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'IL', 'Springfield');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'IN', 'Indianapolis');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'IA', 'Des Moines');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'KS', 'Topeka');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'KY', 'Frankfort');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'LA', 'Baton Rouge');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ME', 'Augusta');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MD', 'Annapolis');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MA', 'Boston');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MI', 'Lansing');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MN', 'Saint Paul');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MS', 'Jackson');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MO', 'Jefferson City');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'MT', 'Helena');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NE', 'Lincoln');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NV', 'Carson City');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NH', 'Concord');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NJ', 'Trenton');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NM', 'Santa Fe');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NY', 'Albany');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'NC', 'Raleigh');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'ND', 'Bismarck');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'OH', 'Columbus');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'OK', 'Oklahoma City');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'OR', 'Salem');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'PA', 'Harrisburg');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'RI', 'Providence');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'SC', 'Columbia');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'SD', 'Pierre');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'TN', 'Nashville');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'TX', 'Austin');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'UT', 'Salt Lake City');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'VT', 'Montpelier');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'VA', 'Richmond');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'WA', 'Olympia');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'WV', 'Charleston');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'WI', 'Madison');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'WY', 'Cheyenne');

-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'Orleanais', 'Orleans');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('prov-city', 'Liaoning', 'Dalian');




INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('covid-category', 'category', 'covid entity category', 'lightapi.net');
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('covid-subcategory', 'subcategory', 'covid entity subcategory', 'lightapi.net');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('askandgive', 'covid-category', 'askandgive', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('freecycle', 'covid-category', 'freecycle', 410, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('barter', 'covid-category', 'barter', 415, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('buyandsell', 'covid-category', 'buyandsell', 420, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('realestate', 'covid-category', 'realestate', 430, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('e-commerce', 'covid-category', 'e-commerce', 540, 'Y');


INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('retail', 'covid-category', 'retail', 600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('service', 'covid-category', 'service', 700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('manufacture', 'covid-category', 'manufacture', 800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('healthcare', 'covid-category', 'healthcare', 900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('education', 'covid-category', 'education', 1000, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('government', 'covid-category', 'government', 1100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('entertainment', 'covid-category', 'entertainment', 1200, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('recreation', 'covid-category', 'recreation', 1300, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ask', 'covid-subcategory', 'ask', 400, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('give', 'covid-subcategory', 'give', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('offer', 'covid-subcategory', 'offer', 600, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('want', 'covid-subcategory', 'want', 700, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('goods', 'covid-subcategory', 'goods', 800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('services', 'covid-subcategory', 'services', 900, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('buy', 'covid-subcategory', 'buy', 800, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('sell', 'covid-subcategory', 'sell', 900, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('forrent', 'covid-subcategory', 'forrent', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('torent', 'covid-subcategory', 'torent', 501, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('forsale', 'covid-subcategory', 'forsale', 502, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('tobuy', 'covid-subcategory', 'tobuy', 503, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('agent', 'covid-subcategory', 'agent', 510, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('lawyer', 'covid-subcategory', 'lawyer', 511, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('insurance', 'covid-subcategory', 'insurance', 512, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('mortgage', 'covid-subcategory', 'mortgage', 513, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('inspector', 'covid-subcategory', 'inspector', 514, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('surveyor', 'covid-subcategory', 'surveyor', 514, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('builder', 'covid-subcategory', 'builder', 515, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('renovator', 'covid-subcategory', 'renovator', 516, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('decorator', 'covid-subcategory', 'decorator', 517, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('landscape', 'covid-subcategory', 'landscape', 518, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('architect', 'covid-subcategory', 'architect', 519, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('commercial', 'covid-subcategory', 'commerical', 520, 'Y');



INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('face-mask', 'covid-subcategory', 'face-mask', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('grocery', 'covid-subcategory', 'grocery', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('pharmacy', 'covid-subcategory', 'pharmacy', 500, 'Y');

INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('restaurant', 'covid-subcategory', 'restaurant', 500, 'Y');

-- healthcare
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('hospital', 'covid-subcategory', 'hospital', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('veterinary', 'covid-subcategory', 'veterinary', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('clinic', 'covid-subcategory', 'clinic', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('dental', 'covid-subcategory', 'dental', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('optical', 'covid-subcategory', 'optical', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('laboratory', 'covid-subcategory', 'laboratory', 500, 'Y');
-- education
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('school', 'covid-subcategory', 'school', 500, 'Y');
-- government
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('office', 'covid-subcategory', 'office', 500, 'Y');
-- entertainment
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('all', 'covid-subcategory', 'all', 500, 'Y');
-- recreation
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('virtualtravel', 'covid-subcategory', 'virtualtravel', 500, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('other', 'covid-subcategory', 'other', 500, 'Y');



INSERT INTO value_locale(value_id, language, value_desc) VALUES ('askandgive', 'en', 'Ask and Give');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('freecycle', 'en', 'Freecycle');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('barter', 'en', 'Barter');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('buyandsell', 'en', 'Buy and Sell');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('realestate', 'en', 'Real Estate');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('retail', 'en', 'Retail');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('service', 'en', 'Service');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('manufacture', 'en', 'Manufacture');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('healthcare', 'en', 'Healthcare');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('education', 'en', 'Education');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('government', 'en', 'Government');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('entertainment', 'en', 'Entertainment');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('recreation', 'en', 'Recreation');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ask', 'en', 'Ask');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('give', 'en', 'Give');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('offer', 'en', 'Offer');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('want', 'en', 'Want');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('goods', 'en', 'Goods');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('services', 'en', 'Services');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('buy', 'en', 'Buy');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('sell', 'en', 'Sell');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('forrent', 'en', 'For Rent');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('torent', 'en', 'To Rent');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('forsale', 'en', 'For Sale');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('tobuy', 'en', 'To Buy');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('agent', 'en', 'Real Estate Agent');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('lawyer', 'en', 'Property Lawyer');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('insurance', 'en', 'Insurance Agent');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('mortgage', 'en', 'Mortgage Broker');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('inspector', 'en', 'Home Inspector');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('surveyor', 'en', 'Land Survey');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('builder', 'en', 'Home Builder');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('renovator', 'en', 'Renovation Contractor');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('decorator', 'en', 'Home Decorator');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('landscape', 'en', 'Landscape Contractor');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('architect', 'en', 'Architectural Designer');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('commercial', 'en', 'Commercial Property');


INSERT INTO value_locale(value_id, language, value_desc) VALUES ('face-mask', 'en', 'Face Mask');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('grocery', 'en', 'Grocery');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('pharmacy', 'en', 'Pharmacy');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('restaurant', 'en', 'Restaurant');

INSERT INTO value_locale(value_id, language, value_desc) VALUES ('hospital', 'en', 'Hospital');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('veterinary', 'en', 'Veterinary');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('clinic', 'en', 'Clinic');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('dental', 'en', 'Dental');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('optical', 'en', 'Optical');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('laboratory', 'en', 'Laboratory');

-- education
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('school', 'en', 'school');
-- government
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('office', 'en', 'Office');
-- entertainment / manufacture
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('all', 'en', 'All');
-- recreation
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('virtualtravel', 'en', 'Virtual Travel');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('other', 'en', 'Other');


INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('cov-cat', 'covid-category', 'covid categroy and sub category');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'askandgive', 'ask');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'askandgive', 'give');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'freecycle', 'offer');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'freecycle', 'want');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'barter', 'goods');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'barter', 'services');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'buyandsell', 'buy');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'buyandsell', 'sell');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'forrent');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'torent');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'forsale');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'tobuy');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'agent');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'lawyer');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'insurance');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'mortgage');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'inspector');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'surveyor');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'builder');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'renovator');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'landscape');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'architect');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'realestate', 'commercial');


INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'retail', 'face-mask');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'retail', 'grocery');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'retail', 'pharmacy');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'service', 'restaurant');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'service', 'other');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'manufacture', 'all');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'hospital');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'veterinary');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'clinic');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'dental');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'optical');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'laboratory');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'healthcare', 'other');


INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'education', 'school');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'government', 'office');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'entertainment', 'all');

INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'recreation', 'virtualtravel');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('cov-cat', 'recreation', 'other');


-- Add host and values
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('host', 'host', 'Host', 'lightapi.net');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('lightapi.net', 'host', 'lightapi.net', 100, 'Y');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('lightapi.net', 'en', 'lightapi.net');

-- Add language values
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('en', 'language', 'en', 100, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('fr', 'language', 'fr', 101, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('zh', 'language', 'zh', 102, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('es', 'language', 'es', 103, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ja', 'language', 'ja', 104, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ko', 'language', 'ko', 105, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('pt', 'language', 'pt', 106, 'Y');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ru', 'language', 'ru', 107, 'Y');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('en', 'en', 'English');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('fr', 'en', 'French');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('zh', 'en', 'Chinese');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('es', 'en', 'Spanish');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ja', 'en', 'Japanese');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ko', 'en', 'Korean');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('pt', 'en', 'Portuguese');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ru', 'en', 'Russian');


-- Ad lob and relationship with host
INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('lob', 'lob', 'Line of Business', 'lightapi.net');
INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('portal', 'lob', 'portal', 100, 'Y');
INSERT INTO value_locale(value_id, language, value_desc) VALUES ('portal', 'en', 'portal');
INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('host-lob', 'host-lob', 'host and line of businss mapping');
INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('host-lob', 'lightapi.net', 'portal');



-- TODO This will be removed to the light-portal category in the future
-- INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('quiz-type', 'quiz-type', 'quiz type', 'lightapi.net');
-- INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('quiz-category', 'quiz-category', 'quiz category', 'lightapi.net');
-- INSERT INTO ref_table(table_id, table_name, table_desc, host) values ('quiz-subcategory', 'quiz-subcategory', 'quiz subcategory', 'lightapi.net');
--
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-preschool', 'quiz-type', 'math-preschool', 399, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-kindergarten', 'quiz-type', 'math-kindergarten', 400, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade1', 'quiz-type', 'math-grade1', 401, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade2', 'quiz-type', 'math-grade2', 402, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade3', 'quiz-type', 'math-grade3', 403, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade4', 'quiz-type', 'math-grade4', 404, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade5', 'quiz-type', 'math-grade5', 405, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade6', 'quiz-type', 'math-grade6', 406, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade7', 'quiz-type', 'math-grade7', 407, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade8', 'quiz-type', 'math-grade8', 408, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade9', 'quiz-type', 'math-grade9', 409, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade10', 'quiz-type', 'math-grade10', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade11', 'quiz-type', 'math-grade11', 411, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('math-grade12', 'quiz-type', 'math-grade12', 412, 'Y');
--
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-preschool', 'quiz-type', 'english-preschool', 419, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-kindergarten', 'quiz-type', 'english-kindergarten', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade1', 'quiz-type', 'english-grade1', 421, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade2', 'quiz-type', 'english-grade2', 422, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade3', 'quiz-type', 'english-grade3', 423, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade4', 'quiz-type', 'english-grade4', 424, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade5', 'quiz-type', 'english-grade5', 425, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade6', 'quiz-type', 'english-grade6', 426, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade7', 'quiz-type', 'english-grade7', 427, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade8', 'quiz-type', 'english-grade8', 428, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade9', 'quiz-type', 'english-grade9', 429, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade10', 'quiz-type', 'english-grade10', 430, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade11', 'quiz-type', 'english-grade11', 431, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('english-grade12', 'quiz-type', 'english-grade12', 432, 'Y');
--
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-preschool', 'en', 'Math Preschool');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-kindergarten', 'en', 'Math Kindergarten');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade1', 'en', 'Math Grade 1');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade2', 'en', 'Math Grade 2');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade3', 'en', 'Math Grade 3');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade4', 'en', 'Math Grade 4');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade5', 'en', 'Math Grade 5');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade6', 'en', 'Math Grade 6');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade7', 'en', 'Math Grade 7');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade8', 'en', 'Math Grade 8');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade9', 'en', 'Math Grade 9');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade10', 'en', 'Math Grade 10');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade11', 'en', 'Math Grade 11');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('math-grade12', 'en', 'Math Grade 12');
--
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-preschool', 'en', 'English Preschool');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-kindergarten', 'en', 'English Kindergarten');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade1', 'en', 'English Grade 1');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade2', 'en', 'English Grade 2');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade3', 'en', 'English Grade 3');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade4', 'en', 'English Grade 4');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade5', 'en', 'English Grade 5');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade6', 'en', 'English Grade 6');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade7', 'en', 'English Grade 7');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade8', 'en', 'English Grade 8');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade9', 'en', 'English Grade 9');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade10', 'en', 'English Grade 10');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade11', 'en', 'English Grade 11');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('english-grade12', 'en', 'English Grade 12');
--
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MathematicalProcess', 'quiz-category', 'MathematicalProcess', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('NumberSenseAndNumeration', 'quiz-category', 'NumberSenseAndNumeration', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Measurement', 'quiz-category', 'Measurement', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('GeometryAndSpatialSense', 'quiz-category', 'GeometryAndSpatialSense', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('PatterningAndAlgebra', 'quiz-category', 'PatterningAndAlgebra', 410, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('DataManagementAndProbability', 'quiz-category', 'DataManagementAndProbability', 410, 'Y');
--
--
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('QuantityRelationships', 'quiz-subcategory', 'QuantityRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Counting', 'quiz-subcategory', 'Counting', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('OperationalSense', 'quiz-subcategory', 'OperationalSense', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('ProportionalRelationships', 'quiz-subcategory', 'ProportionalRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('AttributesUnitsAndMeasurementSense', 'quiz-subcategory', 'AttributesUnitsAndMeasurementSense', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('MeasurementRelationships', 'quiz-subcategory', 'MeasurementRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('GeometricProperties', 'quiz-subcategory', 'GeometricProperties', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('GeometricRelationships', 'quiz-subcategory', 'GeometricRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('LocationAndMovement', 'quiz-subcategory', 'LocationAndMovement', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('PatternsAndRelationships', 'quiz-subcategory', 'PatternsAndRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('VariablesExpressionsAndEquations', 'quiz-subcategory', 'VariablesExpressionsAndEquations', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('CollectionAndOrganizationOfData', 'quiz-subcategory', 'CollectionAndOrganizationOfData', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('DataRelationships', 'quiz-subcategory', 'DataRelationships', 420, 'Y');
-- INSERT INTO ref_value(value_id, table_id, value_code, display_order, active) VALUES ('Probability', 'quiz-subcategory', 'Probability', 420, 'Y');
--
--
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MathematicalProcess', 'en', 'Mathematical Process');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('NumberSenseAndNumeration', 'en', 'Number Sense and Numeration');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Measurement', 'en', 'Measurement');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('GeometryAndSpatialSense', 'en', 'Geometry and Spatial Sense');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('PatterningAndAlgebra', 'en', 'Patterning and Algebra');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('DataManagementAndProbability', 'en', 'Data Management and Probability');
--
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('QuantityRelationships', 'en', 'QuantityRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Counting', 'en', 'Counting');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('OperationalSense', 'en', 'OperationalSense');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('ProportionalRelationships', 'en', 'ProportionalRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('AttributesUnitsAndMeasurementSense', 'en', 'AttributesUnitsAndMeasurementSense');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('MeasurementRelationships', 'en', 'MeasurementRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('GeometricProperties', 'en', 'GeometricProperties');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('GeometricRelationships', 'en', 'GeometricRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('LocationAndMovement', 'en', 'LocationAndMovement');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('PatternsAndRelationships', 'en', 'PatternsAndRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('VariablesExpressionsAndEquations', 'en', 'VariablesExpressionsAndEquations');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('CollectionAndOrganizationOfData', 'en', 'CollectionAndOrganizationOfData');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('DataRelationships', 'en', 'DataRelationships');
-- INSERT INTO value_locale(value_id, language, value_desc) VALUES ('Probability', 'en', 'Probability');
--
-- INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('quiz-type-cat', 'quiz-type-category', 'quiz type to category');
-- INSERT INTO relation_type(relation_id, relation_name, relation_desc) VALUES ('quiz-cat-sub', 'quiz-cat-sub', 'quiz category to subcategory');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade1', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade2', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade3', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade4', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade5', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade6', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade7', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'MathematicalProcess');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'NumberSenseAndNumeration');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'Measurement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'GeometryAndSpatialSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'PatterningAndAlgebra');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-type-cat', 'math-grade8', 'DataManagementAndProbability');
--
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'NumberSenseAndNumeration', 'QuantityRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'NumberSenseAndNumeration', 'Counting');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'NumberSenseAndNumeration', 'OperationalSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'NumberSenseAndNumeration', 'ProportionalRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'Measurement', 'AttributesUnitsAndMeasurementSense');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'Measurement', 'MeasurementRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'GeometryAndSpatialSense', 'GeometricProperties');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'GeometryAndSpatialSense', 'GeometricRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'GeometryAndSpatialSense', 'LocationAndMovement');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'PatterningAndAlgebra', 'PatternsAndRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'PatterningAndAlgebra', 'VariablesExpressionsAndEquations');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'DataManagementAndProbability', 'CollectionAndOrganizationOfData');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'DataManagementAndProbability', 'DataRelationships');
-- INSERT INTO relation(relation_id, value_id_from, value_id_to) VALUES ('quiz-cat-sub', 'DataManagementAndProbability', 'Probability');

