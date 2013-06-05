"""Rename change status column to verification_status

Revision ID: 28eecd3a1b82
Revises: 1bfd6fb94938
Create Date: 2013-06-05 14:14:49.701925

"""

# revision identifiers, used by Alembic.
revision = '28eecd3a1b82'
down_revision = '1bfd6fb94938'

from alembic import op


def upgrade():
    op.alter_column('change', 'status', new_column_name='verification_status')


def downgrade():
    op.alter_column('change', 'verification_status', new_column_name='status')
