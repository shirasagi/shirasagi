require 'spec_helper'

describe Opendata::Idea, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search) { create(:opendata_node_search_idea, cur_site: site) }
  let!(:node) { create(:opendata_node_idea, cur_site: site) }
  let!(:keyword1) { unique_id }
  let!(:keyword2) { unique_id }
  let!(:keyword3) { unique_id }
  let!(:tag1) { unique_id }
  let!(:tag2) { unique_id }
  let!(:tag3) { unique_id }
  let!(:idea1) do
    create(:opendata_idea, cur_site: site, cur_node: node, text: "#{keyword1} #{keyword2}", tags: [ tag1, tag2 ])
  end
  let!(:idea2) do
    create(:opendata_idea, cur_site: site, cur_node: node, text: "#{keyword2} #{keyword3}", tags: [ tag2, tag3 ])
  end
  let!(:idea3) do
    create(:opendata_idea, cur_site: site, cur_node: node, text: "#{keyword3} #{keyword1}", tags: [ tag1, tag3 ])
  end
  let!(:idea_closed) do
    create(
      :opendata_idea, cur_site: site, cur_node: node, state: "closed",
      text: "#{keyword1} #{keyword2} #{keyword3}", tags: [ tag1, tag2, tag3 ]
    )
  end
  let(:site_other) { create :cms_site_unique }
  let!(:node_other) { create(:opendata_node_idea, cur_site: site_other) }
  let!(:node_search_other) { create(:opendata_node_search_idea, cur_site: site_other) }
  let!(:idea_other) do
    create(:opendata_idea, cur_site: site_other, cur_node: node_other, text: "#{keyword1} #{keyword2}", tags: [ tag1, tag2 ])
  end
  let(:base_criteria) { described_class.site(site).and_public }
  subject { base_criteria.search(search_params).pluck(:id) }

  describe ".search" do
    # context 'with no option' do
    #   subject { base_criteria.search }
    #   it { expect(subject.count).to eq 3 }
    # end

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

    context 'with tag' do
      let(:search_params) { { tag: [ tag1, tag2, tag3 ].sample } }
      it { expect(subject.length).to eq 2 }
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
