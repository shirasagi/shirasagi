require 'spec_helper'

RSpec.describe Gws::Memo, type: :model, dbscope: :example do
  context "with blank" do
    it do
      sub = Gws::Memo.html_to_text(nil)
      expect(sub).to be_nil
      sub = Gws::Memo.html_to_text("")
      expect(sub).to be_blank
    end
  end

  context "with p" do
    let(:html) do
      <<~HTML
        <p>paragraph1</p>
        <p>paragraph2</p>
      HTML
    end

    it do
      sub = Gws::Memo.html_to_text(html)
      expect(sub).to eq "paragraph1\nparagraph2\n"
    end
  end
end
