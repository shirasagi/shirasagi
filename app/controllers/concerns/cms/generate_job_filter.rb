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

    opts = {
      name: task_name,
      site_id: @cur_site.id
    }
    opts[:node_id] = @cur_node.id if @cur_node
    opts[:segment] = @segment if @segment
    @item = Cms::Task.find_or_create_by(opts)
  end
end
