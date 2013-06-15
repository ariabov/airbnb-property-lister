class CreateAvailabilities < ActiveRecord::Migration
  def change
    create_table :availabilities do |t|
      t.integer :property_id
      t.date    :available_on

      t.timestamps
    end
  end
end
