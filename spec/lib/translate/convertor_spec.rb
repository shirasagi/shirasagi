require 'spec_helper'

describe Translate::Convertor, dbscope: :example do
  let(:ss_proj1) { ::File.read("spec/fixtures/translate/ss_proj1.html") }
  let(:site) { cms_site }
  let(:source) { "ja" }
  let(:target) { "en" }

  before do
    site.translate_state = "enabled"
    site.translate_api = "mock"
    site.update!
  end

  it do
    item = Translate::Convertor.new(site, source, target)
    html = item.convert(ss_proj1)

    doc = Nokogiri.parse(html)
    texts = doc.search('//text()').map do |node|
      next if node.node_type != 3
      next if node.blank?
      node.content
    end.compact

    texts.each do |text|
      expect(text).to match(/^\[#{target}\:.+?\]/)
    end
  end
end
