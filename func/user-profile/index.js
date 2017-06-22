'use strict';
var jwt = require('jsonwebtoken');
var request = require('request');

exports.handler = function(event, context, callback) {
  if (!event.authToken) {
    callback('Could not find token');
    return;
  }

  var token = event.authToken.split(' ')[1];

  jwt.verify(token, process.env.AUTH0_SECRET, function(err, decoded) {
    if (err) {
      console.log('Failed jwt verification: ', err, 'auth: ', event.authToken);
      callback('Authorization Failed');
    } else {

      var body = {
        'id_token': token
      };

      var options = {
        url: 'https://' + process.env.DOMAIN + '/tokeninfo',
        method: 'POST',
        json: true,
        body: body
      };

      request(options, function(err, response, body){
        if (err) {
          callback(err);
        } else if (response.statusCode === 200) {
          callback(null, body);
        }
      });
    }
  });
}
