module Api
  class AvailabilitiesController < ApplicationController
    def index
      date = params[:date]
      availabilities = if date
        get_availabilities_for_date(Date.parse(date))
      else
        get_all_availabilities
      end
      
      render json: { availabilities: availabilities }
    end

    def show
      date, start_time = params[:id].split('T')
      date = Date.parse(date)
      
      if is_time_available?(date, start_time)
        render json: { available: true }
      else
        render json: { available: false }
      end
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
      puts "!!!"
      puts "checking availability for date: #{date.strftime("%A").downcase} - #{date.to_s}"
      day_schedule = load_availability_config["schedule"][date.strftime("%A").downcase]
      puts "found day_schedule: #{day_schedule}"
      return [] unless day_schedule

      puts "preparing available slots"
      available_slots = []
      
      day_schedule.each do |window|
        puts "processing window: #{window}"
        start_time = Time.parse(window["start"])
        end_time = Time.parse(window["end"])
        
        current_slot = Time.new(date.year, date.month, date.day, 
                              start_time.hour, start_time.min)
        window_end = Time.new(date.year, date.month, date.day,
                            end_time.hour, end_time.min)
        
        puts "starting daily inspection with #{current_slot}, is this less than end_time #{window_end}? #{current_slot < window_end - 59.minutes}"
        while current_slot < window_end - 59.minutes
          puts "checking if current_slot is available: #{current_slot} on date #{date.to_s}"
          if is_time_available?(date, current_slot.strftime("%H:%M"))
            datetime_str = "#{date}T#{current_slot.strftime("%H:%M")}"
            puts "Yes it is, add #{datetime_str} to the set"
            available_slots << datetime_str
          end
          current_slot += load_availability_config["slot_duration"].minutes
        end
      end

      available_slots
    end

    def is_time_available?(date, start_time)
      # Check if time falls within schedule
      day_schedule = load_availability_config["schedule"][date.strftime("%A").downcase]
      return false unless day_schedule

      start_time_obj = Time.parse(start_time)
      window_available = day_schedule.any? do |window|
        window_start = Time.parse(window["start"])
        window_end = Time.parse(window["end"])
        
        comparison_time = Time.new(date.year, date.month, date.day, 
                                 start_time_obj.hour, start_time_obj.min)
        
        comparison_time >= window_start && comparison_time <= (window_end - 59.minutes)
      end

      return false unless window_available

      # Check if there's no booking
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
