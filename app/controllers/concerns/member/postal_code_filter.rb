module Member::PostalCodeFilter
  extend ActiveSupport::Concern

  def postal_code
    postal_code = params.permit(:code)[:code]
    if postal_code.blank?
      render json: {}
      return
    end

    postal_code = Sys::PostalCode.search(code: postal_code).first
    raise "404" if postal_code.blank?

    render json: postal_code.attributes.except(:_id, :updated, :created)
  end
end
