class Garbage::K5374::DescriptionExporter < Garbage::K5374::BaseExporter
  def model
    Garbage::Node::Category
  end

  def filename
    "description.csv"
  end

  def path
    ::File.join(node.path, filename)
  end

  def headers
    %w(name sublabel description style bgcolor).map { |k| t(k) }
  end

  def nodes
    @_nodes ||= model.site(site).
      where(filename: /^#{node.filename}\//).
      and_public
  end

  def description_csv
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << headers
        nodes.each do |node|
          row = []
          row << node.name
          row << nil # sublabel
          row << nil # description
          row << node.style
          row << node.bgcolor
          data << row
        end
      end
    end
    ("\uFEFF" + csv).encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def write_csv
    @task.log "#{@node.url}#{filename}" if @task
    Fs.write(path, description_csv)
  end
end
