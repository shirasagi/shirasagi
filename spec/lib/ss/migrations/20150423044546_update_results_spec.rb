require 'spec_helper'
require Rails.root.join('lib/migrations/ezine/20150423044546_update_results.rb')

RSpec.describe SS::Migration20150423044546, dbscope: :example do
  context "1 result" do
    let(:started) { Time.zone.now }
    let(:delivered) { started + 1 }

    before do
      x = create :ezine_page
      @id = x.id
      x[:results] = [started, delivered, 1]
      x.save
    end

    let(:page) { Ezine::Page.find @id }

    it { expect(page[:results]).to be_kind_of Array }

    context "after migration" do
      before { described_class.new.change }

      let(:result) { page.results.first }

      it { expect(result.started).to eq_as_time started }
      it { expect(result.delivered).to eq_as_time delivered }
    end
  end

  context "2 results" do
    let(:started1) { Time.zone.now }
    let(:delivered1) { started1 + 1 }
    let(:started2) { delivered1 + 1 }
    let(:delivered2) { started2 + 1 }

    before do
      x = create :ezine_page
      @id = x.id
      x[:results] = [started1, delivered1, 1, started2, delivered2, 2]
      x.save
      described_class.new.change
    end

    let(:page) { Ezine::Page.find @id }
    let(:result1) { page.results[0] }
    let(:result2) { page.results[1] }

    it { expect(page.results.count).to eq 2 }
    it { expect(result1.started).to eq_as_time started1 }
    it { expect(result1.delivered).to eq_as_time delivered1 }
    it { expect(result1.count).to eq_as_time 1 }
    it { expect(result2.started).to eq_as_time started2 }
    it { expect(result2.delivered).to eq_as_time delivered2 }
    it { expect(result2.count).to eq_as_time 2 }
  end
end
