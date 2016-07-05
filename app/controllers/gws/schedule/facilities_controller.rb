class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_category, only: :index

  private
    def facility_category_criteria
      Gws::Facility::Category.site(@cur_site).readable(@cur_user, @cur_site)
    end

    def set_category
      set_facility_category
      set_schedule_category
    end

    def set_facility_category
      @facility_categories = facility_category_criteria.tree_sort

      if params[:s].blank?
        @facility_category ||= begin
          c = @facility_categories.find { |c| c.id.present? }
          c = facility_category_criteria.find(c.id) rescue nil
          c
        end
        return
      end

      facility_category_id = params.dig(:s, :facility_category_id)
      if facility_category_id.present?
        @facility_category = facility_category_criteria.find(facility_category_id) rescue nil
      end
    end

    def set_schedule_category
      @schedule_categories = Gws::Schedule::Category.site(@cur_site).readable(@cur_user, @cur_site)

      schedule_category_id = params.dig(:s, :category_id)
      if schedule_category_id.present?
        @schedule_category = @schedule_categories.find(schedule_category_id) rescue nil
      end
    end

    def category_ids
      return nil if @facility_category.blank?
      ids = facility_category_criteria.where(name: /^#{Regexp.escape(@facility_category.name)}\//).pluck(:id)
      ids << @facility_category.id
    end

  public
    def index
      @items = Gws::Facility::Item.site(@cur_site).
        readable(@cur_user, @cur_site).
        active
      @items = @items.in(category_id: category_ids)
    end
end
