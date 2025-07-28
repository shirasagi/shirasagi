module Cms::GenerateJobFilter
  extend ActiveSupport::Concern

  private

  def job_options
    @segment.present? ? { segment: @segment } : {}
  end

  def generate_segments
    []
  end

  def set_segment
    @segments = generate_segments
    return if @segments.blank?

    @segment = params[:segment]
    @segment = nil if !@segments.include?(@segment)
  end

  def set_item
    set_segment

    if @segments.present? && @segment.blank?
      redirect_to({ action: :index, segment: @segments.first })
      return
    end

    criteria = Cms::Task.all
    criteria = criteria.where(name: task_name, site_id: @cur_site.id)
    if @cur_node
      criteria = criteria.where(node_id: @cur_node.id)
    else
      criteria = criteria.where(node_id: nil)
    end
    if @segment
      criteria = criteria.where(segment: @segment)
    else
      criteria = criteria.where(segment: nil)
    end
    @item = criteria.reorder(id: 1).first_or_create
  end
end
