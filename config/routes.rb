NdrError::Engine.routes.draw do
  resources :errors,
            only: [:index, :show, :edit, :update, :destroy],
            controller: 'errors',
            as: 'error_fingerprints'

  resources :client_errors,
            only: [:create],
            controller: 'client_errors'
end
