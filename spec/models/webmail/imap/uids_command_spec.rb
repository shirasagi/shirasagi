require 'spec_helper'

describe Webmail::Imap::UidsCommand do
  describe "#uids_size" do
    it do
      expect(Webmail::Imap.uids_size('1,2,3,4')).to eq 4
      expect(Webmail::Imap.uids_size('1:6')).to eq 6
      expect(Webmail::Imap.uids_size('1,5:7,10,15:17')).to eq 8
    end
  end

  describe "#uids_compress" do
    it do
      expect(Webmail::Imap.uids_compress([1, 2, 3, 4])).to eq [1..4]
      expect(Webmail::Imap.uids_compress([1, 3, 5, 7])).to eq [1, 3, 5, 7]
      expect(Webmail::Imap.uids_compress([1, 2, 3, 9])).to eq [1..3, 9]
    end
  end
end
