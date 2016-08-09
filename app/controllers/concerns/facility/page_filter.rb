require "csv"

module Facility::PageFilter
  extend ActiveSupport::Concern

  def download
    @items = Facility::Node::Page.site(@cur_site).
      where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1)
    csv = @items.to_csv.encode("SJIS", invalid: :replace, undef: :replace)

    send_data csv, filename: "facility_node_pages_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?
    @item = @cur_node

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("facility.import.invalid_file")
      end
      CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "facility/file"
      ss_file.save

      # call job
      Facility::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("facility.import.start")
    rescue => e
      @item.errors.add :base, e.to_s
    end
  end
end
