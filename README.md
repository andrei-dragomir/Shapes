
Setup
=====

This assumes you have Ruby >= 1.9.3 installed

		git clone https://github.com/andrei-dragomir/Shapes.git
		cd Shapes
		bundle install
		rake db:migrate
		rails server

Then just visit: [http://localhost:3000/shapes](http://localhost:3000/shapes)

CSV import
==========

The CSV import feature expects a csv with the following header: x,y,radius,width,height,type.
Width and height aren't needed for circles, nor radius for rectangles. Type should be Circle or Rectangle (capitalized).
You can find a sample Shapes.csv file in the root folder.