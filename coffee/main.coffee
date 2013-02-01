$ ()->
  #models
  Memo = Backbone.Model.extend
    localStorage: new Backbone.LocalStorage('memo')
    defaults:
      title: "no title"

    initialize: ()->

    validate: (options)->
      if options.body == ""
        return "本文を入力してください。"

  MemoList = Backbone.Collection.extend
    model: Memo
    localStorage: new Backbone.LocalStorage('memo')

  Tag = Backbone.Model.extend
    localStorage: new Backbone.LocalStorage('tag')

  TagList = Backbone.Collection.extend
    model: Tag
    localStorage: new Backbone.LocalStorage('tag')

  Memos = new MemoList()
  Tags = new TagList()

  #views
  MemoListView = Backbone.View.extend
    #一覧表示されるメモ用のview
    tagName: 'li'
    template: _.template $('#memo-list-template').html()

    events:
      "click .memo-title": "showDetail"
      "click .icon-remove": "clear"

      "mouseover": ()-> 
        @toggleIcons(true) 
        @$el.addClass 'label-warning'

      "mouseleave": ()->
        @toggleIcons(false) 
        @$el.removeClass 'label-warning'

    initialize:(options)->
      @app_view = options.app_view
      @listenTo @model, 'destroy', @remove

    render: ()->
      @$el.html @template @model.toJSON()

      @$('.icon-tag').popover
        content: ()->
          #return "<ul><li>foo</li><li>bar</li></ul>"
          return (new TagListView()).render().el
        html: true

      return this

    showDetail: (evt)->
      evt.stopPropagation()
      memo_view = new MemoView(model: @model)
      @app_view.setDisp memo_view.render().el

    toggleIcons: (show)->
      if show == true
        @$('.icons').show()
      else
        @$('.icons').hide()

    clear: (evt)->
      evt.stopPropagation()
      @model.destroy()

  TagListView = Backbone.View.extend
    #popoverで一覧表示されるアルバム用のview
    tagName: 'ul'
    render: ()->
      Tags.each @addOne, this
      return this

    addOne: (tag)->
      view = new TagView(model: tag)
      @$el.append view.render().el 

  TagView = Backbone.View.extend
    tagName: 'li'
    render: ()->
      @$el.html @model.name
      return this

  MemoView = Backbone.View.extend
    template: _.template $('#memo-template').html()

    render: ()->
      @$el.html @template @model.toJSON()
      return this


  InputView = Backbone.View.extend
    #belongs_to :AppView
    #新規メモ作成領域用のview
    el: $('#input-area') 
    events:
      "click #toggle-input-panel": "toggleInputPanel" 
      "click #save": "saveMemo" 
      "keydown": "closePanel"

    initialize: ()->
      @button = $('#toggle-input-panel')

      @input_panel = @$('#input-panel')
      @memo_title = @$('#memo-title')
      @memo_body  = @$('#memo-body')

      #templates
      @new_memo_button_template    = (_.template @$("#toggle-input-panel").html())()
      @close_input_button_template = (_.template $("#close-input-button").html())()

    panel_is_invisible: ()->
      return @input_panel.css("display") == "none"

    saveMemo: ()->
      new_memo = new Memo
        title: @memo_title.val() 
        body : @memo_body.val()

      new_memo.save()

      if new_memo.validationError
        @renderError(new_memo.validationError)

      else
        Memos.add new_memo, wait: true

        @input_panel.slideUp()
        @resetPanel()
        @button.html @new_memo_button_template

    toggleInputPanel: (e)->
      if @panel_is_invisible() == true
        @input_panel.slideDown ()=>
          @memo_title.focus()
        @button.html @close_input_button_template

      else
        @button.html @new_memo_button_template
        @resetPanel()
        @input_panel.slideUp()

    renderError: (message)->
      @$('div.control-group').addClass('error')
      @$('span.help-inline').html(message)

    resetPanel: ()->
      @memo_title.val('')
      @memo_body.val('')
      @$('div.control-group').removeClass('error')
      @$('span.help-inline').html('')

    closePanel: (e)->
      return if e.keyCode != 27

      @input_panel.slideUp ()=>
        @button.html @new_memo_button_template
        @button.focus()
        @resetPanel()

  AppView = Backbone.View.extend
    #アプリケーション全体のview
    el: $('#app')

    initialize: ()-> 
      @disparea   = @$('#mem')
      @input_area = new InputView 
        parentView: @

      @listenTo Memos, 'add'  , @addOneMemo
      @listenTo Memos, 'reset', @addAllMemo

      Memos.fetch()
      Tags.fetch()

    addOneMemo: (memo)->
      list_view = new MemoListView(model: memo, app_view: @)
      @$('.memos ul').append list_view.render().el

    addAllMemo: ()->
      Memos.each @addOneMemo, @

    setDisp: (v)->
      @disparea.html v

  app = new AppView()
