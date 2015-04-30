require 'spec_helper'
require Rails.root.join('lib/migrations/ezine/20150423044546_update_results.rb')

RSpec.describe SS::Migration20150423044546, dbscope: :example do
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
