class AddTypeToShapes < ActiveRecord::Migration
  def change
    add_column :shapes, :type, :string
  end
end
