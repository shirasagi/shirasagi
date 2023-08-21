require 'spec_helper'

describe Voice::JapaneseTextReconstructor do
  describe "#new" do
    it "converts many small texts to a few appropriate texts" do
      texts = %w(黒川まさし 山中正敏 八田愛 久保田美智子 進藤寛治 矢野さとみ 滝口雅彦 浜田隆 神木亮)
      reconstructor = Voice::JapaneseTextReconstructor.new(texts, 10)
      chunks = reconstructor.to_a
      expect(chunks.length).to eq 4
      expect(chunks).to include("黒川まさし。山中正敏。")
      expect(chunks).to include("八田愛。久保田美智子。")
      expect(chunks).to include("進藤寛治。矢野さとみ。")
      expect(chunks).to include("滝口雅彦。浜田隆。神木亮。")
    end

    it "converts too long text to a few appropriate texts" do
      texts = [ "黒川まさし 山中正敏 八田愛 久保田美智子 進藤寛治 矢野さとみ 滝口雅彦 浜田隆 神木亮" ]
      reconstructor = Voice::JapaneseTextReconstructor.new(texts, 10)
      chunks = reconstructor.to_a
      expect(chunks.length).to eq 4
      expect(chunks).to include("黒川まさし。山中正敏。")
      expect(chunks).to include("八田愛。久保田美智子。")
      expect(chunks).to include("進藤寛治。矢野さとみ。")
      expect(chunks).to include("滝口雅彦。浜田隆。神木亮。")
    end
  end
end
