module Api
  class AvailabilitiesController < ApplicationController
    def index
      availabilities = if availability_params[:date]
        get_availabilities_for_date(Date.parse(availability_params[:date]))
      else
        get_all_availabilities
      end
      
      render json: { availabilities: availabilities }
    end

    def status
      date = Date.parse(params[:date])
      time = params[:time]
      
      render json: { available: is_time_available?(date, time) }
    end

    private

    def availability_params
      params.permit(:date)
    end

    private

    def get_all_availabilities
      # Get next 7 days of availabilities
      availabilities = []
      date = Date.today
      
      7.times do
        availabilities.concat(get_availabilities_for_date(date))
        date = date.next_day
      end
      
      availabilities
    end

    def get_availabilities_for_date(date)
      day_schedule = load_availability_config["schedule"][date.strftime("%A").downcase]
      return [] unless day_schedule
      available_slots = []
      
      day_schedule.each do |window|
        start_time = Time.parse(window["start"])
        end_time = Time.parse(window["end"])
        
        current_slot = Time.new(date.year, date.month, date.day, 
                              start_time.hour, start_time.min)
        window_end = Time.new(date.year, date.month, date.day,
                            end_time.hour, end_time.min)
        
        while current_slot < window_end - 59.minutes
          if is_time_available?(date, current_slot.strftime("%H:%M"))
            datetime_str = "#{date}T#{current_slot.strftime("%H:%M")}"
            available_slots << datetime_str
          end
          current_slot += load_availability_config["slot_duration"].minutes
        end
      end

      available_slots
    end

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

    def load_bookings
      @bookings ||= JSON.parse(File.read(Rails.root.join('db', 'bookings.json')))
    end
  end
end
