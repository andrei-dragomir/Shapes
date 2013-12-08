class Circle < Shape
	# http://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
	def self.model_name
		Shape.model_name
	end
end
