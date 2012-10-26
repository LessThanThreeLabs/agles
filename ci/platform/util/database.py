def to_dict(row, columns):
	return dict([(col.name, getattr(row, col.name)) for col in columns]) if row else {}
