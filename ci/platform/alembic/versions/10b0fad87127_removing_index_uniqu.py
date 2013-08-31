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
    op.create_index('ix_console_output_build_console_id', 'console_output', ['build_console_id'])
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_index('ix_console_output_build_console_id', 'console_output')
    remove_dupes = """WITH cte AS (
            SELECT 
                id, ROW_NUMBER() OVER(PARTITION BY build_console_id, line_number ORDER BY id DESC) as rn
            FROM 
                console_output
        ) DELETE FROM console_output WHERE id IN (SELECT id FROM cte WHERE rn > 1)"""

    op.get_bind().execute(remove_dupes)
    op.create_unique_constraint(
    	'console_output_build_console_id_line_number_key', 
    	'console_output', 
    	['build_console_id', 'line_number']
    )
    ### end Alembic commands ###
