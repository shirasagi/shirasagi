require 'spec_helper'

describe Cms::Part, type: :model, dbscope: :example do
  let(:item) { create :cms_part }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Base, type: :model, dbscope: :example do
  let(:item) { create :cms_part_base }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Free, type: :model, dbscope: :example do
  let(:item) { create :cms_part_free }
  it_behaves_like "cms_part#spec"

  describe "validation" do
    it "basename" do
      item = build(:cms_part_free_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end

  describe ".and_public" do
    let(:site) { cms_site }
    let(:node) { create :cms_node_node, site: site }
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:part1) { create :cms_part_free, cur_site: site, cur_node: node, released: current, state: "public" }
    let!(:part2) { create :cms_part_free, cur_site: site, cur_node: node, released: current, state: "closed" }
    let!(:part3) { create :cms_part_free, cur_site: site, cur_node: node, released: current + 1.day, state: "public" }
    let!(:part4) { create :cms_part_free, cur_site: site, cur_node: node, released: current + 1.day, state: "closed" }

    it do
      # without specific date to and_public
      expect(described_class.and_public.count).to eq 2
      expect(described_class.and_public.pluck(:id)).to include(part1.id, part3.id)
      expect(Cms::Part.and_public.count).to eq 2
      expect(Cms::Part.and_public.pluck(:id)).to include(part1.id, part3.id)

      # at current
      expect(described_class.and_public(current).count).to eq 1
      expect(described_class.and_public(current).pluck(:id)).to include(part1.id)
      expect(Cms::Part.and_public(current).count).to eq 1
      expect(Cms::Part.and_public(current).pluck(:id)).to include(part1.id)

      # at current + 1.day
      expect(described_class.and_public(current + 1.day).count).to eq 2
      expect(described_class.and_public(current + 1.day).pluck(:id)).to include(part1.id, part3.id)
      expect(Cms::Part.and_public(current + 1.day).count).to eq 2
      expect(Cms::Part.and_public(current + 1.day).pluck(:id)).to include(part1.id, part3.id)
    end
  end

  describe "#public?" do
    let(:site) { cms_site }
    let(:node) { create :cms_node_node, site: site }
    let(:current) { Time.zone.now.beginning_of_minute }
    let!(:part1) { create :cms_part_free, cur_site: site, cur_node: node, released: current, state: "public" }
    let!(:part2) { create :cms_part_free, cur_site: site, cur_node: node, released: current, state: "closed" }
    let!(:part3) { create :cms_part_free, cur_site: site, cur_node: node, released: current + 1.day, state: "public" }
    let!(:part4) { create :cms_part_free, cur_site: site, cur_node: node, released: current + 1.day, state: "closed" }

    it do
      expect(part1.public?).to be_truthy
      expect(part2.public?).to be_falsey
      expect(part3.public?).to be_truthy
      expect(part4.public?).to be_falsey

      # at current
      Timecop.freeze(current) do
        part1.reload
        part2.reload
        part3.reload
        part4.reload

        expect(part1.public?).to be_truthy
        expect(part2.public?).to be_falsey
        expect(part3.public?).to be_truthy
        expect(part4.public?).to be_falsey
      end

      # at current + 1.day
      Timecop.freeze(current + 1.day) do
        part1.reload
        part2.reload
        part3.reload
        part4.reload

        expect(part1.public?).to be_truthy
        expect(part2.public?).to be_falsey
        expect(part3.public?).to be_truthy
        expect(part4.public?).to be_falsey
      end
    end
  end

  context "database access" do
    let(:site) { cms_site }

    before do
      create :cms_part_free, cur_site: site
      expect(Cms::Part::Free.all.count).to eq 1
    end

    context "without cur_site" do
      it do
        part = Cms::Part::Free.all.first

        case rand(0..4)
        when 0
          expect { part.path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 1
          expect { part.url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 2
          expect { part.full_url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 3
          expect { part.json_path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 4
          expect { part.json_url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        end
      end
    end

    context "with cur_site" do
      it do
        part = Cms::Part::Free.all.first
        part.cur_site = site

        expect { part.path }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { part.url }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { part.full_url }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { part.json_path }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { part.json_url }.to change { MongoAccessCounter.succeeded_count }.by(0)
      end
    end
  end
end

describe Cms::Part::Node, type: :model, dbscope: :example do
  let(:item) { create :cms_part_node }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Page, type: :model, dbscope: :example do
  let(:item) { create :cms_part_page }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Tabs, type: :model, dbscope: :example do
  let(:item) { create :cms_part_tabs }
  it_behaves_like "cms_part#spec"
end

describe Cms::Part::Crumb, type: :model, dbscope: :example do
  let(:item) { create :cms_part_crumb }
  it_behaves_like "cms_part#spec"
end
