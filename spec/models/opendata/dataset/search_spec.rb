require 'spec_helper'

describe Opendata::Dataset, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset, cur_site: site) }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }
  let!(:name1) { unique_id }
  let!(:name2) { unique_id }
  let!(:name3) { unique_id }
  let!(:keyword1) { unique_id }
  let!(:keyword2) { unique_id }
  let!(:keyword3) { unique_id }
  let!(:tag1) { unique_id }
  let!(:tag2) { unique_id }
  let!(:tag3) { unique_id }
  let!(:dataset1) do
    create(
      :opendata_dataset, cur_site: site, cur_node: node, name: "#{name1} #{name2}",
      text: "#{keyword1} #{keyword2}", tags: [ tag1, tag2 ]
    )
  end
  let!(:dataset2) do
    create(
      :opendata_dataset, cur_site: site, cur_node: node, name: "#{name2} #{name3}",
      text: "#{keyword2} #{keyword3}", tags: [ tag2, tag3 ]
    )
  end
  let!(:dataset3) do
    create(
      :opendata_dataset, cur_site: site, cur_node: node, name: "#{name3} #{name1}",
      text: "#{keyword3} #{keyword1}", tags: [ tag1, tag3 ]
    )
  end
  let!(:dataset_closed) do
    create(
      :opendata_dataset, cur_site: site, cur_node: node, state: "closed", name: "#{name1} #{name2}",
      text: "#{keyword1} #{keyword2} #{keyword3}", tags: [ tag1, tag2, tag3 ]
    )
  end

  let(:site_other) { create :cms_site_unique }
  let!(:node_search_other) { create(:opendata_node_search_dataset, cur_site: site_other) }
  let!(:node_other) { create(:opendata_node_dataset, cur_site: site_other) }
  let!(:dataset_other) do
    create(
      :opendata_dataset, cur_site: site_other, cur_node: node_other, name: "#{name3} #{name1}",
      text: "#{keyword1} #{keyword2} #{keyword3}", tags: [ tag1, tag2, tag3 ]
    )
  end

  let(:base_criteria) { described_class.site(site).and_public }
  subject { base_criteria.search(search_params).pluck(:id) }

  describe ".search" do
    context 'with nil' do
      let(:search_params) { nil }
      it { expect(subject.length).to eq 3 }
    end

    context 'with empty hash' do
      let(:search_params) { {} }
      it { expect(subject.length).to eq 3 }
    end

    context 'with keyword' do
      context 'with single keyword' do
        let(:search_params) { { keyword: keyword1 } }
        it { expect(subject.length).to eq 2 }
      end

      context 'with 2 keywords' do
        let(:search_params) { { keyword: [ keyword2, keyword3 ].join(" ") } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with 3 keywords' do
        let(:search_params) { { keyword: [ keyword1, keyword2, keyword3 ].join(" ") } }
        it { expect(subject.length).to eq 0 }
      end
    end

    context 'with keyword and all_keywords' do
      context 'with single keyword' do
        let(:search_params) { { keyword: keyword1, option: 'all_keywords' } }
        it { expect(subject.length).to eq 2 }
      end

      context 'with 2 keywords' do
        let(:keyword) { [ keyword2, keyword3 ].join(" ") }
        let(:search_params) { { keyword: keyword, option: 'all_keywords' } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with 3 keywords' do
        let(:keyword) { [ keyword1, keyword2, keyword3 ].join(" ") }
        let(:search_params) { { keyword: keyword, option: 'all_keywords' } }
        it { expect(subject.length).to eq 0 }
      end
    end

    context 'with keyword and any_keywords' do
      context 'with single keyword' do
        let(:search_params) { { keyword: keyword1, option: 'any_keywords' } }
        it { expect(subject.length).to eq 2 }
      end

      context 'with 2 keywords' do
        let(:keyword) { [ keyword2, keyword3 ].join(" ") }
        let(:search_params) { { keyword: keyword, option: 'any_keywords' } }
        it { expect(subject.length).to eq 3 }
      end

      context 'with 3 keywords' do
        let(:keyword) { [ keyword1, keyword2, keyword3 ].join(" ") }
        let(:search_params) { { keyword: keyword, option: 'any_keywords' } }
        it { expect(subject.length).to eq 3 }
      end
    end

    context 'with ids' do
      context 'with single id' do
        let(:search_params) { { ids: dataset1.id.to_s } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with 2 ids' do
        let(:search_params) { { ids: [ dataset1.id.to_s, dataset2.id.to_s ].join(",") } }
        it { expect(subject.length).to eq 2 }
      end
    end

    context 'with name' do
      context 'with single name' do
        let(:search_params) { { name: name1 } }
        it { expect(subject.length).to eq 2 }
      end

      context 'with 2 names' do
        let(:search_params) { { name: [ name1, name3 ].join(" ") } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with modal' do
        let(:search_params) { { name: [ name1, name3 ].join(" "), modal: true } }
        it { expect(subject.length).to eq 1 }
      end
    end

    context 'with tag' do
      let(:search_params) { { tag: [ tag1, tag2, tag3 ].sample } }
      it { expect(subject.length).to eq 2 }
    end

    context 'with area_id' do
      let!(:area1) { create :opendata_node_area }
      let!(:area2) { create :opendata_node_area }
      let(:search_params) { { area_id: area1.id.to_s } }

      before do
        dataset1.update(area_ids: [ area1.id ])
        dataset2.update(area_ids: [ area2.id ])
      end

      it { expect(subject.length).to eq 1 }
    end

    context 'with category_id' do
      let!(:category1) { create :opendata_node_category }
      let!(:category2) { create :opendata_node_category }
      let(:search_params) { { site: cms_site, category_id: category2.id.to_s } }

      before do
        dataset1.update(category_ids: [ category1.id ])
        dataset2.update(category_ids: [ category2.id ])
      end

      it { expect(subject.length).to eq 1 }
    end

    context 'with dataset_group / dataset_group_id' do
      let!(:category) { create :opendata_node_category }
      let!(:dataset_group1) { create :opendata_dataset_group, category_ids: [ category.id ] }
      let!(:dataset_group2) { create :opendata_dataset_group, category_ids: [ category.id ] }

      before do
        dataset1.update(dataset_group_ids: [ dataset_group1.id ])
        dataset2.update(dataset_group_ids: [ dataset_group2.id ])
        dataset3.unset(:dataset_group_ids)
      end

      context 'with dataset_group' do
        let(:search_params) { { site: cms_site, dataset_group: dataset_group1.name } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with dataset_group_id' do
        let(:search_params) { { site: cms_site, dataset_group_id: dataset_group1.id.to_s } }
        it { expect(subject.length).to eq 1 }
      end
    end

    context 'with format / license_id' do
      let!(:license1) { create(:opendata_license) }
      let!(:license2) { create(:opendata_license) }

      before do
        resource = dataset1.resources.new(attributes_for(:opendata_resource))
        file = Rails.root.join("spec/fixtures/opendata/shift_jis.csv")
        Fs::UploadedFile.create_from_file(file, basename: "spec", content_type: "application/vnd.ms-excel") do |in_file|
          resource.in_file = in_file
          resource.license_id = license1.id
          resource.save!
        end

        resource = dataset2.resources.new(attributes_for(:opendata_resource))
        file = Rails.root.join("spec/fixtures/ss/logo.png")
        Fs::UploadedFile.create_from_file(file, basename: "spec", content_type: "image/png") do |in_file|
          resource.in_file = in_file
          resource.license_id = license2.id
          resource.save!
        end
      end

      context 'with format "csv"' do
        let(:search_params) { { format: "csv" } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with license_id' do
        let(:search_params) { { license_id: license2.id.to_s } }
        it { expect(subject.length).to eq 1 }
      end
    end

    context 'with poster' do
      let!(:member1) { create :cms_member }
      let!(:member2) { create :cms_member }

      before do
        dataset1.update(workflow_member_id: member1.id)
        dataset2.update(workflow_member_id: member2.id)
      end

      context 'with "member"' do
        let(:search_params) { { poster: "member" } }
        it { expect(subject.length).to eq 2 }
      end

      context 'with "admin"' do
        let(:search_params) { { poster: "admin" } }
        it { expect(subject.length).to eq 1 }
      end
    end

    context 'with composite params' do
      let(:search_params) { { keyword: keyword3, tag: tag2 } }
      it { expect(subject.length).to eq 1 }
    end

    context 'with composite params with any_conditions' do
      let(:search_params) { { keyword: keyword3, tag: tag2, option: 'any_conditions' } }
      it { expect(subject.length).to eq 3 }
    end
  end
end
