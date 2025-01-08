class Kana::BuildKanaDictinaryJob < Cms::ApplicationJob
  def perform(ids = [])
    error_message = Kana::Dictionary.build_dic(site.id, ids)
    if error_message.present?
      Rails.logger.error(error_message)
      puts error_message
    else
      message = I18n.t("kana.build_success")
      Rails.logger.info(message)
      puts message
    end
  end
end
