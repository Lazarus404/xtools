var crypto = require('crypto');

function getTURNCredentials(name, secret){    
    var unixTimeStamp = parseInt(Date.now()/1000) + 24*3600,   // this credential would be valid for the next 24 hours
        username = [unixTimeStamp, name].join(':'),
        password,
        hmac = crypto.createHmac('sha1', secret);
    hmac.setEncoding('base64');
    hmac.write(username);
    hmac.end();
    password = hmac.read();
    return {
        username: username,
        password: password
    };
}

console.log(getTURNCredentials("1665139498077:webrtc", "41f5bea6-4624-11ed-b878-0242ac120002"));
