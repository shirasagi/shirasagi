class Garbage::K5374::CenterExporter < Garbage::K5374::BaseExporter
  def model
    Garbage::Node::Center
  end

  def filename
    "center.csv"
  end

  def path
    ::File.join(node.path, filename)
  end

  def headers
    %w(name rest_start rest_end).map { |k| t(k) }
  end

  def nodes
    @_nodes ||= model.site(site).
      where(filename: /^#{node.filename}\//).
      and_public
  end

  def center_csv
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << headers
        nodes.each do |node|
          row = []
          row << node.name
          row << (I18n.l(node.rest_start.to_date, format: :picker) rescue nil)
          row << (I18n.l(node.rest_end.to_date, format: :picker) rescue nil)
          data << row
        end
      end
    end
    ("\uFEFF" + csv).encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def write_csv
    @task.log "#{@node.url}#{filename}" if @task
    Fs.write(path, center_csv)
  end
end
