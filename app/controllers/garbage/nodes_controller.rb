class Garbage::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Page

  private

  def redirect_url
    diff = (@item.route.pluralize != "garbage/pages")
    diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def send_csv(items)
    require "csv"

    csv = CSV.generate do |data|
      data << [
        @model.t(:filename),
        @model.t(:name),
        @model.t(:layout),
        @model.t(:category_ids),
        @model.t(:remark),
        @model.t(:groups)
      ]
      items.each do |item|
        row = []
        row << item.basename
        row << item.name
        row << item.layout.try(:name)
        row << item.categories.pluck(:name).join("\n")
        row << item.remark
        row << item.groups.pluck(:name).join("_n")
        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "garbage_pages_#{Time.zone.now.strftime("%Y_%m%d_%H%M")}.csv"
  end

  public

  def download
    send_csv @cur_node.children.map(&:becomes_with_route)
  end

  def import
    return if request.get?
    @item = @model.new

    file = params.dig(:item, :file)
    if file.blank?
      @item.errors.add :base, I18n.t("ss.errors.import.blank_file")
      return
    end

    if ::File.extname(file.original_filename) != ".csv"
      @item.errors.add :base, I18n.t("ss.errors.import.invalid_file_type")
      return
    end

    begin
      CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    rescue => e
      @item.errors.add :base, I18n.t("ss.errors.import.invalid_file_type")
      return
    end

    begin
      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "garbage/file"
      ss_file.save!

      # call job
      Garbage::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      @item.errors.add :base, e.to_s
    end
  end
end
