module SS::Model::Column
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    attr_accessor :cur_form

    has_many :init_columns, class_name: 'Cms::InitColumn', dependent: :destroy, inverse_of: :column
    belongs_to :form, polymorphic: true
    field :name, type: String
    field :order, type: Integer
    field :required, type: String, default: 'required'
    field :tooltips, type: SS::Extensions::Lines
    field :prefix_label, type: String
    field :postfix_label, type: String
    field :prefix_explanation, type: String
    field :postfix_explanation, type: String

    permit_params :name, :order, :required, :tooltips, :prefix_label, :postfix_label
    permit_params :prefix_explanation, :postfix_explanation

    before_validation :set_form_id, if: ->{ @cur_form }

    validates :form_id, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :name, format: { without: /[{}"'\[\]\/]/ }, if: ->{ SS.config.cms.column_name_type == 'restricted' }
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
    validates :required, inclusion: { in: %w(required optional), allow_blank: true }
    validates :prefix_label, length: { maximum: 10 }
    validates :postfix_label, length: { maximum: 10 }

    scope :form, ->(form) { where(form_id: form.id, form_type: form.class.name) }
  end

  module ClassMethods
    SEARCH_HANDLERS = %i[search_name search_keyword].freeze

    def search(params = {})
      criteria = all
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = {})
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name
    end

    def build_column_values(hash)
      hash = hash.to_unsafe_h if hash.respond_to?(:to_unsafe_h)
      hash.filter_map do |key, value|
        column = all.find(key) rescue nil
        if column.is_a?(Gws::Column::RadioButton)
          prefix = "#{key}_"
          values = {}
          hash.each do |k, v|
            k = k.to_s
            values[k[prefix.length..-1].to_sym] = v if k.start_with?(prefix)
          end
          column.serialize_value(value, values)
        elsif column.present?
          column.serialize_value(value)
        end
      end
    end

    def value_type
      @value_type ||= name.dup.insert(name.rindex("::"), "::Value").constantize
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

  def show_partial_path
    "#{path}/show" if File.exist?("#{Rails.root}/app/views/#{path}/_show.html.erb")
  end

  def form_partial_path
    "#{path}/form" if File.exist?("#{Rails.root}/app/views/#{path}/_form.html.erb")
  end

  def column_form_partial_path
    "#{path}/column_form" if File.exist?("#{Rails.root}/app/views/#{path}/_column_form.html.erb")
  end

  def column_show_partial_path
    "#{path}/column_show" if File.exist?("#{Rails.root}/app/views/#{path}/_column_show.html.erb")
  end

  delegate :value_type, to: :class

  def serialize_value(*args)
    raise NotImplementedError
  end

  def syntax_check_enabled?
    false
  end

  def link_check_enabled?
    false
  end

  def form_check_enabled?
    required?
  end

  private

  def set_form_id
    return unless @cur_form
    self.form = @cur_form
  end
end
