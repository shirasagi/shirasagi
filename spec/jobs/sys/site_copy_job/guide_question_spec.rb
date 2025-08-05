require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy guide question" do
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

    describe "copy guide/question" do
      let!(:guide_node) { create :guide_node_guide, cur_site: site, layout_id: layout.id }
      let!(:question1) do
        create(:guide_question, cur_site: site, cur_node: guide_node, order: 10,
          name: "市内に移住されますか？", id_name: "question1",
          question_type: "yes_no", check_type: "single")
      end
      let!(:question2) do
        create(:guide_question, cur_site: site, cur_node: guide_node, order: 20,
          name: "地元素材を利用した住居を新築・増築・改築しますか？", id_name: "question2",
          question_type: "yes_no", check_type: "single")
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

        # コピーされた質問の確認
        expect(Guide::Question.site(dest_site).count).to eq 2

        # question1の確認
        dest_question1 = Guide::Question.site(dest_site).where(id_name: question1.id_name).first
        expect(dest_question1).to be_present
        expect(dest_question1.name).to eq question1.name
        expect(dest_question1.id_name).to eq question1.id_name
        expect(dest_question1.order).to eq question1.order
        expect(dest_question1.question_type).to eq question1.question_type
        expect(dest_question1.check_type).to eq question1.check_type
        expect(dest_question1.node_id).to eq dest_guide_node.id

        # question2の確認
        dest_question2 = Guide::Question.site(dest_site).where(id_name: question2.id_name).first
        expect(dest_question2).to be_present
        expect(dest_question2.name).to eq question2.name
        expect(dest_question2.id_name).to eq question2.id_name
        expect(dest_question2.order).to eq question2.order
        expect(dest_question2.question_type).to eq question2.question_type
        expect(dest_question2.check_type).to eq question2.check_type
        expect(dest_question2.node_id).to eq dest_guide_node.id
      end
    end

    # describe "copy guide question with edges" do
    #   let!(:guide_node) { create :guide_node_guide, cur_site: site, layout_id: layout.id }
    #   let!(:procedure) do
    #     create(:guide_procedure, cur_site: site, cur_node: guide_node, order: 10,
    #       name: "テスト手続き", id_name: "test_procedure")
    #   end
    #   let!(:question) do
    #     create(:guide_question, cur_site: site, cur_node: guide_node, order: 10,
    #       name: "テスト質問", id_name: "test_question",
    #       question_type: "yes_no", check_type: "single",
    #       in_edges: [
    #         { value: I18n.t("guide.links.applicable"), question_type: "yes_no", point_ids: [procedure.id] },
    #         { value: I18n.t("guide.links.not_applicable"), question_type: "yes_no", point_ids: [] }
    #       ])
    #   end

    #   before do
    #     perform_enqueued_jobs do
    #       ss_perform_now Sys::SiteCopyJob
    #     end
    #   end

    #   it do
    #     dest_site = Cms::Site.find_by(host: target_host_host)
    #     dest_guide_node = Guide::Node::Guide.site(dest_site).find_by(filename: guide_node.filename)
    #     dest_question = Guide::Question.site(dest_site).where(id_name: question.id_name).first
    #     dest_procedure = Guide::Procedure.site(dest_site).where(id_name: procedure.id_name).first

    #     expect(dest_question).to be_present
    #     expect(dest_procedure).to be_present

    #     # エッジの確認
    #     # expect(dest_question.edges.count).to eq 2

    #     # 適用可能エッジの確認
    #     applicable_edge = dest_question.edges.find { |edge| edge[:value] == I18n.t("guide.links.applicable") }
    #     expect(applicable_edge).to be_present
    #     expect(applicable_edge[:point_ids]).to include(dest_procedure.id)

    #     # 適用不可エッジの確認
    #     not_applicable_edge = dest_question.edges.find { |edge| edge[:value] == I18n.t("guide.links.not_applicable") }
    #     expect(not_applicable_edge).to be_present
    #     expect(not_applicable_edge[:point_ids]).to be_empty
    #   end
    # end

    describe "copy guide question with choices" do
      let!(:guide_node) { create :guide_node_guide, cur_site: site, layout_id: layout.id }
      let!(:question) do
        create(:guide_question, cur_site: site, cur_node: guide_node, order: 10,
          name: "選択肢テスト質問", id_name: "choice_question",
          question_type: "choices", check_type: "multiple",
          explanation: "複数選択可能な質問です")
      end

      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        dest_guide_node = Guide::Node::Guide.site(dest_site).find_by(filename: guide_node.filename)
        dest_question = Guide::Question.site(dest_site).where(id_name: question.id_name).first

        expect(dest_question).to be_present
        expect(dest_question.question_type).to eq "choices"
        expect(dest_question.check_type).to eq "multiple"
        expect(dest_question.explanation).to eq "複数選択可能な質問です"
        expect(dest_question.node_id).to eq dest_guide_node.id
      end
    end
  end
end
