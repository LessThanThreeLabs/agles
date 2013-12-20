"""Add hook types to github repo metadata

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
	op.add_column('github_repo_metadata', sa.Column('hook_push_enabled', sa.Boolean(), nullable=True))
	op.add_column('github_repo_metadata', sa.Column('hook_pull_request_enabled', sa.Boolean(), nullable=True))

	github_repo_metadata = sa.sql.table('github_repo_metadata',
		sa.sql.column('id', sa.Integer()), sa.sql.column('hook_id', sa.Integer()),
		sa.sql.column('hook_push_enabled', sa.Boolean()), sa.sql.column('hook_pull_request_enabled', sa.Boolean()))

	op.get_bind().execute(
		github_repo_metadata.update().values(hook_push_enabled=False, hook_pull_request_enabled=False)
	)
	op.get_bind().execute(
		github_repo_metadata.update().values(hook_push_enabled=True, hook_pull_request_enabled=False).where(github_repo_metadata.c.hook_id != None)
	)

	op.alter_column('github_repo_metadata', 'hook_push_enabled', nullable=False)
	op.alter_column('github_repo_metadata', 'hook_pull_request_enabled', nullable=False)


def downgrade():
	op.drop_column('github_repo_metadata', 'hook_push_enabled')
	op.drop_column('github_repo_metadata', 'hook_pull_request_enabled')
