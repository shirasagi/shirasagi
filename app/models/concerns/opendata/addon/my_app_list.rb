module Opendata::Addon::MyAppList
  extend SS::Addon
  extend ActiveSupport::Concern
  include Cms::Addon::PageList

  public
  def template_variable_get(item, name)
    if name.start_with?('app_')
      if name == 'app_name'
        ERB::Util.html_escape item.name
      elsif name == 'app_url'
        ERB::Util.html_escape "#{self.url}#{item.id}/"
      elsif name == 'app_updated'
        I18n.l item.updated, format: "%Y年%1m月%1d日 %1H時%1M分"
      elsif name =~ /^app_updated\.(.+)$/
        I18n.l item.updated, format: $1
      elsif name == 'app_state'
        ERB::Util.html_escape(item.label :state)
      elsif name == 'app_point'
        ERB::Util.html_escape(item.point.to_i.to_s)
      else
        false
      end
    else
      super
    end
  end
end
