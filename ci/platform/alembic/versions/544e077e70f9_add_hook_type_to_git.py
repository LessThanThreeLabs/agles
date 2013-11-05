"""Add hook type to github repo metadata

Revision ID: 544e077e70f9
Revises: 46fcde433d7f
Create Date: 2013-11-04 17:43:47.709503

"""

# revision identifiers, used by Alembic.
revision = '544e077e70f9'
down_revision = '46fcde433d7f'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('github_repo_metadata', sa.Column('hook_type', sa.String(), nullable=True))

    github_repo_metadata = sa.sql.table('github_repo_metadata',
		sa.sql.column('id', sa.Integer()), sa.sql.column('hook_id', sa.Integer()), sa.sql.column('hook_type', sa.String()))

    github_repo_metadata.update().values(hook_type='push').where(github_repo_metadata.c.hook_id != None)


def downgrade():
    op.drop_column('github_repo_metadata', 'hook_type')
