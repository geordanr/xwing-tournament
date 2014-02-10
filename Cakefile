{spawn}    = require 'child_process'

task 'test', 'Run tests', (cb) ->
    mocha_proc = spawn 'mocha', [ '--compilers', 'coffee:coffee-script/register' ]
    mocha_proc.stdout.on 'data', (data) ->
        process.stdout.write "#{data}"
    mocha_proc.stderr.on 'data', (data) ->
        process.stderr.write "#{data}"
