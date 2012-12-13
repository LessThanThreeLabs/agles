chef_gem "ruby-shadow"

user "verification" do
	system true
	password "$1$hiX0Dkyd$USCqEEofXmio5YPN7/NWE1"
	home "/home/verification"
	supports({:manage_home => true})
end

directory "/verification" do
	owner "verification"
end
