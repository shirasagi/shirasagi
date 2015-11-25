require "csv"

module Facility::PageFilter
  extend ActiveSupport::Concern

  COLUMNS = %w(
    filename name layout kana address postcode tel
    fax related_url categories locations services
    map_points groups
  )

  private
    def attributes_to_row(item, additional_columns)
      maps = Facility::Map.site(@cur_site).
        where(filename: /^#{item.filename}\//, depth: item.depth + 1)
      points = maps.map{ |m| m.map_points }.flatten.
        map{ |m| m[:loc].join(",") }

      row = []
      row << item.basename
      row << item.name
      row << item.layout.try(:name)
      row << item.kana
      row << item.address
      row << item.postcode
      row << item.tel
      row << item.fax
      row << item.related_url
      row << item.categories.map(&:name).join("\n")
      row << item.locations.map(&:name).join("\n")
      row << item.services.map(&:name).join("\n")
      row << points.join("\n")
      row << item.groups.pluck(:name).join("\n")
      additional_columns.each do |c|
        row << item.additional_info.map { |i| [i[:field], i[:value]] }.to_h[c]
      end
      row
    end

  public
    def download
      @items = Facility::Node::Page.site(@cur_site).
        where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1)
      t_columns = COLUMNS.map { |c| @model.t(c) }
      additional_columns = @items.map { |item| item.additional_info.map { |i| i[:field] } }.
        flatten.compact.uniq

      csv = CSV.generate do |data|
        data << t_columns + additional_columns.map { |c| "#{@model.t(:additional_info)}:#{c}" }
        @items.each do |item|
          data << attributes_to_row(item, additional_columns)
        end
      end

      send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
        filename: "facility_node_pages_#{Time.zone.now.to_i}.csv"
    end

    def import
      return if request.get?
      @item = @cur_node
      t_columns = COLUMNS.map { |c| @model.t(c) }

      begin
        file = params[:item].try(:[], :file)
        if file.nil? || ::File.extname(file.original_filename) != ".csv"
          raise I18n.t("facility.import.invalid_file")
        end
        table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

        # save csv to use in job
        ss_file = SS::File.new
        ss_file.in_file = file
        ss_file.model = "facility/file"
        ss_file.save

        # call job
        @job = Facility::ImportJob.call_async(ss_file.id, @cur_site.host, @cur_node.filename) do |job|
          job.site_id = @cur_site.id
        end
        SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"
        flash.now[:notice] = I18n.t("facility.import.start")
      rescue => e
        @item.errors.add :base, e.to_s
      end
    end
end
