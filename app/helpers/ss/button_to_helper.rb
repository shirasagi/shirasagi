module SS::ButtonToHelper
  extend ActiveSupport::Concern

  # this method has same interface of Rails' button_to:
  #   button_to(name = nil, options = nil, html_options = nil, &block)
  #
  # see: action_view/helpers/url_helper.rb
  def ss_button_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      html_options = options
      options = name
    end
    options      ||= {}
    html_options ||= {}
    html_options = html_options.stringify_keys

    url    = options.is_a?(String) ? options : url_for(options)
    remote = html_options.delete("remote")
    method = html_options.delete("method").to_s
    if confirmation_required?(html_options["model"])
      confirm = html_options.delete("confirm")
    end
    params = html_options.delete("params")

    html_options["type"] ||= "button"
    html_options["class"] = Array(html_options["class"])
    html_options["class"] << "ss-dc-guard" unless html_options["class"].include?("ss-dc-guard")
    html_options["data"] ||= {}
    html_options["data"]["remote"] = true if remote
    html_options["data"]["ss-button-to-action"] = url
    html_options["data"]["ss-button-to-method"] = method.presence || "post"
    # rails の confirm が勝ってしまって上手く動作しないので data-ss-confirmation に設定しなおす
    html_options["data"]["ss-confirmation"] = confirm if confirm.try(:present?)
    html_options["data"]["ss-button-to-params"] = params if params.present?

    if block_given?
      button = button_tag(html_options, &block)
    else
      button = button_tag(name || url, html_options)
    end

    button
  end

  def confirmation_required?(model)
    model.to_s.match(/\A(Sys|Gws|SS|Webmail|Opendata|Job)::/).present?
  end
end
