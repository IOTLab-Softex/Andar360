class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    @rooms = Room.includes(:reservations)
  end
end
