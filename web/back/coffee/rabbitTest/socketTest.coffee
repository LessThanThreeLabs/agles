os = require 'os'
cluster = require 'cluster'

numWorkers = os.cpus().length
cluster.setupMaster exec: "js/rabbitTest/socketTestWorker"
cluster.fork() for num in [0...numWorkers]
