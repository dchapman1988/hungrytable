# Hungrytable

The purpose of this gem is to interact with the [OpenTable](http://www.opentable.com) REST API.

## Installation

Add this line to your application's Gemfile:

    gem 'hungrytable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hungrytable

## Usage

You need to set some environment variable for this gem to work properly:

Observe:

    # In ~/.bashrc
    export OT_PARTNER_ID=<YOUR OPENTABLE PARTNER ID>
    export OT_PARTNER_AUTH=<YOUR OPENTABLE PARTNER AUTH> # For XML feed only...
    export OT_OAUTH_KEY=<YOUR OPENTABLE OAUTH KEY>
    export OT_OAUTH_SECRET=<YOUR OPENTABLE OAUTH SECRET KEY>


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
