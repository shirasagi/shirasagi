class Gws::Column::Base
  include SS::Document
  include SS::Model::Column
  include Gws::Reference::Site

  attr_accessor :skip_elastic

  store_in collection: 'gws_columns'

  after_destroy :update_form
  after_save :update_form

  class << self
    def default_attributes
      {
        name: self.model_name.human
      }
    end

    def inherited(subclass)
      super

      subclass.cattr_accessor(:use_required, instance_accessor: false)
      subclass.use_required = true
    end
  end

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

  def set_required_optional
    self.required = 'optional'
  end
end
