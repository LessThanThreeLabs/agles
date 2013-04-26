execute "install_koality" do
		cwd node[:koality][:source_path][:platform]
		user "root"
		command "/etc/koality/python setup.py install'"
end
