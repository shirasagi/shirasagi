class Gws::Column::Base
  include SS::Document
  include SS::Model::Column
  include Gws::Reference::Site

  store_in collection: 'gws_columns'

  after_destroy :update_form
  after_save :update_form

  def to_es
    texts = []
    texts << name
    texts += tooltips.to_a
    texts += select_options.to_a if respond_to?(:select_options)
    texts.select(&:present?).join("\r\n")
  end

  private

  def update_form
    return if form.nil?
    return if form.instance_variable_get(:@destroy_parent)

    update_forms = form.class.try(:update_forms) rescue nil
    return if update_forms.blank?

    update_forms.each { |callback| callback.call(form) }
  end
end
