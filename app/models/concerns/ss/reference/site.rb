module SS::Reference::Site
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    cattr_accessor :site_required, instance_accessor: false
    self.site_required = true

    attr_accessor :cur_site

    belongs_to :site, class_name: "SS::Site"

    validates :site_id, presence: true, if: ->{ self.class.site_required }
    before_validation :set_site_id, if: ->{ @cur_site }
  end

  module ClassMethods
    # define scope by class method instead of scope to be able to override by subclass
    def site(site)
      where(site_id: site.id)
    end
  end

  private

  def set_site_id
    self.site_id ||= @cur_site.id
  end
end
