#!/bin/bash
username=lt3
password=42f6e8eacf66b9ee7c7b0a5b6a0e1498f7c0d42f
if [ "$(rabbitmqctl list_users -q | grep "^$username")" ]; then
	rabbitmqctl change_password $username $password
else
	rabbitmqctl add_user $username $password
fi
rabbitmqctl set_user_tags $username administrator
rabbitmqctl set_permissions $username '.*' '.*' '.*'
if [ "$(rabbitmqctl list_users -q | grep '^guest')" ]; then
	rabbitmqctl delete_user guest
fi
