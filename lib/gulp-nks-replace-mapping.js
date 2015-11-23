(function() {
  var $, PLUGIN_NAME, _, _createMappingChunk, _deserializeMapping, _replaceMappingChunk, assert, fs, gutil, msgpack, reader, riffBuilder, through;

  fs = require('fs');

  assert = require('assert');

  through = require('through2');

  gutil = require('gulp-util');

  _ = require('underscore');

  reader = require('riff-reader');

  msgpack = require('msgpack-lite');

  riffBuilder = require('./riff-builder');

  PLUGIN_NAME = 'bitwig-replace-mapping';

  $ = {
    chunkId: 'NICA',
    chunkVer: 1,
    formType: 'NIKS'
  };

  module.exports = function(opts, data) {
    opts = _.defaults(opts, {
      mapping_src: 'NKSF'
    });
    return through.obj(function(file, enc, cb) {
      var error, error1, mapping, replace, replaced, src;
      replaced = false;
      replace = (function(_this) {
        return function(err, src) {
          var chunk, error, error1;
          if (replaced) {
            _this.emit('error', new gutil.PluginError(PLUGIN_NAME, 'duplicate callback'));
            return;
          }
          replaced = true;
          if (err) {
            _this.emit('error', new gutil.PluginError(PLUGIN_NAME, err));
            return cb();
          }
          if (!src) {
            return cb();
          }
          try {
            chunk = _createMappingChunk(opts, src);
            _replaceMappingChunk(file, chunk);
            _this.push(file);
          } catch (error1) {
            error = error1;
            _this.emit('error', new gutil.PluginError(PLUGIN_NAME, error));
          }
          return cb();
        };
      })(this);
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
          mapping = _deserializeMapping(file);
          src = data.call(this, file, mapping, replace);
        } catch (error1) {
          error = error1;
          replace(error);
        }
        if (data.length <= 2) {
          return replace(void 0, src);
        }
      } else {
        return replace(void 0, data);
      }
    });
  };

  _deserializeMapping = function(file) {
    var mapping, src;
    src = file.isBuffer() ? file.contents : file.path;
    mapping = void 0;
    reader(src, $.formType).readSync(function(id, data) {
      var ver;
      assert.ok(id === $.chunkId, "Unexpected chunk id. id:" + id);
      assert.ok(_.isUndefined(mapping), "Duplicate mapping chunk.");
      ver = data.readUInt32LE(0);
      assert.ok(ver === $.chunkVer, "Unsupported format version. version:" + ver);
      return mapping = msgpack.decode(data.slice(4));
    }, [$.chunkId]);
    assert.ok(mapping, $.chunkId + " chunk is not contained in file.");
    return mapping;
  };

  _createMappingChunk = function(opts, src) {
    var buffer, chunk, obj;
    switch (false) {
      case opts.mapping_src !== 'NKSF':
        chunk = void 0;
        reader(src, $.formType).readSync(function(id, data) {
          var ver;
          assert.ok(id === $.chunkId, "Unexpected chunk id. id:" + id);
          assert.ok(_.isUndefined(chunk), "Duplicate mapping chunk.");
          ver = data.readUInt32LE(0);
          assert.ok(ver === $.chunkVer, "Unsupported format version. version:" + ver);
          return chunk = data;
        }, [$.chunkId]);
        assert.ok(chunk, $.chunkId + " chunk is not contained in file. file:" + src);
        return chunk;
      case opts.mapping_src !== 'JSON':
        obj = JSON.parse(fs.readFileSync(src, 'utf8'));
        buffer = new Buffer(4);
        buffer.writeUInt32LE($.chunkVer);
        return Buffer.concat([buffer, msgpack.encode(obj)]);
      case opts.mapping_src !== 'OBJECT':
        buffer = new Buffer(4);
        buffer.writeUInt32LE($.chunkVer);
        return Buffer.concat([buffer, msgpack.encode(src)]);
      default:
        return assert.ok(false, "Unknown option mapping_src value. mapping_src: " + opts.mapping_src);
    }
  };

  _replaceMappingChunk = function(file, chunk) {
    var riff, src;
    riff = riffBuilder($.formType);
    src = file.isBuffer() ? file.contents : file.path;
    reader(src, $.formType).readSync(function(id, data) {
      if (id === $.chunkId) {
        return riff.pushChunk(id, chunk);
      } else {
        return riff.pushChunk(id, data);
      }
    });
    return file.contents = riff.buffer();
  };

}).call(this);
