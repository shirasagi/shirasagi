class Service::Apis::QuotaController < ApplicationController
  include Service::ApiFilter

  model Service::Account

  def reload
    @item = @model.find(params[:id])
    raise '403' if !@cur_user.admin? && @item != @cur_user

    @item.reload_quota_used.save

    data = @item.attributes.slice(
      :base_quota_used,
      :cms_quota_used,
      :gws_quota_used,
      :webmail_quota_used
    )
    data.dup.each do |key, val|
      data["#{key}_size"] = view_context.number_to_human_size(val)
    end

    render json: data.to_json
  end
end
