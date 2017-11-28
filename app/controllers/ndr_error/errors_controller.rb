module NdrError
  # Controller for viewing and managing errors
  class ErrorsController < ApplicationController
    before_action :find_fingerprint,  only: [:show, :edit, :update, :destroy]
    before_action :check_permissions, only: [:edit, :update, :destroy]

    def index
      if NdrError::Log.perform_cleanup!
        flash[:notice] = 'Scheduled deletion of historical logs completed.'
      end

      @keywords     = extract_keywords(params[:q])
      @fingerprints = NdrError.paginate(@keywords, params[:page])
    end

    def show
      logs   = @fingerprint.error_logs.not_deleted
      @error = (id = params[:log_id]) ? logs.find_by(error_logid: id) : logs.first

      if @error.nil?
        flash[:error] = 'No matching Logs exist for that Fingerprint!'
        redirect_to error_fingerprints_url(q: @fingerprint.to_param)
      end
    end

    def edit
    end

    def update
      @fingerprint.ticket_url = params[:error_fingerprint][:ticket_url]

      if @fingerprint.save
        flash[:notice] = 'The Error Fingerprint was successfully updated!'
        redirect_to error_fingerprint_url(@fingerprint)
      else
        flash.now[:error] = errors_for(@fingerprint)
        render 'edit'
      end
    end

    def destroy
      flash[:error] = 'Fingerprint purged!' if @fingerprint.purge!

      redirect_to error_fingerprints_url
    end

    private

    def errors_for(object)
      object.errors.full_messages.to_sentence
    end

    def user_can_edit_errors?
      NdrError.check_current_user_permissions.call(self) # Call with the current context
    end
    helper_method :user_can_edit_errors?

    def check_permissions
      return if user_can_edit_errors?

      flash[:error] = 'You do not have the required permissions for that.'
      redirect_to error_fingerprints_url
    end

    def find_fingerprint
      @fingerprint = NdrError.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'Unknown or deleted error fingerprint'
      redirect_to error_fingerprints_url
    end
  end
end
