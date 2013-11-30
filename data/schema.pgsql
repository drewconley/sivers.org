BEGIN;

CREATE SCHEMA sivers;
SET search_path = sivers;

CREATE TABLE comments (
	id serial primary key,
	uri varchar(32) not null,
	person_id integer not null REFERENCES peeps.people(id),
	created_at date not null default CURRENT_DATE,
	html text not null,
	name text,
	url text,
	email text,
	ip varchar(15)
);
CREATE INDEX comuri ON comments(uri);
CREATE INDEX compers ON comments(person_id);

COMMIT;
