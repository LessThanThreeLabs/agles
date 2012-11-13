execute "Stop model server" do
	command "killall -9 start_model_server.py"
	ignore_failure true
end

execute "Start model server" do
	command "#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_model_server.py &"
	user node[:agles][:user]
end
