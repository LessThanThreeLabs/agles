package "haproxy"

bash "compile_webserver" do
	cwd "#{node[:koality][:source_path][:internal]}/ci/web/back"
	code <<-EOH
		./compile.sh
		cd front
		timeout 3 ./continuousCompile.sh
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

supervisor_service "redisSessionStore" do
	action [:enable, :start]
	command "redis-server conf/redis/sessionStoreRedis.conf"                                                                                                                                                                                                                     
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	priority 0
end

supervisor_service "redisCreateAccount" do
	action [:enable, :start]
	command "redis-server conf/redis/createAccountRedis.conf"                                                                                                                                                                                                                     
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	user node[:koality][:user]
	priority 0
end

supervisor_service "haproxy" do
	action [:enable, :start]
	command "haproxy -f #{node[:koality][:source_path][:internal]}/ci/web/back/conf/haproxy/haproxy_prod.conf"
	priority 0
end

supervisor_service "webserver" do
	action [:enable, :start]
	command "node --harmony js/index.js --httpPort 9001 --httpsPort 10443"
	user node[:koality][:user]
	directory "#{node[:koality][:source_path][:internal]}/ci/web/back"
	priority 2
end
