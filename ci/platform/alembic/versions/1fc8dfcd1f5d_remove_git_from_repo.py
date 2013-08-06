"""Remove .git from repository names

Revision ID: 1fc8dfcd1f5d
Revises: 28eecd3a1b82
Create Date: 2013-07-31 15:56:04.530781

"""

# revision identifiers, used by Alembic.
revision = '1fc8dfcd1f5d'
down_revision = '28eecd3a1b82'

from alembic import op
import sqlalchemy as sa


def upgrade():
	repo = sa.sql.table('repo',
		sa.sql.column('id', sa.Integer()), sa.sql.column('name', sa.String()))
	repositories = op.get_bind().execute(repo.select())
	for repository in repositories:
		old_name = repository[repo.c.name]
		if old_name.endswith('.git'):
			new_name = old_name[:old_name.rfind('.git')]
		else:
			new_name = old_name
		op.get_bind().execute(
			repo.update().values(name=new_name).where(repo.c.id == repository[repo.c.id])
		)


def downgrade():
	repo = sa.sql.table('repo',
		sa.sql.column('id', sa.Integer()), sa.sql.column('name', sa.String()))
	repositories = op.get_bind().execute(repo.select())
	for repository in repositories:
		new_name = repository[repo.c.name]
		old_name = new_name + '.git'
		op.get_bind().execute(
			repo.update().values(name=old_name).where(repo.c.id == repository[repo.c.id])
		)
