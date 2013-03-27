(($, _, Backbone) ->
  
  # Set custom template settings
  _interpolateBackup = _.templateSettings
  _.templateSettings = 
    interpolate: /\{\{(.+?)\}\}/g
    evaluate: /<%([\s\S]+?)%>/g

  template = _.template '
    <% if (title) { %>
      <div class="modal-header">
        <% if (allowCancel) { %>
          <a class="close">×</a>
        <% } %>
        <h3>{{title}}</h3>
      </div>
    <% } %>
    <div class="modal-body">{{content}}</div>
    <div class="modal-footer">
      <% if (allowCancel) { %>
        <% if (cancelText) { %>
          <a href="#" class="btn cancel">{{cancelText}}</a>
        <% } %>
      <% } %>
      <a href="#" class="btn ok btn-primary">{{okText}}</a>
    </div>
  '


  class Modal extends Backbone.View

    className: 'modal'

    events: 
      'click .close': (event) ->
        event.preventDefault()
        @trigger 'cancel'
        if @options.content and @options.content.trigger
          @options.content.trigger 'cancel', @
  
      'click .cancel': (event) ->
        event.preventDefault()
        @trigger 'cancel'
        if @options.content and @options.content.trigger
          @options.content.trigger 'cancel', @
      
      'click .ok': (event) ->
        event.preventDefault()
        @trigger 'ok'
        if @options.content and @options.content.trigger
          @options.content.trigger 'ok', @
        if @options.okCloses 
          @close()

    # Creates an instance of a Bootstrap Modal
   
    # @see http://twitter.github.com/bootstrap/javascript.html#modals
   
    # @param {Object} options
    # @param {String|View} [options.content] Modal content. Default: none
    # @param {String} [options.title]        Title. Default: none
    # @param {String} [options.okText]       Text for the OK button. Default: 'OK'
    # @param {String} [options.cancelText]   Text for the cancel button. Default: 'Cancel'. If passed a falsey value, the button will be removed
    # @param {Boolean} [options.allowCancel  Whether the modal can be closed, other than by pressing OK. Default: true
    # @param {Boolean} [options.escape]      Whether the 'esc' key can dismiss the modal. Default: true, but false if options.cancellable is true
    # @param {Boolean} [options.animate]     Whether to animate in/out. Default: false
    # @param {Function} [options.template]   Compiled underscore template to override the default one

    initialize: (options) ->
      @options = _.extend
        title: null
        okText: 'OK'
        focusOk: true
        okCloses: true
        cancelText: 'Cancel'
        allowCancel: true
        escape: true
        animate: false
        template: template
      , options

  
    # Creates the DOM element 
    # @api private
    render: ->
      $el = @$el
      options = @options
      content = options.content

      # Create the modal container
      $el.html options.template options
      $content = @$content = $el.find '.modal-body'

      # Insert the main content if it's a view
      if content.$el
        content.render()
        $el.find('.modal-body').html content.$el
      if options.animate then $el.addClass 'fade'
      @isRendered = true
      @
  

    # Render and show the modal
    # @param {Function} [cb]     Optional callback that runs only when OK is pressed.
    open: (cb) ->
      if not @isRendered then @render()
      $el = @$el

      # Create it
      $el.modal _.extend 
        keyboard: @options.allowCancel
        backdrop: if @options.allowCancel then true else 'static'
      , @options.modalOptions

      # Focus OK button
      $el.one 'shown', => 
        if @options.focusOk
          $el.find('.btn.ok').focus()  
        if @options.content and @options.content.trigger
          @options.content.trigger 'shown', @
        @trigger 'shown'    

      # Adjust the modal and backdrop z-index; for dealing with multiple modals
      numModals = Modal.count
      $backdrop = $('.modal-backdrop:eq('+numModals+')')
      backdropIndex = parseInt $backdrop.css('z-index'),10
      elIndex = parseInt $backdrop.css('z-index'), 10

      $backdrop.css 'z-index', backdropIndex + numModals
      @$el.css 'z-index', elIndex + numModals

      if @options.allowCancel
        $backdrop.one 'click', =>
          if @options.content and @options.content.trigger
            @options.content.trigger 'cancel', @
          @trigger 'cancel'
      
        $(document).one 'keyup.dismiss.modal', (e) =>
          e.which is 27 and @trigger 'cancel'

          if @options.content and @options.content.trigger
            e.which is 27 and @options.content.trigger 'shown', @

      @on 'cancel', => @close()

      Modal.count++

      if cb then @on 'ok', cb  # Run callback on OK if provided
      @
  

    # Closes the modal
    close: -> 
      # Check if the modal should stay open
      if @_preventClose 
        @_preventClose = false
        return

      $el = @$el
      $el.one 'hidden', onHidden = (e) =>
        # Ignore events propagated from interior objects, like bootstrap tooltips
        if e.target isnt e.currentTarget
          return $el.one 'hidden', onHidden
        @remove()
        if @options.content and @options.content.trigger
          @options.content.trigger 'hidden', @
        @trigger 'hidden'

      $el.modal 'hide'

      Modal.count--

    # Stop the modal from closing.
    # Can be called from within a 'close' or 'ok' event listener.
    preventClose: ->  @_preventClose = true

  # Reset to users' template settings
  _.templateSettings = _interpolateBackup

  Modal.count = 0 # static!

  # EXPORTS
  # CommonJS
  if typeof require is 'function' and typeof module isnt 'undefined' and exports 
    module.exports = Modal

  # AMD / RequireJS
  if typeof define is 'function' and define.amd
    return define ->
      Backbone.BootstrapModal = Modal
  

  # Regular; add to Backbone.Bootstrap.Modal
  else Backbone.BootstrapModal = Modal

)(jQuery, _, Backbone)
