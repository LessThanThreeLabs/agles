include_recipe "agles"

dependencies = {
		:system_packages => ['gcc', 'g++', 'apache2-utils', 'libevent-dev'],
		:python => {
			:versions => ['2.5', '2.6', '2.7', '3.2', '3.3'],
			:packages => ['distribute', 'nose', 'sqlalchemy', 'redis', 'greenlet', 'eventlet',
				'gevent', 'psycopg2', 'argparse']
			},
		:ruby => {
			:versions => ['1.8.7', '1.9.3'],
			:packages => ['bundler', 'rspec']
			},
		:nodejs => {
			:versions => ['0.8.9'],
			:packages => ['nodetime', 'commander', 'express', 'spdy', 'cookie', 'hbs',
				'socket.io', 'redis', 'connect-redis', 'zombie', 'nodemailer']
			}
		}

apt_repository "deadsnakes" do
	uri "http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu"
	distribution node['lsb']['codename']
	components ["main"]
end

dependencies[:system_packages].each do |system_package|
	package system_package
end

dependencies[:python][:versions].each do |version|
	package "python#{version}-dev" do
		options("--force-yes")
	end
	virtualenv_name = "/home/#{node[:agles][:user]}/virtualenvs/#{version}"
	python_virtualenv virtualenv_name do
		interpreter "python#{version}"
		owner node[:agles][:user]
		group node[:agles][:user]
		action :create
	end
	dependencies[:python][:packages].each do |pip_package|
		python_pip pip_package do
			virtualenv virtualenv_name
			action :install
		end
	end
end

dependencies[:ruby][:versions].each do |version|
	rvm_ruby version
	dependencies[:ruby][:packages].each do |gem_package|
		rvm_gem gem_package do
			ruby_string version
			action :install
		end
	end
end

dependencies[:nodejs][:versions].each do |version|
	agles_nodejs version
end

# Setup postgresql local connection trusting

bash "trust local postgres" do
	code <<-EOH
	sed -r 's/^(\\w+(\\s+\\S+){2,3}\\s+)\\w+$/\\1trust/g' /etc/postgresql/9.1/main/pg_hba.conf > /etc/postgresql/9.1/main/pg_hba.conf.tmp
	mv /etc/postgresql/9.1/main/pg_hba.conf.tmp /etc/postgresql/9.1/main/pg_hba.conf
	EOH
end

service "postgresql" do
	action :reload
end
