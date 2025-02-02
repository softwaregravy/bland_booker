module Api
  class BookingsController < ApplicationController
    def create
      unless params[:date] && params[:start_time] && params[:patient_name]
        return render json: { error: "Missing required parameters" }, status: :unprocessable_entity
      end

      date = Date.parse(params[:date])
      
      unless is_time_available?(date, params[:start_time])
        return render json: { error: "Time slot is not available" }, status: :unprocessable_entity
      end

      booking = {
        "date" => date.to_s,
        "start_time" => params[:start_time],
        "patient_name" => params[:patient_name]
      }

      bookings_data = load_bookings
      bookings_data["bookings"] << booking
      
      File.write(Rails.root.join('db', 'bookings.json'), JSON.pretty_generate(bookings_data))
      
      render json: { booking: booking }, status: :created
    end

    private

    def is_time_available?(date, time)
      return false unless business_day?(date)

      # Check if time falls within schedule
      day_schedule = load_availability_config["schedule"][date.strftime("%A").downcase]
      return false unless day_schedule

      time_obj = Time.parse(time)
      window_available = day_schedule.any? do |window|
        start_time = Time.parse(window["start"])
        end_time = Time.parse(window["end"])
        
        comparison_time = Time.new(date.year, date.month, date.day, 
                                 time_obj.hour, time_obj.min)
        
        comparison_time >= start_time && comparison_time <= (end_time - 59.minutes)
      end

      return false unless window_available

      # Check if there's no booking
      bookings = load_bookings["bookings"]
      !bookings.any? { |booking| booking["date"] == date.to_s && booking["start_time"] == time }
    end

    def business_day?(date)
      !date.saturday? && !date.sunday?
    end

    def load_availability_config
      @availability_config ||= JSON.parse(File.read(Rails.root.join('config', 'availability.json')))
    end

    def load_bookings
      @bookings ||= JSON.parse(File.read(Rails.root.join('db', 'bookings.json')))
    end
  end
end
