{CompositeDisposable} = require 'atom'

module.exports = FormatterBeancount =
  config:
    a:
      title: 'formatter-beancount'
      type: 'object'
      description: 'Settings for formatter-beancount.'
      properties:
        enable:
          title: 'Enable formatter.'
          type: 'boolean'
          default: true
          description: 'Restart required for changes to take effect.'
        executable:
          title: 'Path'
          type: 'string'
          default: 'bean-format'
          description: 'Path to the `bean-format` executable.'

  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'formatter-beancount:run': => @run()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  run: ->
    if atom.config.get 'formatter-beancount.a.enable'
      child_process = require 'child_process'
      text = atom.workspace.getActiveTextEditor().getBuffer().getText()
      atom.notifications.addInfo('Formatting ...')
      promise = new Promise (resolve, reject) ->
        command = atom.config.get 'formatter-beancount.a.executable'
        stdOut = []
        stdErr = []
        process = child_process.spawn(command, [], {})
        process.stdout.on 'data', (data) -> stdOut.push data
        process.stderr.on 'data', (data) -> stdErr.push data
        process.stdin.write text
        process.stdin.end()
        process.on 'close', ->
          if stdOut.length isnt 0
            resolve(stdOut.join('\n'))
          else
            reject(stdErr.join('\n'))
      promise.then((text) ->
        atom.workspace.getActiveTextEditor().getBuffer().setText(text)
        atom.notifications.addSuccess('Formatting succeeded.')
      ).catch((reason) ->
        atom.notifications.addError('Formatting failed!')
      )
    else
      atom.notifications.addInfo('Formatter is disabled.')
