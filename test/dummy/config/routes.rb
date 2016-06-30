Rails.application.routes.draw do
  mount NdrError::Engine => '/fingerprinting'

  get 'disaster/cause', controller: 'disaster', action: 'cause'

  root to: 'disaster#no_panic'
end
