require 'spec_helper'

RSpec.describe Gws::Memo, type: :model, dbscope: :example do
  context "with a signature" do
    let(:signature) do
      <<~TEXT
        ----------------------------------------------------
        シラサギ市　企画政策部　政策課
        システム管理者
        電話番号：00−0000−0000
        ----------------------------------------------------
      TEXT
    end

    shared_examples "what fragment is" do
      it do
        fragment = Nokogiri::HTML.fragment(subject)
        expect(fragment.children.count).to eq 1
        fragment.children[0].tap do |root_node|
          expect(root_node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
          expect(root_node.name).to eq "p"
          expect(root_node.children.count).to eq 10

          root_node.children.tap do |nodes|
            nodes[0].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::TEXT_NODE
              expect(node.name).to eq "text"
              expect(node.inner_text).to eq "-" * 52
            end
            nodes[1].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
              expect(node.name).to eq "br"
              expect(node.inner_text).to be_blank
            end
            nodes[2].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::TEXT_NODE
              expect(node.name).to eq "text"
              expect(node.inner_text).to eq "シラサギ市　企画政策部　政策課"
            end
            nodes[3].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
              expect(node.name).to eq "br"
              expect(node.inner_text).to be_blank
            end

            nodes[-4].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::TEXT_NODE
              expect(node.name).to eq "text"
              expect(node.inner_text).to eq "電話番号：00−0000−0000"
            end
            nodes[-3].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
              expect(node.name).to eq "br"
              expect(node.inner_text).to be_blank
            end
            nodes[-2].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::TEXT_NODE
              expect(node.name).to eq "text"
              expect(node.inner_text).to eq "-" * 52
            end
            nodes[-1].tap do |node|
              expect(node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
              expect(node.name).to eq "br"
              expect(node.inner_text).to be_blank
            end
          end
        end
      end
    end

    context "with LF" do
      subject { Gws::Memo.text_to_html(signature.gsub(/\R/, "\n")) }
      it_behaves_like "what fragment is"
    end

    context "with CRLF" do
      subject { Gws::Memo.text_to_html(signature.gsub(/\R/, "\r\n")) }
      it_behaves_like "what fragment is"
    end
  end

  context "with html unsafe chars" do
    it do
      sub = Gws::Memo.text_to_html("<")
      expect(sub).to eq "<p>&lt;</p>"

      sub = Gws::Memo.text_to_html(">")
      expect(sub).to eq "<p>&gt;</p>"

      sub = Gws::Memo.text_to_html("\"")
      expect(sub).to eq "<p>\"</p>"

      sub = Gws::Memo.text_to_html("&")
      expect(sub).to eq "<p>&amp;</p>"

      sub = Gws::Memo.text_to_html("<>\"&")
      expect(sub).to eq "<p>&lt;&gt;\"&amp;</p>"
    end
  end

  context "with html unsafe tag" do
    it do
      sub = Gws::Memo.text_to_html("<script>alert('XSS')</script>")
      expect(sub).to eq "<p>alert('XSS')</p>"
    end
  end

  context "with blank" do
    it do
      sub = Gws::Memo.text_to_html(nil)
      expect(sub).to be_nil
      sub = Gws::Memo.text_to_html("")
      expect(sub).to be_blank
    end
  end
end
