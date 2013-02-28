execute "install_koality" do
		cwd node[:koality][:source_path][:platform]
		user "root"
		command "bash -c 'source /etc/koality/koalityrc && python setup.py install'"
end
