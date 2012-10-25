include_recipe "agles"

apt_repository "deadsnakes" do
	uri "http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu"
	distribution node['lsb']['codename']
	components ["main"]
end

python_versions = ['2.5', '2.6', '2.7', '3.2', '3.3']

python_versions.each do |version|
	package "python#{version}" do
		options("--force-yes")
	end
	python_virtualenv "/home/#{node[:agles][:user]}/#{version}" do
		interpreter "python#{version}"
		owner node[:agles][:user]
		group node[:agles][:user]
		action :create
	end
end

ruby_versions = ['1.8.7', '1.9.3']

ruby_versions.each do |version|
	rvm_ruby version
end

node_versions = ['v0.8.9']

node_versions.each do |version|
	agles_nodejs version
end

# Setup postgresql local connection trusting

bash "trust local postgres" do
	code <<-EOH
	sed -r 's/^(\\w+\\s+\\w+\\s+\\w+\\s+\\S+)\\w+$/\\1trust/g' /etc/postgresql/9.1/main/pg_hba.conf > /etc/postgresql/9.1/main/pg_hba.conf.tmp
	sed -r 's/^(\\w+\\s+\\w+\\s+\\w+\\s+)\\w+$/\\1trust/g' /etc/postgresql/9.1/main/pg_hba.conf.tmp > /etc/postgresql/9.1/main/pg_hba.conf
	rm /etc/postgresql/9.1/main/pg_hba.conf.tmp
	EOH
end

service "postgresql" do
	action :reload
end
