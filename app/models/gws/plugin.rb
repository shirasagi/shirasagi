class Gws::Plugin
  include SS::PluginBase

  self.scope = 'gws'

  attr_accessor :model_class, :registory

  def i18n_name_only
    model_class.model_name.human
  end
  alias name_only i18n_name_only

  # def enabled?
  #   true
  # end
end
