module Gws::Tabular::Release
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Release

  included do
    self.default_release_state = "closed"
  end
end
