json.array!(@shapes) do |shape|
  json.extract! shape, 
  json.url shape_url(shape, format: :json)
end
