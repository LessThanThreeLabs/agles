"""Add commit type base_sha

Revision ID: 1850579c138
Revises: 3f18d444f38f
Create Date: 2013-08-14 14:14:42.284484

"""

# revision identifiers, used by Alembic.
revision = '1850579c138'
down_revision = '3f18d444f38f'

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.add_column('commit', sa.Column('base_sha', sa.String(), nullable=True))
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('commit', 'base_sha')
    ### end Alembic commands ###