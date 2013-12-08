# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class Shape extends Backbone.Model
	defaults:
		x: null
		y: null

class ShapesCollection extends Backbone.Collection
	model: Shape
	url: '/shapes'

class CanvasView extends Backbone.View

	initialize: ->
		@context = @el.getContext '2d'
		@shapesCollection = new ShapesCollection()
		
		@listenTo @shapesCollection, 'add', @renderShape

		@shapesCollection.fetch()

	renderShape: (shape) ->
		if shape.get('type') is 'Circle' 
			@circle shape.get('x'), shape.get('y'), shape.get('radius')
		else
			@rectangle shape.get('x'), shape.get('y'), shape.get('width'), shape.get('height')

	circle: (x, y, radius) ->
		@context.beginPath()
		@context.arc x, y, radius, 0, Math.PI * 2, false
		@context.closePath()
		@context.strokeStyle = '#f00'
		@context.stroke()

	rectangle: (x, y, width, height) ->
		@context.strokeStyle = '#f0f'
		@context.strokeRect x, y, width, height

canvas = new CanvasView el: '#shapes-canvas'