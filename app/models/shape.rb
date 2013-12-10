class Shape < ActiveRecord::Base

	def self.import(file)
		options_hash = {}
		results = SmarterCSV.process( file.path, options_hash )
		self.create results
	end
end
