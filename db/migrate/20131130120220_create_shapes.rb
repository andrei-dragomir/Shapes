class CreateShapes < ActiveRecord::Migration
  def change
    create_table :shapes do |t|

      t.timestamps
    end
  end
end
