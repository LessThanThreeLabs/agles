chef_gem "ruby-shadow"

user "git" do
	system true
	password "$1$hiX0Dkyd$USCqEEofXmio5YPN7/NWE1"
	home "/home/git"
end

directory "/git/repositories" do
	owner "git"
	recursive true
end

bash "register own ssh key" do
	cwd "/home/git"
	user "git"
	code <<-EOH
		ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -C gituser
		cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
		EOH
	not_if {File.exists?("/home/git/.ssh/id_rsa")}
end
