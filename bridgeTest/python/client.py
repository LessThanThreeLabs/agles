from BridgePython.bridge import Bridge 


bridge = Bridge(api_key='dfikjjgmhmdahhlg', host='127.0.0.1', port=8090)

def helloCallback(msg):
    print msg
    
helloService = bridge.get_service('helloWorld')
helloService.hello(helloCallback)

bridge.connect()
print 'python bridge client running!!'