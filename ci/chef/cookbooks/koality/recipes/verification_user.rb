include_recipe "rvm"

chef_gem "ruby-shadow"

user "verification" do
	system true
	password "$1$hiX0Dkyd$USCqEEofXmio5YPN7/NWE1"
	home "/home/verification"
	supports({:manage_home => true})
end

directory "/verification" do
	owner "verification"
	mode "0777"
end

bash "generate ssh key" do
	cwd "/home/verification"
	user "verification"
	code <<-EOH
		mkdir -p /home/verification/.ssh
		ssh-keygen -t rsa -N "" -f /home/verification/.ssh/id_rsa -C verification_user
		EOH
	not_if {File.exists?("/home/verification/.ssh/id_rsa")}
end
