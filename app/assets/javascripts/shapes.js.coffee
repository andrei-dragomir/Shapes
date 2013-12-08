
# change underscore template delimiters since they're the same as ERB
_.templateSettings =
	interpolate: /\[\%\=(.+?)\%\]/g
	evaluate: /\[\%(.+?)\%\]/g

# event aggregator for communication between components 
vent = _.clone Backbone.Events

class Shape extends Backbone.Model
	defaults:
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
	className: 'shape'
	circleTemplate: _.template( $('#circle-template').html() )
	rectangleTemplate: _.template( $('#rectangle-template').html() )

	events:
		'mouseenter': 'highlight'
		'mouseleave': 'draw'

	render: ->
		template = if @model.get('type') is 'Circle' then @circleTemplate else @rectangleTemplate
		@$el.html template @model.attributes
		@

	highlight: ->
		vent.trigger 'highlight', @model

	draw: ->
		vent.trigger 'draw', @model

	destroy: ->



class AppView extends Backbone.View

	initialize: ->
		@shapesCollection = new ShapesCollection()
		@shapesContainer = @$('#shapes')

		@listenTo @shapesCollection, 'add', @renderShape

		@shapesCollection.fetch()

	renderShape: (shape) ->
		shapeView = new ShapeView model: shape
		@shapesContainer.append shapeView.render().el
		vent.trigger 'draw', shape


class CanvasView extends Backbone.View

	initialize: ->
		@context = @el.getContext '2d'
		@color = 'blue'
		@highlightColor = 'red'

		@listenTo vent, 'draw', @drawShape
		@listenTo vent, 'highlight', @highlightShape

	drawShape: (shape, fill = false) ->
		if shape.get('type') is 'Circle' 
			@circle shape.get('x'), shape.get('y'), shape.get('radius'), fill
		else
			@rectangle shape.get('x'), shape.get('y'), shape.get('width'), shape.get('height'), fill

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
			@context.fillRect x, y, width, height
		else
			@clearRectangle arguments...
			@context.strokeStyle = @color
			@context.strokeRect x, y, width, height

	clearRectangle: (x, y, width, height) ->
		@context.fillStyle = 'white'
		@context.fillRect x, y, width, height

	clearCircle: (x, y, radius) ->
		@context.beginPath()
		@context.arc x, y, radius, 0, Math.PI * 2, false
		@context.closePath()
		@context.fillStyle = 'white'
		@context.fill()


appView = new AppView el: 'body'
canvasView = new CanvasView el: '#shapes-canvas'