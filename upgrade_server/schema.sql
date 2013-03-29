create table company (
	id		SERIAL PRIMARY KEY,
	name	VARCHAR NOT NULL,
	email	VARCHAR NOT NULL
);

CREATE UNIQUE INDEX company_name_unique_idx ON company (name);


create table license (
	id			SERIAL PRIMARY KEY,
	key 		VARCHAR NOT NULL,
	created		INTEGER NOT NULL,
	expires		INTEGER NOT NULL,
	instances	INTEGER NOT NULL,
	valid		BOOLEAN NOT NULL DEFAULT TRUE,
	company_id	INTEGER NOT NULL REFERENCES company(id)
);

create table server_id (
	id			SERIAL PRIMARY KEY,
	license_id	INTEGER NOT NULL REFERENCES license(id),
	server_id	VARCHAR NOT NULL
);

create table version (
	id				SERIAL PRIMARY KEY,
	version_num		VARCHAR NOT NULL,
	release_date	INTEGER NOT NULL
);
