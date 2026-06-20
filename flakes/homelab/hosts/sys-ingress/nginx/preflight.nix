''
    if ($request_method = OPTIONS ) {
        add_header 'Access-Control-Allow-Origin'  '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, HEAD, PUT, DELETE, CONNECT, TRACE, PATCH';
        add_header 'Access-Control-Allow-Headers' 'Authorization, Origin, X-Requested-With, Content-Type, Accept';

        return 200;
    }
''
