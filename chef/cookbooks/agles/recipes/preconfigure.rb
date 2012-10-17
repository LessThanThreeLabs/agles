apt_repository "deadsnakes" do
	uri "http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu"
	distribution node['lsb']['codename']
	components ["main"]
end

package "python2.7"
