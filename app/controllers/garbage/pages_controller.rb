class Garbage::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Page

  prepend_view_path "app/views/cms/node/nodes"
  menu_view "garbage/page/menu"

  public
    def download
      send_csv @cur_node.children.map(&:becomes_with_route)
    end

    def import
      return if request.get?
      @item = Garbage::Node::Page.new

      if params[:item] && params[:item][:file]
        begin
          if ::File.extname(params[:item][:file].original_filename) != ".csv"
            raise "CSV形式のファイルを選択してください。"
          end

          import_csv params[:item][:file]
        rescue => e
          @item.errors.add :base, "エラーが発生しました。: #{e.to_s}"
        end
      end
    end

  private
    def send_csv(items)
      require "csv"

      csv = CSV.generate do |data|
        data << %w(filename name layout categories remark)
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

    def import_csv(csv)
      require "csv"

      count = 0
      st_categories = @cur_node.becomes_with_route.st_categories.map{|c| [c.name, c.id]}.to_h

      # dummy read
      table = CSV.read(csv.tempfile.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, idx|
        #
      end

      # destroy all documents
      @cur_node.children.where(route: /garbage\/page/).destroy_all

      # update documents
      table = CSV.read(csv.tempfile.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, idx|

        begin
          filename = row["filename"].to_s.gsub(/\s/, "")
          name     = row["name"].to_s.gsub(/\s/, "")
          layout   = Cms::Layout.where(name: row["layout"].to_s).first
          remark   = row["remark"]
          categories = row["categories"].to_s.strip.split("\n")

          raise "フォルダー名（filename）を入力してください。" if filename.blank?

          filename = ::File.join(@cur_node.filename, filename)
          cond = { site_id: @cur_site.id, filename: filename }

          item = Garbage::Node::Page.find_or_create_by(cond)
          item.name   = name
          item.remark = remark
          item.layout = layout
          item.category_ids = categories.map{ |c| st_categories[c] }

          if item.save
            count += 1
          else
            raise item.errors.full_messages.join(", ")
          end

        rescue => e
          @item.errors.add :base, "インポート失敗#{idx + 2}行目: #{e.to_s}"
        end

      end

      flash.now[:notice] = "#{count}件の更新をおこないました。"
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "garbage/page" }
    end
end
