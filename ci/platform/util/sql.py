import database.schema

from database.engine import ConnectionFactory


def to_dict(row, columns, tablename=None):
	if not tablename:
		return dict([(col.name, getattr(row, col.name)) for col in columns]) if row else {}
	else:
		return dict([(col.name, getattr(row, '_'.join([tablename, col.name]))) for col in columns]) if row else {}


def load_temp_strings(strings):
	temp_string = database.schema.temp_string

	delete = temp_string.delete()
	ins = temp_string.insert()

	ins_list = [{'string': str(string)} for string in strings]
	with ConnectionFactory.get_sql_connection() as sqlconn:
		sqlconn.execute(delete)
		if ins_list:
			sqlconn.execute(ins, ins_list)


class InconsistentDataError(Exception):
	pass
