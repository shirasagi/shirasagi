module Sys::SiteCopy::GuideQuestions
  extend ActiveSupport::Concern
  include Sys::SiteCopy::CmsContents

  def copy_guide_questions
    # Guide::QuestionはGuide::Diagram::Pointとして保存されているため、
    # guide_diagram_pointコレクションから取得する必要がある
    question_ids = Guide::Diagram::Point.site(@src_site).where(_type: "Guide::Question").pluck(:id)
    Rails.logger.debug{ "[copy_guide_questions] コピー対象質問数: #{question_ids.size}" }
    question_ids.each do |question_id|
      question = Guide::Diagram::Point.site(@src_site).find(question_id) rescue nil
      next if question.blank?
      next unless question._type == "Guide::Question"
      Rails.logger.debug{ "[copy_guide_questions] 質問コピー開始: #{question.id_name} (#{question.id})" }
      copy_guide_question(question)
      Rails.logger.debug{ "[copy_guide_questions] 質問コピー終了: #{question.id_name} (#{question.id})" }
    end
  end

  def copy_guide_question(src_question)
    Rails.logger.debug{ "[copy_guide_question] コピー開始: #{src_question.id_name}(#{src_question.id})" }
    copy_guide_content(:guide_questions, src_question, copy_guide_question_options)
  rescue => e
    @task.log("#{src_question.id_name}(#{src_question.id}): 質問のコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_guide_content(cache_id, src_content, options = {})
    Rails.logger.debug do
      "Sys::SiteCopy::GuideQuestions[copy_guide_content] " \
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

        # Guide::Questionの場合、in_edgesからedgesを作成するためにバリデーションを実行
        if dest_content.is_a?(Guide::Question) && dest_content.in_edges.present?
          dest_content.valid?
        end
      else
        # at first, copy non-reference values and references which have no possibility of circular reference
        dest_content = klass.new(cur_site: @dest_site)
        dest_content.attributes = copy_basic_attributes(src_content, klass)

        options[:before].call(src_content, dest_content) if options[:before]

        # Guide::Questionの場合、in_edgesからedgesを作成するためにバリデーションを実行
        if dest_content.is_a?(Guide::Question) && dest_content.in_edges.present?
          dest_content.valid?
        end

        dest_content.save!
      end
      dest_content.id
    end

    Rails.logger.debug{ "[cache] キャッシュキー=#{cache_id}, 値=#{id} (#{id.class})" }

    if dest_content
      # after create item, copy references which have possibility of circular reference
      dest_content.attributes = resolve_unsafe_references(src_content, klass)

      # Guide::Questionの場合、既存のedgesをコピー
      if src_content.is_a?(Guide::Question) && src_content.edges.present?
        copy_guide_question_edges(src_content, dest_content)
      end

      dest_content.save!
      options[:after].call(src_content, dest_content) if options[:after]
    end

    dest_content ||= klass.site(@dest_site).find(id) if id
    dest_content
  end

  def resolve_guide_question_reference(id_or_ids)
    if id_or_ids.respond_to?(:each)
      return id_or_ids.map { |id| resolve_guide_question_reference(id) }
    end

    cache(:guide_questions, id_or_ids) do
      src_question = Guide::Diagram::Point.site(@src_site).find(id_or_ids) rescue nil
      if src_question.blank? || src_question._type != "Guide::Question"
        Rails.logger.warn{ "[resolve_guide_question_reference] #{id_or_ids}: 参照されている質問が存在しません。" }
        return nil
      end

      Rails.logger.debug{ "[resolve_guide_question_reference] 参照質問コピー開始: #{src_question.id_name} (#{src_question.id})" }
      dest_question = copy_guide_question(src_question)
      Rails.logger.debug{ "[resolve_guide_question_reference] コピー後の dest_question: #{dest_question&.id}" }
      dest_question.try(:id)
    end
  end

  def copy_guide_question_edges(src_question, dest_question)
    Rails.logger.debug{ "[copy_guide_question_edges] エッジコピー開始: #{src_question.id_name}" }

    src_question.edges.each do |src_edge|
      # エッジの基本属性をコピー
      edge_attributes = src_edge.attributes.except('_id', 'id')

      # point_idsを新しいIDにマッピング
      if src_edge.point_ids.present?
        new_point_ids = src_edge.point_ids.map do |point_id|
          # Guide::Diagram::Pointから該当するポイントを検索
          src_point = Guide::Diagram::Point.site(@src_site).find(point_id) rescue nil
          next nil if src_point.blank?

          # 新しいサイトで同じid_nameを持つポイントを検索
          dest_point = Guide::Diagram::Point.site(@dest_site).where(
            id_name: src_point.id_name,
            node_id: resolve_node_reference(src_point.node_id)
          ).first

          dest_point&.id
        end.compact

        edge_attributes['point_ids'] = new_point_ids
      end

      # 新しいエッジを作成
      dest_edge = dest_question.edges.new(edge_attributes)
      dest_edge.save!
    end

    Rails.logger.debug{ "[copy_guide_question_edges] エッジコピー終了: #{src_question.id_name}" }
end

  def copy_guide_question_in_edges(src_in_edges)
    return [] if src_in_edges.blank?

    src_in_edges.map do |src_edge|
      new_edge = src_edge.deep_dup

      # point_idsを新しいIDにマッピング
      if new_edge[:point_ids].present?
        new_point_ids = new_edge[:point_ids].map do |point_id|
          # Guide::Diagram::Pointから該当するポイントを検索
          src_point = Guide::Diagram::Point.site(@src_site).find(point_id) rescue nil
          next nil if src_point.blank?

          # 新しいサイトで同じid_nameを持つポイントを検索
          dest_point = Guide::Diagram::Point.site(@dest_site).where(
            id_name: src_point.id_name,
            node_id: resolve_node_reference(src_point.node_id)
          ).first

          dest_point&.id
        end.compact

        new_edge[:point_ids] = new_point_ids
      end

      new_edge
    end
  end

  private

  def copy_guide_question_options
    {
      before: ->(src_question, dest_question) do
        dest_question.site_id = @dest_site.id
        if src_question.node_id.present?
          dest_node_id = resolve_node_reference(src_question.node_id)
          Rails.logger.debug{ "[copy_guide_question_options] node_id: #{src_question.node_id} -> #{dest_node_id}" }
          dest_question.node_id = dest_node_id
        end

        # in_edges属性をコピー（Guide::Addon::Questionで処理される）
        if src_question.respond_to?(:in_edges) && src_question.in_edges.present?
          dest_question.in_edges = copy_guide_question_in_edges(src_question.in_edges)
          Rails.logger.debug{ "[copy_guide_question_options] in_edges copied: #{src_question.in_edges.size} edges" }
        end
      end
    }
  end
end
