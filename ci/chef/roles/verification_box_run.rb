name "verification_box_run"
description "Stripped down agles verification virtual box run"
run_list(
	"recipe[agles::copy_source]",
	"recipe[agles::language_config]",
	"recipe[agles::configure]"
)
