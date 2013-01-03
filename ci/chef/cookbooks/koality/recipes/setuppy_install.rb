execute "python setup.py install" do
	command "python #{node[:koality][:source_path][:internal]}/ci/platform/setup.py install"
end