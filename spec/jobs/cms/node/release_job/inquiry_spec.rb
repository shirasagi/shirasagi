require 'spec_helper'

describe Cms::Node::ReleaseJob, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let(:inquiry1) { create :inquiry_node_form, layout_id: layout.id }
  let(:inquiry2) { create :inquiry_node_form, layout_id: layout.id, release_date: release_date }
  let(:inquiry3) { create :inquiry_node_form, layout_id: layout.id, close_date: close_date }
  let(:inquiry4) do
    create :inquiry_node_form, layout_id: layout.id, release_date: release_date, close_date: close_date
  end
  let(:inquiry5) { create :inquiry_node_form, layout_id: layout.id, state: "closed" }

  let(:inquiry1_path) { File.join(inquiry1.path, "index.html") }
  let(:inquiry2_path) { File.join(inquiry2.path, "index.html") }
  let(:inquiry3_path) { File.join(inquiry3.path, "index.html") }
  let(:inquiry4_path) { File.join(inquiry4.path, "index.html") }
  let(:inquiry5_path) { File.join(inquiry5.path, "index.html") }

  let!(:release_date) { 1.day.from_now }
  let!(:close_date) { 7.days.from_now }

  def generate_all
    described_class.bind(site_id: site.id).perform_now
    Cms::Node::GenerateJob.bind(site_id: site.id).perform_now
    inquiry1.reload
    inquiry2.reload
    inquiry3.reload
    inquiry4.reload
  end

  describe "#perform" do
    context "generate all" do
      it do
        expect(inquiry1.state).to eq "public"
        expect(inquiry2.state).to eq "ready"
        expect(inquiry3.state).to eq "public"
        expect(inquiry4.state).to eq "ready"
        expect(inquiry5.state).to eq "closed"
        expect(File.exist?(inquiry1_path)).to be false
        expect(File.exist?(inquiry2_path)).to be false
        expect(File.exist?(inquiry3_path)).to be false
        expect(File.exist?(inquiry4_path)).to be false
        expect(File.exist?(inquiry5_path)).to be false

        generate_all
        expect(inquiry1.state).to eq "public"
        expect(inquiry2.state).to eq "ready"
        expect(inquiry3.state).to eq "public"
        expect(inquiry4.state).to eq "ready"
        expect(inquiry5.state).to eq "closed"
        expect(File.exist?(inquiry1_path)).to be true
        expect(File.exist?(inquiry2_path)).to be false
        expect(File.exist?(inquiry3_path)).to be true
        expect(File.exist?(inquiry4_path)).to be false
        expect(File.exist?(inquiry5_path)).to be false

        Timecop.travel(release_date.advance(days: 1)) do
          generate_all
          expect(inquiry1.state).to eq "public"
          expect(inquiry2.state).to eq "public"
          expect(inquiry3.state).to eq "public"
          expect(inquiry4.state).to eq "public"
          expect(inquiry5.state).to eq "closed"
          expect(File.exist?(inquiry1_path)).to be true
          expect(File.exist?(inquiry2_path)).to be true
          expect(File.exist?(inquiry3_path)).to be true
          expect(File.exist?(inquiry4_path)).to be true
          expect(File.exist?(inquiry5_path)).to be false
        end

        Timecop.travel(close_date.advance(days: 1)) do
          generate_all
          expect(inquiry1.state).to eq "public"
          expect(inquiry2.state).to eq "public"
          expect(inquiry3.state).to eq "closed"
          expect(inquiry4.state).to eq "closed"
          expect(inquiry5.state).to eq "closed"
          expect(File.exist?(inquiry1_path)).to be true
          expect(File.exist?(inquiry2_path)).to be true
          expect(File.exist?(inquiry3_path)).to be false
          expect(File.exist?(inquiry4_path)).to be false
          expect(File.exist?(inquiry5_path)).to be false
        end

        Timecop.travel(close_date.advance(days: 3)) do
          generate_all
          expect(inquiry1.state).to eq "public"
          expect(inquiry2.state).to eq "public"
          expect(inquiry3.state).to eq "closed"
          expect(inquiry4.state).to eq "closed"
          expect(inquiry5.state).to eq "closed"
          expect(File.exist?(inquiry1_path)).to be true
          expect(File.exist?(inquiry2_path)).to be true
          expect(File.exist?(inquiry3_path)).to be false
          expect(File.exist?(inquiry4_path)).to be false
          expect(File.exist?(inquiry5_path)).to be false
        end
      end
    end
  end
end
