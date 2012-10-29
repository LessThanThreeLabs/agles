name "verification_box_run"
description "Agles verification virtual box run"
run_list(
	"recipe[agles::language_config]",
	"recipe[agles::configure]"
)
