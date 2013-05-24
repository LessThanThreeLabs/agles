"""Initial database version

Revision ID: edfe8fda35e
Revises: None
Create Date: 2013-04-02 18:50:48.566340

"""

# revision identifiers, used by Alembic.
revision = 'edfe8fda35e'
down_revision = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.create_table('system_setting',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('resource', sa.String(), nullable=False),
    sa.Column('key', sa.String(), nullable=False),
    sa.Column('value_yaml', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('resource','key')
    )
    op.create_table('temp',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('string', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('repostore',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('ip_address', sa.String(), nullable=False),
    sa.Column('repositories_path', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('ip_address','repositories_path')
    )
    op.create_table('user',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('email', sa.String(), nullable=False),
    sa.Column('first_name', sa.String(), nullable=False),
    sa.Column('last_name', sa.String(), nullable=False),
    sa.Column('password_hash', sa.String(length=88), nullable=False),
    sa.Column('salt', sa.String(length=24), nullable=False),
    sa.Column('admin', sa.Boolean(), nullable=False),
    sa.Column('created', sa.Integer(), nullable=False),
    sa.Column('deleted', sa.Integer(), nullable=False),
    sa.CheckConstraint('deleted = 0 OR id = deleted'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('email','deleted')
    )
    op.execute('alter sequence user_id_seq restart with 1000')
    op.execute('alter table "user" alter column id set default nextval(\'user_id_seq\'::regclass);')
    op.create_table('media',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('hash', sa.String(length=32), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('repo',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(), nullable=False),
    sa.Column('uri', sa.String(), nullable=False),
    sa.Column('repostore_id', sa.Integer(), nullable=False),
    sa.Column('forward_url', sa.String(), nullable=False),
    sa.Column('privatekey', sa.String(), nullable=False),
    sa.Column('publickey', sa.String(), nullable=False),
    sa.Column('created', sa.Integer(), nullable=False),
    sa.Column('deleted', sa.Integer(), nullable=False),
    sa.CheckConstraint('deleted = 0 OR id = deleted'),
    sa.ForeignKeyConstraint(['repostore_id'], ['repostore.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('uri','deleted')
    )
    op.create_table('ssh_pubkey',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('alias', sa.String(), nullable=False),
    sa.Column('ssh_key', sa.String(), nullable=False),
    sa.Column('timestamp', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['user.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('ssh_key'),
    sa.UniqueConstraint('user_id','alias')
    )
    op.create_table('commit',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('repo_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('sha', sa.String(), nullable=False),
    sa.Column('message', sa.String(), nullable=False),
    sa.Column('timestamp', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['repo_id'], ['repo.id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['user.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('change',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('commit_id', sa.Integer(), nullable=False),
    sa.Column('repo_id', sa.Integer(), nullable=False),
    sa.Column('merge_target', sa.String(), nullable=False),
    sa.Column('number', sa.Integer(), nullable=False),
    sa.Column('status', sa.String(), nullable=False),
    sa.Column('merge_status', sa.String(), nullable=True),
    sa.Column('create_time', sa.Integer(), nullable=False),
    sa.Column('start_time', sa.Integer(), nullable=True),
    sa.Column('end_time', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['commit_id'], ['commit.id'], ),
    sa.ForeignKeyConstraint(['repo_id'], ['repo.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('repo_id','number')
    )
    op.create_table('build',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('change_id', sa.Integer(), nullable=False),
    sa.Column('repo_id', sa.Integer(), nullable=False),
    sa.Column('status', sa.String(), nullable=False),
    sa.Column('create_time', sa.Integer(), nullable=False),
    sa.Column('start_time', sa.Integer(), nullable=True),
    sa.Column('end_time', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['change_id'], ['change.id'], ),
    sa.ForeignKeyConstraint(['repo_id'], ['repo.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('build_commits_map',
    sa.Column('build_id', sa.Integer(), nullable=False),
    sa.Column('commit_id', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['build_id'], ['build.id'], ),
    sa.ForeignKeyConstraint(['commit_id'], ['commit.id'], ),
    sa.PrimaryKeyConstraint()
    )
    op.create_table('build_console',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('build_id', sa.Integer(), nullable=False),
    sa.Column('repo_id', sa.Integer(), nullable=False),
    sa.Column('type', sa.String(), nullable=False),
    sa.Column('subtype', sa.String(), nullable=False),
    sa.Column('subtype_priority', sa.Integer(), nullable=False),
    sa.Column('start_time', sa.Integer(), nullable=False),
    sa.Column('end_time', sa.Integer(), nullable=True),
    sa.Column('return_code', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['build_id'], ['build.id'], ),
    sa.ForeignKeyConstraint(['repo_id'], ['repo.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('build_id','type','subtype')
    )
    op.create_table('console_output',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('build_console_id', sa.Integer(), nullable=False),
    sa.Column('line_number', sa.Integer(), nullable=False),
    sa.Column('line', sa.String(), nullable=False),
    sa.ForeignKeyConstraint(['build_console_id'], ['build_console.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('build_console_id','line_number')
    )
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('console_output')
    op.drop_table('build_console')
    op.drop_table('build_commits_map')
    op.drop_table('build')
    op.drop_table('change')
    op.drop_table('commit')
    op.drop_table('ssh_pubkey')
    op.drop_table('repo')
    op.drop_table('media')
    op.drop_table('user')
    op.drop_table('repostore')
    op.drop_table('temp')
    op.drop_table('system_setting')
    ### end Alembic commands ###
