require 'rails_helper'

RSpec.describe BookingManager do
  let(:monday) { Date.parse("2024-02-05") } # A Monday
  
  before do
    # Mock availability config
    allow(subject).to receive(:load_availability_config).and_return({
      "schedule" => {
        "monday" => [
          { "start" => "09:00", "end" => "12:00" },
          { "start" => "13:00", "end" => "17:00" }
        ]
      },
      "slot_duration" => 60
    })
    
    # Mock bookings
    allow(subject).to receive(:load_bookings).and_return({
      "bookings" => [
        { "date" => monday.to_s, "start_time" => "10:00", "patient_name" => "John Doe" }
      ]
    })
  end

  describe '#is_time_available?' do
    context 'when checking business hours' do
      it 'returns true for time within business hours' do
        expect(subject.send(:is_time_available?, monday, "09:00")).to be true
      end

      it 'returns false for time outside business hours' do
        expect(subject.send(:is_time_available?, monday, "08:00")).to be false
        expect(subject.send(:is_time_available?, monday, "18:00")).to be false
      end

      it 'returns false for time during lunch break' do
        expect(subject.send(:is_time_available?, monday, "12:30")).to be false
      end
    end

    context 'when checking appointment duration' do
      it 'returns false for slot too close to window end' do
        # 11:30 would push the 1-hour appointment past the 12:00 window end
        expect(subject.send(:is_time_available?, monday, "11:30")).to be false
      end

      it 'returns true for slot that fits within window' do
        expect(subject.send(:is_time_available?, monday, "11:00")).to be true
      end
    end

    context 'when checking existing bookings' do
      it 'returns false for already booked time slot' do
        expect(subject.send(:is_time_available?, monday, "10:00")).to be false
      end

      it 'returns true for available time slot' do
        expect(subject.send(:is_time_available?, monday, "09:00")).to be true
      end
    end
  end

  describe '#book_appointment!' do
    let(:new_booking) { { "date" => monday.to_s, "start_time" => "09:00", "patient_name" => "Jane Smith" } }
    
    before do
      allow(File).to receive(:write)
    end

    it 'adds the booking to the bookings data' do
      expect(subject.send(:book_appointment!, monday, "09:00", "Jane Smith")).to eq(new_booking)
    end

    it 'writes the updated bookings to the file' do
      expected_bookings = {
        "bookings" => [
          { "date" => monday.to_s, "start_time" => "10:00", "patient_name" => "John Doe" },
          new_booking
        ]
      }

      subject.send(:book_appointment!, monday, "09:00", "Jane Smith")
      
      expect(File).to have_received(:write).with(
        Rails.root.join('db', 'bookings.json'),
        JSON.pretty_generate(expected_bookings)
      )
    end
  end
end
