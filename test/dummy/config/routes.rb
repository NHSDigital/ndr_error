Rails.application.routes.draw do
  mount NdrError::Engine => '/fingerprinting'

  get '/:controller(/:action(/:id))'

  root to: 'disaster#no_panic'
end
