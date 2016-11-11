class Rss::WeatherXml::Action::SendMail < Rss::WeatherXml::Action::Base
  belongs_to :my_anpi_post, class_name: "Cms::Node"
  belongs_to :anpi_mail, class_name: "Cms::Node"
  field :title_mail_text, type: String
  field :upper_mail_text, type: String
  field :loop_mail_text, type: String
  field :lower_mail_text, type: String
  permit_params :my_anpi_post_id, :anpi_mail_id
  permit_params :title_mail_text, :upper_mail_text, :loop_mail_text, :lower_mail_text

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
