module Sys::SiteCopy::GuideProcedures
  extend ActiveSupport::Concern
  include Sys::SiteCopy::CmsContents

  def copy_guide_procedures
    # Guide::ProcedureはGuide::Diagram::Pointとして保存されているため、
    # guide_diagram_pointコレクションから取得する必要がある
    procedure_ids = Guide::Diagram::Point.site(@src_site).where(_type: "Guide::Procedure").pluck(:id)
    Rails.logger.debug{ "[copy_guide_procedures] コピー対象手続き数: #{procedure_ids.size}" }
    procedure_ids.each do |procedure_id|
      procedure = Guide::Diagram::Point.site(@src_site).find(procedure_id) rescue nil
      next if procedure.blank?
      next unless procedure._type == "Guide::Procedure"
      Rails.logger.debug{ "[copy_guide_procedures] 手続きコピー開始: #{procedure.id_name} (#{procedure.id})" }
      copy_guide_procedure(procedure)
      Rails.logger.debug{ "[copy_guide_procedures] 手続きコピー終了: #{procedure.id_name} (#{procedure.id})" }
    end
  end

  def copy_guide_procedure(src_procedure)
    Rails.logger.debug{ "[copy_guide_procedure] コピー開始: #{src_procedure.id_name}(#{src_procedure.id})" }
    copy_guide_content(:guide_procedures, src_procedure, copy_guide_procedure_options)
  rescue => e
    @task.log("#{src_procedure.id_name}(#{src_procedure.id}): 手続きのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_guide_content(cache_id, src_content, options = {})
    Rails.logger.debug do
      "Sys::SiteCopy::GuideProcedures[copy_guide_content] " \
        "コピー開始 (src_content.id_name=#{src_content.try(:id_name)}," \
        "node_id=#{src_content.try(:node_id)})"
    end
    klass = src_content.class
    dest_content = nil
    id = cache(cache_id, src_content.id) do
      # Guide::Diagram::Pointはfilenameを持たないため、id_nameとnode_idで検索
      dest_content = klass.site(@dest_site).where(id_name: src_content.id_name,
node_id: resolve_node_reference(src_content.node_id)).first

      if dest_content.present?
        options[:before].call(src_content, dest_content) if options[:before]
      else
        # at first, copy non-reference values and references which have no possibility of circular reference
        dest_content = klass.new(cur_site: @dest_site)
        dest_content.attributes = copy_basic_attributes(src_content, klass)

        options[:before].call(src_content, dest_content) if options[:before]
        dest_content.save!
      end
      dest_content.id
    end

    Rails.logger.debug{ "[cache] キャッシュキー=#{cache_id}, 値=#{id} (#{id.class})" }

    if dest_content
      # after create item, copy references which have possibility of circular reference
      dest_content.attributes = resolve_unsafe_references(src_content, klass)
      dest_content.save!
      options[:after].call(src_content, dest_content) if options[:after]
    end

    dest_content ||= klass.site(@dest_site).find(id) if id
    dest_content
  end

  def resolve_guide_procedure_reference(id_or_ids)
    if id_or_ids.respond_to?(:each)
      return id_or_ids.map { |id| resolve_guide_procedure_reference(id) }
    end

    cache(:guide_procedures, id_or_ids) do
      src_procedure = Guide::Diagram::Point.site(@src_site).find(id_or_ids) rescue nil
      if src_procedure.blank? || src_procedure._type != "Guide::Procedure"
        Rails.logger.warn{ "[resolve_guide_procedure_reference] #{id_or_ids}: 参照されている手続きが存在しません。" }
        return nil
      end

      Rails.logger.debug{ "[resolve_guide_procedure_reference] 参照手続きコピー開始: #{src_procedure.id_name} (#{src_procedure.id})" }
      dest_procedure = copy_guide_procedure(src_procedure)
      Rails.logger.debug{ "[resolve_guide_procedure_reference] コピー後の dest_procedure: #{dest_procedure&.id}" }
      dest_procedure.try(:id)
    end
  end

  private

  def copy_guide_procedure_options
    {
      before: ->(src_procedure, dest_procedure) do
        dest_procedure.site_id = @dest_site.id
        if src_procedure.node_id.present?
          dest_node_id = resolve_node_reference(src_procedure.node_id)
          Rails.logger.debug{ "[copy_guide_procedure_options] node_id: #{src_procedure.node_id} -> #{dest_node_id}" }
          dest_procedure.node_id = dest_node_id
        end
      end
    }
  end
end
