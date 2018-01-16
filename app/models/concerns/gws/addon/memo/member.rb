module Gws::Addon
  module Memo::Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member
  end
end
