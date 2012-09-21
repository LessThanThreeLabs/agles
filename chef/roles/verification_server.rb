name "verification_server"
description "Agles verification server"
run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[agles::verification]"
)
