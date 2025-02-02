module BookingManager
  extend ActiveSupport::Concern

  private

  def is_time_available?(date, start_time)
    # First check if it's within business hours
    day_schedule = load_availability_config["schedule"][date.strftime("%A").downcase]
    return false unless day_schedule

    # Convert requested time to a Time object on the correct date
    requested_time = Time.new(date.year, date.month, date.day,
                            Time.parse(start_time).hour,
                            Time.parse(start_time).min)

    # Check if the time falls within any of the day's windows
    window_available = day_schedule.any? do |window|
      # Create window times with the correct date
      window_start = Time.new(date.year, date.month, date.day,
                            Time.parse(window["start"]).hour,
                            Time.parse(window["start"]).min)
      window_end = Time.new(date.year, date.month, date.day,
                           Time.parse(window["end"]).hour,
                           Time.parse(window["end"]).min)
      
      # Check if requested time falls within the window
      # Subtract 59 minutes from end time to ensure full hour appointment fits
      requested_time >= window_start && requested_time <= (window_end - 59.minutes)
    end

    return false unless window_available

    # Finally check that there's no existing booking
    bookings = load_bookings["bookings"]
    !bookings.any? { |booking| booking["date"] == date.to_s && booking["start_time"] == start_time }
  end

  def load_availability_config
    @availability_config ||= JSON.parse(File.read(Rails.root.join('config', 'availability.json')))
  end

  def book_appointment!(date, start_time, patient_name)
    booking = {
      "date" => date.to_s,
      "start_time" => start_time,
      "patient_name" => patient_name
    }

    bookings_data = load_bookings
    bookings_data["bookings"] << booking
    
    File.write(Rails.root.join('db', 'bookings.json'), JSON.pretty_generate(bookings_data))
    booking
  end

  def load_bookings
    @bookings ||= JSON.parse(File.read(Rails.root.join('db', 'bookings.json')))
  end
end
