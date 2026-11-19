require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "map" do
      let(:map_point1) do
        {
          name: unique_id, loc: [ 138.235266, 36.244941 ], text: Array.new(2) { unique_id }.join("\n"),
          image: "/assets/img/openlayers/marker3.png"
        }
      end
      let(:map_point2) do
        {
          name: unique_id, loc: [ 141.441159, 35.613984 ], text: Array.new(2) { unique_id }.join("\n"),
          image: "/assets/img/openlayers/marker5.png"
        }
      end
      let(:map_zoom_level) { rand(5..12) }
      let(:center_setting) { %w(auto designated_location).sample }
      let(:set_center_position) { "138.252924,36.204824" }
      let(:zoom_setting) { %w(auto designated_level).sample }
      let(:set_zoom_level) { rand(5..12) }
      let(:map_reference_method) { "direct" }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node,
          map_points: [ map_point1, map_point2 ], map_zoom_level: map_zoom_level, center_setting: center_setting,
          set_center_position: set_center_position, zoom_setting: zoom_setting, set_zoom_level: set_zoom_level,
          map_reference_method: map_reference_method
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          # puts csv_table.headers.join("\n")
          expect(csv_table.headers).to include(Article::Page.t(:map_reference_column_name))
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:map_reference_method)]).to eq page1.label(:map_reference_method)
            expect(csv_row[Article::Page.t(:map_reference_column_name)]).to be_blank
            expect(csv_row[Article::Page.t(:center_setting)]).to eq page1.label(:center_setting)
            expect(csv_row[Article::Page.t(:set_center_position)]).to eq page1.set_center_position
            expect(csv_row[Article::Page.t(:zoom_setting)]).to eq page1.label(:zoom_setting)
            expect(csv_row[Article::Page.t(:set_zoom_level)]).to eq page1.set_zoom_level.to_s
            expect(csv_row[Article::Page.t(:map_zoom_level)]).to eq page1.map_zoom_level.to_s

            "#{Article::Page.t(:map_points)}_1_#{Article::Page.t(:marker_name)}".tap do |header|
              expect(csv_row[header]).to eq map_point1[:name]
            end
            "#{Article::Page.t(:map_points)}_1_#{Article::Page.t(:marker_loc)}".tap do |header|
              expect(csv_row[header]).to eq map_point1[:loc].join(",")
            end
            "#{Article::Page.t(:map_points)}_1_#{Article::Page.t(:marker_text)}".tap do |header|
              expect(csv_row[header]).to eq map_point1[:text]
            end
            "#{Article::Page.t(:map_points)}_1_#{Article::Page.t(:marker_image)}".tap do |header|
              expect(csv_row[header]).to eq map_point1[:image]
            end

            "#{Article::Page.t(:map_points)}_2_#{Article::Page.t(:marker_name)}".tap do |header|
              expect(csv_row[header]).to eq map_point2[:name]
            end
            "#{Article::Page.t(:map_points)}_2_#{Article::Page.t(:marker_loc)}".tap do |header|
              expect(csv_row[header]).to eq map_point2[:loc].join(",")
            end
            "#{Article::Page.t(:map_points)}_2_#{Article::Page.t(:marker_text)}".tap do |header|
              expect(csv_row[header]).to eq map_point2[:text]
            end
            "#{Article::Page.t(:map_points)}_2_#{Article::Page.t(:marker_image)}".tap do |header|
              expect(csv_row[header]).to eq map_point2[:image]
            end
          end
        end
      end
    end
  end
end
