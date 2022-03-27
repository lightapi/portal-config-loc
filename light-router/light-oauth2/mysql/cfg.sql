DROP DATABASE IF EXISTS cfg;
CREATE DATABASE cfg;

GRANT ALL PRIVILEGES ON cfg.* TO 'mysqluser'@'%' WITH GRANT OPTION;

USE cfg;

DROP table IF EXISTS prop;
DROP table IF EXISTS glob;
DROP table IF EXISTS glob_file;
DROP table IF EXISTS glob_cert;
DROP table IF EXISTS serv_pmod;
DROP table IF EXISTS serv_prop;
DROP table IF EXISTS serv_file;
DROP table IF EXISTS serv_cert;
DROP table IF EXISTS serv;

CREATE TABLE prop (
  host                  VARCHAR(64) NOT NULL,
  cap                   VARCHAR(64) NOT NULL,
  project               VARCHAR(64) NOT NULL,
  projver               VARCHAR(64) NOT NULL,
  scope                 VARCHAR(32) NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  porder                INT,
  PRIMARY KEY(host, cap, project, projver, scope, pkey)
);

CREATE TABLE glob (
  host                  VARCHAR(64) NOT NULL,
  cap                   VARCHAR(64) NOT NULL,
  project               VARCHAR(64) NOT NULL,
  projver               VARCHAR(64) NOT NULL,
  service               VARCHAR(128) NOT NULL,
  servver               VARCHAR(64) NOT NULL,
  env                   VARCHAR(32) NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024) NOT NULL,
  CONSTRAINT uc_pkey UNIQUE(pkey),
  PRIMARY KEY(host, cap, project, projver, service, servver, env, pkey)
);

CREATE TABLE glob_file (
  host                  VARCHAR(64) NOT NULL,
  cap                   VARCHAR(64) NOT NULL,
  project               VARCHAR(64) NOT NULL,
  projver               VARCHAR(64) NOT NULL,
  service               VARCHAR(128) NOT NULL,
  servver               VARCHAR(64) NOT NULL,
  env                   VARCHAR(32) NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               MEDIUMTEXT,
  CONSTRAINT uc_file UNIQUE(filename),
  PRIMARY KEY(host, cap, project, projver, service, servver, env, filename)
);

CREATE TABLE glob_cert (
  host                  VARCHAR(64) NOT NULL,
  cap                   VARCHAR(64) NOT NULL,
  project               VARCHAR(64) NOT NULL,
  projver               VARCHAR(64) NOT NULL,
  service               VARCHAR(128) NOT NULL,
  servver               VARCHAR(64) NOT NULL,
  env                   VARCHAR(32) NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               MEDIUMTEXT,
  CONSTRAINT uc_cert UNIQUE(filename),
  PRIMARY KEY(host, cap, project, projver, service, servver, env, filename)
);

CREATE TABLE serv (
  sid                   INT AUTO_INCREMENT PRIMARY KEY,
  host                  VARCHAR(64) NOT NULL,
  cap                   VARCHAR(64) NOT NULL,
  project               VARCHAR(64) NOT NULL,
  projver               VARCHAR(64) NOT NULL,
  service               VARCHAR(128) NOT NULL,
  servver               VARCHAR(64) NOT NULL,
  env                   VARCHAR(32) NOT NULL,
  CONSTRAINT uc_serv UNIQUE(project, projver, service, servver, env)
);

CREATE TABLE serv_prop (
  sid                   INT NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024) NOT NULL,
  PRIMARY KEY(sid, pkey)
);

ALTER TABLE serv_prop ADD FOREIGN KEY(sid) REFERENCES serv(sid);

CREATE TABLE serv_file (
  sid                   INT NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               MEDIUMTEXT,
  PRIMARY KEY(sid, filename)
);

ALTER TABLE serv_file ADD FOREIGN KEY(sid) REFERENCES serv(sid);

CREATE TABLE serv_cert (
  sid                   INT NOT NULL,
  filename              VARCHAR(64) NOT NULL,
  content               MEDIUMTEXT,
  PRIMARY KEY(sid, filename)
);

ALTER TABLE serv_cert ADD FOREIGN KEY(sid) REFERENCES serv(sid);

CREATE TABLE serv_pmod (
  sid                   INT NOT NULL,
  pkey                  VARCHAR(128) NOT NULL,
  module                VARCHAR(128) NOT NULL,
  typ                   VARCHAR(16) NOT NULL,
  rid                   VARCHAR(128) NOT NULL,
  pvalue                VARCHAR(1024),
  PRIMARY KEY(sid, pkey, module, typ, rid)
);

ALTER TABLE serv_pmod ADD FOREIGN KEY(sid, pkey) REFERENCES serv_prop(sid, pkey);
