module Member::PostalCodeFilter
  extend ActiveSupport::Concern

  def postal_code
    postal_code = params.permit(:code)[:code]
    if postal_code.blank?
      render json: {}
      return
    end

    postal_code = postal_code.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z').gsub(/[^0-9a-zA-Z]/, '')
    postal_code = Cms::PostalCode.find_by(code: postal_code) rescue nil
    raise "404" if postal_code.blank?

    render json: postal_code.attributes.except(:_id, :updated, :created)
  end
end
