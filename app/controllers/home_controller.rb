class HomeController < ApplicationController

  before_action only: :index do |controller|
    controller.rate_limit 100, 1.hour
  end

  def index
    render plain: 'Ok'
  end
end
