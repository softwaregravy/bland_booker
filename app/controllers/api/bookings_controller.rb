module Api
  class BookingsController < ApplicationController
    include AvailabilityChecker
    skip_before_action :verify_authenticity_token
    def create
      unless params[:date] && params[:start_time] && params[:patient_name]
        return render json: { error: "Missing required parameters" }, status: :unprocessable_entity
      end

      date = Date.parse(params[:date])
      
      unless is_time_available?(date, params[:start_time])
        return render json: { error: "Time slot is not available" }, status: :unprocessable_entity
      end

      booking = book_appointment!(date, params[:start_time], params[:patient_name])
      render json: { booking: booking }, status: :created
    end

    private

  end
end
