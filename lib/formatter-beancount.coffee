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

  isBeancountScope: (editor) ->
    if editor?
      return editor.getGrammar().scopeName is 'source.beancount'
    return false

  run: ->
    if not @isBeancountScope atom.workspace.getActiveTextEditor()
      atom.notifications.addInfo('Not a beancount file.')
      return

    if not atom.config.get 'formatter-beancount.a.enable'
      atom.notifications.addInfo('Formatter is disabled.')
      return

    atom.notifications.addInfo('Formatting ...')
    child_process = require 'child_process'
    text = atom.workspace.getActiveTextEditor().getBuffer().getText()
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
        if stdOut.length is 0
          reject(stdErr.join('\n'))
        else
          resolve(stdOut.join('\n'))

    promise.then((text) ->
      if text isnt atom.workspace.getActiveTextEditor().getBuffer().getText()
        atom.workspace.getActiveTextEditor().getBuffer().setText(text)
        atom.notifications.addSuccess('Formatting succeeded.')
      else
        atom.notifications.addInfo('Nothing to change.')
    ).catch((reason) ->
      atom.notifications.addError('Formatting failed!', {detail: reason, dismissable: true})
    )
