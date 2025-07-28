class Gws::Workflow2::Form::External < Gws::Workflow2::Form::Base
  field :url, type: String

  permit_params :state, :url

  validates :url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
end
