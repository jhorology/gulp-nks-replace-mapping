fs          = require 'fs'
gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
del         = require 'del'
watch       = require 'gulp-watch'
extract     = require 'gulp-riff-extractor'
rename      = require 'gulp-rename'
data        = require 'gulp-data'
exec        = require 'gulp-exec'
msgpack     = require 'msgpack-lite'

beautify    = require 'js-beautify'

# paths, misc settings
$ =
  execOpts:
    continueOnError: false # default = false, true means don't emit error event
    pipeStdout: false      # default = false, true means stdout is written to file.contents
  execReportOpts:
    err: true              # default = true, false means don't write err
    stderr: true           # default = true, false means don't write stderr
    stdout: true           # default = true, false means don't write stdout

gulp.task 'coffeelint', ->
  gulp.src ['./*.coffee', './src/*.coffee']
    .pipe coffeelint './coffeelint.json'
    .pipe coffeelint.reporter()

gulp.task 'coffee', ['coffeelint'], ->
  gulp.src ['./src/*.coffee']
    .pipe coffee()
    .pipe gulp.dest './lib'

gulp.task 'default', ['coffee']

gulp.task 'watch', ->
  gulp.watch './**/*.coffee', ['default']
 
gulp.task 'clean', (cb) ->
  del ['./lib/*.js', './**/*~', 'test_out'], force: true, cb

gulp.task 'test', [
  'test-nksf-1'
  'test-nksf-2'
  'test-nksf-3'
  'test-json-1'
  'test-json-2'
  'test-json-3'
  'test-object-1'
  'test-object-2'
  'test-object-3'
  ]
, ->
  gulp.src ['./test_out/*.nksf']
    .pipe exec [
      'echo Compairing "<%= file.relative%>" : "test/sample.nksf"'
      'cmp -b "<%= file.path%>" "test/sample.nksf"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts
      

# print test data
gulp.task 'print-sample-mapping', ['default'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace undefined, (file, mapping) ->
      console.info beautify (JSON.stringify mapping), indent_size: 2
      undefined

# prepare test data
gulp.task 'extract-sample-mapping', ['default'], ->
  gulp.src ["test/**/*.nksf"]
    .pipe extract chunk_ids: ['NICA']
    .pipe data (file) ->
      json = msgpack.decode file.contents.slice 4
      file.contents = new Buffer (beautify (JSON.stringify json), indent_size: 2)
    .pipe rename extname: '.json'
    .pipe gulp.dest 'test_out'

# mapping src .nksf, static data
gulp.task 'test-nksf-1', ['default'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'NKSF', 'test/sample.nksf'
    .pipe rename suffix: '_nksf-1'
    .pipe gulp.dest 'test_out'

# mapping src .nksf, function
gulp.task 'test-nksf-2', ['default'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'NKSF', (file, mapping) ->
      'test/sample.nksf'
    .pipe rename suffix: '_nksf-2'
    .pipe gulp.dest 'test_out'

# mapping src .nksf, non-blocking
gulp.task 'test-nksf-3', ['default'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'NKSF', (file, mapping, done) ->
      setTimeout ->
        done undefined, 'test/sample.nksf'
      , 1000
    .pipe rename suffix: '_nksf-3'
    .pipe gulp.dest 'test_out'

# mapping src .json, immediate
gulp.task 'test-json-1', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'JSON', 'test_out/sample.json'
    .pipe rename suffix: '_json-1'
    .pipe gulp.dest 'test_out'

# mapping src .json, function
gulp.task 'test-json-2', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'JSON', (file, mapping) ->
      'test_out/sample.json'
    .pipe rename suffix: '_json-2'
    .pipe gulp.dest 'test_out'

# mapping src .json, non-blocking
gulp.task 'test-json-3', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'JSON', (file, mapping, done) ->
      setTimeout ->
        done undefined, 'test_out/sample.json'
      , 1000
    .pipe rename suffix: '_json-3'
    .pipe gulp.dest 'test_out'

# mapping src object, immediate
gulp.task 'test-object-1', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'OBJECT', (JSON.parse fs.readFileSync 'test_out/sample.json', 'utf8')
    .pipe rename suffix: '_object-1'
    .pipe gulp.dest 'test_out'

# mapping src object, function
gulp.task 'test-object-2', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'OBJECT', (file, mapping) ->
      JSON.parse fs.readFileSync 'test_out/sample.json', 'utf8'
    .pipe rename suffix: '_object-2'
    .pipe gulp.dest 'test_out'

# mapping src .json, non-blocking
gulp.task 'test-object-3', ['extract-sample-mapping'], ->
  replace = require './'
  gulp.src ["test/**/*.nksf"]
    .pipe replace mapping_src: 'OBJECT', (file, mapping, done) ->
      setTimeout ->
        done undefined, (JSON.parse fs.readFileSync 'test_out/sample.json', 'utf8')
      , 1000
    .pipe rename suffix: '_object-3'
    .pipe gulp.dest 'test_out'




