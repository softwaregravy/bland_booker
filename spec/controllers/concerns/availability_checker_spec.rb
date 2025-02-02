require 'rails_helper'

RSpec.describe AvailabilityChecker do
  let(:test_class) { Class.new { include AvailabilityChecker } }
  let(:checker) { test_class.new }
  let(:monday) { Date.parse("2024-02-05") } # A Monday
  
  before do
    # Mock availability config
    allow(checker).to receive(:load_availability_config).and_return({
      "schedule" => {
        "monday" => [
          { "start" => "09:00", "end" => "12:00" },
          { "start" => "13:00", "end" => "17:00" }
        ]
      },
      "slot_duration" => 60
    })
    
    # Mock bookings
    allow(checker).to receive(:load_bookings).and_return({
      "bookings" => [
        { "date" => monday.to_s, "start_time" => "10:00", "patient_name" => "John Doe" }
      ]
    })
  end

  describe '#is_time_available?' do
    context 'when checking business hours' do
      it 'returns true for time within business hours' do
        expect(checker.send(:is_time_available?, monday, "09:00")).to be true
      end

      it 'returns false for time outside business hours' do
        expect(checker.send(:is_time_available?, monday, "08:00")).to be false
        expect(checker.send(:is_time_available?, monday, "18:00")).to be false
      end

      it 'returns false for time during lunch break' do
        expect(checker.send(:is_time_available?, monday, "12:30")).to be false
      end
    end

    context 'when checking appointment duration' do
      it 'returns false for slot too close to window end' do
        # 11:30 would push the 1-hour appointment past the 12:00 window end
        expect(checker.send(:is_time_available?, monday, "11:30")).to be false
      end

      it 'returns true for slot that fits within window' do
        expect(checker.send(:is_time_available?, monday, "11:00")).to be true
      end
    end

    context 'when checking existing bookings' do
      it 'returns false for already booked time slot' do
        expect(checker.send(:is_time_available?, monday, "10:00")).to be false
      end

      it 'returns true for available time slot' do
        expect(checker.send(:is_time_available?, monday, "09:00")).to be true
      end
    end
  end
end
