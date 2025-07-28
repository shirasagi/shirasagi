require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy guide procedure" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ''
      task.save!
    end

    describe "copy guide/procedure" do
      let!(:guide_node) { create :guide_node_guide, cur_site: site, layout_id: layout.id }
      let!(:procedure1) do
        create(:guide_procedure, cur_site: site, cur_node: guide_node, order: 10,
          name: "住宅用自然エネルギーシステム設置費補助金制度", id_name: "procedure1",
          procedure_location: "シラサギ市役所", remarks: "地球温暖化防止対策の一環として補助します。")
      end
      let!(:procedure2) do
        create(:guide_procedure, cur_site: site, cur_node: guide_node, order: 20,
          name: "環境対策支援事業補助金", id_name: "procedure2",
          procedure_location: "シラサギ市役所", remarks: "再生可能エネルギー等の有効利用を促進します。")
      end

      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).not_to include(include('WARN'))
          expect(log.logs).not_to include(include('ERROR'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        # コピーされたノードの確認
        dest_guide_node = Guide::Node::Guide.site(dest_site).find_by(filename: guide_node.filename)
        expect(dest_guide_node).to be_present
        expect(dest_guide_node.name).to eq guide_node.name
        expect(dest_guide_node.layout_id).to eq Cms::Layout.site(dest_site).find_by(filename: layout.filename).id

        # コピーされた手続きの確認
        expect(Guide::Procedure.site(dest_site).count).to eq 2

        # procedure1の確認
        dest_procedure1 = Guide::Procedure.site(dest_site).where(id_name: procedure1.id_name).first
        expect(dest_procedure1).to be_present
        expect(dest_procedure1.name).to eq procedure1.name
        expect(dest_procedure1.id_name).to eq procedure1.id_name
        expect(dest_procedure1.order).to eq procedure1.order
        expect(dest_procedure1.procedure_location).to eq procedure1.procedure_location
        expect(dest_procedure1.remarks).to eq procedure1.remarks
        expect(dest_procedure1.node_id).to eq dest_guide_node.id

        # procedure2の確認
        dest_procedure2 = Guide::Procedure.site(dest_site).where(id_name: procedure2.id_name).first
        expect(dest_procedure2).to be_present
        expect(dest_procedure2.name).to eq procedure2.name
        expect(dest_procedure2.id_name).to eq procedure2.id_name
        expect(dest_procedure2.order).to eq procedure2.order
        expect(dest_procedure2.procedure_location).to eq procedure2.procedure_location
        expect(dest_procedure2.remarks).to eq procedure2.remarks
        expect(dest_procedure2.node_id).to eq dest_guide_node.id
      end
    end

    describe "copy guide procedure with additional fields" do
      let!(:guide_node) { create :guide_node_guide, cur_site: site, layout_id: layout.id }
      let!(:procedure) do
        create(:guide_procedure, cur_site: site, cur_node: guide_node, order: 10,
          name: "テスト手続き", id_name: "test_procedure",
          link_url: "https://example.com", html: "<p>テスト手続きの説明</p>",
          procedure_location: "テスト場所", belongings: %W[\u8EAB\u5206\u8A3C\u660E\u66F8 \u7533\u8ACB\u66F8],
          procedure_applicant: %W[\u672C\u4EBA \u4EE3\u7406\u4EBA], remarks: "テスト備考")
      end

      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        dest_guide_node = Guide::Node::Guide.site(dest_site).find_by(filename: guide_node.filename)
        dest_procedure = Guide::Procedure.site(dest_site).where(id_name: procedure.id_name).first

        expect(dest_procedure).to be_present
        expect(dest_procedure.link_url).to eq procedure.link_url
        expect(dest_procedure.html).to eq procedure.html
        expect(dest_procedure.belongings).to eq procedure.belongings
        expect(dest_procedure.procedure_applicant).to eq procedure.procedure_applicant
        expect(dest_procedure.remarks).to eq procedure.remarks
      end
    end
  end
end
