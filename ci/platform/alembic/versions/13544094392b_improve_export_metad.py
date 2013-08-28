"""Improve export metadata table

Revision ID: 13544094392b
Revises: 440b49adf33
Create Date: 2013-08-23 19:17:25.935686

"""

# revision identifiers, used by Alembic.
revision = '13544094392b'
down_revision = '440b49adf33'

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.create_table('build_export_metadata',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('build_id', sa.Integer(), nullable=False),
        sa.Column('uri', sa.String(), nullable=False),
        sa.Column('path', sa.String(), nullable=False),
        sa.ForeignKeyConstraint(['build_id'], ['build.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('build_id','path'),
        sa.UniqueConstraint('build_id','uri')
    )
    op.drop_table(u'change_export_uri')
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.create_table(u'change_export_uri',
        sa.Column(u'id', sa.INTEGER(), nullable=False),
        sa.Column(u'change_id', sa.INTEGER(), autoincrement=False, nullable=False),
        sa.Column(u'uri', sa.VARCHAR(), autoincrement=False, nullable=False),
        sa.ForeignKeyConstraint(['change_id'], [u'change.id'], name=u'change_export_uri_change_id_fkey'),
        sa.PrimaryKeyConstraint(u'id', name=u'change_export_uri_pkey')
    )
    op.drop_table('build_export_metadata')
    ### end Alembic commands ###
