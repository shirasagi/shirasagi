require 'spec_helper'

describe Voice::MecabParser do
  subject(:site) { cms_site }

  describe "#new", mecab: true do
    it "analyzes alphabet" do
      mecab_parser = Voice::MecabParser.new(site.id, "abcdefghijklmn")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to be_nil
      end
    end

    it "analyzes number" do
      mecab_parser = Voice::MecabParser.new(site.id, "0123456789")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to be_nil
      end
    end

    it "analyzes hiragana" do
      mecab_parser = Voice::MecabParser.new(site.id, "おはよう")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to_not be_empty
      end
    end

    it "analyzes katakana" do
      mecab_parser = Voice::MecabParser.new(site.id, "おはよう")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to_not be_empty
      end
    end

    it "analyzes fullwidth number" do
      mecab_parser = Voice::MecabParser.new(site.id, "０１２３４５６７８９")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to_not be_empty
      end
    end

    it "analyzes fullwidth alphabet" do
      mecab_parser = Voice::MecabParser.new(site.id, "ａｂｃｄｅｆｇｈｉｊｋｌｍｎ")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to be_nil
      end
    end

    it "analyzes kanji" do
      mecab_parser = Voice::MecabParser.new(site.id, "日本")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to_not be_empty
      end
    end

    it "analyzes free text" do
      mecab_parser = Voice::MecabParser.new(site.id, "僕、ミッキーだよ。")
      mecab_parser.each do |start_pos, end_pos, hyoki, yomi|
        expect(start_pos).to be >= 0
        expect(end_pos).to be >= 0
        expect(hyoki).to_not be_empty
        expect(yomi).to_not be_empty
      end
    end
  end
end
