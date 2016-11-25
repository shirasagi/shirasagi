class Jmaxml::Mailer::Main < ActionMailer::Base
  include Jmaxml::Helper::ControlHandler
  include Jmaxml::Helper::HeadHandler
  include Jmaxml::Helper::EarthquakeHandler
  include Jmaxml::Helper::VolcanoHandler
  include Jmaxml::Helper::CommentHandler

  def self.inherited(child)
    attr_reader :xmldoc
    child.append_view_path "#{Rails.root}/app/views/#{child.mailer_name}"
    child.append_view_path "#{Rails.root}/app/views/#{self.mailer_name}"
  end

  def render_title
    head_title
  end

  def template_paths
    [ self.class.mailer_name, Jmaxml::Mailer::Main.mailer_name ]
  end

  def create(page, context, action)
    @page = page
    @context = context
    @action = action
    @xmldoc = @context.xmldoc
    @helper = self
    if head_info_type == '取消'
      mail template_path: template_paths, template_name: 'cancel'
    else
      mail template_path: template_paths
    end
  end
end
