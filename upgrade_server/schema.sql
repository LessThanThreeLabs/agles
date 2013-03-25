create table company (
	id		SERIAL PRIMARY KEY,
	name	VARCHAR NOT NULL,
	contact	VARCHAR NOT NULL
);

create table license (
	id			SERIAL PRIMARY KEY,
	key 		VARCHAR NOT NULL,
	created		INTEGER NOT NULL,
	expires		INTEGER NOT NULL,
	company_id	INTEGER NOT NULL REFERENCES company(id)
);

create table version (
	id				SERIAL PRIMARY KEY,
	version_num		VARCHAR NOT NULL,
	release_date	INTEGER NOT NULL
)
