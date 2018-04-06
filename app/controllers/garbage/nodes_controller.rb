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
        @model.t(:remark)
      ]
      items.each do |item|
        row = []
        row << item.basename
        row << item.name
        row << item.layout.try(:name)
        row << item.categories.map(&:name).join("\n")
        row << item.remark
        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "garbage_pages_#{Time.now.strftime("%Y_%m%d_%H%M")}.csv"
  end

  public

  def download
    send_csv @cur_node.children.map(&:becomes_with_route)
  end

  def import
    return if request.get?
    @item = @model.new

    in_file = params.dig(:item, :file)
    if in_file.blank?
      @item.errors.add :base, "ファイルを選択してください。"
      return
    end

    begin
      CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      in_file.rewind
    rescue => e
      @item.errors.add :base, "不正なファイル形式です。"
    end

    result = import_csv(in_file)
    render_create result, location: { action: :import }
    flash.now[:notice] = "#{@count}件の更新をおこないました。"
  end

  def import_csv(csv)
    require "csv"

    @count = 0
    st_categories = @cur_node.becomes_with_route.st_categories.map{|c| [c.name, c.id]}.to_h

    # destroy all documents
    @cur_node.children.where(route: "garbage/page").destroy_all

    # update documents
    table = CSV.read(csv.tempfile.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, idx|

      begin
        filename = row[@model.t("filename")].to_s.strip
        name     = row[@model.t("name")].to_s.strip
        layout   = Cms::Layout.where(name: row[@model.t("layout")].to_s.strip).first
        remark   = row[@model.t("remark")].to_s.strip
        categories = row[@model.t("category_ids")].to_s.strip.split("\n")
        categories_ids = categories.map{ |c| st_categories[c] }.compact

        raise "フォルダー名を入力してください。" if filename.blank?

        filename = ::File.join(@cur_node.filename, filename)
        cond = { site_id: @cur_site.id, filename: filename }

        item = Garbage::Node::Page.find_or_create_by(cond)
        item.name   = name
        item.remark = remark
        item.layout = layout
        item.category_ids = categories_ids

        item.cur_site = @cur_site
        item.cur_node = @cur_node
        item.cur_user = @cur_user

        if item.save
          @count += 1
        else
          raise item.errors.full_messages.join(", ")
        end

      rescue => e
        @item.errors.add :base, "インポート失敗#{idx + 2}行目: #{e.to_s}"
      end

    end

    @item.errors.empty?
  end
end
