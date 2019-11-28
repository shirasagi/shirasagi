require 'spec_helper'

describe Translate::RequestBuffer, dbscope: :example do
  let(:sample1) { ::File.read("spec/fixtures/translate/sample1.txt") }
  let(:ss_proj1) { ::File.read("spec/fixtures/translate/ss_proj1.html") }

  it do
    item = Translate::RequestBuffer.new(array_size_limit: 10, text_size_limit: 50, contents_size_limit: 100)
    item.push sample1, "1"
    #expect(item.request_array.map { |req| req.size }.max).to eq 10
    #expect(item.request_array.map { |req| req.map { |cache| cache.original_text.size } }.flatten.max).to eq 50

    item = Translate::RequestBuffer.new(text_size_limit: 50, array_size_limit: 10)

    #item = Translate::RequestBuffer.new(text_size_limit: 300, array_size_limit: 100)
    #item.push sample1, "1"
    #expect(item.request_array.map { |req| req.size }.max).to eq 100
    #expect(item.request_array.map { |req| req.map { |cache| cache.original_text.size } }.flatten.max).to eq 300
  end

  xit do
    item = Translate::RequestBuffer.new(text_size_limit: 100, array_size_limit: 20)
    sample1.split(/\n/).each_with_index do |line, idx|
      item.push(line, idx)
    end
    item.translated
  end

  xit do
    doc = Nokogiri.parse(ss_proj1)

    text_nodes = []
    doc.search('//text()').each do |text_node|
      text = text_node.content
      next if text =~ /^\s*$/

      text_nodes << text_node
    end

    item = Translate::RequestBuffer.new(text_size_limit: 100, array_size_limit: 20)
    text_nodes.each do |text_node|
      text = text_node.content
      item.push text, text_node
    end

    translated = item.translate

    translated.each do |text_node, caches|
      text_node.content = caches.map { |caches| caches.text }.join("\n")
    end

    doc.to_s

  end
end
