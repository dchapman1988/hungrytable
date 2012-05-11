require 'test_helper'

describe Hungrytable::Restaurant do
  subject { Hungrytable::Restaurant }

  it 'should be a class' do
    subject.class.must_be_kind_of Class
  end

  %w{ get_details search }.each do |meth|
    it "should respond to #{meth}" do
      assert subject.new.respond_to?(meth.to_sym), true
    end
  end

  describe 'when getting details' do
    before do
      @restaurant = subject.new
    end

    it 'should return relevant details about an individual restaurant' do
      response = @restaurant.get_details(82591)
      response.must_be_kind_of Hash
    end

    it 'should look for availability at an inidividual restaurant' do
      date_time = Time.now.strftime "%-m/#{Time.now.day + 1}/%Y %-l:%M %p"
      response = @restaurant.search({ restaurant_id: 82591, date_time: date_time, party_size: 2 })
      response.must_be_kind_of Hash
    end

  end
end
