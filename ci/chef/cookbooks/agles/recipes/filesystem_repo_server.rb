execute "Stop filesystem repo server" do
	command "killall -9 start_filesystem_repo_server.py"
end

execute "Start filesystem repo server" do
	command "#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_filesystem_repo_server.py &"
	user "git"
end
