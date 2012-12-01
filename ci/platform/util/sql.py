def to_dict(row, columns, tablename=None):
	if not tablename:
		return dict([(col.name, getattr(row, col.name)) for col in columns]) if row else {}
	else:
		return dict([(col.name, getattr(row, '_'.join([tablename, col.name]))) for col in columns]) if row else {}

class InconsistentDataError(Exception):
	pass
