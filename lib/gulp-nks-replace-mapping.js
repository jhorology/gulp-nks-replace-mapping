(function() {
  var $, PLUGIN_NAME, PluginError, _, _createMappingChunk, _deserializeMapping, _replaceMappingChunk, assert, fs, msgpack, reader, riffBuilder, through;

  fs = require('fs');

  assert = require('assert');

  through = require('through2');

  PluginError = require('plugin-error');

  _ = require('underscore');

  reader = require('riff-reader');

  msgpack = require('msgpack-lite');

  riffBuilder = require('./riff-builder');

  PLUGIN_NAME = 'bitwig-replace-mapping';

  // chunk id
  $ = {
    chunkId: 'NICA',
    chunkVer: 1,
    formType: 'NIKS'
  };

  module.exports = function(data, opts) {
    opts = opts || {};
    opts = _.defaults(opts, {
      type: 'NKSF' // 'NKSF' or 'JSON' or 'OBJECT'
    });
    return through.obj(function(file, enc, cb) {
      var error, originalMapping, replace, replaced, userData;
      replaced = false;
      replace = (err, userData) => {
        var chunk, error;
        if (replaced) {
          this.emit('error', new PluginError(PLUGIN_NAME, 'duplicate callback'));
          return;
        }
        replaced = true;
        if (err) {
          this.emit('error', new PluginError(PLUGIN_NAME, err));
          cb();
          retunn;
        }
        // just skip
        if (!userData) {
          cb();
          return;
        }
        try {
          chunk = _createMappingChunk(opts, userData);
          _replaceMappingChunk(file, chunk);
          this.push(file);
        } catch (error1) {
          error = error1;
          this.emit('error', new PluginError(PLUGIN_NAME, error));
        }
        cb();
      };
      if (!file) {
        replace('Files can not be empty');
        return;
      }
      if (file.isStream()) {
        replace('Streaming not supported');
        return;
      }
      if (_.isFunction(data)) {
        try {
          originalMapping = _deserializeMapping(file);
          userData = data.call(this, file, originalMapping, replace);
        } catch (error1) {
          error = error1;
          replace(error);
        }
        if (data.length <= 2) {
          return replace(void 0, userData);
        }
      } else {
        return replace(void 0, data);
      }
    });
  };

  
  // deserialize src file's NICA chunk
  _deserializeMapping = function(file) {
    var mapping, src;
    src = file.isBuffer() ? file.contents : file.path;
    mapping = void 0;
    reader(src, $.formType).readSync(function(id, data) {
      var ver;
      assert.ok(id === $.chunkId, `Unexpected chunk id. id:${id}`);
      assert.ok(_.isUndefined(mapping), "Duplicate mapping chunk.");
      ver = data.readUInt32LE(0);
      assert.ok(ver === $.chunkVer, `Unsupported format version. version:${ver}`);
      return mapping = msgpack.decode(data.slice(4));
    }, [$.chunkId]);
    assert.ok(mapping, `${$.chunkId} chunk is not contained in file.`);
    return mapping;
  };

  
  // create new NICA chunk
  _createMappingChunk = function(opts, userData) {
    var buffer, chunk, obj;
    switch (false) {
      case opts.type !== 'NKSF':
        chunk = void 0;
        reader(userData, $.formType).readSync(function(id, data) {
          var ver;
          assert.ok(id === $.chunkId, `Unexpected chunk id. id:${id}`);
          assert.ok(_.isUndefined(chunk), "Duplicate mapping chunk.");
          ver = data.readUInt32LE(0);
          assert.ok(ver === $.chunkVer, `Unsupported format version. version:${ver}`);
          return chunk = data;
        }, [$.chunkId]);
        assert.ok(chunk, `${$.chunkId} chunk is not contained in file. file:${userData}`);
        return chunk;
      case opts.type !== 'JSON':
        obj = JSON.parse(fs.readFileSync(userData, 'utf8'));
        // TODO: need validation here
        // chunk format version
        buffer = Buffer.alloc(4);
        buffer.writeUInt32LE($.chunkVer);
        // seriaize metadata to buffer
        return Buffer.concat([buffer, msgpack.encode(obj)]);
      case opts.type !== 'OBJECT':
        // TODO: need validation here
        // chunk format version
        buffer = Buffer.alloc(4);
        buffer.writeUInt32LE($.chunkVer);
        // seriaize metadata to buffer
        return Buffer.concat([buffer, msgpack.encode(userData)]);
      default:
        return assert.ok(false, `Unknown option type value. type: ${opts.type}`);
    }
  };

  
  // replace NICA chunk
  _replaceMappingChunk = function(file, chunk) {
    var riff, src;
    // riff buffer builder
    riff = riffBuilder($.formType);
    // iterate chunks
    src = file.isBuffer() ? file.contents : file.path;
    reader(src, $.formType).readSync(function(id, data) {
      if (id === $.chunkId) {
        return riff.pushChunk(id, chunk);
      } else {
        return riff.pushChunk(id, data);
      }
    });
    // output file contents
    return file.contents = riff.buffer();
  };

}).call(this);
