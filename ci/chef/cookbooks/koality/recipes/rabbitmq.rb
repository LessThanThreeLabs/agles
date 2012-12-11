include_recipe "koality"
include_recipe "rabbitmq"

unless File.exists? "/usr/local/bin/rabbitmqadmin"
	execute "rabbitmq-plugins enable rabbitmq_management"

	service "rabbitmq-server" do
		action :restart
	end

	bash "setup rabbitmqadmin" do
		code <<-EOH
		wget --http-user=guest --http-password=guest localhost:55672/cli/rabbitmqadmin
		chmod +x rabbitmqadmin
		chown #{node[:koality][:user]} rabbitmqadmin
		mv rabbitmqadmin /usr/local/bin/rabbitmqadmin
		EOH
	end
end
