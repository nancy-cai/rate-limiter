require 'rails_helper'


RSpec.describe 'Rate Limiter', type: :request do
  include Rack::Test::Methods
  before(:each) do
    $redis.flushall
  end

  describe "GET #index" do

    before do
      freezed_time = Time.utc(2018, 1, 1, 10, 10, 0)
      Timecop.freeze(freezed_time)
      request_count.times{ get '/'}
    end

    context 'when request count is under the limit' do
      let(:request_count) { 100 }

      it "returns successful status" do
        expect(last_response.status).to eq 200
      end
    end

    context 'when request count is going over the limit' do
      let(:request_count) { 1011 }

      it "returns over the limit status with time remaining in the messge" do
        expect(last_response.status).to eq 429
        expect(last_response.body).to include('3600')
      end

      it "returns successful status if a request occurs in the next hour'" do
        Timecop.travel(3600.seconds.from_now)
        get '/'
        expect(last_response.status).to eq 200
      end
    end
  end
end
