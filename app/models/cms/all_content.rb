require "csv"

class Cms::AllContent
  cattr_accessor :site

  class << self
    def csv(site, encode: nil)
      self.site = site

      CSV.generate do |data|
        data << header
        (Cms::Page.site(site).all + Cms::Node.site(site).all).each do |content|
          data << row(content)
        end
      end
    end

    private
      def header
        fields = %w(
          page_id node_id route name index_name url category_ids files file_urls use_map
          group_ids group_names close_date created released updated status file_size
         )
        fields.map { |e| I18n.t("all_content.#{e}") }
      end

      def row(content)
        content.site ||= site
        page_id    = (content.class == Cms::Page) ? content.id : ""
        node_id    = (content.class == Cms::Node) ? content.id : ""
        files      = content.files.map(&:name).join("\n") rescue ""
        file_urls  = content.files.map(&:url).join("\n") rescue ""
        map_points = content.map_points.map { |point| point[:loc].join(",") }.join("\n") rescue ""

        [
          page_id,
          node_id,
          content.route,
          content.name,
          content.index_name,
          content.full_url,
          Category::Node::Base.where(:id.in => content.category_ids).pluck(:name).join(","),
          files,
          file_urls,
          map_points,
          content.group_ids.join(","),
          Cms::Group.where(:id.in => content.group_ids).pluck(:name).join(","),
          content.try(:close_date).try(:strftime, "%F %T"),
          content.created.strftime("%F %T"),
          content.released.try(:strftime, "%F %T"),
          content.updated.strftime("%F %T"),
          content.label(:state),
          file_size(content),
        ]
      end

      def file_size(content)
        return nil unless File.exist?(content.path)

        size = File.stat(content.path).size
        return size unless content.respond_to?(:files)

        content.files.each do |file|
          if File.exist?(file.public_path)
            size += File.stat(file.public_path).size.to_i
          end
        end
        size
      end
  end
end

