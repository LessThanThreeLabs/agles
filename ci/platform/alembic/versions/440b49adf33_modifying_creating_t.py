"""Modifying/creating temp tables

Revision ID: 440b49adf33
Revises: 2785518efe6e
Create Date: 2013-08-20 21:05:11.083578

"""

# revision identifiers, used by Alembic.
revision = '440b49adf33'
down_revision = '2785518efe6e'

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.create_table('temp_string',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('value', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('temp_id',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('value', sa.Integer(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.drop_table(u'temp')
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('temp_id')
    op.drop_table('temp_string')

    op.create_table(u'temp',
    sa.Column(u'id', sa.INTEGER(), nullable=False),
    sa.Column(u'string', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint(u'id', name=u'temp_pkey')
    )
    ### end Alembic commands ###
