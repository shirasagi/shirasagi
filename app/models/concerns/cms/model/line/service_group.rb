module Cms::Model::Line::ServiceGroup
  extend ActiveSupport::Concern
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::SitePermission

  included do
    seqid :id
    field :name, type: String
    field :order, type: Integer, default: 0
    field :state, type: String, default: "closed"
    field :start_date, type: DateTime
    field :close_date, type: DateTime
    permit_params :name, :order, :state, :start_date, :close_date

    validates :name, presence: true
    validates :start_date, datetime: true
    validates :close_date, datetime: true
    validate :validate_close_date

    default_scope -> { order_by(order: 1) }
  end

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def root_owned?(user)
    true
  end

  def term_label
    return if start_date.blank? && close_date.blank?
    h = []
    h << start_date.strftime("%Y/%m/%d") if start_date
    h << I18n.t("ss.wave_dash")
    h << close_date.strftime("%Y/%m/%d") if close_date
    h.join(" ")
  end

  private

  def validate_close_date
    return if start_date.blank? && close_date.blank?

    if start_date.blank?
      errors.add :start_date, :blank
    elsif close_date.blank?
      errors.add :close_date, :blank
    elsif start_date >= close_date
      errors.add :close_date, :greater_than, count: t(:start_date)
    end
  end

  module ClassMethods
    def and_public
      self.where(state: "public")
    end

    def active_group
      now = Time.zone.now
      self.and_public.where("$or" => [
        { start_date: nil, close_date: nil },
        { :start_date.lte => now, :close_date.gte => now }
      ]).first
    end

    def search(params)
      criteria = all
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
end
