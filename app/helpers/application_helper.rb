module ApplicationHelper
  extend ActiveSupport::Concern
  include SS::StandardHelper
  include SS::BootstrapSupport::FormHelper
  include SS::BootstrapSupport::FormOptionsHelper
  include SS::BootstrapSupport::FormTagHelper
  include SS::BootstrapSupport::UrlHelper
end
