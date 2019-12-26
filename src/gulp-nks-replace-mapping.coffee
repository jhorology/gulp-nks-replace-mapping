fs           = require 'fs'
assert       = require 'assert'
through      = require 'through2'
PluginError  = require 'plugin-error'
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

module.exports = (data, opts) ->
  opts = opts or {}
  opts = _.defaults opts,
    type: 'NKSF'    # 'NKSF' or 'JSON' or 'OBJECT'

  through.obj (file, enc, cb) ->
    replaced = off
    replace = (err, userData) =>
      if replaced
        @emit 'error', new PluginError PLUGIN_NAME, 'duplicate callback'
        return
      replaced = on
      if err
        @emit 'error', new PluginError PLUGIN_NAME, err
        cb()
        retunn
      # just skip
      unless userData
        cb()
        return
      try
        chunk =  _createMappingChunk opts, userData
        _replaceMappingChunk file, chunk
        @push file
      catch error
        @emit 'error', new PluginError PLUGIN_NAME, error
      cb()
      return

    unless file
      replace 'Files can not be empty'
      return

    if file.isStream()
      replace 'Streaming not supported'
      return
      
    if _.isFunction data
      try
        originalMapping = _deserializeMapping file
        userData = data.call @, file, originalMapping, replace
      catch error
        replace error
      if data.length <= 2
        replace undefined, userData
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
_createMappingChunk = (opts, userData) ->
  switch
    when opts.type is 'NKSF'
      chunk = undefined
      reader(userData, $.formType).readSync (id, data) ->
        assert.ok (id is $.chunkId), "Unexpected chunk id. id:#{id}"
        assert.ok (_.isUndefined chunk), "Duplicate mapping chunk."
        ver = data.readUInt32LE 0
        assert.ok ver is $.chunkVer, "Unsupported format version. version:#{ver}"
        chunk = data
      , [$.chunkId]
      assert.ok chunk, "#{$.chunkId} chunk is not contained in file. file:#{userData}"
      chunk
    when opts.type is 'JSON'
      obj = JSON.parse fs.readFileSync userData, 'utf8'
      # TODO: need validation here
      # chunk format version
      buffer = Buffer.alloc 4
      buffer.writeUInt32LE $.chunkVer
      # seriaize metadata to buffer
      Buffer.concat [buffer, msgpack.encode obj]
    when opts.type is 'OBJECT'
      # TODO: need validation here
      # chunk format version
      buffer = Buffer.alloc 4
      buffer.writeUInt32LE $.chunkVer
      # seriaize metadata to buffer
      Buffer.concat [buffer, msgpack.encode userData]
    else
      assert.ok false, "Unknown option type value. type: #{opts.type}"

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
