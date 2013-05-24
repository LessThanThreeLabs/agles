"""Remove ssh keypairs from repositories

Revision ID: 1bfd6fb94938
Revises: 1173ebf00891
Create Date: 2013-05-21 12:22:25.278628

"""

# revision identifiers, used by Alembic.
revision = '1bfd6fb94938'
down_revision = '1173ebf00891'

from alembic import op
import sqlalchemy as sa


def upgrade():
	### commands auto generated by Alembic - please adjust! ###
	op.drop_column('repo', u'publickey')
	op.drop_column('repo', u'privatekey')
	### end Alembic commands ###


def downgrade():
	op.add_column('repo', sa.Column(u'privatekey', sa.VARCHAR()))
	op.add_column('repo', sa.Column(u'publickey', sa.VARCHAR()))
	repo = sa.sql.table('repo',
		sa.Column('privatekey', sa.VARCHAR()),
		sa.Column('publickey', sa.VARCHAR()))
	op.get_bind().execute(
		repo.update().values(privatekey='Unsupported downgrade', publickey='Unsupported downgrade')
	)
	### end Alembic commands ###
