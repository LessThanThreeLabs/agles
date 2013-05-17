#!/usr/bin/env python
import argparse
import time
import uuid

from sqlalchemy import *

connection_string = "postgresql://localhost/license"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("company_name", metavar='cn', type=str, help="Company name we are generating the key for")
	parser.add_argument("email", metavar='ce', type=str, help="Contact email for the company we are generating a key for")
	parser.add_argument("expiration", metavar='expires', type=str, help="Key's expiration date in unix time")
	parser.add_argument("max_instances", metavar='instances', type=str, help="Number of instances this key supports")
	args = parser.parse_args()

	engine = create_engine(connection_string)
	meta = MetaData()
	meta.reflect(bind=engine)

	company = meta.tables['company']
	license = meta.tables['license']
	query = company.select().where(company.c.name == args.company_name)

	row = engine.execute(query).first()
	if not row:
		company_ins = company.insert().values(name=args.company_name, email=args.email)
		result = engine.execute(company_ins)
		company_id = result.inserted_primary_key[0]
	else:
		company_id = row[company.c.id]

	key = uuid.uuid1().hex
	created = int(time.time())
	license_ins = license.insert().values(key=key, created=created, expires=args.expiration, instances=args.max_instances, company_id=company_id)
	engine.execute(license_ins)

	print "Generated License Key:", key


if __name__ == "__main__":
	main()
