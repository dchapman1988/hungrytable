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

    it 'should return some JSON given a valid restaurant_id' do
      VCR.use_cassette('restaurant_get_details') do
        response = @restaurant.get_details(82591)
        response.must_be_kind_of Hash
      end
    end
  end
end
