# Some application logic that we should be able to log failures from:
class DisasterController < ApplicationController
  def no_panic; end

  def cause
    raise params[:message].to_s
  end
end
