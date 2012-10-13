name "verification_box"
description "Agles verification virtual box"
run_list(
	"recipe[python]",
	"recipe[agles::copy_source]",
	"recipe[agles::configure]",
	"recipe[agles::verification_box]"
)
