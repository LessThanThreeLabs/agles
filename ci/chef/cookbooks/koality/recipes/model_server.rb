supervisor_service "model_server" do
	action [:stop]
	directory "/tmp/model_server"
end

supervisor_service "redis-repostore" do
	action [:stop]
end

directory "/tmp/model_server" do
	owner node[:koality][:user]
	group node[:koality][:user]
end

supervisor_service "model_server" do
	action [:enable, :start]
	directory "/tmp/model_server"
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_model_server.py"
	user node[:koality][:user]
	priority 1
end

supervisor_service "redis-repostore" do
	action [:enable, :start]
	command "redis-server"
	user node[:koality][:user]
	priority 0
end
