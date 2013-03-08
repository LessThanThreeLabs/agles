if not File.exists? "/usr/local/sbin/haproxy"
	remote_file "/tmp/haproxy-1.5-dev17.tar.gz" do
		source "http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-1.5-dev17.tar.gz"
		mode "0644"
	end

	bash "install haproxy-1.5" do
		user "root"
		cwd "/tmp"
		code <<-EOH
			tar -xf /tmp/haproxy-1.5-dev17.tar.gz
			cd haproxy-1.5-dev17
			make clean
			make install USE_OPENSSL=1 -j 4
		EOH
	end
end

bash "compile_webserver" do
	cwd "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	environment "HOME" => "/home/#{node[:koality][:user]}"
	code <<-EOH
		source ~/.bash_profile
		./compile.sh
		cd front
		./compile.sh
		exit 0
	EOH
end

supervisor_service "redis-sessionStore" do
	action [:stop]
end

supervisor_service "redis-createAccount" do
	action [:stop]
end

supervisor_service "redis-createRepository" do
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
	command "redis-server #{node[:koality][:source_path][:internal]}/ci/web/back/conf/redis/sessionStoreRedis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-sessionStore_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-sessionStore_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/production"
	user node[:koality][:user]
	priority 0
end

supervisor_service "redis-createAccount" do
	action [:enable, :start]
	command "redis-server #{node[:koality][:source_path][:internal]}/ci/web/back/conf/redis/createAccountRedis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createAccount_stout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createAccount_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/production"
	user node[:koality][:user]
	priority 0
end

supervisor_service "redis-createRepository" do
	action [:enable, :start]
	command "redis-server #{node[:koality][:source_path][:internal]}/ci/web/back/conf/redis/createRepositoryRedis.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createRepository_stout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/redis-createRepository_stderr.log"
	directory "#{node[:koality][:source_path][:internal]}/ci/production"
	user node[:koality][:user]
	priority 0
end

supervisor_service "haproxy" do
	action [:enable, :start]
	command "haproxy -f #{node[:koality][:source_path][:internal]}/ci/web/back/conf/haproxy/haproxy.conf"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/haproxy_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/haproxy_stderr.log"
	priority 0
end

supervisor_service "webserver" do
	action [:enable, :start]
	command "bash -c 'source /etc/koality/koalityrc && node --harmony js/index.js --httpsPort 10443 --mode production'"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/webserver_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/webserver_stderr.log"
	user node[:koality][:user]
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	priority 2
end
