# Bland Booker

A simple appointment booking system API.

## API Endpoints

### Get All Availabilities
```bash
curl http://localhost:3000/api/availabilities
```

### Get Availabilities for Specific Date
```bash
curl http://localhost:3000/api/availabilities?date=2024-02-05
```

### Check Specific Time Slot
```bash
curl http://localhost:3000/api/availabilities/2024-02-05T09:00
```

### Create a Booking
```bash
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"date":"2024-02-05","start_time":"09:00","patient_name":"John Doe"}'
```
