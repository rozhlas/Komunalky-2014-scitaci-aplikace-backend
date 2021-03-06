require! {
  expect: 'expect.js'
  './config.ls'
  '../src/Uploader.ls'
  request
  zlib
}
data = field1: \value1 feild2: Math.random!
uploadedList = []
uploader = new Uploader config.azure
uploader.parallelLimit = 1
describe "Uploader", (_) ->
  describe "Single operation" (_) ->
    it 'should upload a results file as JSON' (done) ->
      (err) <~ uploader.upload 9999, data
      expect err .to.be null
      done!

    it 'should set correct CORS headers' (done) ->
      (err) <~ uploader.setCors
      expect err .to.be null
      done!

    response = null
    responseBody = null
    it 'should upload the file to correct address' (done) ->
      (err, _response, _body) <~ request.get do
        url: "https://smzkomunalky.blob.core.windows.net/vysledky/9999.json"
        encoding: null
      expect err .to.be null
      response := _response
      responseBody := _body
      done!

    it 'should upload the file compressed' (done) ->
      (err, unzipped) <~ zlib.gunzip responseBody
      obj = JSON.parse unzipped
      expect obj .to.eql data
      done!

    it 'should provide correct headers' (done) ->
      expect response.headers .to.have.property \content-type \application/json
      expect response.headers .to.have.property \content-encoding \gzip
      expect response.headers .to.have.property \access-control-allow-origin "*"
      done!

  describe 'queuing' (_) ->
    it 'should work' (done) ->
      uploader.upload 9998, value: 1
      uploader.upload 9998, value: 2
      uploader.upload 9998, value: 3
      uploader.upload 9998, value: 4, -> done!
      uploader.upload 9998, value: 5, ->
        done!
      expect uploader.queue .to.have.length 1

    it 'should upload the last file' (done) ->
      (err, _response, body) <~ request.get do
        url: "https://smzkomunalky.blob.core.windows.net/vysledky/9998.json"
        encoding: null
      (err, unzipped) <~ zlib.gunzip body
      obj = JSON.parse unzipped
      expect obj.value .to.eql 5
      done!
