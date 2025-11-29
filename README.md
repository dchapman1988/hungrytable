# Hungrytable

[![CI](https://github.com/dchapman1988/hungrytable/actions/workflows/ci.yml/badge.svg)](https://github.com/dchapman1988/hungrytable/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/dchapman1988/hungrytable/graph/badge.svg)](https://codecov.io/gh/dchapman1988/hungrytable)
[![Ruby Version](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/hungrytable.svg)](https://badge.fury.io/rb/hungrytable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ruby client for the OpenTable REST API. Supports restaurant search, availability lookup, reservations, and booking management.

## Features

- Fetch restaurant details
- Search available reservation times
- Lock time slots before booking
- Create and cancel reservations
- Check reservation status
- Requires Ruby 3.0+
- No `method_missing` - all methods explicitly defined
- Error classes for different failure types

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hungrytable'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install hungrytable
```

## Configuration

### Environment Variables

Set the following environment variables (recommended for production):

```bash
export OT_PARTNER_ID=<YOUR OPENTABLE PARTNER ID>
export OT_OAUTH_KEY=<YOUR OPENTABLE OAUTH KEY>
export OT_OAUTH_SECRET=<YOUR OPENTABLE OAUTH SECRET KEY>
```

### Programmatic Configuration

Alternatively, configure programmatically in your code:

```ruby
Hungrytable.configure do |config|
  config.partner_id = 'your_partner_id'
  config.oauth_key = 'your_oauth_key'
  config.oauth_secret = 'your_oauth_secret'
end
```

## Usage

### 1. Get Restaurant Details

```ruby
restaurant = Hungrytable::Restaurant.new(82591)

if restaurant.valid?
  puts restaurant.restaurant_name
  puts restaurant.address
  puts restaurant.phone
  puts restaurant.primary_food_type
  puts restaurant.price_range
else
  puts "Error: #{restaurant.error_message}"
end
```

Available restaurant attributes:
- `restaurant_name`, `restaurant_ID`
- `address`, `city`, `state`, `postal_code`
- `phone`, `url`
- `latitude`, `longitude`
- `neighborhood_name`, `metro_name`
- `primary_food_type`, `price_range`
- `restaurant_description`
- `parking`, `parking_details`
- `image_link`

### 2. Search for Availability

```ruby
restaurant = Hungrytable::Restaurant.new(82591)

# Search for a table for 4 people, 5 days from now at 7pm
search_time = 5.days.from_now.change(hour: 19, min: 0)
search = Hungrytable::RestaurantSearch.new(
  restaurant,
  date_time: search_time,
  party_size: 4
)

if search.valid?
  puts "Exact time: #{search.exact_time}" if search.exact_time
  puts "Early time: #{search.early_time}" if search.early_time
  puts "Later time: #{search.later_time}" if search.later_time
  puts "Best time: #{search.ideal_time}"
else
  puts "No availability: #{search.error_message}"
end
```

### 3. Lock a Time Slot

```ruby
slotlock = Hungrytable::RestaurantSlotlock.new(search)

if slotlock.successful?
  puts "Slot locked! ID: #{slotlock.slotlock_id}"
else
  puts "Failed to lock slot: #{slotlock.errors}"
end
```

### 4. Make a Reservation

```ruby
reservation = Hungrytable::ReservationMake.new(
  slotlock,
  email_address: 'john.doe@example.com',
  firstname: 'John',
  lastname: 'Doe',
  phone: '5551234567',
  specialinstructions: 'Window seat please'
)

if reservation.successful?
  puts "Reservation confirmed! Number: #{reservation.confirmation_number}"
else
  puts "Reservation failed: #{reservation.error_message}"
end
```

### 5. Check Reservation Status

```ruby
status = Hungrytable::ReservationStatus.new(
  restaurant_id: 82591,
  confirmation_number: 'ABC123XYZ'
)

if status.successful?
  puts "Status: #{status.status}"
  details = status.reservation_details
  puts "Restaurant: #{details[:restaurant_name]}"
  puts "Date/Time: #{details[:date_time]}"
  puts "Party Size: #{details[:party_size]}"
end
```

### 6. Cancel a Reservation

```ruby
cancel = Hungrytable::ReservationCancel.new(
  email_address: 'john.doe@example.com',
  confirmation_number: 'ABC123XYZ',
  restaurant_id: 82591
)

if cancel.successful?
  puts "Reservation cancelled successfully"
else
  puts "Cancellation failed: #{cancel.error_message}"
end
```

### Complete Example: Full Reservation Flow

```ruby
require 'hungrytable'

# Configure
Hungrytable.configure do |config|
  config.partner_id = ENV['OT_PARTNER_ID']
  config.oauth_key = ENV['OT_OAUTH_KEY']
  config.oauth_secret = ENV['OT_OAUTH_SECRET']
end

# 1. Get restaurant details
restaurant = Hungrytable::Restaurant.new(82591)
raise "Restaurant not found" unless restaurant.valid?

puts "Booking at: #{restaurant.restaurant_name}"

# 2. Search for availability
search_time = 3.days.from_now.change(hour: 19, min: 0)
search = Hungrytable::RestaurantSearch.new(
  restaurant,
  date_time: search_time,
  party_size: 2
)

raise "No availability" unless search.valid?

puts "Found time slot: #{search.ideal_time}"

# 3. Lock the slot
slotlock = Hungrytable::RestaurantSlotlock.new(search)
raise "Could not lock slot: #{slotlock.errors}" unless slotlock.successful?

# 4. Make the reservation
reservation = Hungrytable::ReservationMake.new(
  slotlock,
  email_address: 'diner@example.com',
  firstname: 'Jane',
  lastname: 'Smith',
  phone: '5551234567'
)

if reservation.successful?
  puts "Success! Confirmation: #{reservation.confirmation_number}"
else
  puts "Failed: #{reservation.error_message}"
end
```

## Error Handling

Available error classes:

```ruby
begin
  restaurant = Hungrytable::Restaurant.new(invalid_id)
rescue Hungrytable::ConfigurationError => e
  puts "Configuration error: #{e.message}"
rescue Hungrytable::HTTPError => e
  puts "HTTP error: #{e.message}"
rescue Hungrytable::APIError => e
  puts "API error #{e.error_code}: #{e.error_message}"
rescue Hungrytable::MissingRequiredFieldError => e
  puts "Missing required field: #{e.message}"
end
```

Error hierarchy:
- `Hungrytable::Error` (base class)
  - `ConfigurationError` - Missing or invalid configuration
  - `HTTPError` - HTTP-level errors
    - `NotFoundError` - 404 errors
    - `UnauthorizedError` - 401 authentication errors
    - `ServerError` - 5xx server errors
  - `APIError` - OpenTable API errors
  - `ValidationError` - Input validation errors
    - `MissingRequiredFieldError` - Missing required parameters

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

### Running Tests

```bash
bundle exec rake test
```

### Running RuboCop

```bash
bundle exec rubocop
```

### Auto-fixing RuboCop Issues

```bash
bundle exec rubocop -A
```

## Requirements

- Ruby >= 3.0.0
- OpenTable Partner API credentials

## Dependencies

Runtime:
- `activesupport` (>= 6.0)
- `http` (~> 5.0)
- `oauth` (~> 1.1)

Development:
- `minitest` (~> 5.20) - Testing framework
- `webmock` (~> 3.20) - HTTP mocking for tests
- `rubocop` (~> 1.60) - Code quality and style
- `mocha` (~> 2.1) - Mocking and stubbing


## Contributing

1. Fork it (https://github.com/dchapman1988/hungrytable/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please ensure:
- All tests pass (`bundle exec rake test`)
- RuboCop is clean (`bundle exec rubocop`)
- New features have tests
- Code follows existing style

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Authors

- David Chapman ([@dchapman1988](https://github.com/dchapman1988))
- Nicholas Fine

## Changelog

See [RELEASE_NOTES.md](RELEASE_NOTES.md) for version history.
