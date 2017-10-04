class Gws::Workflow::Form
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission
  include Gws::Addon::History

  class << self
    def search(params)
      all
    end
  end
end
