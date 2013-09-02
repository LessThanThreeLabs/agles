"""Adding new special users to the database

Revision ID: 18d08ab3a7b9
Revises: 10c6543b5424
Create Date: 2013-04-19 12:42:29.446425

"""

# revision identifiers, used by Alembic.
revision = '18d08ab3a7b9'
down_revision = '10c6543b5424'

from alembic import op
import sqlalchemy as sa


from database.engine import ConnectionFactory

def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('build', u'commit_id',
              existing_type=sa.INTEGER(),
              nullable=False)
    ### end Alembic commands ###


    user = sa.sql.table('user', 
      sa.sql.column('id', sa.Integer()),
      sa.sql.column('email', sa.String()),
      sa.sql.column('first_name', sa.String()),
      sa.sql.column('last_name', sa.String()),
      sa.sql.column('password_hash', sa.String()),
      sa.sql.column('salt', sa.String()),
      sa.sql.column('github_oauth', sa.String()),
      sa.sql.column('admin', sa.Boolean()),
      sa.sql.column('created', sa.Integer()),
      sa.sql.column('deleted', sa.Integer())
    )
    op.get_bind().execute(user.delete().where(user.c.id == 1))

    query = sa.select([sa.func.count(user.c.id)]).where(user.c.id == 1)
    row = op.get_bind().execute(query).first()
    if row[0] == 0:
      op.bulk_insert(user,
        [dict(id=1, email="admin-koala@koalitycode.com", first_name="Koality", last_name="Admin",
              password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
              salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True, deleted=0)]
      )

    query = sa.select([sa.func.count(user.c.id)]).where(user.c.id == 2)
    row = op.get_bind().execute(query).first()
    if row[0] == 0:
      op.bulk_insert(user,
        [dict(id=2, email="api-koala@koalitycode.com", first_name="Koality", last_name="Api",
          password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
          salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True, deleted=0)]
      )

    query = sa.select([sa.func.count(user.c.id)]).where(user.c.id == 3)
    row = op.get_bind().execute(query).first()
    if row[0] == 0:
      op.bulk_insert(user,
        [dict(id=3, email="verify-koala@koalitycode.com", first_name="Koality", last_name="Verifier",
          password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
          salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True, deleted=0)]
      )


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('build', u'commit_id',
               existing_type=sa.INTEGER(),
               nullable=True)
    ### end Alembic commands ###
    user = sa.sql.table('user', sa.sql.column('id', sa.Integer()))
    op.get_bind().execute(user.delete().where(user.c.id == 2))
    op.get_bind().execute(user.delete().where(user.c.id == 3))
