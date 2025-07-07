require 'spec_helper'

describe "public_entity", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:category_node) { create_once(:cms_node_node, filename: "category") }
  let(:category1) do
    create_once(
      :opendata_node_category, filename: "#{category_node.filename}/opendata_category1",
      depth: category_node.depth + 1
    )
  end
  let(:estat_category_node) { create_once(:cms_node_node, filename: "estat_category") }
  let(:estat_category1) do
    create_once(
      :opendata_node_estat_category, filename: "#{estat_category_node.filename}/opendata_estat_category1",
      depth: estat_category_node.depth + 1
    )
  end
  let(:area_node) { create_once(:cms_node_node, filename: "area") }
  let(:area1) do
    create_once(
      :opendata_node_area, filename: "#{area_node.filename}/opendata_area_1",
      depth: area_node.depth + 1
    )
  end
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:dataset) do
    create(
      :opendata_dataset, cur_node: node, metadata_dataset_id: unique_id,
      metadata_japanese_local_goverment_code: unique_id, metadata_local_goverment_name: unique_id,
      metadata_dataset_keyword: unique_id, estat_category_ids: [estat_category1.id],
      update_plan: unique_id, metadata_dataset_follow_standards: unique_id,
      metadata_dataset_related_document: unique_id, area_ids: [area1.id],
      metadata_dataset_target_period: unique_id, metadata_dataset_creator: unique_id,
      metadata_dataset_contact_name: unique_id, metadata_dataset_contact_email: unique_id,
      metadata_dataset_contact_tel: unique_id, metadata_dataset_contact_ext: unique_id,
      metadata_dataset_contact_form_url: unique_id, metadata_dataset_contact_remark: unique_id,
      metadata_dataset_remark: unique_id
    )
  end
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:resource) do
    dataset.resources.new(
      attributes_for(
        :opendata_resource, license_id: license.id, metadata_file_access_url: unique_id,
        metadata_file_download_url: unique_id,
        metadata_imported_attributes: { 'ファイル_サイズ': unique_id },
        metadata_file_terms_of_service: unique_id, metadata_file_related_document: unique_id,
        metadata_file_follow_standards: unique_id, metadata_file_copyright: unique_id
      )
    )
  end

  context "with auth" do
    before do
      Fs::UploadedFile.create_from_file(csv_file, basename: "spec") do |f|
        resource.in_file = f
        resource.save!
      end
      resource.reload

      login_cms_user
    end

    describe "#download" do
      it do
        visit opendata_dataset_public_entity_path(site, node)
        click_on I18n.t("ss.links.download")
        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true, encoding: 'Shift_JIS')
        expect(csv.length).to eq 1
        csv.each do |row|
          expect(row[0]).to eq dataset.metadata_dataset_id
          expect(row[1]).to eq dataset.metadata_japanese_local_goverment_code
          expect(row[2]).to eq dataset.metadata_local_goverment_name
          expect(row[3]).to eq dataset.name
          expect(row[4]).to be_blank
          expect(row[5]).to eq dataset.text
          expect(row[6]).to eq dataset.metadata_dataset_keyword.to_s.tr(',', ';')
          expect(row[7]).to eq estat_category1.name
          expect(row[8]).to be_blank
          expect(row[9]).to eq dataset.created.strftime("%Y-%m-%d")
          expect(row[10]).to eq dataset.updated.strftime("%Y-%m-%d")
          expect(row[11]).to be_blank
          expect(row[12]).to eq I18n.locale.to_s
          expect(row[13]).to eq dataset.full_url
          expect(row[14]).to eq dataset.update_plan
          expect(row[15]).to eq dataset.metadata_dataset_follow_standards
          expect(row[16]).to eq dataset.metadata_dataset_related_document
          expect(row[17]).to be_blank
          expect(row[18]).to eq dataset.areas.pluck(:name).join("\n")
          expect(row[19]).to eq dataset.metadata_dataset_target_period
          expect(row[20]).to eq dataset.metadata_dataset_creator
          expect(row[21]).to eq dataset.metadata_dataset_contact_name
          expect(row[22]).to eq dataset.metadata_dataset_contact_email
          expect(row[23]).to eq dataset.metadata_dataset_contact_tel
          expect(row[24]).to eq dataset.metadata_dataset_contact_ext
          expect(row[25]).to eq dataset.metadata_dataset_contact_form_url
          expect(row[26]).to eq dataset.metadata_dataset_contact_remark
          expect(row[27]).to eq dataset.metadata_dataset_remark
          expect(row[28]).to eq resource.name
          expect(row[29]).to eq resource.metadata_file_access_url
          expect(row[30]).to eq resource.metadata_file_download_url
          expect(row[31]).to eq resource.text
          expect(row[32]).to eq resource.format
          expect(row[33]).to eq license.name
          expect(row[34]).to eq '配信中'
          expect(row[35]).to eq resource.metadata_imported_attributes['ファイル_サイズ']
          expect(row[36]).to eq resource.created.strftime("%Y-%m-%d")
          expect(row[37]).to eq resource.updated.strftime("%Y-%m-%d")
          expect(row[38]).to eq resource.metadata_file_terms_of_service
          expect(row[39]).to eq resource.metadata_file_related_document
          expect(row[40]).to eq I18n.locale.to_s
          expect(row[41]).to eq resource.metadata_file_follow_standards
          expect(row[42]).to eq dataset.label(:api_state)
          expect(row[43]).to eq resource.metadata_file_copyright
        end
      end
    end
  end
end
