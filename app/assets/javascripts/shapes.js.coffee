
# change underscore template delimiters since they're the same as ERB
_.templateSettings =
	interpolate: /\[\%\=(.+?)\%\]/g
	evaluate: /\[\%(.+?)\%\]/g

# Override Backbone.sync to provide a valid CSRF token to Rails
Backbone.oldSync = Backbone.sync
Backbone.sync = (method, model, options) ->
	newOptions = _.extend {
		beforeSend: (xhr) ->
			token = $('meta[name="csrf-token"]').attr('content')
			xhr.setRequestHeader('X-CSRF-Token', token) if token
	}, options
	Backbone.oldSync method, model, newOptions

# create an event aggregator for communication between components 
vent = _.clone Backbone.Events

class Shape extends Backbone.Model
	defaults:
		id: null
		x: null
		y: null
		radius: null
		width: null
		height: null
		type: null


class ShapesCollection extends Backbone.Collection
	model: Shape
	url: '/shapes'


class ShapeView extends Backbone.View
	tagName: 'li'
	className: -> 'shape ' + @model.get('type').toLowerCase()
	circleTemplate: _.template( $('#circle-template').html() )
	rectangleTemplate: _.template( $('#rectangle-template').html() )

	events:
		'mouseenter': 'highlight'
		'mouseleave': 'draw'
		'click .info': 'toggleForm'
		'submit form': 'update'

	initialize: ->
		@listenTo @model, 'change', @refresh

	render: ->
		template = if @model.get('type') is 'Circle' then @circleTemplate else @rectangleTemplate
		@$el.html template @model.attributes
		@form = @$('form')
		@

	highlight: ->
		vent.trigger 'highlight', @model

	draw: ->
		vent.trigger 'draw', @model

	toggleForm: ->
		if @form.is(':visible') then @form.hide() else @form.show()

	update: (e) ->
		e.preventDefault()
		formData = {}
		model = @model
		@form.find('input').each ->
			prop = @className
			formData[ prop ] = ~~@value if model.get(prop)? and @value != model.get(prop)
		@model.save formData, wait: true

	destroy: ->

	refresh: ->
		@render()
		vent.trigger 'redraw', @model
		



class AppView extends Backbone.View

	initialize: ->
		@shapesCollection = new ShapesCollection()
		@shapesContainer = @$('#shapes')

		@listenTo @shapesCollection, 'add', @renderShape

		@shapesCollection.fetch()

	renderShape: (shape) ->
		shapeView = new ShapeView model: shape
		@shapesContainer.append shapeView.render().el
		shapeView.draw()


class CanvasView extends Backbone.View

	tagName: 'canvas'

	constructor: (options) ->
		@options = options || {}
		super

	initialize: ->
		@context = @el.getContext '2d'
		@color = 'blue'
		@highlightColor = 'red'
		@context.lineWidth = 1.5
		originalWidth = 640
		originalHeight = 480

		@ratio = @options.ratio || 1

		@$el.attr 
			width: @ratio * originalWidth
			height: @ratio * originalHeight

		@listenTo vent, 'draw', @drawShape
		@listenTo vent, 'highlight', @highlightShape
		@listenTo vent, 'redraw', @redrawShape

	drawShape: (shape, fill = false) ->
		if shape.get('type') is 'Circle' 
			@circle shape.get('x') * @ratio, shape.get('y') * @ratio, shape.get('radius') * @ratio, fill
		else
			@rectangle shape.get('x') * @ratio, shape.get('y') * @ratio, shape.get('width') * @ratio, shape.get('height') * @ratio, fill

	clearShape: (shape) ->
		@context.lineWidth = 3.5
		if shape.get('type') is 'Circle' 
			@clearCircle shape.previous('x') * @ratio, shape.previous('y') * @ratio, shape.previous('radius') * @ratio
		else
			@clearRectangle shape.previous('x') * @ratio, shape.previous('y') * @ratio, shape.previous('width') * @ratio, shape.previous('height') * @ratio
		@context.lineWidth = 1.5

	redrawShape: (shape) ->
		@clearShape shape
		@drawShape shape

	highlightShape: (shape) ->
		@drawShape shape, true

	circle: (x, y, radius, fill = false) ->
		@context.beginPath()
		@context.arc x, y, radius, 0, Math.PI * 2, false
		@context.closePath()
		
		if fill
			@context.fillStyle = @color
			@context.fill()
		else
			@clearCircle arguments...
			@context.strokeStyle = @color
			@context.stroke()

	rectangle: (x, y, width, height, fill = false) ->
		@context.strokeStyle = @color
		@context.fillStyle = @color
		if fill
			@context.fillRect x + 0.5, y + 0.5, width, height
		else
			@clearRectangle arguments...
			@context.strokeStyle = @color
			@context.strokeRect x, y, width, height

	clearRectangle: (x, y, width, height) ->
		@context.fillStyle = 'white'
		@context.strokeStyle = 'white'
		@context.fillRect x + 0.5, y + 0.5, width, height
		@context.strokeRect x + 0.5, y+ 0.5, width, height

	clearCircle: (x, y, radius) ->
		@context.beginPath()
		@context.arc x + 0.5, y + 0.5, radius, 0, Math.PI * 2, false
		@context.closePath()
		@context.fillStyle = 'white'
		@context.strokeStyle = 'white'
		@context.fill()
		@context.stroke()


scaledCanvasContainer = $('#scaled-canvas-container')
originalCanvasContainer = $('#original-canvas-container')

# create canvases of different sizes
canvasView = new CanvasView
mediumCanvasView = new CanvasView ratio: 2
largeCanvasView = new CanvasView ratio: 10

# insert canvases into the DOM
originalCanvasContainer.append canvasView.render().el
scaledCanvasContainer.append '<h2>2x</h2>', mediumCanvasView.render().el
scaledCanvasContainer.append '<h2>10x</h2>', largeCanvasView.render().el

# init the interface and fetch shapes from the server
appView = new AppView el: 'body'