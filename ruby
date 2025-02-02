require 'rails_helper'

RSpec.describe Api::AvailabilitiesController, type: :request do
  describe "GET /api/availabilities" do
    it "returns all availabilities for the next 7 days" do
      get "/api/availabilities"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("availabilities")
      expect(json["availabilities"]).to be_an(Array)
    end

    it "returns availabilities for a specific date" do
      get "/api/availabilities", params: { date: Date.today.to_s }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("availabilities")
      expect(json["availabilities"]).to be_an(Array)
    end
  end

  describe "GET /api/availabilities/status/:date/:time" do
    it "checks if a specific time slot is available" do
      get "/api/availabilities/status/#{Date.today}/09:00"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("available")
      expect(json["available"]).to be_in([true, false])
    end
  end
end
