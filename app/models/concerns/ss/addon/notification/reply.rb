module SS::Addon::Notification::Reply
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :reply_module, type: String
    field :reply_model, type: String
    field :reply_item_id, type: String
  end

  def reply_addon_name
    return nil if reply_module.blank?
    I18n.t "modules.addons.ss/notification/reply.#{reply_module}", default: name.titleize
  end

  def reply_addon_show_file
    return nil if reply_module.blank?
    file = "#{Rails.root}/app/views/ss/agents/addons/notification/reply/#{reply_module}/_show.html.erb"
    File.exists?(file) ? file : nil
  end

  def reply_item
    reply_model.camelize.constantize.where(:id => reply_item_id).first rescue nil
  end
end
