include_recipe "koality::git_user"

execute "Stop filesystem repo server" do
	command "killall -9 start_filesystem_repo_server.py"
	returns [0, 1]
end

execute "Start filesystem repo server" do
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_filesystem_repo_server.py -r #{node[:koality][:repositories_path]}&"
	user "git"
end
