require 'rails_helper'

RSpec.describe Api::BookingsController, type: :request do
  describe 'POST /api/bookings' do
    let(:valid_date) { Date.today.to_s }
    let(:valid_time) { "10:00" }
    let(:valid_params) do
      {
        date: valid_date,
        start_time: valid_time,
        patient_name: "John Doe"
      }
    end

    context 'with valid parameters' do
      before do
        allow_any_instance_of(Api::BookingsController).to receive(:is_time_available?)
          .and_return(true)
      end

      it 'creates a new booking' do
        post '/api/bookings', params: valid_params
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['booking']['date']).to eq(valid_date)
        expect(json_response['booking']['start_time']).to eq(valid_time)
        expect(json_response['booking']['patient_name']).to eq("John Doe")
      end
    end

    context 'with missing parameters' do
      it 'returns an error for missing date' do
        post '/api/bookings', params: valid_params.except(:date)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Missing required parameters")
      end

      it 'returns an error for missing start_time' do
        post '/api/bookings', params: valid_params.except(:start_time)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Missing required parameters")
      end

      it 'returns an error for missing patient_name' do
        post '/api/bookings', params: valid_params.except(:patient_name)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Missing required parameters")
      end
    end

    context 'when time slot is not available' do
      before do
        allow_any_instance_of(Api::BookingsController).to receive(:is_time_available?)
          .and_return(false)
      end

      it 'returns an error' do
        post '/api/bookings', params: valid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Time slot is not available")
      end
    end
  end
end
