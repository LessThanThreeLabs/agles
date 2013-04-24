"""Encrypt database settings

Revision ID: 1173ebf00891
Revises: 51208e23491
Create Date: 2013-04-23 18:55:26.872211

"""

# revision identifiers, used by Alembic.
revision = '1173ebf00891'
down_revision = '51208e23491'

from alembic import op
import sqlalchemy as sa

import base64
import binascii
import yaml

from Crypto.Cipher import AES


system_settings_cipher = AES.new(binascii.unhexlify('6B9945583AF2F9DE00D9EF1FABCCFA30CF84AA4E855E12DC448B277D7C65D90F'))


def upgrade():
	op.add_column('system_setting', sa.Column('value', sa.String(), nullable=True))

	system_setting = sa.sql.table('system_setting',
		sa.sql.column('id', sa.Integer()), sa.sql.column('value', sa.String()), sa.sql.column('value_yaml', sa.String()))
	settings = op.get_bind().execute(system_setting.select())
	for setting in settings:
		old_value = yaml.safe_load(setting[system_setting.c.value_yaml])
		new_value = dump(old_value)
		op.get_bind().execute(
			system_setting.update().values(value=new_value).where(system_setting.c.id == setting[system_setting.c.id])
		)

	op.alter_column('system_setting', 'value', nullable=False)
	op.drop_column('system_setting', 'value_yaml')


def downgrade():
	op.add_column('system_setting', sa.Column('value_yaml', sa.String(), nullable=True))

	system_setting = sa.sql.table('system_setting',
		sa.sql.column('id', sa.Integer()), sa.sql.column('value', sa.String()), sa.sql.column('value_yaml', sa.String()))
	settings = op.get_bind().execute(system_setting.select())
	for setting in settings:
		new_value = load(setting[system_setting.c.value])
		old_value = yaml.safe_dump(new_value)
		op.get_bind().execute(
			system_setting.update().values(value_yaml=old_value).where(system_setting.c.id == setting[system_setting.c.id])
		)

	op.alter_column('system_setting', 'value_yaml', nullable=False)
	op.drop_column('system_setting', 'value')


def dump(setting):
	return base64.encodestring(system_settings_cipher.encrypt(_pad(yaml.safe_dump(setting))))


def load(setting):
	return yaml.safe_load(system_settings_cipher.decrypt(base64.decodestring(setting)))


def _pad(setting):
	return setting + ((system_settings_cipher.block_size - len(setting) % system_settings_cipher.block_size) * '\n')
