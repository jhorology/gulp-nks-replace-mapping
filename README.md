## gulp-nks-replace-mapping

Gulp plugin for replacing the mapping chunk of NKSF file.

## Installation
```
  npm install gulp-nks-replace-mapping --save-dev
```

## Usage

print mapping.
```javascript
const replace = require('gulp-nks-replace-mapping'),
      beautify = require('js-beautify')

function printMapping() {
  return src('src/**/*.nksf')
    .pipe(replace((file, mapping) => {
      console.log(beautify(JSON.stringify(mapping), { indent_size: 2 }))
      return undefined
    }))
}
```

use exists template .nksf file as mapping
```javascript
const replace = require('gulp-nks-replace-mapping')
      { src, dest } = require('gulp')

function replaceMapping() {
  return src('src/Spier/**/*.nksf')
    .pipe(replace('Spire template.nksf', { type: 'NKSF' }))
    .pipe(dest('dist/Spire'))
}
```


edit original mapping
```javascript
const replace = require('gulp-nks-replace-mapping')
      { src, dest } = require('gulp')

function swapPage1and2() {
  return src('src/**/*.nksf')
    .pipe(replace((file, mapping) => {
      const page1 = mapping.ni8[0]
      const page2 = mapping.ni8[1]
      mapping.ni8[0] = page2
      mapping.ni8[1] = page1
      return mapping
    }, { type: 'OBJECT' }))
    .pipe(dest('dist'))
}
```

## API

### replace(data [,options])

#### options [optional]
Type: `Object`
Defalut: {type: 'NKSF'}

##### options.type [optional]
Type: `String`, Default: 'NKSF'

###### 'NKSF'
 The data arg should specify NKSF file path or function to provide NKSF file path.
###### 'JSON'
  The data arg should specify JSON file path or function to provide JSON file path.
###### 'OBJECT'
 The data arg should specify mapping object or function to provide mapping object.

#### data
  Type: `String` or `Object` or `function(file, mapping [,callback])`

  The replacement source file path or mapping object or function.


#### function (file, mapping [,callbak])
The function to provide file path or mapping object.

##### file
Type: `vinyl` file

##### mapping
Type: `Object`

The mapping object of source file.

##### callback
Type: `function(err, data)`

The callback function to support non-blocking function.

example mapping of .nksf
```javascript
{
  "ni8": [
    [{
      "autoname": false,
      "id": 0,
      "name": "Level",
      "section": "Master",
      "vflag": false
    }, {
      "autoname": false,
      "id": 1,
      "name": "Tune",
      "vflag": false
    }, {
      "autoname": false,
      "id": 18,
      "name": "VCF Freq",
      "section": "Param",
      "vflag": false
    }, {
      "autoname": false,
      "id": 19,
      "name": "VCF Resonance",
      "vflag": false
    }, {
      "autoname": false,
      "id": 20,
      "name": "Lfo Speed",
      "vflag": false
    }, {
      "autoname": false,
      "id": 21,
      "name": "Vibrato Depth",
      "vflag": false
    }, {
      "autoname": false,
      "id": 22,
      "name": "VCF FM2",
      "vflag": false
    }, {
      "autoname": false,
      "id": 23,
      "name": "Env1 Decay",
      "vflag": false
    }],
    [{
      "autoname": false,
      "id": 24,
      "name": "Left Reverb",
      "section": "Param",
      "vflag": false
    }, {
      "autoname": false,
      "id": 25,
      "name": "Right Reverb",
      "vflag": false
    }, {
      "autoname": false,
      "id": 26,
      "name": "Chorus Dry/Wet",
      "section": "FX",
      "vflag": false
    }, {
      "autoname": false,
      "id": 27,
      "name": "Delay Dry/Wet",
      "vflag": false
    }, {
      "autoname": false,
      "id": 28,
      "name": "Env2 Attack",
      "section": "Env",
      "vflag": false
    }, {
      "autoname": false,
      "id": 29,
      "name": "Width Osc1",
      "vflag": false
    }, {
      "autoname": false,
      "id": 30,
      "name": "Audio2 Vca",
      "vflag": false
    }, {
      "autoname": false,
      "id": 31,
      "name": "Env2 Release",
      "vflag": false
    }],
    [{
      "autoname": false,
      "id": 32,
      "name": "Env1 Attack",
      "section": "Env",
      "vflag": false
    }, {
      "autoname": false,
      "id": 33,
      "name": "Env1 Decay",
      "vflag": false
    }, {
      "autoname": false,
      "id": 34,
      "name": "Env1 Sustain",
      "vflag": false
    }, {
      "autoname": false,
      "id": 35,
      "name": "Env1 Release",
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }, {
      "autoname": true,
      "vflag": false
    }]
  ]
}
```
