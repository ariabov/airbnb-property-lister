class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.integer :airbnb_id, unique: true
      t.string  :name
      t.text    :meta

      t.timestamps
    end
  end
end
