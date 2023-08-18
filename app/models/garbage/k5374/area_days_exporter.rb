class Garbage::K5374::AreaDaysExporter < Garbage::K5374::BaseExporter

  attr_reader :area_days, :remarks, :remark_count

  def initialize(cur_node, task = nil)
    super(cur_node, task)
    format_garbage_type
  end

  def model
    Garbage::Node::Area
  end

  def area_days_path
    ::File.join(node.path, "area_days.csv")
  end

  def remarks_path
    ::File.join(node.path, "remarks.csv")
  end

  def area_days_headers
    h = %w(name center).map { |k| t(k) }
    h += garbage_type_fields
    h
  end

  def remarks_headers
    %w(id remark).map { |k| t(k) }
  end

  def garbage_type_fields
    @_garbage_type_fields ||= nodes.map { |node| node.garbage_type.map { |v| v["field"] } }.flatten.uniq
  end

  def nodes
    @_nodes ||= model.site(site).
      where(filename: /^#{node.filename}\//).
      and_public.
      select { |item| item.garbage_type.present? }
  end

  def format_garbage_type
    @area_days = []

    @remark_count = 0
    @remarks = []

    nodes.each do |node|
      row = []
      row << node.name
      row << node.center
      garbage_type_fields.each do |field|
        type = node.garbage_type.select { |v| v["field"] == field }.first
        if type.nil?
          row << ""
          next
        end

        value = type["value"]
        if type["remarks"].present?
          @remark_count += 1
          @remarks << [@remark_count, type["remarks"]]
          value += " *#{@remark_count}"
        end
        row << value
      end
      @area_days << row
    end
  end

  def area_days_csv
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << area_days_headers
        @area_days.each do |row|
          data << row
        end
      end
    end
    ("\uFEFF" + csv).encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def remarks_csv
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << remarks_headers
        @remarks.each do |row|
          data << row
        end
      end
    end
    ("\uFEFF" + csv).encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def write_csv
    @task.log "#{@node.url}area_days.csv" if @task
    Fs.write(area_days_path, area_days_csv)

    @task.log "#{@node.url}remarks.csv" if @task
    Fs.write(remarks_path, remarks_csv)
  end
end
