import database.schema

from database.engine import ConnectionFactory


def to_dict(row, columns, tablename=None):
	if not tablename:
		return { col.name: getattr(row, col.name) for col in columns } if row else {}
	else:
		return { col.name: getattr(row, '%s_%s' % (tablename, col.name)) for col in columns } if row else {}


def load_temp_strings(strings):
	temp_string = database.schema.temp_string

	delete = temp_string.delete()
	ins = temp_string.insert()

	ins_list = [{'value': str(string)} for string in strings]
	with ConnectionFactory.transaction_context() as sqlconn:
		sqlconn.execute(delete)
		if ins_list:
			sqlconn.execute(ins, ins_list)


def load_temp_ids(ids):
	temp_id = database.schema.temp_id

	delete = temp_id.delete()
	ins = temp_id.insert()

	ins_list = [{'value': id} for id in ids]
	with ConnectionFactory.transaction_context() as sqlconn:
		sqlconn.execute(delete)
		if ins_list:
			sqlconn.execute(ins, ins_list)

class InconsistentDataError(Exception):
	pass
