NdrError::Engine.routes.draw do
  resources :errors,
            only: %i[index show edit update destroy],
            controller: 'errors',
            as: 'error_fingerprints'
end
