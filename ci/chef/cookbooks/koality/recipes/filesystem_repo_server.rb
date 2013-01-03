include_recipe "koality::setuppy_install"
include_recipe "koality::git_user"

execute "Stop filesystem repo server" do
	command "killall -9 start_filesystem_repo_server.py"
	returns [0, 1]
end

directory "/tmp/repo_server" do
	owner "git"
	group "git"
end

execute "Start filesystem repo server" do
	cwd "/tmp/repo_server"
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_filesystem_repo_server.py -r #{node[:koality][:repositories_path]}&"
	user "git"
end
