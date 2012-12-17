execute "Stop model server" do
	command "killall -9 start_model_server.py"
	returns [0, 1]
end

directory "/tmp/model_server" do
	owner node[:koality][:user]
	group node[:koality][:user]
end

execute "Start model server" do
	cwd "/tmp/model_server"
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_model_server.py &"
	user node[:koality][:user]
end
