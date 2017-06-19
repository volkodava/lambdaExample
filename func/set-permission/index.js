var AWS = require('aws-sdk');
var s3 = new AWS.S3();

exports.handler = function(evt, ctx, cb) {
  var msg = JSON.parse(evt.Records[0].Sns.Message);

  var sourceBucket = msg.Records[0].s3.bucket.name;
  var sourceKey = decodeURIComponent(msg.Records[0].s3.object.key.replace(/\+/g, " "))

  var params = {
    Bucket: sourceBucket,
    Key: sourceKey,
    ACL: 'public-read'
  };

  s3.putObjectAcl(params, function(err, data){
    if (err) cb(err);
  });
};
