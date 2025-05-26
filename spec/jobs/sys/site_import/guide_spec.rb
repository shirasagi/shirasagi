require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_setting) { create :cms_loop_setting, site: source_site }

  let!(:node1) { create :guide_node_guide, site: source_site }
  let!(:procedure1_1) do
    create(:guide_procedure, cur_site: source_site, cur_node: node1, order: 10,
      name: "procedure1", id_name: unique_id)
  end
  let!(:procedure1_2) do
    create(:guide_procedure, cur_site: source_site, cur_node: node1, order: 20,
      name: "procedure2", id_name: unique_id)
  end
  let!(:question1_1) do
    create(:guide_question, cur_site: source_site, cur_node: node1, order: 10,
      name: "question1", id_name: unique_id, in_edges: in_edges(procedure1_1))
  end
  let!(:question1_2) do
    create(:guide_question, cur_site: source_site, cur_node: node1, order: 20,
      name: "question2", id_name: unique_id, in_edges: in_edges(procedure1_2))
  end

  let!(:node2) { create :guide_node_guide, site: source_site }
  let!(:procedure2_1) do
    create(:guide_procedure, cur_site: source_site, cur_node: node2, order: 10,
      name: "procedure1", id_name: unique_id)
  end
  let!(:procedure2_2) do
    create(:guide_procedure, cur_site: source_site, cur_node: node2, order: 20,
      name: "procedure2", id_name: unique_id)
  end
  let!(:question2_1) do
    create(:guide_question, cur_site: source_site, cur_node: node2, order: 10,
      name: "question1", id_name: unique_id, in_edges: in_edges(procedure2_1))
  end
  let!(:question2_2) do
    create(:guide_question, cur_site: source_site, cur_node: node2, order: 20,
      name: "question2", id_name: unique_id, in_edges: in_edges(procedure2_2))
  end

  def in_edges(point)
    [
      { value: I18n.t("guide.links.applicable"), question_type: "yes_no", point_ids: [point.id] },
      { value: I18n.t("guide.links.not_applicable"), question_type: "yes_no", point_ids: [] }
    ]
  end

  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.task = ::Tasks::Cms.mock_task(source_site_id: source_site.id)
      job.perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    it do
      job = ::Sys::SiteImportJob.new
      job.task = ::Tasks::Cms.mock_task(target_site_id: destination_site.id, import_file: file_path)
      job.perform

      expect(Guide::Node::Guide.site(destination_site).count).to eq 2
      dest_node1 = Guide::Node::Guide.site(destination_site).where(filename: node1.filename).first
      dest_node2 = Guide::Node::Guide.site(destination_site).where(filename: node2.filename).first
      expect(dest_node1).to be_present
      expect(dest_node2).to be_present

      # node1
      expect(Guide::Procedure.site(destination_site).node(dest_node1).count).to eq 2
      dest_procedure1_1 = Guide::Procedure.site(destination_site).node(dest_node1).where(id_name: procedure1_1.id_name).first
      dest_procedure1_2 = Guide::Procedure.site(destination_site).node(dest_node1).where(id_name: procedure1_2.id_name).first
      expect(dest_procedure1_1).to be_present
      expect(dest_procedure1_2).to be_present

      expect(Guide::Question.site(destination_site).node(dest_node1).count).to eq 2
      dest_question1_1 = Guide::Question.site(destination_site).node(dest_node1).where(id_name: question1_1.id_name).first
      dest_question1_2 = Guide::Question.site(destination_site).node(dest_node1).where(id_name: question1_2.id_name).first
      expect(dest_question1_1).to be_present
      expect(dest_question1_2).to be_present

      dest_question1_1_edges = dest_question1_1.edges.map do |edge|
        { value: edge[:value], question_type: edge[:question_type], point_ids: edge[:point_ids] }
      end
      dest_question1_2_edges = dest_question1_2.edges.map do |edge|
        { value: edge[:value], question_type: edge[:question_type], point_ids: edge[:point_ids] }
      end
      expect(dest_question1_1_edges).to match_array(in_edges(dest_procedure1_1))
      expect(dest_question1_2_edges).to match_array(in_edges(dest_procedure1_2))

      # node2
      expect(Guide::Procedure.site(destination_site).node(dest_node2).count).to eq 2
      dest_procedure2_1 = Guide::Procedure.site(destination_site).node(dest_node2).where(id_name: procedure2_1.id_name).first
      dest_procedure2_2 = Guide::Procedure.site(destination_site).node(dest_node2).where(id_name: procedure2_2.id_name).first
      expect(dest_procedure2_1).to be_present
      expect(dest_procedure2_2).to be_present

      expect(Guide::Question.site(destination_site).node(dest_node2).count).to eq 2
      dest_question2_1 = Guide::Question.site(destination_site).node(dest_node2).where(id_name: question2_1.id_name).first
      dest_question2_2 = Guide::Question.site(destination_site).node(dest_node2).where(id_name: question2_2.id_name).first
      expect(dest_question2_1).to be_present
      expect(dest_question2_2).to be_present

      dest_question2_1_edges = dest_question2_1.edges.map do |edge|
        { value: edge[:value], question_type: edge[:question_type], point_ids: edge[:point_ids] }
      end
      dest_question2_2_edges = dest_question2_2.edges.map do |edge|
        { value: edge[:value], question_type: edge[:question_type], point_ids: edge[:point_ids] }
      end
      expect(dest_question2_1_edges).to match_array(in_edges(dest_procedure2_1))
      expect(dest_question2_2_edges).to match_array(in_edges(dest_procedure2_2))
    end
  end
end
