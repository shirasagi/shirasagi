class Cms::Transaction::Unit::Base
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::SitePermission

  set_permission_name "cms_transactions", :use
  store_in collection: "cms_transaction_units"

  attr_accessor :site, :task
  attr_accessor :in_execute_date, :in_execute_hour, :in_execute_min

  field :name, type: String
  field :order, type: Integer
  field :execute_at, type: DateTime
  permit_params :name, :order
  permit_params :in_execute_date, :in_execute_hour, :in_execute_min

  before_validation :set_execute_at
  validates :name, presence: true, length: { maximum: 40 }

  belongs_to :plan, class_name: "Cms::Transaction::Plan", inverse_of: :units

  default_scope -> { order_by(order: 1, name: 1) }

  private

  def set_execute_at
    return if in_execute_date.nil?

    if in_execute_date.blank?
      self.execute_at = nil
      return
    end
    begin
      self.execute_at = Time.zone.parse(in_execute_date).change(hour: in_execute_hour, min: in_execute_min)
    rescue => e
      self.errors.add :execute_at, :invalid
    end
  end

  public

  def load_in_execute
    return if execute_at.nil?

    self.in_execute_date = I18n.t(execute_at.to_date, format: :picker)
    self.in_execute_hour = execute_at.hour.to_s
    self.in_execute_min = execute_at.min.to_s
  end

  def type
  end

  def type_options
    I18n.t("cms.options.transaction_type").map { |k, v| [v, k] }
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def long_name
    "#{order}. [#{label(:type)}] #{name}"
  end

  def hour_options
    (0..59).map { |v| ["#{v}時", v] }
  end

  def min_options
    (0..59).map { |v| ["#{v}分", v] }
  end

  def execute
    task.log "\# #{long_name}"
    if execute_at
      task.log "wait until #{I18n.l(execute_at, format: :picker)}"
      while (Time.zone.now < execute_at) do
        sleep 1
      end
    end
    execute_main
    task.log ""
  end

  def execute_main
  end
end
