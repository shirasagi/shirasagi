module Gws::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Reference::Role
  end
end
