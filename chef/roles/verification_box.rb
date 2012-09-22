name "verification_box"
description "Agles verification virtual box"
run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[agles::verification_box]"
)
