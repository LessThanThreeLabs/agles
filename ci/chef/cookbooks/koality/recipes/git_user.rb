chef_gem "ruby-shadow"

user "git" do
	system true
	password "$1$hiX0Dkyd$USCqEEofXmio5YPN7/NWE1"
	home "/home/git"
	supports({:manage_home => true})
end

directory "/git/repositories" do
	owner "git"
	recursive true
end

bash "register own ssh key" do
	cwd "/home/git"
	user "git"
	code <<-EOH
		ssh-keygen -t rsa -N "" -f /home/git/.ssh/id_rsa -C git_user
		cat /home/git/.ssh/id_rsa.pub >> /home/git/.ssh/authorized_keys
		EOH
	not_if {File.exists?("/home/git/.ssh/id_rsa")}
end

bash "setup git user information" do
	user "git"
	code <<-EOH
		git config --global user.email "koality@koalitycode.com"
		git config --global user.name "Koality"
		EOH
end
