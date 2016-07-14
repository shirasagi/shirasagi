module Rss::Addon
  module AnpiMailSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :earthquake_intensity, type: String, default: '5+'
      embeds_ids :target_regions, class_name: "Rss::WeatherXmlRegion"
      belongs_to :my_anpi_post, class_name: "Cms::Node"
      belongs_to :anpi_mail, class_name: "Cms::Node"
      field :title_mail_text, type: String
      field :upper_mail_text, type: String
      field :loop_mail_text, type: String
      field :lower_mail_text, type: String
      permit_params :earthquake_intensity, :my_anpi_post_id, :anpi_mail_id
      permit_params target_region_ids: []
      permit_params :title_mail_text, :upper_mail_text, :loop_mail_text, :lower_mail_text
      validates :earthquake_intensity, inclusion: { in: %w(0 1 2 3 4 5- 5+ 6- 6+ 7) }
    end

    def earthquake_intensity_options
      %w(4 5- 5+ 6- 6+ 7).map { |value| [I18n.t("rss.options.earthquake_intensity.#{value}"), value] }
    end

    def default_my_anpi_post
      site = @cur_site || self.site
      return nil unless site
      Member::Node::MyAnpiPost.site(site).first
    end

    def default_anpi_mail
      site = @cur_site || self.site
      return nil unless site
      Ezine::Node::MemberPage.site(site).first
    end
  end
end
