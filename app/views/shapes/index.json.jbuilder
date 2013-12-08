json.array!(@shapes) do |shape|
	json.extract! shape, :x, :y, :type
	if shape.type == "Circle"
		json.extract! shape, :radius
	elsif shape.type == "Rectangle"
		json.extract! shape, :width, :height
	end
	json.url shape_url(shape, format: :json)
end
