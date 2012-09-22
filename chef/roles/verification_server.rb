name "verification_server"
description "Agles verification server"
run_list(
	"recipe[python]",
	"recipe[rabbitmq]",
	"recipe[agles::verification_server]"
)
