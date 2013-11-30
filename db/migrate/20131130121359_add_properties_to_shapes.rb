class AddPropertiesToShapes < ActiveRecord::Migration
  def change
    add_column :shapes, :x, :integer
    add_column :shapes, :y, :integer
    add_column :shapes, :radius, :integer
    add_column :shapes, :width, :integer
    add_column :shapes, :height, :integer
  end
end
