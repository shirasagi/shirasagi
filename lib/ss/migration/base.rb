module SS::Migration::Base
  extend ActiveSupport::Concern

  included do
    cattr_accessor :depends
  end

  module ClassMethods
    def depends_on(*versions)
      self.depends = versions.flatten.uniq.compact
    end
  end
end
