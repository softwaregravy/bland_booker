module Api
  class AvailabilitiesController < ApplicationController
    include BookingManager
    skip_before_action :verify_authenticity_token
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

  end
end
