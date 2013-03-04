include_recipe "koality::setuppy_install"
include_recipe "koality::git_user"


supervisor_service "filesystem_repo_server" do
	action [:stop]
	directory "/tmp/repo_server"
end

supervisor_service "redis-repostore" do
	action [:stop]
end

directory "/tmp/repo_server" do
	owner "git"
	group "git"
end

supervisor_service "redis-repostore" do
	action [:enable, :start]
	command "redis-server #{node[:koality][:source_path][:internal]}/ci/platform/conf/redis/filesystem_repo_server_redis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-repostore_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-repostore_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/production"
	user node[:koality][:user]
	priority 0
end

supervisor_service "filesystem_repo_server" do
	action [:enable, :start]
	directory "/tmp/repo_server"
	command "/etc/koality/python #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_filesystem_repo_server.py -r #{node[:koality][:repositories_path]}"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/filesystem_repo_server_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/filesystem_repo_server_stderr.log"
	user "git"
	priority 1
end
