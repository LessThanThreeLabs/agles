"""Removing index/unique key from console_output

Revision ID: 10b0fad87127
Revises: 13544094392b
Create Date: 2013-08-28 16:30:08.236654

"""

# revision identifiers, used by Alembic.
revision = '10b0fad87127'
down_revision = '13544094392b'

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint('console_output_build_console_id_line_number_key', 'console_output')
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.create_unique_constraint(
    	'console_output_build_console_id_line_number_key', 
    	'console_output', 
    	['build_console_id', 'line_number']
    )
    ### end Alembic commands ###
