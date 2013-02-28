include_recipe "koality::setuppy_install"

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
	command "bash -c 'source /etc/koality/koalityrc && #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_model_server.py'"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/model_server_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/model_server_stderr.log"
	user node[:koality][:user]
	priority 2
end
