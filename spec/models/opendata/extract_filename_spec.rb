require 'spec_helper'

describe Opendata, dbscope: :example do
  describe ".extract_filename" do
    it do
      {
        'attachment; filename=a.csv; size=1' => "a.csv",
        "attachment; filename=x.csv; filename*=UTF-8''%E8%A1%A8.csv" => "表.csv",
        "attachment; filename=\"#{"表.csv".encode("CP932").b}\"" => "表.csv",
        'attachment; filename="../../etc/x.csv"' => "x.csv",
        "attachment; filename=f.csv; filename*=UTF-8''%FF.csv" => "f.csv",
        'attachment; filename=".."' => nil,
        'inline' => nil
      }.each do |header, expected|
        expect(Opendata.extract_filename(header)).to eq expected
      end
    end
  end
end
