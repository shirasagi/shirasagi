require "csv"

class Cms::AllContent
  class << self
    def csv(encode: nil)
      CSV.generate do |data|
        data << header
        (Cms::Page.all + Cms::Node.all).each do |content|
          data << row(content)
        end
      end
    end

    private
      def header
        fields = %w(url group_ids group_names id file_size name index_name created released updated close_date
                    status route category_ids use_map have_files)
        fields.map { |e| I18n.t("all_content.#{e}") }
      end

      def row(content)
        [
          content.full_url,
          content.group_ids.join(","),
          Cms::Group.where(:id.in => content.group_ids).pluck(:name).join(","),
          content.id,
          file_size(content.path),
          content.name,
          content.index_name,
          content.created.strftime("%F %T"),
          content.released.try(:strftime, "%F %T"),
          content.updated.strftime("%F %T"),
          content.try(:close_date).try(:strftime, "%F %T"),
          content.status,
          content.route,
          Category::Node::Base.where(:id.in => content.category_ids).pluck(:name).join(","),
          content.try(:map_points).present?,
          content.try(:files).present?,
        ]
      end

      def file_size(file_path)
        File.exist?(file_path) ? File.stat(file_path).size : nil
      end
  end
end

