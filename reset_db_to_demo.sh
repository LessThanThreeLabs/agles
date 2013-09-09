dropdb koality
createdb koality
psql koality -f tc_demo.db
(cd ci/platform && alembic upgrade head)
