class Voice::MecabParser
  include Enumerable

  MECAB_OPTIONS = '--node-format=%ps,%pe,%m,%H\n'

  def initialize(site_id, text)
    @site_id = site_id
    @text = text
  end

  def each
    Kana::Dictionary.pull(@site_id) do |userdic|
      mecab = create_mecab(userdic)
      mecab.parse(@text).split(/\n/).each do |line|
        next if line == "EOS"
        data = line.split(",")

        start_pos = data[0].to_i
        end_pos = data[1].to_i
        hyoki = data[2]
        yomi = data[10]

        yield start_pos, end_pos, hyoki, yomi
      end
    end
  end

  private
    def create_mecab(userdic)
      mecab_param = MECAB_OPTIONS
      mecab_param << %( -u "#{userdic}") if userdic.present?

      require "MeCab"
      MeCab::Tagger.new(mecab_param)
    end
end
