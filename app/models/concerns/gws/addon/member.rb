module Gws::Addon
  module Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member
  end
end
