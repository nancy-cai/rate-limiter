require 'rails_helper'


RSpec.describe HomeController, type: :controller do

  before(:each) do
    $redis.flushall
  end

  describe "GET #index" do

    before do
      freezed_time = Time.utc(2018, 1, 1, 10, 10, 0)
      Timecop.freeze(freezed_time)
      request_count.times{ get :index }
    end

    context 'when request count is under the limit' do
      let(:request_count) { 100 }

      it "returns successful status" do
        expect(response.status).to eq 200
      end
    end

    context 'when request count is going over the limit' do
      let(:request_count) { 100 }

      it "returns over the limit status with time remaining in the messge" do
        expect(response.status).to eq 429
        expect(response.body).to include('1800')
      end

      it "returns successful status if a request occurs in the next hour'" do
        Timecop.travel(1800.seconds.from_now)
        expect(response.status).to eq 200
      end
    end
  end
end
