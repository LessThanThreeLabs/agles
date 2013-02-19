(rabbitmqctl list_users -q | grep '^lt3') > /dev/null || rabbitmqctl add_user lt3 42f6e8eacf66b9ee7c7b0a5b6a0e1498f7c0d42f
rabbitmqctl set_user_tags lt3 administrator
rabbitmqctl set_permissions lt3 '.*' '.*' '.*'
# rabbitmqctl list_users -q | while read username tags; do
# 	[ $username == 'lt3' ] || rabbitmqctl delete_user $username
# done
