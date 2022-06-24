require 'spec_helper'

describe Webmail::Converter do
  describe "#extract_address" do
    it do
      Webmail::Converter.extract_address('email@example.jp')
      expect(Webmail::Converter.extract_address('email@example.jp')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('<email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('Name <email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('山田 <email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('(山田 <email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('(山田) <email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('(山田） <email@example.jp>')).to eq 'email@example.jp'
      expect(Webmail::Converter.extract_address('山田')).to eq '??'
      expect(Webmail::Converter.extract_address('(山田')).to eq '(山田'
      expect(Webmail::Converter.extract_address('(山田)')).to eq '(山田)'
    end
  end

  # unused?
  describe "#extract_display_name" do
    it do
      Webmail::Converter.extract_address('email@example.jp')
      expect(Webmail::Converter.extract_display_name('email@example.jp')).to eq ''
      expect(Webmail::Converter.extract_display_name('<email@example.jp>')).to eq ''
      expect(Webmail::Converter.extract_display_name('Name <email@example.jp>')).to eq 'Name'
      expect(Webmail::Converter.extract_display_name('山田 <email@example.jp>')).to eq '山田'
      expect(Webmail::Converter.extract_display_name('(山田 <email@example.jp>')).to eq '(山田'
      expect(Webmail::Converter.extract_display_name('(山田) <email@example.jp>')).to eq '(山田)'
      expect(Webmail::Converter.extract_display_name('(山田） <email@example.jp>')).to eq '(山田）'
    end
  end
end
