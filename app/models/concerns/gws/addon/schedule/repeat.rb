module Gws::Addon::Schedule::Repeat
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, :wdays
    belongs_to :repeat_plan, class_name: "Gws::Schedule::RepeatPlan"
    permit_params :repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, wdays: []

    validate :validate_repeat_params, if: -> { repeat? }
    validate :validate_repeat_plan, if: -> { repeat? }

    before_save :save_repeat_plan, if: -> { repeat? }
    before_save :remove_repeat_plan, if: -> { repeat_type == '' }
    after_save :extract_repeat_plans, if: -> { repeat? }
    before_destroy :remove_repeat_plan
  end

  private
    def repeat_plan_fields
      [:repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, :wdays]
    end

    def validate_repeat_params
      self.repeat_start = start_at.to_date if repeat_start.blank? && start_at
    end

    def validate_repeat_plan
      @repeat_plan = repeat_plan || Gws::Schedule::RepeatPlan.new
      repeat_plan_fields.each { |name| @repeat_plan.send "#{name}=", send(name) }
      return if @repeat_plan.valid?

      @repeat_plan.errors.to_hash.each do |key, messages|
        messages.each { |m| errors.add key, m }
      end
    end

    def save_repeat_plan
      #@extract_repeat_plans = nil
      return unless @repeat_plan.changed?

      #@extract_repeat_plans = true
      @repeat_plan.save
      self.repeat_plan_id = @repeat_plan.id
    end

    def remove_repeat_plan
      if repeat_plan
        plans = self.class.where(repeat_plan_id: repeat_plan_id, :_id.ne => id)
        repeat_plan.destroy if plans.size == 0
      end
      remove_attribute(:repeat_plan_id)
    end

  public
    # 繰り返し予定を作成しているか。
    def repeat?
      repeat_type.present?
    end

    # repleat_plan が持つ値をコピーする。
    # 同期後にplanを更新するとrepeat_planの更新処理も実行する。
    def sync_repeat_plan
      if rp = repeat_plan || Gws::Schedule::RepeatPlan.new
        repeat_plan_fields.each { |name| self.send "#{name}=", rp.send(name) }
      end
    end

    def repeat_type_options
      [:daily, :weekly, :monthly].map do |name|
        [I18n.t("gws/schedule.options.repeat_type.#{name}"), name.to_s]
      end
    end

    def interval_options
      1..10
    end

    def extract_repeat_plans
      repeat_plan.extract_plans(self)
    end
end
