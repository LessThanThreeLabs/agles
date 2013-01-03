execute "install_koality" do
		cwd node[:koality][:source_path][:platform]
		user "root"
		command "python setup.py install"
end
