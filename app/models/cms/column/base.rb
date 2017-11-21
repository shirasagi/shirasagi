class Cms::Column::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  store_in collection: 'cms_columns'

  attr_accessor :cur_form
  belongs_to :form, class_name: 'Cms::Form'
  before_validation :set_form_id, if: ->{ @cur_form }

  scope :form, ->(form) { where(form_id: form.id) }

  field :name, type: String
  field :order, type: Integer
  field :required, type: String, default: 'required'
  field :tooltips, type: SS::Extensions::Lines

  permit_params :name, :order, :required, :tooltips

  validates :form_id, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :required, inclusion: { in: %w(required optional), allow_blank: true }

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def required_options
    %w(required optional).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def required?
    self.required == 'required'
  end

  def form_options
    {}
  end

  def path
    self.class.name.underscore.sub('/column/', '/agents/columns/')
  end

  def show_file
    file = "#{Rails.root}/app/views/#{path}/_show.html.erb"
    File.exists?(file) ? file : nil
  end

  def form_file
    file = "#{Rails.root}/app/views/#{path}/_form.html.erb"
    File.exists?(file) ? file : nil
  end

  def column_form_path
    file = "#{Rails.root}/app/views/#{path}/_column_form.html.erb"
    File.exists?(file) ? file : nil
  end

  def column_show_path
    file = "#{Rails.root}/app/views/#{path}/_column_show.html.erb"
    File.exists?(file) ? file : nil
  end

  def serialize_value(*args)
    raise NotImplementedError
  end

  private

  def set_form_id
    return unless @cur_form
    self.form_id = @cur_form.id
  end
end
