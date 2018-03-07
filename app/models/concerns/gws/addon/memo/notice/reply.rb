module Gws::Addon::Memo::Notice::Reply
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :reply_module, type: String
    field :reply_model, type: String
    field :reply_item_id, type: String
  end

  public

  def reply_addon_name
    return nil if reply_module.blank?
    I18n.t "modules.addons.gws/memo/notice/reply.#{reply_module}", default: name.titleize
  end

  def reply_addon_show_file
    return nil if reply_module.blank?
    file = "#{Rails.root}/app/views/gws/agents/addons/memo/notice/reply/#{reply_module}/_show.html.erb"
    File.exists?(file) ? file : nil
  end

  def reply_item
    reply_model.camelize.constantize.where(:id => reply_item_id).first rescue nil
  end
end
