class Guide::MermaidComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :site, :node

  def call
    @rendered_point_map = {}
    @rendered_edge_map = {}
    @additional_info = {}

    output_buffer << tag.div(class: "mermaid guide-diagnostic-chart") do
      output_buffer << "graph LR\n".html_safe
      all_questions = all_points.select { |point| point.is_a?(Guide::Question) }
      all_questions.each do |question|
        output_buffer << "\n"
        render_question(question)
      end

      if node.procedures.present?
        output_buffer << "ID_NODE{{そのほか}}\n".html_safe
        node.procedures.each do |procedure|
          output_buffer << "\n"
          output_buffer << build_point(procedure)
          output_buffer << "ID_NODE ---> ID#{procedure.id}\n".html_safe
        end
      end

      all_procedures = all_points.reject { |point| point.is_a?(Guide::Question) }
      unreachable_procedures = all_procedures.reject { |procedure| @rendered_point_map.key?(procedure.id) }
      if unreachable_procedures.present?
        output_buffer << "ID_UNREACHABLE{{\"#{escape("")}\"}}\n".html_safe

        unreachable_procedures.each do |procedure|
          output_buffer << "\n"
          output_buffer << build_point(procedure)
          output_buffer << "ID_UNREACHABLE ---> ID#{procedure.id}\n".html_safe
        end
      end
    end

    output_buffer << tag.script(type: "application/json", class: "guide-diagnostic-data") do
      output_buffer << @additional_info.to_json.html_safe
    end
  end

  def all_points
    @all_points ||= Guide::Diagram::Point.all.site(site).node(node).to_a
  end

  def find_point(id)
    @point_map ||= all_points.index_by(&:id)
    @point_map[id]
  end

  def select_points(ids)
    ret = ids.map { |id| find_point(id) }
    ret.compact!
    ret
  end

  def escape(text)
    text.delete('"')
  end

  def build_point(point)
    return if @rendered_point_map.key?(point.id)

    begin
      if point.is_a?(Guide::Question)
        @additional_info["ID#{point.id}"] = { url: guide_question_path(site: point.site_id, cid: point.node_id, id: point.id) }
        "ID#{point.id}{{\"#{escape(point.name_with_type)}\"}}\n".html_safe
      else
        @additional_info["ID#{point.id}"] = { url: guide_procedure_path(site: point.site_id, cid: point.node_id, id: point.id) }
        "ID#{point.id}[[\"#{escape(point.name_with_type)}\"]]\n".html_safe
      end
    ensure
      @rendered_point_map[point.id] = true
    end
  end

  def build_edge(from_point, to_point, edge)
    @additional_info["L-L-ID#{from_point.id}-ID#{to_point.id}"] = {
      url: guide_question_path(site: from_point.site_id, cid: from_point.node_id, id: from_point.id),
      edge_id: edge.id.to_s, point_id: to_point.id
    }

    "ID#{from_point.id} -- \"#{escape(edge.value)}\" --> ID#{to_point.id}\n".html_safe
  end

  def render_question(question)
    output_buffer << build_point(question)
    question.edges.each do |edge|
      points = select_points(edge.point_ids)
      next if points.blank?

      points.each do |point|
        output_buffer << build_point(point)
        output_buffer << build_edge(question, point, edge)
      end
    end

    child_questions = []
    question.edges.each do |edge|
      next if @rendered_edge_map.key?(edge.id)

      points = select_points(edge.point_ids)
      next if points.blank?

      points.each do |point|
        if point.is_a?(Guide::Question)
          child_questions << point
        end
      end
    ensure
      @rendered_edge_map[edge.id] = true
    end

    child_questions.each do |child_question|
      render_question(child_question)
    end
  end
end
