class Property < ActiveRecord::Base
  attr_accessible :airbnb_id, :meta, :name

  serialize :meta, Hash  # EXPLANATION: I would store all of the fields given back from the API as
                         # generally speaking chances are you probably want to access additional
                         # fields in the future (which would require doing the API call again).
                         # This way the fields are already saved in the hash

  has_many :availabilities

  class << self
    # PART 1: START HERE
    def populate_area
      save_all_properties_in_the_area
      save_properties_availability_for_next_7_days
    end

    def save_properties_available_on(date, gather_all_properties=false, page=1) # Use Date.today as possible input
      raise 'Please provide valid date such as Date.today' if gather_all_properties==false && date.class.to_s != "Date"
      a = Mechanize.new

      url = "https://www.airbnb.com/search/ajax_get_results?"

      parameters = {
        "&checkin" => (gather_all_properties == true ? "" : date.strftime('%d-%m-%Y')),
        "&checkout" => (gather_all_properties == true ? "" : (date + 1.day).strftime('%d-%m-%Y')),
        "&locale" => "en",
        "&location" => "Sacramento,CA",
        "&page" => "#{page}"
      }

      parameters.each{|k, v| url << "#{k}=#{v}"}

      raw_json = JSON.parse(a.get(url).body)

      raw_json["properties"].each do |property|
        p = Property.find_or_create_by_airbnb_id(property["id"],
                                          {name: property["name"],
                                           meta: property})

        Availability.find_or_create_by_property_id_and_available_on(p.id, date) unless gather_all_properties
      end

      # "results_count_html" : "  <h4>64 &ndash; 68 of 68 listings</h4>\n"
      progress = raw_json["results_count_html"].match(/(\d*)\Wof\W(\d*)/)
      save_properties_available_on(date, gather_all_properties, page += 1) if progress[1] != progress[2]
    end

    def save_properties_availability_for_next_7_days
      t = Date.today
      [t, t+1.day, t+2.days, t+3.days, t+4.days, t+5.days, t+6.days, t+7.days].each do |day|
        save_properties_available_on(day)
      end
    end

    def save_all_properties_in_the_area
      save_properties_available_on('all properties', true)
    end

    # PART 2: START HERE
    def show_properties_available_between(date_start, date_end)
      date_range = date_start..date_end
      date_range_str = date_range.collect{|d| "availabilities.available_on is #{d}"}.join(' AND ')
      Property.includes(:availabilities).where(date_range_str)
    end

  end
end
