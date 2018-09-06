module Webmail::Addon::UserExtension
  extend ActiveSupport::Concern
  extend SS::Addon
  include Webmail::UserExtension
end
