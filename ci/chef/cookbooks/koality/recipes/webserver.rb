package "haproxy"

bash "compile_webserver" do
	cwd "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	code <<-EOH
		./compile.sh
		cd front
		timeout 3 ./continuousCompile.sh
		exit 0
	EOH
end

supervisor_service "redisSessionStore" do
	action [:stop]
end

supervisor_service "redisCreateAccount" do
	action [:stop]
end

supervisor_service "haproxy" do
	action [:stop]
end

supervisor_service "webserver" do
	action [:stop]
end

supervisor_service "redis-sessionStore" do
	action [:enable, :start]
	command "redis-server conf/redis/sessionStoreRedis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-sessionStore_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-sessionStore_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	priority 0
end

supervisor_service "redis-createAccount" do
	action [:enable, :start]
	command "redis-server conf/redis/createAccountRedis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createAccount_stout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createAccount_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	priority 0
end

supervisor_service "haproxy" do
	action [:enable, :start]
	command "haproxy -f #{node[:koality][:source_path][:internal]}/ci/web/back/conf/haproxy/haproxy_prod.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/haproxy_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/haproxy_stderr.log"
	priority 0
end

supervisor_service "webserver" do
	action [:enable, :start]
	command "node --harmony js/index.js --httpPort 9001 --httpsPort 10443"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/webserver_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/webserver_stderr.log"
	user node[:koality][:user]
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	priority 2
end
