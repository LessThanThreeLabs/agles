chef_gem "ruby-shadow"

user "git" do
	system true
	password "$1$hiX0Dkyd$USCqEEofXmio5YPN7/NWE1"
	home "/"
end

directory "/git/repositories" do
	owner "git"
	recursive true
end
