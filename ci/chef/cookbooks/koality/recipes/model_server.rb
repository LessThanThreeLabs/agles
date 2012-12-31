supervisor_service "model_server" do
	action [:stop]
	directory "/tmp/model_server"
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
