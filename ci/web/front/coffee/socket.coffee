window.socket = io.connect 'https://' + window.location.host + '?csrfToken=' + window.csrfToken, resource: 'socket'
