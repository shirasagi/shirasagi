module Member::Addon::Blog
  module PageSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File
    include Member::Reference::BlogLayout

    included do
      field :description, type: String
      #field :order, type: Integer, default: 0
      field :genres, type: SS::Extensions::Lines
      belongs_to_file :image

      embeds_ids :blog_page_locations, class_name: "Member::Node::BlogPageLocation"

      validate :validate_genres
      validates :description, length: { maximum: 400 }

      permit_params :image_id, :description, :genres
      permit_params blog_page_location_ids: []

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
      end
    end

    def thumb_url
      image ? image.thumb_url : "/assets/img/dummy.png"
    end

    def template_variable_handler_img_src(name, issuer)
      ERB::Util.html_escape(thumb_url)
    end

    private
      def validate_genres
        lines = SS::Extensions::Lines.new(genres).map(&:strip).select(&:present?).uniq

        if lines.select { |line| line.size > 40 }.present?
          errors.add :genres, :too_long, count: 40
        end
        self.genres = lines.join("\n")
      end
  end
end
