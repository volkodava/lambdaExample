'use strict';

var AWS = require('aws-sdk');
var exec = require('child_process').exec;
var fs = require('fs');

process.env.PATH = process.env.PATH + ':' + process.env.LAMBDA_TASK_ROOT;

var s3 = new AWS.S3();

function saveMetaDataToS3(body, bucket, key, callback) {
  console.log('Saving metadata to S3');
  s3.putObject({
    Bucket: bucket,
    Key: key,
    Body: body
  }, function (err, data) {
    if (err) callback(err);
  });
}

function extractMetadata(sourceBucket, sourceKey, localFilename, callback) {
  console.log('Extracting metadata');

  var cmd = 'bin/ffprobe -v quiet -print_format json -show_format "/tmp/' + localFilename + '"';

  exec(cmd, function(err, stdout, stderr){
    if (err) {
      console.log(stderr);
      callback(err);
    } else {
      var metadataKey = sourceKey.split('.')[0] + '.json';
      saveMetaDataToS3(stdout, sourceBucket, metadataKey, callback);
    }
  });
}

function saveFileToFileSystem(sourceBucket, sourceKey, callback){
  console.log('Saving to file system.', sourceKey);

  var localFilename = sourceKey.split('/').pop();
  var file = fs.createWriteStream('/tmp/' + localFilename);

  var stream = s3
    .getObject({
      Bucket: sourceBucket,
      Key: sourceKey})
    .createReadStream()
    .pipe(file);

  stream.on('error', function(err) {
    callback(err);
  });

  stream.on('close', function(){
    extractMetadata(sourceBucket, sourceKey, localFilename, callback);
  });
}

exports.handler = function(event, context, callback) {
  var message = JSON.parse(event.Records[0].Sns.Message);
  console.log(message);
  console.log(process.env.PATH);
  var sourceBucket = message.Records[0].s3.bucket.name;
  var sourceKey = decodeURIComponent(message.Records[0].s3.object.key.replace(/\+/g, " "));
  saveFileToFileSystem(sourceBucket, sourceKey, callback);
}
