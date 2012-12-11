name "verification_box_run"
description "Stripped down koality verification virtual box run"
run_list(
	"recipe[koality::copy_source]",
	"recipe[koality::language_config]",
	"recipe[koality::compile_config]",
	"recipe[koality::test_config]",
	"recipe[koality::setup_config]"
)
