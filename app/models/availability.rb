class Availability < ActiveRecord::Base
  attr_accessible :available_on, :property_id

  belongs_to :property
end
