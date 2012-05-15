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

  describe '#get_details' do
    before do
      @restaurant = subject.new
      stub_request(:get, /.*secure.opentable.com\/api\/otapi_v2.ashx\/restaurant.*/).to_return(File.new('./test/restaurant_get_details_result.json'))
    end
    
    it 'should return relevant details about an individual restaurant' do
      response = @restaurant.get_details(82591)
      response.must_be_kind_of Hash
    end
  end

  describe '#search' do
    before do
      @restaurant = subject.new
      stub_request(:get, /.*secure.opentable.com\/api\/otapi_v2.ashx\/table.*/).to_return(File.new('./test/restaurant_search_result.json'), :status => 200)
    end
    
    it 'should look for availability at an inidividual restaurant' do
      date_time = Time.now.strftime "%-m/#{Time.now.day + 1}/%Y %-l:%M %p"
      response = @restaurant.search({ restaurant_id: 82591, date_time: date_time, party_size: 2 })
      response.must_be_kind_of Hash
    end
  end

end
