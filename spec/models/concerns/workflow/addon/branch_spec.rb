require 'spec_helper'

describe Workflow::Addon::Branch, dbscope: :example do
  let(:page) { create :cms_page }
  let(:cloned_page) { x = page.new_clone; x.master_id = page.id; x.save; x }

  describe "assertions" do
    it { expect(page).not_to be_nil }
    it { expect(cloned_page).not_to be_nil }
    it { expect(page.id).not_to eq cloned_page.id }
    it { expect(page.name).to eq cloned_page.name }
  end

  describe "cloned page filename (without extension)" do
    subject { cloned_page.filename.gsub('.html', '') }

    let(:page_filename) { page.filename.gsub('.html', '') }

    it "is the one that \"_01\" is appended to the tail" do
      expect(subject).to eq "#{page_filename}_01"
    end

    describe "2nd cloned page" do
      before do
        cloned_page # create 1st cloned page (and also the "page")
        @cloned_page2 = page.new_clone
        @cloned_page2.master_id = page.id
        @cloned_page2.save
      end

      subject { @cloned_page2.filename.gsub('.html', '') }

      it "is the one that \"_02\" is appended to the tail" do
        expect(subject).to eq "#{page_filename}_02"
      end
    end
  end
end
