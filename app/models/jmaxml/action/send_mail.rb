class Jmaxml::Action::SendMail < Jmaxml::Action::Base
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

  def execute(page, context)
    case context.type
    when Jmaxml::Type::EARTH_QUAKE
      execute_earth_quake(page, context)
    else
      raise NotImplementedError
    end
  end

  private
    def execute_earth_quake(page, context)
      target_datetime = REXML::XPath.first(context.xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip
      if target_datetime.present?
        target_datetime = Time.zone.parse(target_datetime.to_s) rescue nil
      end

      renderer = Rss::Renderer::AnpiMail.new(
        cur_site: context.site,
        cur_node: self,
        cur_page: page,
        cur_infos: { infos: context.region_eq_infos, target_time: target_datetime })

      name = renderer.render_template(title_mail_text)
      text = renderer.render

      ezine_page = Ezine::Page.new(
        cur_site: context.site,
        cur_node: anpi_mail,
        cur_user: context.user,
        name: name,
        text: text
      )

      unless ezine_page.save
        Rails.logger.warn("failed to save ezine/page:\n#{ezine_page.errors.full_messages.join("\n")}")
        return
      end

      Ezine::Task.deliver ezine_page.id
    end
end
