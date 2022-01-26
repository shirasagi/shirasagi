class SS::OAuth2::Application::Confidential < SS::OAuth2::Application::Base
  field :client_secret, type: String
  field :redirect_uris, type: SS::Extensions::Lines

  validates :client_secret, presence: true
  validates :redirect_uris, presence: true

  permit_params :client_secret, :redirect_uris
end
