module SS::Model::Column
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    attr_accessor :cur_form

    belongs_to :form, polymorphic: true
    field :name, type: String
    field :order, type: Integer
    field :required, type: String, default: 'required'
    field :tooltips, type: SS::Extensions::Lines
    field :prefix_label, type: String
    field :postfix_label, type: String

    permit_params :name, :order, :required, :tooltips, :prefix_label, :postfix_label

    before_validation :set_form_id, if: ->{ @cur_form }

    validates :form_id, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
    validates :required, inclusion: { in: %w(required optional), allow_blank: true }
    validates :prefix_label, length: { maximum: 80 }
    validates :postfix_label, length: { maximum: 80 }

    scope :form, ->(form) { where(form_id: form.id, form_type: form.class.name) }
  end

  module ClassMethods
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      criteria = criteria.search_name(params)
      criteria = criteria.search_keyword(params)
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
      hash.map do |key, value|
        column = all.find(key) rescue nil
        next nil if column.blank?

        column.serialize_value(value)
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
