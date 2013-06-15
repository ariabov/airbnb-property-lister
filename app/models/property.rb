class Property < ActiveRecord::Base
  attr_accessible :airbnb_id, :meta, :name

  serialize :meta, Hash  # EXPLANATION: I would store all of the fields given back from the API as
                         # generally speaking chances are you probably want to access additional
                         # fields in the future (which would require doing the API call again).
                         # This way the fields are already saved in the hash

  has_many :availabilities

  class << self
    def save_properties_available_on(date) # Use Date.today as possible input
      raise 'Please provide valid date such as Date.today' if date.class.to_s != "Date"
      a = Mechanize.new
      url = "https://www.airbnb.com/search/ajax_get_results?"

      parameters = {
        "&checkin" => date.strftime('%d-%m-%Y'),
        "&checkout" => (date + 1.day).strftime('%d-%m-%Y'),
        "&locale" => "en",
        "&location" => "Sacramento,CA"
      }

      parameters.each{|k, v| url << "#{k}=#{v}"}

      raw_json = JSON.parse(a.get(url).body)
      
      raw_json["properties"].each do |property|
        p = Property.find_or_create_by_airbnb_id(property["id"],
                                          {name: property["name"],
                                           meta: property})

        Availability.find_or_create_by_property_id_and_available_on(p.id, date)
      end
    end

    def save_properties_availability_for_next_7_days
      t = Date.today
      [t, t+1.day, t+2.days, t+3.days, t+4.days, t+5.days, t+6.days].each do |day|
        save_properties_available_on(day)
      end
    end

  end
end
