module SS::Reference
  module Site
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_site

    included do
      belongs_to :site, class_name: "SS::Site"

      validates :site_id, presence: true
      before_validation :set_site_id, if: ->{ @cur_site }

      scope :site, ->(site) { where(site_id: site.id) }
    end

    private
      def set_site_id
        self.site_id ||= @cur_site.id
      end
  end
end
