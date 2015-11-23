fs           = require 'fs'
assert       = require 'assert'
through      = require 'through2'
gutil        = require 'gulp-util'
_            = require 'underscore'
reader       = require 'riff-reader'
msgpack      = require 'msgpack-lite'
riffBuilder  = require './riff-builder'

PLUGIN_NAME = 'bitwig-replace-mapping'

# chunk id
$ =
 chunkId: 'NICA'
 chunkVer: 1
 formType: 'NIKS'

module.exports = (opts, data) ->
  opts = _.defaults opts,
    mapping_src: 'NKSF'    # 'NKSF' or 'JSON' or 'OBJECT'
    
  through.obj (file, enc, cb) ->
    replaced = off
    replace = (err, src) =>
      if replaced
        @emit 'error', new gutil.PluginError PLUGIN_NAME, 'duplicate callback'
        return
      replaced = on
      if err
        @emit 'error', new gutil.PluginError PLUGIN_NAME, err
        return cb()
      # just skip
      unless src
        return cb()
      try
        chunk =  _createMappingChunk opts, src
        _replaceMappingChunk file, chunk
        @push file
      catch error
        @emit 'error', new gutil.PluginError PLUGIN_NAME, error
      cb()

    unless file
      replace 'Files can not be empty'
      return

    if file.isStream()
      replace 'Streaming not supported'
      return
      
    if _.isFunction data
      try
        mapping = _deserializeMapping file
        src = data.call @, file, mapping, replace
      catch error
        replace error
      if data.length <= 2
        replace undefined, src
    else
      replace undefined, data

#
# deserialize src file's NICA chunk
_deserializeMapping = (file) ->
  src = if file.isBuffer() then file.contents else file.path
  mapping = undefined
  reader(src, $.formType).readSync (id, data) ->
    assert.ok (id is $.chunkId), "Unexpected chunk id. id:#{id}"
    assert.ok (_.isUndefined mapping), "Duplicate mapping chunk."
    ver = data.readUInt32LE 0
    assert.ok ver is $.chunkVer, "Unsupported format version. version:#{ver}"
    mapping = msgpack.decode data.slice 4
  , [$.chunkId]

  assert.ok mapping, "#{$.chunkId} chunk is not contained in file."
  mapping

#
# create new NICA chunk
_createMappingChunk = (opts, src) ->
  switch
    when opts.mapping_src is 'NKSF'
      chunk = undefined
      reader(src, $.formType).readSync (id, data) ->
        assert.ok (id is $.chunkId), "Unexpected chunk id. id:#{id}"
        assert.ok (_.isUndefined chunk), "Duplicate mapping chunk."
        ver = data.readUInt32LE 0
        assert.ok ver is $.chunkVer, "Unsupported format version. version:#{ver}"
        chunk = data
      , [$.chunkId]
      assert.ok chunk, "#{$.chunkId} chunk is not contained in file. file:#{src}"
      chunk
    when opts.mapping_src is 'JSON'
      obj = JSON.parse fs.readFileSync src, 'utf8'
      # TODO: need validation here
      # chunk format version
      buffer = new Buffer 4
      buffer.writeUInt32LE $.chunkVer
      # seriaize metadata to buffer
      Buffer.concat [buffer, msgpack.encode obj]
    when opts.mapping_src is 'OBJECT'
      # TODO: need validation here
      # chunk format version
      buffer = new Buffer 4
      buffer.writeUInt32LE $.chunkVer
      # seriaize metadata to buffer
      Buffer.concat [buffer, msgpack.encode src]
    else
      assert.ok false, "Unknown option mapping_src value. mapping_src: #{opts.mapping_src}"

#
# replace NICA chunk
_replaceMappingChunk = (file, chunk) ->
  # riff buffer builder
  riff = riffBuilder $.formType
  # iterate chunks
  src = if file.isBuffer() then file.contents else file.path
  reader(src, $.formType).readSync (id, data) ->
    if id is $.chunkId
      riff.pushChunk id, chunk
    else
      riff.pushChunk id, data
  # output file contents
  file.contents = riff.buffer()
