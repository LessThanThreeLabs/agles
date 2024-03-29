"""Adding email_to field to change

Revision ID: 46fcde433d7f
Revises: 2b278a305caf
Create Date: 2013-10-02 13:15:03.089675

"""

# revision identifiers, used by Alembic.
revision = '46fcde433d7f'
down_revision = '2b278a305caf'

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.add_column('change', sa.Column('email_to', sa.String(), nullable=True))
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('change', 'email_to')
    ### end Alembic commands ###
