require 'spec_helper'

describe Opendata::App, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search) { create(:opendata_node_search_app, cur_site: site) }
  let!(:node) { create(:opendata_node_app, cur_site: site) }
  let!(:name1) { unique_id }
  let!(:name2) { unique_id }
  let!(:name3) { unique_id }
  let!(:keyword1) { unique_id }
  let!(:keyword2) { unique_id }
  let!(:keyword3) { unique_id }
  let!(:tag1) { unique_id }
  let!(:tag2) { unique_id }
  let!(:tag3) { unique_id }
  let!(:license1) { unique_id }
  let!(:license2) { unique_id }
  let!(:license3) { unique_id }
  let!(:app1) do
    create(
      :opendata_app, cur_site: site, cur_node: node, name: "#{name1} #{name2}", text: "#{keyword1} #{keyword2}",
      tags: [ tag1, tag2 ], license: "#{license1} #{license2}"
    )
  end
  let!(:app2) do
    create(
      :opendata_app, cur_site: site, cur_node: node, name: "#{name2} #{name3}", text: "#{keyword2} #{keyword3}",
      tags: [ tag2, tag3 ], license: "#{license2} #{license3}"
    )
  end
  let!(:app3) do
    create(
      :opendata_app, cur_site: site, cur_node: node, name: "#{name3} #{name1}", text: "#{keyword3} #{keyword1}",
      tags: [ tag1, tag3 ], license: "#{license3} #{license1}"
    )
  end
  let!(:app_closed) do
    create(
      :opendata_app, cur_site: site, cur_node: node, state: "closed",
      text: "#{keyword1} #{keyword2} #{keyword3}", tags: [ tag1, tag2, tag3 ]
    )
  end
  let(:site_other) { create :cms_site_unique }
  let!(:node_other) { create(:opendata_node_app, cur_site: site_other) }
  let!(:node_search_other) { create(:opendata_node_search_app, cur_site: site_other) }
  let!(:app_other) do
    create(:opendata_app, cur_site: site_other, cur_node: node_other, text: "#{keyword1} #{keyword2}", tags: [ tag1, tag2 ])
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

    context 'with only site' do
      let(:search_params) { { site: site } }
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
        app1.update(area_ids: [ area1.id ])
        app2.update(area_ids: [ area2.id ])
      end

      it { expect(subject.length).to eq 1 }
    end

    context 'with category_id' do
      let!(:category1) { create :opendata_node_category }
      let!(:category2) { create :opendata_node_category }
      let(:search_params) { { site: cms_site, category_id: category2.id.to_s } }

      before do
        app1.update(category_ids: [ category1.id ])
        app2.update(category_ids: [ category2.id ])
      end

      it { expect(subject.length).to eq 1 }
    end

    context 'with license' do
      context 'with single license' do
        let(:search_params) { { license: license1 } }
        it { expect(subject.length).to eq 0 }
      end

      context 'with 2 licenses' do
        let(:search_params) { { license: [ license2, license3 ].join(" ") } }
        it { expect(subject.length).to eq 1 }
      end

      context 'with 3 licenses' do
        let(:search_params) { { license: [ license1, license2, license3 ].join(" ") } }
        it { expect(subject.length).to eq 0 }
      end
    end

    context 'with poster' do
      let!(:member1) { create :cms_member }
      let!(:member2) { create :cms_member }

      before do
        app1.update(workflow_member_id: member1.id)
        app2.update(workflow_member_id: member2.id)
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
