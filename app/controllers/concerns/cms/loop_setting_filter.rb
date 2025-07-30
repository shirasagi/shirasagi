module Cms::LoopSettingFilter
  extend ActiveSupport::Concern

  private

  def process_loop_setting_params
    return unless params[:item]

    html_format = params[:item][:html_format]
    loop_setting_id = params[:item][:loop_setting_id]
    loop_html = params[:item][:loop_html]
    loop_liquid = params[:item][:loop_liquid]

    Rails.logger.info "=== ループ設定パラメータ処理 ==="
    Rails.logger.info "html_format: #{html_format.inspect}"
    Rails.logger.info "loop_setting_id: #{loop_setting_id.inspect}"
    Rails.logger.info "loop_setting_id class: #{loop_setting_id.class}"
    Rails.logger.info "loop_html present?: #{loop_html.present?}"
    Rails.logger.info "loop_html: #{loop_html.inspect}" if loop_html.present?
    Rails.logger.info "loop_liquid: #{loop_liquid.inspect}" if loop_liquid.present?
    # 直接入力が選択されている場合（loop_setting_idが空または空文字列で、loop_htmlが入力されている）
    if loop_html.present?
      if html_format == "shirasagi" && loop_setting_id.present?
        Rails.logger.info "シラサギ形式の直接入力が選択されました"
        # ループ設定IDをnilに設定
        params[:item][:loop_setting_id] = nil
        params[:item][:loop_liquid] = nil
      end
    # ループ設定が選択されている場合（loop_setting_idが有効な数値）
    else
      Rails.logger.info "ループ設定が選択されました: #{loop_setting_id}"
      # 直接入力のHTMLをクリア
      params[:item][:loop_html] = nil
    end
  end
end
