
CANVAS_WIDTH = 6400
CANVAS_HEIGHT = 4800

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

	validate: ->
		errors = []
		unless typeof @get('x') is 'number'
			errors.push "x should be a positive number"
		unless typeof @get('y') is 'number'
			errors.push "y should be a positive number"

		unless (@get('type') is 'Circle' and @isValidCircle()) or (@get('type') is 'Rectangle' and @isValidRectangle())
			errors.push "Shapes should be in the space #{CANVAS_WIDTH}x#{CANVAS_HEIGHT}"

		if errors.length > 0
			# collection.create doesn't trigger an error if validation fails, so treat the error somewhere else (AppView)
			# http://stackoverflow.com/questions/8572937/bind-to-error-event-of-a-model-created-by-collection-create
			vent.trigger 'error', errors
			return errors

	isValidCircle: ->
		@get('x') - @get('radius') > 0 and @get('x') + @get('radius') < CANVAS_WIDTH and @get('y') - @get('radius') > 0 and @get('y') + @get('radius') < CANVAS_HEIGHT

	isValidRectangle: ->
		@get('x') > 0 and @get('x') + @get('width') < CANVAS_WIDTH and @get('y') > 0 and @get('y') + @get('height') < CANVAS_HEIGHT


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
		'click .delete': 'destroy'

	initialize: ->
		@listenTo @model, 'change', @refresh
		@listenTo @model, 'destroy', @removeShape

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

	destroy: (e) ->
		e.preventDefault()
		@model.destroy wait: true

	removeShape: (model) ->
		if confirm 'Are you sure?'
			@remove()
			vent.trigger 'erase', model

	refresh: ->
		@render()
		vent.trigger 'redraw', @model	



class AppView extends Backbone.View

	events:
		'submit .form-new-circle': 'createCircle'
		'submit .form-new-rectangle': 'createRectangle'

	initialize: ->
		@shapesCollection = new ShapesCollection()
		@shapesContainer = @$('#shapes')
		@formCircle = @$('.form-new-circle')
		@formRectangle = @$('.form-new-rectangle')

		@listenTo @shapesCollection, 'add', @renderShape

		# alert errors thrown by model validation
		@listenTo vent, 'error', @error

		@shapesCollection.fetch()

	renderShape: (shape) ->
		shapeView = new ShapeView model: shape
		@shapesContainer.append shapeView.render().el
		shapeView.draw()

	createShape: (form) ->
		formData = {}
		form.find('input:text').each ->
			prop = @className
			formData[ prop ] = ~~@value
		formData['type'] = form.find('input.type').val()
		@shapesCollection.create formData, wait: true

	createCircle: (e) ->
		e.preventDefault()
		@createShape @formCircle

	createRectangle: (e) ->
		e.preventDefault()
		@createShape @formRectangle

	error: (errors) ->
		if typeof errors is 'string'
			alert errors
		else if typeof errors is 'object' # typeof array returns 'object' in javascript :|
			alert error for error in errors
		


class CanvasView extends Backbone.View

	tagName: 'canvas'

	constructor: (options) ->
		# options are not auto-attached anymore since Backbone 1.1
		@options = options || {}
		super

	initialize: ->
		@context = @el.getContext '2d'
		@color = 'blue'
		@highlightColor = 'red'
		@context.lineWidth = 1.5
		@originalWidth = CANVAS_WIDTH
		@originalHeight = CANVAS_HEIGHT

		@ratio = @options.ratio || 1

		@$el.attr 
			width: @ratio * @originalWidth
			height: @ratio * @originalHeight

		@listenTo vent, 'draw', @drawShape
		@listenTo vent, 'highlight', @highlightShape
		@listenTo vent, 'redraw', @redrawShape
		@listenTo vent, 'clear', @clearShape
		@listenTo vent, 'erase', @eraseShape

	drawShape: (shape, fill = false) ->
		x = Math.round(shape.get('x') * @ratio)
		y = Math.round(shape.get('y') * @ratio)
		if shape.get('type') is 'Circle' 
			radius = Math.round(shape.get('radius') * @ratio)
			@circle x, y, radius, fill
		else
			width = Math.round(shape.get('width') * @ratio)
			height = Math.round(shape.get('height') * @ratio)
			@rectangle x, y, width, height, fill

	clearShape: (shape) ->
		@context.lineWidth = 3.5
		x = Math.round(shape.previous('x') * @ratio)
		y = Math.round(shape.previous('y') * @ratio)
		
		if shape.get('type') is 'Circle' 
			radius = Math.round(shape.previous('radius') * @ratio)
			@clearCircle x, y, radius
		else
			width = Math.round(shape.previous('width') * @ratio)
			height = Math.round(shape.previous('height') * @ratio)
			@clearRectangle x, y, width, height

		@context.lineWidth = 1.5

	eraseShape: (shape) ->
		@context.lineWidth = 3.5
		x = Math.round(shape.get('x') * @ratio)
		y = Math.round(shape.get('y') * @ratio)
		
		if shape.get('type') is 'Circle' 
			radius = Math.round(shape.get('radius') * @ratio)
			@clearCircle x, y, radius
		else
			width = Math.round(shape.get('width') * @ratio)
			height = Math.round(shape.get('height') * @ratio)
			@clearRectangle x, y, width, height

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
canvasView = new CanvasView ratio: 0.1
originalCanvasView = new CanvasView

# insert canvases into the DOM
scaledCanvasContainer.append canvasView.render().el
originalCanvasContainer.append '<h2>Original size (6400x4800)</h2>', originalCanvasView.render().el

# init the interface and fetch shapes from the server
appView = new AppView el: 'body'