class Garbage::K5374::TargetExporter < Garbage::K5374::BaseExporter

  attr_reader :targets

  def initialize(cur_node, task = nil)
    super(cur_node, task)
    format_category
  end

  def model
    Garbage::Node::Page
  end

  def filename
    "target.csv"
  end

  def path
    ::File.join(node.path, filename)
  end

  def headers
    %w(category name remark kana).map { |k| t(k) }
  end

  def nodes
    @_nodes ||= model.site(site).
      where(filename: /^#{node.filename}\//).
      and_public
  end

  def format_category
    @targets = []
    nodes.each do |node|
      node.categories.each do |cate|
        first_kana = node.kana.present? ? node.kana[0] : ""
        @targets << [cate.name, node.name, node.remark, first_kana]
      end
    end
  end

  def target_csv
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << headers
        @targets.each do |row|
          data << row
        end
      end
    end
    ("\uFEFF" + csv).encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def write_csv
    @task.log "#{@node.url}#{filename}" if @task
    Fs.write(path, target_csv)
  end
end
