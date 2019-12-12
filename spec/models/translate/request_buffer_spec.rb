require 'spec_helper'

describe Translate::RequestBuffer, dbscope: :example do
  let(:site) { cms_site }
  let(:source) { "ja" }
  let(:target) { "en" }
  let(:item) do
    Translate::RequestBuffer.new(
      site, source, target,
      array_size_limit: 10,
      text_size_limit: 10,
      contents_size_limit: 10
    )
  end
  let(:contents) { %w(first second third) }

  before do
    site.translate_state = "enabled"
    site.translate_api = "mock"
    site.update!
  end

  it do
    item.push contents[0], 0
    item.push contents[1], 1
    item.push contents[2], 2
    translated = item.translate

    expect(translated.keys).to eq [0, 1, 2]
    expect(translated[0].map(&:text)).to eq ["[en:first]"]
    expect(translated[1].map(&:text)).to eq ["[en:second]"]
    expect(translated[2].map(&:text)).to eq ["[en:third]"]
  end
end
