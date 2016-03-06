# Some application logic that we should be able to log failures from:
class DisasterController < ApplicationController
  def no_panic
    # Triggers no exceptions
  end

  def cause
    # Triggers a server-side exception
    fail params[:message]
  end

  def cause_client
    # Triggers a client-side exception
  end
end
