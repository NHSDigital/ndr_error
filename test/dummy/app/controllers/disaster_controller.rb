# Some application logic that we should be able to log failures from:
class DisasterController < ApplicationController
  def cause
    fail params[:message]
  end
end
