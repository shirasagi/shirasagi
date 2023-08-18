FactoryBot.define do
  factory :jmaxml_forecast_region_base, class: Jmaxml::ForecastRegion do
    cur_site { cms_site }

    factory :jmaxml_forecast_region_c0110000 do
      code { "0110000" }
      name { "北海道札幌市" }
      yomi { "ほっかいどうさっぽろし" }
      short_name { "札幌市" }
      short_yomi { "さっぽろし" }
    end

    factory :jmaxml_forecast_region_c0120200 do
      code { "0120200" }
      name { "北海道函館市" }
      yomi { "ほっかいどうはこだてし" }
      short_name { "函館市" }
      short_yomi { "はこだてし" }
    end

    factory :jmaxml_forecast_region_c0120300 do
      code { "0120300" }
      name { "北海道小樽市" }
      yomi { "ほっかいどうおたるし" }
      short_name { "小樽市" }
      short_yomi { "おたるし" }
    end

    factory :jmaxml_forecast_region_c0120400 do
      code { "0120400" }
      name { "北海道旭川市" }
      yomi { "ほっかいどうあさひかわし" }
      short_name { "旭川市" }
      short_yomi { "あさひかわし" }
    end

    factory :jmaxml_forecast_region_c0120500 do
      code { "0120500" }
      name { "北海道室蘭市" }
      yomi { "ほっかいどうむろらんし" }
      short_name { "室蘭市" }
      short_yomi { "むろらんし" }
    end

    factory :jmaxml_forecast_region_c0120600 do
      code { "0120600" }
      name { "北海道釧路市" }
      yomi { "ほっかいどうくしろし" }
      short_name { "釧路市" }
      short_yomi { "くしろし" }
    end

    factory :jmaxml_forecast_region_c0120700 do
      code { "0120700" }
      name { "北海道帯広市" }
      yomi { "ほっかいどうおびひろし" }
      short_name { "帯広市" }
      short_yomi { "おびひろし" }
    end

    factory :jmaxml_forecast_region_c0120800 do
      code { "0120800" }
      name { "北海道北見市" }
      yomi { "ほっかいどうきたみし" }
      short_name { "北見市" }
      short_yomi { "きたみし" }
    end

    factory :jmaxml_forecast_region_c0120900 do
      code { "0120900" }
      name { "北海道夕張市" }
      yomi { "ほっかいどうゆうばりし" }
      short_name { "夕張市" }
      short_yomi { "ゆうばりし" }
    end

    factory :jmaxml_forecast_region_c0121000 do
      code { "0121000" }
      name { "北海道岩見沢市" }
      yomi { "ほっかいどういわみざわし" }
      short_name { "岩見沢市" }
      short_yomi { "いわみざわし" }
    end

    factory :jmaxml_forecast_region_c0121100 do
      code { "0121100" }
      name { "北海道網走市" }
      yomi { "ほっかいどうあばしりし" }
      short_name { "網走市" }
      short_yomi { "あばしりし" }
    end

    factory :jmaxml_forecast_region_c0121200 do
      code { "0121200" }
      name { "北海道留萌市" }
      yomi { "ほっかいどうるもいし" }
      short_name { "留萌市" }
      short_yomi { "るもいし" }
    end

    factory :jmaxml_forecast_region_c0121300 do
      code { "0121300" }
      name { "北海道苫小牧市" }
      yomi { "ほっかいどうとまこまいし" }
      short_name { "苫小牧市" }
      short_yomi { "とまこまいし" }
    end

    factory :jmaxml_forecast_region_c0121400 do
      code { "0121400" }
      name { "北海道稚内市" }
      yomi { "ほっかいどうわっかないし" }
      short_name { "稚内市" }
      short_yomi { "わっかないし" }
    end

    factory :jmaxml_forecast_region_c0121500 do
      code { "0121500" }
      name { "北海道美唄市" }
      yomi { "ほっかいどうびばいし" }
      short_name { "美唄市" }
      short_yomi { "びばいし" }
    end

    factory :jmaxml_forecast_region_c0121600 do
      code { "0121600" }
      name { "北海道芦別市" }
      yomi { "ほっかいどうあしべつし" }
      short_name { "芦別市" }
      short_yomi { "あしべつし" }
    end

    factory :jmaxml_forecast_region_c0121700 do
      code { "0121700" }
      name { "北海道江別市" }
      yomi { "ほっかいどうえべつし" }
      short_name { "江別市" }
      short_yomi { "えべつし" }
    end

    factory :jmaxml_forecast_region_c0121800 do
      code { "0121800" }
      name { "北海道赤平市" }
      yomi { "ほっかいどうあかびらし" }
      short_name { "赤平市" }
      short_yomi { "あかびらし" }
    end

    factory :jmaxml_forecast_region_c0121900 do
      code { "0121900" }
      name { "北海道紋別市" }
      yomi { "ほっかいどうもんべつし" }
      short_name { "紋別市" }
      short_yomi { "もんべつし" }
    end

    factory :jmaxml_forecast_region_c0122000 do
      code { "0122000" }
      name { "北海道士別市" }
      yomi { "ほっかいどうしべつし" }
      short_name { "士別市" }
      short_yomi { "しべつし" }
    end

    factory :jmaxml_forecast_region_c0122100 do
      code { "0122100" }
      name { "北海道名寄市" }
      yomi { "ほっかいどうなよろし" }
      short_name { "名寄市" }
      short_yomi { "なよろし" }
    end

    factory :jmaxml_forecast_region_c0122200 do
      code { "0122200" }
      name { "北海道三笠市" }
      yomi { "ほっかいどうみかさし" }
      short_name { "三笠市" }
      short_yomi { "みかさし" }
    end

    factory :jmaxml_forecast_region_c0122300 do
      code { "0122300" }
      name { "北海道根室市" }
      yomi { "ほっかいどうねむろし" }
      short_name { "根室市" }
      short_yomi { "ねむろし" }
    end

    factory :jmaxml_forecast_region_c0122400 do
      code { "0122400" }
      name { "北海道千歳市" }
      yomi { "ほっかいどうちとせし" }
      short_name { "千歳市" }
      short_yomi { "ちとせし" }
    end

    factory :jmaxml_forecast_region_c0122500 do
      code { "0122500" }
      name { "北海道滝川市" }
      yomi { "ほっかいどうたきかわし" }
      short_name { "滝川市" }
      short_yomi { "たきかわし" }
    end

    factory :jmaxml_forecast_region_c0122600 do
      code { "0122600" }
      name { "北海道砂川市" }
      yomi { "ほっかいどうすながわし" }
      short_name { "砂川市" }
      short_yomi { "すながわし" }
    end

    factory :jmaxml_forecast_region_c0122700 do
      code { "0122700" }
      name { "北海道歌志内市" }
      yomi { "ほっかいどううたしないし" }
      short_name { "歌志内市" }
      short_yomi { "うたしないし" }
    end

    factory :jmaxml_forecast_region_c0122800 do
      code { "0122800" }
      name { "北海道深川市" }
      yomi { "ほっかいどうふかがわし" }
      short_name { "深川市" }
      short_yomi { "ふかがわし" }
    end

    factory :jmaxml_forecast_region_c0122900 do
      code { "0122900" }
      name { "北海道富良野市" }
      yomi { "ほっかいどうふらのし" }
      short_name { "富良野市" }
      short_yomi { "ふらのし" }
    end

    factory :jmaxml_forecast_region_c0123000 do
      code { "0123000" }
      name { "北海道登別市" }
      yomi { "ほっかいどうのぼりべつし" }
      short_name { "登別市" }
      short_yomi { "のぼりべつし" }
    end

    factory :jmaxml_forecast_region_c0123100 do
      code { "0123100" }
      name { "北海道恵庭市" }
      yomi { "ほっかいどうえにわし" }
      short_name { "恵庭市" }
      short_yomi { "えにわし" }
    end

    factory :jmaxml_forecast_region_c0123300 do
      code { "0123300" }
      name { "北海道伊達市" }
      yomi { "ほっかいどうだてし" }
      short_name { "伊達市" }
      short_yomi { "だてし" }
    end

    factory :jmaxml_forecast_region_c0123400 do
      code { "0123400" }
      name { "北海道北広島市" }
      yomi { "ほっかいどうきたひろしまし" }
      short_name { "北広島市" }
      short_yomi { "きたひろしまし" }
    end

    factory :jmaxml_forecast_region_c0123500 do
      code { "0123500" }
      name { "北海道石狩市" }
      yomi { "ほっかいどういしかりし" }
      short_name { "石狩市" }
      short_yomi { "いしかりし" }
    end

    factory :jmaxml_forecast_region_c0123600 do
      code { "0123600" }
      name { "北海道北斗市" }
      yomi { "ほっかいどうほくとし" }
      short_name { "北斗市" }
      short_yomi { "ほくとし" }
    end

    factory :jmaxml_forecast_region_c0130300 do
      code { "0130300" }
      name { "北海道当別町" }
      yomi { "ほっかいどうとうべつちょう" }
      short_name { "当別町" }
      short_yomi { "とうべつちょう" }
    end

    factory :jmaxml_forecast_region_c0130400 do
      code { "0130400" }
      name { "北海道新篠津村" }
      yomi { "ほっかいどうしんしのつむら" }
      short_name { "新篠津村" }
      short_yomi { "しんしのつむら" }
    end

    factory :jmaxml_forecast_region_c0133100 do
      code { "0133100" }
      name { "北海道松前町" }
      yomi { "ほっかいどうまつまえちょう" }
      short_name { "松前町" }
      short_yomi { "まつまえちょう" }
    end

    factory :jmaxml_forecast_region_c0133200 do
      code { "0133200" }
      name { "北海道福島町" }
      yomi { "ほっかいどうふくしまちょう" }
      short_name { "福島町" }
      short_yomi { "ふくしまちょう" }
    end

    factory :jmaxml_forecast_region_c0133300 do
      code { "0133300" }
      name { "北海道知内町" }
      yomi { "ほっかいどうしりうちちょう" }
      short_name { "知内町" }
      short_yomi { "しりうちちょう" }
    end

    factory :jmaxml_forecast_region_c0133400 do
      code { "0133400" }
      name { "北海道木古内町" }
      yomi { "ほっかいどうきこないちょう" }
      short_name { "木古内町" }
      short_yomi { "きこないちょう" }
    end

    factory :jmaxml_forecast_region_c0133700 do
      code { "0133700" }
      name { "北海道七飯町" }
      yomi { "ほっかいどうななえちょう" }
      short_name { "七飯町" }
      short_yomi { "ななえちょう" }
    end

    factory :jmaxml_forecast_region_c0134300 do
      code { "0134300" }
      name { "北海道鹿部町" }
      yomi { "ほっかいどうしかべちょう" }
      short_name { "鹿部町" }
      short_yomi { "しかべちょう" }
    end

    factory :jmaxml_forecast_region_c0134500 do
      code { "0134500" }
      name { "北海道森町" }
      yomi { "ほっかいどうもりまち" }
      short_name { "森町" }
      short_yomi { "もりまち" }
    end

    factory :jmaxml_forecast_region_c0134600 do
      code { "0134600" }
      name { "北海道八雲町" }
      yomi { "ほっかいどうやくもちょう" }
      short_name { "八雲町" }
      short_yomi { "やくもちょう" }
    end

    factory :jmaxml_forecast_region_c0134700 do
      code { "0134700" }
      name { "北海道長万部町" }
      yomi { "ほっかいどうおしゃまんべちょう" }
      short_name { "長万部町" }
      short_yomi { "おしゃまんべちょう" }
    end

    factory :jmaxml_forecast_region_c0136100 do
      code { "0136100" }
      name { "北海道江差町" }
      yomi { "ほっかいどうえさしちょう" }
      short_name { "江差町" }
      short_yomi { "えさしちょう" }
    end

    factory :jmaxml_forecast_region_c0136200 do
      code { "0136200" }
      name { "北海道上ノ国町" }
      yomi { "ほっかいどうかみのくにちょう" }
      short_name { "上ノ国町" }
      short_yomi { "かみのくにちょう" }
    end

    factory :jmaxml_forecast_region_c0136300 do
      code { "0136300" }
      name { "北海道厚沢部町" }
      yomi { "ほっかいどうあっさぶちょう" }
      short_name { "厚沢部町" }
      short_yomi { "あっさぶちょう" }
    end

    factory :jmaxml_forecast_region_c0136400 do
      code { "0136400" }
      name { "北海道乙部町" }
      yomi { "ほっかいどうおとべちょう" }
      short_name { "乙部町" }
      short_yomi { "おとべちょう" }
    end

    factory :jmaxml_forecast_region_c0136700 do
      code { "0136700" }
      name { "北海道奥尻町" }
      yomi { "ほっかいどうおくしりちょう" }
      short_name { "奥尻町" }
      short_yomi { "おくしりちょう" }
    end

    factory :jmaxml_forecast_region_c0137000 do
      code { "0137000" }
      name { "北海道今金町" }
      yomi { "ほっかいどういまかねちょう" }
      short_name { "今金町" }
      short_yomi { "いまかねちょう" }
    end

    factory :jmaxml_forecast_region_c0137100 do
      code { "0137100" }
      name { "北海道せたな町" }
      yomi { "ほっかいどうせたなちょう" }
      short_name { "せたな町" }
      short_yomi { "せたなちょう" }
    end

    factory :jmaxml_forecast_region_c0139100 do
      code { "0139100" }
      name { "北海道島牧村" }
      yomi { "ほっかいどうしままきむら" }
      short_name { "島牧村" }
      short_yomi { "しままきむら" }
    end

    factory :jmaxml_forecast_region_c0139200 do
      code { "0139200" }
      name { "北海道寿都町" }
      yomi { "ほっかいどうすっつちょう" }
      short_name { "寿都町" }
      short_yomi { "すっつちょう" }
    end

    factory :jmaxml_forecast_region_c0139300 do
      code { "0139300" }
      name { "北海道黒松内町" }
      yomi { "ほっかいどうくろまつないちょう" }
      short_name { "黒松内町" }
      short_yomi { "くろまつないちょう" }
    end

    factory :jmaxml_forecast_region_c0139400 do
      code { "0139400" }
      name { "北海道蘭越町" }
      yomi { "ほっかいどうらんこしちょう" }
      short_name { "蘭越町" }
      short_yomi { "らんこしちょう" }
    end

    factory :jmaxml_forecast_region_c0139500 do
      code { "0139500" }
      name { "北海道ニセコ町" }
      yomi { "ほっかいどうにせこちょう" }
      short_name { "ニセコ町" }
      short_yomi { "にせこちょう" }
    end

    factory :jmaxml_forecast_region_c0139600 do
      code { "0139600" }
      name { "北海道真狩村" }
      yomi { "ほっかいどうまっかりむら" }
      short_name { "真狩村" }
      short_yomi { "まっかりむら" }
    end

    factory :jmaxml_forecast_region_c0139700 do
      code { "0139700" }
      name { "北海道留寿都村" }
      yomi { "ほっかいどうるすつむら" }
      short_name { "留寿都村" }
      short_yomi { "るすつむら" }
    end

    factory :jmaxml_forecast_region_c0139800 do
      code { "0139800" }
      name { "北海道喜茂別町" }
      yomi { "ほっかいどうきもべつちょう" }
      short_name { "喜茂別町" }
      short_yomi { "きもべつちょう" }
    end

    factory :jmaxml_forecast_region_c0139900 do
      code { "0139900" }
      name { "北海道京極町" }
      yomi { "ほっかいどうきょうごくちょう" }
      short_name { "京極町" }
      short_yomi { "きょうごくちょう" }
    end

    factory :jmaxml_forecast_region_c0140000 do
      code { "0140000" }
      name { "北海道倶知安町" }
      yomi { "ほっかいどうくっちゃんちょう" }
      short_name { "倶知安町" }
      short_yomi { "くっちゃんちょう" }
    end

    factory :jmaxml_forecast_region_c0140100 do
      code { "0140100" }
      name { "北海道共和町" }
      yomi { "ほっかいどうきょうわちょう" }
      short_name { "共和町" }
      short_yomi { "きょうわちょう" }
    end

    factory :jmaxml_forecast_region_c0140200 do
      code { "0140200" }
      name { "北海道岩内町" }
      yomi { "ほっかいどういわないちょう" }
      short_name { "岩内町" }
      short_yomi { "いわないちょう" }
    end

    factory :jmaxml_forecast_region_c0140300 do
      code { "0140300" }
      name { "北海道泊村" }
      yomi { "ほっかいどうとまりむら" }
      short_name { "泊村" }
      short_yomi { "とまりむら" }
    end

    factory :jmaxml_forecast_region_c0140400 do
      code { "0140400" }
      name { "北海道神恵内村" }
      yomi { "ほっかいどうかもえないむら" }
      short_name { "神恵内村" }
      short_yomi { "かもえないむら" }
    end

    factory :jmaxml_forecast_region_c0140500 do
      code { "0140500" }
      name { "北海道積丹町" }
      yomi { "ほっかいどうしゃこたんちょう" }
      short_name { "積丹町" }
      short_yomi { "しゃこたんちょう" }
    end

    factory :jmaxml_forecast_region_c0140600 do
      code { "0140600" }
      name { "北海道古平町" }
      yomi { "ほっかいどうふるびらちょう" }
      short_name { "古平町" }
      short_yomi { "ふるびらちょう" }
    end

    factory :jmaxml_forecast_region_c0140700 do
      code { "0140700" }
      name { "北海道仁木町" }
      yomi { "ほっかいどうにきちょう" }
      short_name { "仁木町" }
      short_yomi { "にきちょう" }
    end

    factory :jmaxml_forecast_region_c0140800 do
      code { "0140800" }
      name { "北海道余市町" }
      yomi { "ほっかいどうよいちちょう" }
      short_name { "余市町" }
      short_yomi { "よいちちょう" }
    end

    factory :jmaxml_forecast_region_c0140900 do
      code { "0140900" }
      name { "北海道赤井川村" }
      yomi { "ほっかいどうあかいがわむら" }
      short_name { "赤井川村" }
      short_yomi { "あかいがわむら" }
    end

    factory :jmaxml_forecast_region_c0142300 do
      code { "0142300" }
      name { "北海道南幌町" }
      yomi { "ほっかいどうなんぽろちょう" }
      short_name { "南幌町" }
      short_yomi { "なんぽろちょう" }
    end

    factory :jmaxml_forecast_region_c0142400 do
      code { "0142400" }
      name { "北海道奈井江町" }
      yomi { "ほっかいどうないえちょう" }
      short_name { "奈井江町" }
      short_yomi { "ないえちょう" }
    end

    factory :jmaxml_forecast_region_c0142500 do
      code { "0142500" }
      name { "北海道上砂川町" }
      yomi { "ほっかいどうかみすながわちょう" }
      short_name { "上砂川町" }
      short_yomi { "かみすながわちょう" }
    end

    factory :jmaxml_forecast_region_c0142700 do
      code { "0142700" }
      name { "北海道由仁町" }
      yomi { "ほっかいどうゆにちょう" }
      short_name { "由仁町" }
      short_yomi { "ゆにちょう" }
    end

    factory :jmaxml_forecast_region_c0142800 do
      code { "0142800" }
      name { "北海道長沼町" }
      yomi { "ほっかいどうながぬまちょう" }
      short_name { "長沼町" }
      short_yomi { "ながぬまちょう" }
    end

    factory :jmaxml_forecast_region_c0142900 do
      code { "0142900" }
      name { "北海道栗山町" }
      yomi { "ほっかいどうくりやまちょう" }
      short_name { "栗山町" }
      short_yomi { "くりやまちょう" }
    end

    factory :jmaxml_forecast_region_c0143000 do
      code { "0143000" }
      name { "北海道月形町" }
      yomi { "ほっかいどうつきがたちょう" }
      short_name { "月形町" }
      short_yomi { "つきがたちょう" }
    end

    factory :jmaxml_forecast_region_c0143100 do
      code { "0143100" }
      name { "北海道浦臼町" }
      yomi { "ほっかいどううらうすちょう" }
      short_name { "浦臼町" }
      short_yomi { "うらうすちょう" }
    end

    factory :jmaxml_forecast_region_c0143200 do
      code { "0143200" }
      name { "北海道新十津川町" }
      yomi { "ほっかいどうしんとつかわちょう" }
      short_name { "新十津川町" }
      short_yomi { "しんとつかわちょう" }
    end

    factory :jmaxml_forecast_region_c0143300 do
      code { "0143300" }
      name { "北海道妹背牛町" }
      yomi { "ほっかいどうもせうしちょう" }
      short_name { "妹背牛町" }
      short_yomi { "もせうしちょう" }
    end

    factory :jmaxml_forecast_region_c0143400 do
      code { "0143400" }
      name { "北海道秩父別町" }
      yomi { "ほっかいどうちっぷべつちょう" }
      short_name { "秩父別町" }
      short_yomi { "ちっぷべつちょう" }
    end

    factory :jmaxml_forecast_region_c0143600 do
      code { "0143600" }
      name { "北海道雨竜町" }
      yomi { "ほっかいどううりゅうちょう" }
      short_name { "雨竜町" }
      short_yomi { "うりゅうちょう" }
    end

    factory :jmaxml_forecast_region_c0143700 do
      code { "0143700" }
      name { "北海道北竜町" }
      yomi { "ほっかいどうほくりゅうちょう" }
      short_name { "北竜町" }
      short_yomi { "ほくりゅうちょう" }
    end

    factory :jmaxml_forecast_region_c0143800 do
      code { "0143800" }
      name { "北海道沼田町" }
      yomi { "ほっかいどうぬまたちょう" }
      short_name { "沼田町" }
      short_yomi { "ぬまたちょう" }
    end

    factory :jmaxml_forecast_region_c0145200 do
      code { "0145200" }
      name { "北海道鷹栖町" }
      yomi { "ほっかいどうたかすちょう" }
      short_name { "鷹栖町" }
      short_yomi { "たかすちょう" }
    end

    factory :jmaxml_forecast_region_c0145300 do
      code { "0145300" }
      name { "北海道東神楽町" }
      yomi { "ほっかいどうひがしかぐらちょう" }
      short_name { "東神楽町" }
      short_yomi { "ひがしかぐらちょう" }
    end

    factory :jmaxml_forecast_region_c0145400 do
      code { "0145400" }
      name { "北海道当麻町" }
      yomi { "ほっかいどうとうまちょう" }
      short_name { "当麻町" }
      short_yomi { "とうまちょう" }
    end

    factory :jmaxml_forecast_region_c0145500 do
      code { "0145500" }
      name { "北海道比布町" }
      yomi { "ほっかいどうぴっぷちょう" }
      short_name { "比布町" }
      short_yomi { "ぴっぷちょう" }
    end

    factory :jmaxml_forecast_region_c0145600 do
      code { "0145600" }
      name { "北海道愛別町" }
      yomi { "ほっかいどうあいべつちょう" }
      short_name { "愛別町" }
      short_yomi { "あいべつちょう" }
    end

    factory :jmaxml_forecast_region_c0145700 do
      code { "0145700" }
      name { "北海道上川町" }
      yomi { "ほっかいどうかみかわちょう" }
      short_name { "上川町" }
      short_yomi { "かみかわちょう" }
    end

    factory :jmaxml_forecast_region_c0145800 do
      code { "0145800" }
      name { "北海道東川町" }
      yomi { "ほっかいどうひがしかわちょう" }
      short_name { "東川町" }
      short_yomi { "ひがしかわちょう" }
    end

    factory :jmaxml_forecast_region_c0145900 do
      code { "0145900" }
      name { "北海道美瑛町" }
      yomi { "ほっかいどうびえいちょう" }
      short_name { "美瑛町" }
      short_yomi { "びえいちょう" }
    end

    factory :jmaxml_forecast_region_c0146000 do
      code { "0146000" }
      name { "北海道上富良野町" }
      yomi { "ほっかいどうかみふらのちょう" }
      short_name { "上富良野町" }
      short_yomi { "かみふらのちょう" }
    end

    factory :jmaxml_forecast_region_c0146100 do
      code { "0146100" }
      name { "北海道中富良野町" }
      yomi { "ほっかいどうなかふらのちょう" }
      short_name { "中富良野町" }
      short_yomi { "なかふらのちょう" }
    end

    factory :jmaxml_forecast_region_c0146200 do
      code { "0146200" }
      name { "北海道南富良野町" }
      yomi { "ほっかいどうみなみふらのちょう" }
      short_name { "南富良野町" }
      short_yomi { "みなみふらのちょう" }
    end

    factory :jmaxml_forecast_region_c0146300 do
      code { "0146300" }
      name { "北海道占冠村" }
      yomi { "ほっかいどうしむかっぷむら" }
      short_name { "占冠村" }
      short_yomi { "しむかっぷむら" }
    end

    factory :jmaxml_forecast_region_c0146400 do
      code { "0146400" }
      name { "北海道和寒町" }
      yomi { "ほっかいどうわっさむちょう" }
      short_name { "和寒町" }
      short_yomi { "わっさむちょう" }
    end

    factory :jmaxml_forecast_region_c0146500 do
      code { "0146500" }
      name { "北海道剣淵町" }
      yomi { "ほっかいどうけんぶちちょう" }
      short_name { "剣淵町" }
      short_yomi { "けんぶちちょう" }
    end

    factory :jmaxml_forecast_region_c0146800 do
      code { "0146800" }
      name { "北海道下川町" }
      yomi { "ほっかいどうしもかわちょう" }
      short_name { "下川町" }
      short_yomi { "しもかわちょう" }
    end

    factory :jmaxml_forecast_region_c0146900 do
      code { "0146900" }
      name { "北海道美深町" }
      yomi { "ほっかいどうびふかちょう" }
      short_name { "美深町" }
      short_yomi { "びふかちょう" }
    end

    factory :jmaxml_forecast_region_c0147000 do
      code { "0147000" }
      name { "北海道音威子府村" }
      yomi { "ほっかいどうおといねっぷむら" }
      short_name { "音威子府村" }
      short_yomi { "おといねっぷむら" }
    end

    factory :jmaxml_forecast_region_c0147100 do
      code { "0147100" }
      name { "北海道中川町" }
      yomi { "ほっかいどうなかがわちょう" }
      short_name { "中川町" }
      short_yomi { "なかがわちょう" }
    end

    factory :jmaxml_forecast_region_c0147200 do
      code { "0147200" }
      name { "北海道幌加内町" }
      yomi { "ほっかいどうほろかないちょう" }
      short_name { "幌加内町" }
      short_yomi { "ほろかないちょう" }
    end

    factory :jmaxml_forecast_region_c0148100 do
      code { "0148100" }
      name { "北海道増毛町" }
      yomi { "ほっかいどうましけちょう" }
      short_name { "増毛町" }
      short_yomi { "ましけちょう" }
    end

    factory :jmaxml_forecast_region_c0148200 do
      code { "0148200" }
      name { "北海道小平町" }
      yomi { "ほっかいどうおびらちょう" }
      short_name { "小平町" }
      short_yomi { "おびらちょう" }
    end

    factory :jmaxml_forecast_region_c0148300 do
      code { "0148300" }
      name { "北海道苫前町" }
      yomi { "ほっかいどうとままえちょう" }
      short_name { "苫前町" }
      short_yomi { "とままえちょう" }
    end

    factory :jmaxml_forecast_region_c0148400 do
      code { "0148400" }
      name { "北海道羽幌町" }
      yomi { "ほっかいどうはぼろちょう" }
      short_name { "羽幌町" }
      short_yomi { "はぼろちょう" }
    end

    factory :jmaxml_forecast_region_c0148500 do
      code { "0148500" }
      name { "北海道初山別村" }
      yomi { "ほっかいどうしょさんべつむら" }
      short_name { "初山別村" }
      short_yomi { "しょさんべつむら" }
    end

    factory :jmaxml_forecast_region_c0148600 do
      code { "0148600" }
      name { "北海道遠別町" }
      yomi { "ほっかいどうえんべつちょう" }
      short_name { "遠別町" }
      short_yomi { "えんべつちょう" }
    end

    factory :jmaxml_forecast_region_c0148700 do
      code { "0148700" }
      name { "北海道天塩町" }
      yomi { "ほっかいどうてしおちょう" }
      short_name { "天塩町" }
      short_yomi { "てしおちょう" }
    end

    factory :jmaxml_forecast_region_c0151100 do
      code { "0151100" }
      name { "北海道猿払村" }
      yomi { "ほっかいどうさるふつむら" }
      short_name { "猿払村" }
      short_yomi { "さるふつむら" }
    end

    factory :jmaxml_forecast_region_c0151200 do
      code { "0151200" }
      name { "北海道浜頓別町" }
      yomi { "ほっかいどうはまとんべつちょう" }
      short_name { "浜頓別町" }
      short_yomi { "はまとんべつちょう" }
    end

    factory :jmaxml_forecast_region_c0151300 do
      code { "0151300" }
      name { "北海道中頓別町" }
      yomi { "ほっかいどうなかとんべつちょう" }
      short_name { "中頓別町" }
      short_yomi { "なかとんべつちょう" }
    end

    factory :jmaxml_forecast_region_c0151400 do
      code { "0151400" }
      name { "北海道枝幸町" }
      yomi { "ほっかいどうえさしちょう" }
      short_name { "枝幸町" }
      short_yomi { "えさしちょう" }
    end

    factory :jmaxml_forecast_region_c0151600 do
      code { "0151600" }
      name { "北海道豊富町" }
      yomi { "ほっかいどうとよとみちょう" }
      short_name { "豊富町" }
      short_yomi { "とよとみちょう" }
    end

    factory :jmaxml_forecast_region_c0151700 do
      code { "0151700" }
      name { "北海道礼文町" }
      yomi { "ほっかいどうれぶんちょう" }
      short_name { "礼文町" }
      short_yomi { "れぶんちょう" }
    end

    factory :jmaxml_forecast_region_c0151800 do
      code { "0151800" }
      name { "北海道利尻町" }
      yomi { "ほっかいどうりしりちょう" }
      short_name { "利尻町" }
      short_yomi { "りしりちょう" }
    end

    factory :jmaxml_forecast_region_c0151900 do
      code { "0151900" }
      name { "北海道利尻富士町" }
      yomi { "ほっかいどうりしりふじちょう" }
      short_name { "利尻富士町" }
      short_yomi { "りしりふじちょう" }
    end

    factory :jmaxml_forecast_region_c0152000 do
      code { "0152000" }
      name { "北海道幌延町" }
      yomi { "ほっかいどうほろのべちょう" }
      short_name { "幌延町" }
      short_yomi { "ほろのべちょう" }
    end

    factory :jmaxml_forecast_region_c0154300 do
      code { "0154300" }
      name { "北海道美幌町" }
      yomi { "ほっかいどうびほろちょう" }
      short_name { "美幌町" }
      short_yomi { "びほろちょう" }
    end

    factory :jmaxml_forecast_region_c0154400 do
      code { "0154400" }
      name { "北海道津別町" }
      yomi { "ほっかいどうつべつちょう" }
      short_name { "津別町" }
      short_yomi { "つべつちょう" }
    end

    factory :jmaxml_forecast_region_c0154500 do
      code { "0154500" }
      name { "北海道斜里町" }
      yomi { "ほっかいどうしゃりちょう" }
      short_name { "斜里町" }
      short_yomi { "しゃりちょう" }
    end

    factory :jmaxml_forecast_region_c0154600 do
      code { "0154600" }
      name { "北海道清里町" }
      yomi { "ほっかいどうきよさとちょう" }
      short_name { "清里町" }
      short_yomi { "きよさとちょう" }
    end

    factory :jmaxml_forecast_region_c0154700 do
      code { "0154700" }
      name { "北海道小清水町" }
      yomi { "ほっかいどうこしみずちょう" }
      short_name { "小清水町" }
      short_yomi { "こしみずちょう" }
    end

    factory :jmaxml_forecast_region_c0154900 do
      code { "0154900" }
      name { "北海道訓子府町" }
      yomi { "ほっかいどうくんねっぷちょう" }
      short_name { "訓子府町" }
      short_yomi { "くんねっぷちょう" }
    end

    factory :jmaxml_forecast_region_c0155000 do
      code { "0155000" }
      name { "北海道置戸町" }
      yomi { "ほっかいどうおけとちょう" }
      short_name { "置戸町" }
      short_yomi { "おけとちょう" }
    end

    factory :jmaxml_forecast_region_c0155200 do
      code { "0155200" }
      name { "北海道佐呂間町" }
      yomi { "ほっかいどうさろまちょう" }
      short_name { "佐呂間町" }
      short_yomi { "さろまちょう" }
    end

    factory :jmaxml_forecast_region_c0155500 do
      code { "0155500" }
      name { "北海道遠軽町" }
      yomi { "ほっかいどうえんがるちょう" }
      short_name { "遠軽町" }
      short_yomi { "えんがるちょう" }
    end

    factory :jmaxml_forecast_region_c0155900 do
      code { "0155900" }
      name { "北海道湧別町" }
      yomi { "ほっかいどうゆうべつちょう" }
      short_name { "湧別町" }
      short_yomi { "ゆうべつちょう" }
    end

    factory :jmaxml_forecast_region_c0156000 do
      code { "0156000" }
      name { "北海道滝上町" }
      yomi { "ほっかいどうたきのうえちょう" }
      short_name { "滝上町" }
      short_yomi { "たきのうえちょう" }
    end

    factory :jmaxml_forecast_region_c0156100 do
      code { "0156100" }
      name { "北海道興部町" }
      yomi { "ほっかいどうおこっぺちょう" }
      short_name { "興部町" }
      short_yomi { "おこっぺちょう" }
    end

    factory :jmaxml_forecast_region_c0156200 do
      code { "0156200" }
      name { "北海道西興部村" }
      yomi { "ほっかいどうにしおこっぺむら" }
      short_name { "西興部村" }
      short_yomi { "にしおこっぺむら" }
    end

    factory :jmaxml_forecast_region_c0156300 do
      code { "0156300" }
      name { "北海道雄武町" }
      yomi { "ほっかいどうおうむちょう" }
      short_name { "雄武町" }
      short_yomi { "おうむちょう" }
    end

    factory :jmaxml_forecast_region_c0156400 do
      code { "0156400" }
      name { "北海道大空町" }
      yomi { "ほっかいどうおおぞらちょう" }
      short_name { "大空町" }
      short_yomi { "おおぞらちょう" }
    end

    factory :jmaxml_forecast_region_c0157100 do
      code { "0157100" }
      name { "北海道豊浦町" }
      yomi { "ほっかいどうとようらちょう" }
      short_name { "豊浦町" }
      short_yomi { "とようらちょう" }
    end

    factory :jmaxml_forecast_region_c0157500 do
      code { "0157500" }
      name { "北海道壮瞥町" }
      yomi { "ほっかいどうそうべつちょう" }
      short_name { "壮瞥町" }
      short_yomi { "そうべつちょう" }
    end

    factory :jmaxml_forecast_region_c0157800 do
      code { "0157800" }
      name { "北海道白老町" }
      yomi { "ほっかいどうしらおいちょう" }
      short_name { "白老町" }
      short_yomi { "しらおいちょう" }
    end

    factory :jmaxml_forecast_region_c0158100 do
      code { "0158100" }
      name { "北海道厚真町" }
      yomi { "ほっかいどうあつまちょう" }
      short_name { "厚真町" }
      short_yomi { "あつまちょう" }
    end

    factory :jmaxml_forecast_region_c0158400 do
      code { "0158400" }
      name { "北海道洞爺湖町" }
      yomi { "ほっかいどうとうやこちょう" }
      short_name { "洞爺湖町" }
      short_yomi { "とうやこちょう" }
    end

    factory :jmaxml_forecast_region_c0158500 do
      code { "0158500" }
      name { "北海道安平町" }
      yomi { "ほっかいどうあびらちょう" }
      short_name { "安平町" }
      short_yomi { "あびらちょう" }
    end

    factory :jmaxml_forecast_region_c0158600 do
      code { "0158600" }
      name { "北海道むかわ町" }
      yomi { "ほっかいどうむかわちょう" }
      short_name { "むかわ町" }
      short_yomi { "むかわちょう" }
    end

    factory :jmaxml_forecast_region_c0160100 do
      code { "0160100" }
      name { "北海道日高町" }
      yomi { "ほっかいどうひだかちょう" }
      short_name { "日高町" }
      short_yomi { "ひだかちょう" }
    end

    factory :jmaxml_forecast_region_c0160200 do
      code { "0160200" }
      name { "北海道平取町" }
      yomi { "ほっかいどうびらとりちょう" }
      short_name { "平取町" }
      short_yomi { "びらとりちょう" }
    end

    factory :jmaxml_forecast_region_c0160400 do
      code { "0160400" }
      name { "北海道新冠町" }
      yomi { "ほっかいどうにいかっぷちょう" }
      short_name { "新冠町" }
      short_yomi { "にいかっぷちょう" }
    end

    factory :jmaxml_forecast_region_c0160700 do
      code { "0160700" }
      name { "北海道浦河町" }
      yomi { "ほっかいどううらかわちょう" }
      short_name { "浦河町" }
      short_yomi { "うらかわちょう" }
    end

    factory :jmaxml_forecast_region_c0160800 do
      code { "0160800" }
      name { "北海道様似町" }
      yomi { "ほっかいどうさまにちょう" }
      short_name { "様似町" }
      short_yomi { "さまにちょう" }
    end

    factory :jmaxml_forecast_region_c0160900 do
      code { "0160900" }
      name { "北海道えりも町" }
      yomi { "ほっかいどうえりもちょう" }
      short_name { "えりも町" }
      short_yomi { "えりもちょう" }
    end

    factory :jmaxml_forecast_region_c0161000 do
      code { "0161000" }
      name { "北海道新ひだか町" }
      yomi { "ほっかいどうしんひだかちょう" }
      short_name { "新ひだか町" }
      short_yomi { "しんひだかちょう" }
    end

    factory :jmaxml_forecast_region_c0163100 do
      code { "0163100" }
      name { "北海道音更町" }
      yomi { "ほっかいどうおとふけちょう" }
      short_name { "音更町" }
      short_yomi { "おとふけちょう" }
    end

    factory :jmaxml_forecast_region_c0163200 do
      code { "0163200" }
      name { "北海道士幌町" }
      yomi { "ほっかいどうしほろちょう" }
      short_name { "士幌町" }
      short_yomi { "しほろちょう" }
    end

    factory :jmaxml_forecast_region_c0163300 do
      code { "0163300" }
      name { "北海道上士幌町" }
      yomi { "ほっかいどうかみしほろちょう" }
      short_name { "上士幌町" }
      short_yomi { "かみしほろちょう" }
    end

    factory :jmaxml_forecast_region_c0163400 do
      code { "0163400" }
      name { "北海道鹿追町" }
      yomi { "ほっかいどうしかおいちょう" }
      short_name { "鹿追町" }
      short_yomi { "しかおいちょう" }
    end

    factory :jmaxml_forecast_region_c0163500 do
      code { "0163500" }
      name { "北海道新得町" }
      yomi { "ほっかいどうしんとくちょう" }
      short_name { "新得町" }
      short_yomi { "しんとくちょう" }
    end

    factory :jmaxml_forecast_region_c0163600 do
      code { "0163600" }
      name { "北海道清水町" }
      yomi { "ほっかいどうしみずちょう" }
      short_name { "清水町" }
      short_yomi { "しみずちょう" }
    end

    factory :jmaxml_forecast_region_c0163700 do
      code { "0163700" }
      name { "北海道芽室町" }
      yomi { "ほっかいどうめむろちょう" }
      short_name { "芽室町" }
      short_yomi { "めむろちょう" }
    end

    factory :jmaxml_forecast_region_c0163800 do
      code { "0163800" }
      name { "北海道中札内村" }
      yomi { "ほっかいどうなかさつないむら" }
      short_name { "中札内村" }
      short_yomi { "なかさつないむら" }
    end

    factory :jmaxml_forecast_region_c0163900 do
      code { "0163900" }
      name { "北海道更別村" }
      yomi { "ほっかいどうさらべつむら" }
      short_name { "更別村" }
      short_yomi { "さらべつむら" }
    end

    factory :jmaxml_forecast_region_c0164100 do
      code { "0164100" }
      name { "北海道大樹町" }
      yomi { "ほっかいどうたいきちょう" }
      short_name { "大樹町" }
      short_yomi { "たいきちょう" }
    end

    factory :jmaxml_forecast_region_c0164200 do
      code { "0164200" }
      name { "北海道広尾町" }
      yomi { "ほっかいどうひろおちょう" }
      short_name { "広尾町" }
      short_yomi { "ひろおちょう" }
    end

    factory :jmaxml_forecast_region_c0164300 do
      code { "0164300" }
      name { "北海道幕別町" }
      yomi { "ほっかいどうまくべつちょう" }
      short_name { "幕別町" }
      short_yomi { "まくべつちょう" }
    end

    factory :jmaxml_forecast_region_c0164400 do
      code { "0164400" }
      name { "北海道池田町" }
      yomi { "ほっかいどういけだちょう" }
      short_name { "池田町" }
      short_yomi { "いけだちょう" }
    end

    factory :jmaxml_forecast_region_c0164500 do
      code { "0164500" }
      name { "北海道豊頃町" }
      yomi { "ほっかいどうとよころちょう" }
      short_name { "豊頃町" }
      short_yomi { "とよころちょう" }
    end

    factory :jmaxml_forecast_region_c0164600 do
      code { "0164600" }
      name { "北海道本別町" }
      yomi { "ほっかいどうほんべつちょう" }
      short_name { "本別町" }
      short_yomi { "ほんべつちょう" }
    end

    factory :jmaxml_forecast_region_c0164700 do
      code { "0164700" }
      name { "北海道足寄町" }
      yomi { "ほっかいどうあしょろちょう" }
      short_name { "足寄町" }
      short_yomi { "あしょろちょう" }
    end

    factory :jmaxml_forecast_region_c0164800 do
      code { "0164800" }
      name { "北海道陸別町" }
      yomi { "ほっかいどうりくべつちょう" }
      short_name { "陸別町" }
      short_yomi { "りくべつちょう" }
    end

    factory :jmaxml_forecast_region_c0164900 do
      code { "0164900" }
      name { "北海道浦幌町" }
      yomi { "ほっかいどううらほろちょう" }
      short_name { "浦幌町" }
      short_yomi { "うらほろちょう" }
    end

    factory :jmaxml_forecast_region_c0166100 do
      code { "0166100" }
      name { "北海道釧路町" }
      yomi { "ほっかいどうくしろちょう" }
      short_name { "釧路町" }
      short_yomi { "くしろちょう" }
    end

    factory :jmaxml_forecast_region_c0166200 do
      code { "0166200" }
      name { "北海道厚岸町" }
      yomi { "ほっかいどうあっけしちょう" }
      short_name { "厚岸町" }
      short_yomi { "あっけしちょう" }
    end

    factory :jmaxml_forecast_region_c0166300 do
      code { "0166300" }
      name { "北海道浜中町" }
      yomi { "ほっかいどうはまなかちょう" }
      short_name { "浜中町" }
      short_yomi { "はまなかちょう" }
    end

    factory :jmaxml_forecast_region_c0166400 do
      code { "0166400" }
      name { "北海道標茶町" }
      yomi { "ほっかいどうしべちゃちょう" }
      short_name { "標茶町" }
      short_yomi { "しべちゃちょう" }
    end

    factory :jmaxml_forecast_region_c0166500 do
      code { "0166500" }
      name { "北海道弟子屈町" }
      yomi { "ほっかいどうてしかがちょう" }
      short_name { "弟子屈町" }
      short_yomi { "てしかがちょう" }
    end

    factory :jmaxml_forecast_region_c0166700 do
      code { "0166700" }
      name { "北海道鶴居村" }
      yomi { "ほっかいどうつるいむら" }
      short_name { "鶴居村" }
      short_yomi { "つるいむら" }
    end

    factory :jmaxml_forecast_region_c0166800 do
      code { "0166800" }
      name { "北海道白糠町" }
      yomi { "ほっかいどうしらぬかちょう" }
      short_name { "白糠町" }
      short_yomi { "しらぬかちょう" }
    end

    factory :jmaxml_forecast_region_c0169001 do
      code { "0169001" }
      name { "北海道国後島" }
      yomi { "ほっかいどうくなしりとう" }
      short_name { "0" }
      short_yomi { "0" }
    end

    factory :jmaxml_forecast_region_c0169002 do
      code { "0169002" }
      name { "北海道択捉島" }
      yomi { "ほっかいどうえとろふとう" }
      short_name { "0" }
      short_yomi { "0" }
    end

    factory :jmaxml_forecast_region_c0169100 do
      code { "0169100" }
      name { "北海道別海町" }
      yomi { "ほっかいどうべつかいちょう" }
      short_name { "別海町" }
      short_yomi { "べつかいちょう" }
    end

    factory :jmaxml_forecast_region_c0169200 do
      code { "0169200" }
      name { "北海道中標津町" }
      yomi { "ほっかいどうなかしべつちょう" }
      short_name { "中標津町" }
      short_yomi { "なかしべつちょう" }
    end

    factory :jmaxml_forecast_region_c0169300 do
      code { "0169300" }
      name { "北海道標津町" }
      yomi { "ほっかいどうしべつちょう" }
      short_name { "標津町" }
      short_yomi { "しべつちょう" }
    end

    factory :jmaxml_forecast_region_c0169400 do
      code { "0169400" }
      name { "北海道羅臼町" }
      yomi { "ほっかいどうらうすちょう" }
      short_name { "羅臼町" }
      short_yomi { "らうすちょう" }
    end

    factory :jmaxml_forecast_region_c0169500 do
      code { "0169500" }
      name { "北海道色丹村" }
      yomi { "ほっかいどうしこたんむら" }
      short_name { "0" }
      short_yomi { "0" }
    end

    factory :jmaxml_forecast_region_c0220100 do
      code { "0220100" }
      name { "青森県青森市" }
      yomi { "あおもりけんあおもりし" }
      short_name { "青森市" }
      short_yomi { "あおもりし" }
    end

    factory :jmaxml_forecast_region_c0220200 do
      code { "0220200" }
      name { "青森県弘前市" }
      yomi { "あおもりけんひろさきし" }
      short_name { "弘前市" }
      short_yomi { "ひろさきし" }
    end

    factory :jmaxml_forecast_region_c0220300 do
      code { "0220300" }
      name { "青森県八戸市" }
      yomi { "あおもりけんはちのへし" }
      short_name { "八戸市" }
      short_yomi { "はちのへし" }
    end

    factory :jmaxml_forecast_region_c0220400 do
      code { "0220400" }
      name { "青森県黒石市" }
      yomi { "あおもりけんくろいしし" }
      short_name { "黒石市" }
      short_yomi { "くろいしし" }
    end

    factory :jmaxml_forecast_region_c0220500 do
      code { "0220500" }
      name { "青森県五所川原市" }
      yomi { "あおもりけんごしょがわらし" }
      short_name { "五所川原市" }
      short_yomi { "ごしょがわらし" }
    end

    factory :jmaxml_forecast_region_c0220600 do
      code { "0220600" }
      name { "青森県十和田市" }
      yomi { "あおもりけんとわだし" }
      short_name { "十和田市" }
      short_yomi { "とわだし" }
    end

    factory :jmaxml_forecast_region_c0220700 do
      code { "0220700" }
      name { "青森県三沢市" }
      yomi { "あおもりけんみさわし" }
      short_name { "三沢市" }
      short_yomi { "みさわし" }
    end

    factory :jmaxml_forecast_region_c0220800 do
      code { "0220800" }
      name { "青森県むつ市" }
      yomi { "あおもりけんむつし" }
      short_name { "むつ市" }
      short_yomi { "むつし" }
    end

    factory :jmaxml_forecast_region_c0220900 do
      code { "0220900" }
      name { "青森県つがる市" }
      yomi { "あおもりけんつがるし" }
      short_name { "つがる市" }
      short_yomi { "つがるし" }
    end

    factory :jmaxml_forecast_region_c0221000 do
      code { "0221000" }
      name { "青森県平川市" }
      yomi { "あおもりけんひらかわし" }
      short_name { "平川市" }
      short_yomi { "ひらかわし" }
    end

    factory :jmaxml_forecast_region_c0230100 do
      code { "0230100" }
      name { "青森県平内町" }
      yomi { "あおもりけんひらないまち" }
      short_name { "平内町" }
      short_yomi { "ひらないまち" }
    end

    factory :jmaxml_forecast_region_c0230300 do
      code { "0230300" }
      name { "青森県今別町" }
      yomi { "あおもりけんいまべつまち" }
      short_name { "今別町" }
      short_yomi { "いまべつまち" }
    end

    factory :jmaxml_forecast_region_c0230400 do
      code { "0230400" }
      name { "青森県蓬田村" }
      yomi { "あおもりけんよもぎたむら" }
      short_name { "蓬田村" }
      short_yomi { "よもぎたむら" }
    end

    factory :jmaxml_forecast_region_c0230700 do
      code { "0230700" }
      name { "青森県外ヶ浜町" }
      yomi { "あおもりけんそとがはままち" }
      short_name { "外ヶ浜町" }
      short_yomi { "そとがはままち" }
    end

    factory :jmaxml_forecast_region_c0232100 do
      code { "0232100" }
      name { "青森県鰺ヶ沢町" }
      yomi { "あおもりけんあじがさわまち" }
      short_name { "鰺ヶ沢町" }
      short_yomi { "あじがさわまち" }
    end

    factory :jmaxml_forecast_region_c0232300 do
      code { "0232300" }
      name { "青森県深浦町" }
      yomi { "あおもりけんふかうらまち" }
      short_name { "深浦町" }
      short_yomi { "ふかうらまち" }
    end

    factory :jmaxml_forecast_region_c0234300 do
      code { "0234300" }
      name { "青森県西目屋村" }
      yomi { "あおもりけんにしめやむら" }
      short_name { "西目屋村" }
      short_yomi { "にしめやむら" }
    end

    factory :jmaxml_forecast_region_c0236100 do
      code { "0236100" }
      name { "青森県藤崎町" }
      yomi { "あおもりけんふじさきまち" }
      short_name { "藤崎町" }
      short_yomi { "ふじさきまち" }
    end

    factory :jmaxml_forecast_region_c0236200 do
      code { "0236200" }
      name { "青森県大鰐町" }
      yomi { "あおもりけんおおわにまち" }
      short_name { "大鰐町" }
      short_yomi { "おおわにまち" }
    end

    factory :jmaxml_forecast_region_c0236700 do
      code { "0236700" }
      name { "青森県田舎館村" }
      yomi { "あおもりけんいなかだてむら" }
      short_name { "田舎館村" }
      short_yomi { "いなかだてむら" }
    end

    factory :jmaxml_forecast_region_c0238100 do
      code { "0238100" }
      name { "青森県板柳町" }
      yomi { "あおもりけんいたやなぎまち" }
      short_name { "板柳町" }
      short_yomi { "いたやなぎまち" }
    end

    factory :jmaxml_forecast_region_c0238400 do
      code { "0238400" }
      name { "青森県鶴田町" }
      yomi { "あおもりけんつるたまち" }
      short_name { "鶴田町" }
      short_yomi { "つるたまち" }
    end

    factory :jmaxml_forecast_region_c0238700 do
      code { "0238700" }
      name { "青森県中泊町" }
      yomi { "あおもりけんなかどまりまち" }
      short_name { "中泊町" }
      short_yomi { "なかどまりまち" }
    end

    factory :jmaxml_forecast_region_c0240100 do
      code { "0240100" }
      name { "青森県野辺地町" }
      yomi { "あおもりけんのへじまち" }
      short_name { "野辺地町" }
      short_yomi { "のへじまち" }
    end

    factory :jmaxml_forecast_region_c0240200 do
      code { "0240200" }
      name { "青森県七戸町" }
      yomi { "あおもりけんしちのへまち" }
      short_name { "七戸町" }
      short_yomi { "しちのへまち" }
    end

    factory :jmaxml_forecast_region_c0240500 do
      code { "0240500" }
      name { "青森県六戸町" }
      yomi { "あおもりけんろくのへまち" }
      short_name { "六戸町" }
      short_yomi { "ろくのへまち" }
    end

    factory :jmaxml_forecast_region_c0240600 do
      code { "0240600" }
      name { "青森県横浜町" }
      yomi { "あおもりけんよこはままち" }
      short_name { "横浜町" }
      short_yomi { "よこはままち" }
    end

    factory :jmaxml_forecast_region_c0240800 do
      code { "0240800" }
      name { "青森県東北町" }
      yomi { "あおもりけんとうほくまち" }
      short_name { "東北町" }
      short_yomi { "とうほくまち" }
    end

    factory :jmaxml_forecast_region_c0241100 do
      code { "0241100" }
      name { "青森県六ヶ所村" }
      yomi { "あおもりけんろっかしょむら" }
      short_name { "六ヶ所村" }
      short_yomi { "ろっかしょむら" }
    end

    factory :jmaxml_forecast_region_c0241200 do
      code { "0241200" }
      name { "青森県おいらせ町" }
      yomi { "あおもりけんおいらせちょう" }
      short_name { "おいらせ町" }
      short_yomi { "おいらせちょう" }
    end

    factory :jmaxml_forecast_region_c0242300 do
      code { "0242300" }
      name { "青森県大間町" }
      yomi { "あおもりけんおおままち" }
      short_name { "大間町" }
      short_yomi { "おおままち" }
    end

    factory :jmaxml_forecast_region_c0242400 do
      code { "0242400" }
      name { "青森県東通村" }
      yomi { "あおもりけんひがしどおりむら" }
      short_name { "東通村" }
      short_yomi { "ひがしどおりむら" }
    end

    factory :jmaxml_forecast_region_c0242500 do
      code { "0242500" }
      name { "青森県風間浦村" }
      yomi { "あおもりけんかざまうらむら" }
      short_name { "風間浦村" }
      short_yomi { "かざまうらむら" }
    end

    factory :jmaxml_forecast_region_c0242600 do
      code { "0242600" }
      name { "青森県佐井村" }
      yomi { "あおもりけんさいむら" }
      short_name { "佐井村" }
      short_yomi { "さいむら" }
    end

    factory :jmaxml_forecast_region_c0244100 do
      code { "0244100" }
      name { "青森県三戸町" }
      yomi { "あおもりけんさんのへまち" }
      short_name { "三戸町" }
      short_yomi { "さんのへまち" }
    end

    factory :jmaxml_forecast_region_c0244200 do
      code { "0244200" }
      name { "青森県五戸町" }
      yomi { "あおもりけんごのへまち" }
      short_name { "五戸町" }
      short_yomi { "ごのへまち" }
    end

    factory :jmaxml_forecast_region_c0244300 do
      code { "0244300" }
      name { "青森県田子町" }
      yomi { "あおもりけんたっこまち" }
      short_name { "田子町" }
      short_yomi { "たっこまち" }
    end

    factory :jmaxml_forecast_region_c0244500 do
      code { "0244500" }
      name { "青森県南部町" }
      yomi { "あおもりけんなんぶちょう" }
      short_name { "南部町" }
      short_yomi { "なんぶちょう" }
    end

    factory :jmaxml_forecast_region_c0244600 do
      code { "0244600" }
      name { "青森県階上町" }
      yomi { "あおもりけんはしかみちょう" }
      short_name { "階上町" }
      short_yomi { "はしかみちょう" }
    end

    factory :jmaxml_forecast_region_c0245000 do
      code { "0245000" }
      name { "青森県新郷村" }
      yomi { "あおもりけんしんごうむら" }
      short_name { "新郷村" }
      short_yomi { "しんごうむら" }
    end

    factory :jmaxml_forecast_region_c0320100 do
      code { "0320100" }
      name { "岩手県盛岡市" }
      yomi { "いわてけんもりおかし" }
      short_name { "盛岡市" }
      short_yomi { "もりおかし" }
    end

    factory :jmaxml_forecast_region_c0320200 do
      code { "0320200" }
      name { "岩手県宮古市" }
      yomi { "いわてけんみやこし" }
      short_name { "宮古市" }
      short_yomi { "みやこし" }
    end

    factory :jmaxml_forecast_region_c0320300 do
      code { "0320300" }
      name { "岩手県大船渡市" }
      yomi { "いわてけんおおふなとし" }
      short_name { "大船渡市" }
      short_yomi { "おおふなとし" }
    end

    factory :jmaxml_forecast_region_c0320500 do
      code { "0320500" }
      name { "岩手県花巻市" }
      yomi { "いわてけんはなまきし" }
      short_name { "花巻市" }
      short_yomi { "はなまきし" }
    end

    factory :jmaxml_forecast_region_c0320600 do
      code { "0320600" }
      name { "岩手県北上市" }
      yomi { "いわてけんきたかみし" }
      short_name { "北上市" }
      short_yomi { "きたかみし" }
    end

    factory :jmaxml_forecast_region_c0320700 do
      code { "0320700" }
      name { "岩手県久慈市" }
      yomi { "いわてけんくじし" }
      short_name { "久慈市" }
      short_yomi { "くじし" }
    end

    factory :jmaxml_forecast_region_c0320800 do
      code { "0320800" }
      name { "岩手県遠野市" }
      yomi { "いわてけんとおのし" }
      short_name { "遠野市" }
      short_yomi { "とおのし" }
    end

    factory :jmaxml_forecast_region_c0320900 do
      code { "0320900" }
      name { "岩手県一関市" }
      yomi { "いわてけんいちのせきし" }
      short_name { "一関市" }
      short_yomi { "いちのせきし" }
    end

    factory :jmaxml_forecast_region_c0321000 do
      code { "0321000" }
      name { "岩手県陸前高田市" }
      yomi { "いわてけんりくぜんたかたし" }
      short_name { "陸前高田市" }
      short_yomi { "りくぜんたかたし" }
    end

    factory :jmaxml_forecast_region_c0321100 do
      code { "0321100" }
      name { "岩手県釜石市" }
      yomi { "いわてけんかまいしし" }
      short_name { "釜石市" }
      short_yomi { "かまいしし" }
    end

    factory :jmaxml_forecast_region_c0321300 do
      code { "0321300" }
      name { "岩手県二戸市" }
      yomi { "いわてけんにのへし" }
      short_name { "二戸市" }
      short_yomi { "にのへし" }
    end

    factory :jmaxml_forecast_region_c0321400 do
      code { "0321400" }
      name { "岩手県八幡平市" }
      yomi { "いわてけんはちまんたいし" }
      short_name { "八幡平市" }
      short_yomi { "はちまんたいし" }
    end

    factory :jmaxml_forecast_region_c0321500 do
      code { "0321500" }
      name { "岩手県奥州市" }
      yomi { "いわてけんおうしゅうし" }
      short_name { "奥州市" }
      short_yomi { "おうしゅうし" }
    end

    factory :jmaxml_forecast_region_c0321600 do
      code { "0321600" }
      name { "岩手県滝沢市" }
      yomi { "いわてけんたきざわし" }
      short_name { "滝沢市" }
      short_yomi { "たきざわし" }
    end

    factory :jmaxml_forecast_region_c0330100 do
      code { "0330100" }
      name { "岩手県雫石町" }
      yomi { "いわてけんしずくいしちょう" }
      short_name { "雫石町" }
      short_yomi { "しずくいしちょう" }
    end

    factory :jmaxml_forecast_region_c0330200 do
      code { "0330200" }
      name { "岩手県葛巻町" }
      yomi { "いわてけんくずまきまち" }
      short_name { "葛巻町" }
      short_yomi { "くずまきまち" }
    end

    factory :jmaxml_forecast_region_c0330300 do
      code { "0330300" }
      name { "岩手県岩手町" }
      yomi { "いわてけんいわてまち" }
      short_name { "岩手町" }
      short_yomi { "いわてまち" }
    end

    factory :jmaxml_forecast_region_c0332100 do
      code { "0332100" }
      name { "岩手県紫波町" }
      yomi { "いわてけんしわちょう" }
      short_name { "紫波町" }
      short_yomi { "しわちょう" }
    end

    factory :jmaxml_forecast_region_c0332200 do
      code { "0332200" }
      name { "岩手県矢巾町" }
      yomi { "いわてけんやはばちょう" }
      short_name { "矢巾町" }
      short_yomi { "やはばちょう" }
    end

    factory :jmaxml_forecast_region_c0336600 do
      code { "0336600" }
      name { "岩手県西和賀町" }
      yomi { "いわてけんにしわがまち" }
      short_name { "西和賀町" }
      short_yomi { "にしわがまち" }
    end

    factory :jmaxml_forecast_region_c0338100 do
      code { "0338100" }
      name { "岩手県金ケ崎町" }
      yomi { "いわてけんかねがさきちょう" }
      short_name { "金ケ崎町" }
      short_yomi { "かねがさきちょう" }
    end

    factory :jmaxml_forecast_region_c0340200 do
      code { "0340200" }
      name { "岩手県平泉町" }
      yomi { "いわてけんひらいずみちょう" }
      short_name { "平泉町" }
      short_yomi { "ひらいずみちょう" }
    end

    factory :jmaxml_forecast_region_c0344100 do
      code { "0344100" }
      name { "岩手県住田町" }
      yomi { "いわてけんすみたちょう" }
      short_name { "住田町" }
      short_yomi { "すみたちょう" }
    end

    factory :jmaxml_forecast_region_c0346100 do
      code { "0346100" }
      name { "岩手県大槌町" }
      yomi { "いわてけんおおつちちょう" }
      short_name { "大槌町" }
      short_yomi { "おおつちちょう" }
    end

    factory :jmaxml_forecast_region_c0348200 do
      code { "0348200" }
      name { "岩手県山田町" }
      yomi { "いわてけんやまだまち" }
      short_name { "山田町" }
      short_yomi { "やまだまち" }
    end

    factory :jmaxml_forecast_region_c0348300 do
      code { "0348300" }
      name { "岩手県岩泉町" }
      yomi { "いわてけんいわいずみちょう" }
      short_name { "岩泉町" }
      short_yomi { "いわいずみちょう" }
    end

    factory :jmaxml_forecast_region_c0348400 do
      code { "0348400" }
      name { "岩手県田野畑村" }
      yomi { "いわてけんたのはたむら" }
      short_name { "田野畑村" }
      short_yomi { "たのはたむら" }
    end

    factory :jmaxml_forecast_region_c0348500 do
      code { "0348500" }
      name { "岩手県普代村" }
      yomi { "いわてけんふだいむら" }
      short_name { "普代村" }
      short_yomi { "ふだいむら" }
    end

    factory :jmaxml_forecast_region_c0350100 do
      code { "0350100" }
      name { "岩手県軽米町" }
      yomi { "いわてけんかるまいまち" }
      short_name { "軽米町" }
      short_yomi { "かるまいまち" }
    end

    factory :jmaxml_forecast_region_c0350300 do
      code { "0350300" }
      name { "岩手県野田村" }
      yomi { "いわてけんのだむら" }
      short_name { "野田村" }
      short_yomi { "のだむら" }
    end

    factory :jmaxml_forecast_region_c0350600 do
      code { "0350600" }
      name { "岩手県九戸村" }
      yomi { "いわてけんくのへむら" }
      short_name { "九戸村" }
      short_yomi { "くのへむら" }
    end

    factory :jmaxml_forecast_region_c0350700 do
      code { "0350700" }
      name { "岩手県洋野町" }
      yomi { "いわてけんひろのちょう" }
      short_name { "洋野町" }
      short_yomi { "ひろのちょう" }
    end

    factory :jmaxml_forecast_region_c0352400 do
      code { "0352400" }
      name { "岩手県一戸町" }
      yomi { "いわてけんいちのへまち" }
      short_name { "一戸町" }
      short_yomi { "いちのへまち" }
    end

    factory :jmaxml_forecast_region_c0410000 do
      code { "0410000" }
      name { "宮城県仙台市" }
      yomi { "みやぎけんせんだいし" }
      short_name { "仙台市" }
      short_yomi { "せんだいし" }
    end

    factory :jmaxml_forecast_region_c0420200 do
      code { "0420200" }
      name { "宮城県石巻市" }
      yomi { "みやぎけんいしのまきし" }
      short_name { "石巻市" }
      short_yomi { "いしのまきし" }
    end

    factory :jmaxml_forecast_region_c0420300 do
      code { "0420300" }
      name { "宮城県塩竈市" }
      yomi { "みやぎけんしおがまし" }
      short_name { "塩竈市" }
      short_yomi { "しおがまし" }
    end

    factory :jmaxml_forecast_region_c0420500 do
      code { "0420500" }
      name { "宮城県気仙沼市" }
      yomi { "みやぎけんけせんぬまし" }
      short_name { "気仙沼市" }
      short_yomi { "けせんぬまし" }
    end

    factory :jmaxml_forecast_region_c0420600 do
      code { "0420600" }
      name { "宮城県白石市" }
      yomi { "みやぎけんしろいしし" }
      short_name { "白石市" }
      short_yomi { "しろいしし" }
    end

    factory :jmaxml_forecast_region_c0420700 do
      code { "0420700" }
      name { "宮城県名取市" }
      yomi { "みやぎけんなとりし" }
      short_name { "名取市" }
      short_yomi { "なとりし" }
    end

    factory :jmaxml_forecast_region_c0420800 do
      code { "0420800" }
      name { "宮城県角田市" }
      yomi { "みやぎけんかくだし" }
      short_name { "角田市" }
      short_yomi { "かくだし" }
    end

    factory :jmaxml_forecast_region_c0420900 do
      code { "0420900" }
      name { "宮城県多賀城市" }
      yomi { "みやぎけんたがじょうし" }
      short_name { "多賀城市" }
      short_yomi { "たがじょうし" }
    end

    factory :jmaxml_forecast_region_c0421100 do
      code { "0421100" }
      name { "宮城県岩沼市" }
      yomi { "みやぎけんいわぬまし" }
      short_name { "岩沼市" }
      short_yomi { "いわぬまし" }
    end

    factory :jmaxml_forecast_region_c0421200 do
      code { "0421200" }
      name { "宮城県登米市" }
      yomi { "みやぎけんとめし" }
      short_name { "登米市" }
      short_yomi { "とめし" }
    end

    factory :jmaxml_forecast_region_c0421300 do
      code { "0421300" }
      name { "宮城県栗原市" }
      yomi { "みやぎけんくりはらし" }
      short_name { "栗原市" }
      short_yomi { "くりはらし" }
    end

    factory :jmaxml_forecast_region_c0421400 do
      code { "0421400" }
      name { "宮城県東松島市" }
      yomi { "みやぎけんひがしまつしまし" }
      short_name { "東松島市" }
      short_yomi { "ひがしまつしまし" }
    end

    factory :jmaxml_forecast_region_c0421500 do
      code { "0421500" }
      name { "宮城県大崎市" }
      yomi { "みやぎけんおおさきし" }
      short_name { "大崎市" }
      short_yomi { "おおさきし" }
    end

    factory :jmaxml_forecast_region_c0430100 do
      code { "0430100" }
      name { "宮城県蔵王町" }
      yomi { "みやぎけんざおうまち" }
      short_name { "蔵王町" }
      short_yomi { "ざおうまち" }
    end

    factory :jmaxml_forecast_region_c0430200 do
      code { "0430200" }
      name { "宮城県七ヶ宿町" }
      yomi { "みやぎけんしちかしゅくまち" }
      short_name { "七ヶ宿町" }
      short_yomi { "しちかしゅくまち" }
    end

    factory :jmaxml_forecast_region_c0432100 do
      code { "0432100" }
      name { "宮城県大河原町" }
      yomi { "みやぎけんおおがわらまち" }
      short_name { "大河原町" }
      short_yomi { "おおがわらまち" }
    end

    factory :jmaxml_forecast_region_c0432200 do
      code { "0432200" }
      name { "宮城県村田町" }
      yomi { "みやぎけんむらたまち" }
      short_name { "村田町" }
      short_yomi { "むらたまち" }
    end

    factory :jmaxml_forecast_region_c0432300 do
      code { "0432300" }
      name { "宮城県柴田町" }
      yomi { "みやぎけんしばたまち" }
      short_name { "柴田町" }
      short_yomi { "しばたまち" }
    end

    factory :jmaxml_forecast_region_c0432400 do
      code { "0432400" }
      name { "宮城県川崎町" }
      yomi { "みやぎけんかわさきまち" }
      short_name { "川崎町" }
      short_yomi { "かわさきまち" }
    end

    factory :jmaxml_forecast_region_c0434100 do
      code { "0434100" }
      name { "宮城県丸森町" }
      yomi { "みやぎけんまるもりまち" }
      short_name { "丸森町" }
      short_yomi { "まるもりまち" }
    end

    factory :jmaxml_forecast_region_c0436100 do
      code { "0436100" }
      name { "宮城県亘理町" }
      yomi { "みやぎけんわたりちょう" }
      short_name { "亘理町" }
      short_yomi { "わたりちょう" }
    end

    factory :jmaxml_forecast_region_c0436200 do
      code { "0436200" }
      name { "宮城県山元町" }
      yomi { "みやぎけんやまもとちょう" }
      short_name { "山元町" }
      short_yomi { "やまもとちょう" }
    end

    factory :jmaxml_forecast_region_c0440100 do
      code { "0440100" }
      name { "宮城県松島町" }
      yomi { "みやぎけんまつしままち" }
      short_name { "松島町" }
      short_yomi { "まつしままち" }
    end

    factory :jmaxml_forecast_region_c0440400 do
      code { "0440400" }
      name { "宮城県七ヶ浜町" }
      yomi { "みやぎけんしちがはままち" }
      short_name { "七ヶ浜町" }
      short_yomi { "しちがはままち" }
    end

    factory :jmaxml_forecast_region_c0440600 do
      code { "0440600" }
      name { "宮城県利府町" }
      yomi { "みやぎけんりふちょう" }
      short_name { "利府町" }
      short_yomi { "りふちょう" }
    end

    factory :jmaxml_forecast_region_c0442100 do
      code { "0442100" }
      name { "宮城県大和町" }
      yomi { "みやぎけんたいわちょう" }
      short_name { "大和町" }
      short_yomi { "たいわちょう" }
    end

    factory :jmaxml_forecast_region_c0442200 do
      code { "0442200" }
      name { "宮城県大郷町" }
      yomi { "みやぎけんおおさとちょう" }
      short_name { "大郷町" }
      short_yomi { "おおさとちょう" }
    end

    factory :jmaxml_forecast_region_c0442300 do
      code { "0442300" }
      name { "宮城県富谷町" }
      yomi { "みやぎけんとみやまち" }
      short_name { "富谷町" }
      short_yomi { "とみやまち" }
    end

    factory :jmaxml_forecast_region_c0442400 do
      code { "0442400" }
      name { "宮城県大衡村" }
      yomi { "みやぎけんおおひらむら" }
      short_name { "大衡村" }
      short_yomi { "おおひらむら" }
    end

    factory :jmaxml_forecast_region_c0444400 do
      code { "0444400" }
      name { "宮城県色麻町" }
      yomi { "みやぎけんしかまちょう" }
      short_name { "色麻町" }
      short_yomi { "しかまちょう" }
    end

    factory :jmaxml_forecast_region_c0444500 do
      code { "0444500" }
      name { "宮城県加美町" }
      yomi { "みやぎけんかみまち" }
      short_name { "加美町" }
      short_yomi { "かみまち" }
    end

    factory :jmaxml_forecast_region_c0450100 do
      code { "0450100" }
      name { "宮城県涌谷町" }
      yomi { "みやぎけんわくやちょう" }
      short_name { "涌谷町" }
      short_yomi { "わくやちょう" }
    end

    factory :jmaxml_forecast_region_c0450500 do
      code { "0450500" }
      name { "宮城県美里町" }
      yomi { "みやぎけんみさとまち" }
      short_name { "美里町" }
      short_yomi { "みさとまち" }
    end

    factory :jmaxml_forecast_region_c0458100 do
      code { "0458100" }
      name { "宮城県女川町" }
      yomi { "みやぎけんおながわちょう" }
      short_name { "女川町" }
      short_yomi { "おながわちょう" }
    end

    factory :jmaxml_forecast_region_c0460600 do
      code { "0460600" }
      name { "宮城県南三陸町" }
      yomi { "みやぎけんみなみさんりくちょう" }
      short_name { "南三陸町" }
      short_yomi { "みなみさんりくちょう" }
    end

    factory :jmaxml_forecast_region_c0520100 do
      code { "0520100" }
      name { "秋田県秋田市" }
      yomi { "あきたけんあきたし" }
      short_name { "秋田市" }
      short_yomi { "あきたし" }
    end

    factory :jmaxml_forecast_region_c0520200 do
      code { "0520200" }
      name { "秋田県能代市" }
      yomi { "あきたけんのしろし" }
      short_name { "能代市" }
      short_yomi { "のしろし" }
    end

    factory :jmaxml_forecast_region_c0520300 do
      code { "0520300" }
      name { "秋田県横手市" }
      yomi { "あきたけんよこてし" }
      short_name { "横手市" }
      short_yomi { "よこてし" }
    end

    factory :jmaxml_forecast_region_c0520400 do
      code { "0520400" }
      name { "秋田県大館市" }
      yomi { "あきたけんおおだてし" }
      short_name { "大館市" }
      short_yomi { "おおだてし" }
    end

    factory :jmaxml_forecast_region_c0520600 do
      code { "0520600" }
      name { "秋田県男鹿市" }
      yomi { "あきたけんおがし" }
      short_name { "男鹿市" }
      short_yomi { "おがし" }
    end

    factory :jmaxml_forecast_region_c0520700 do
      code { "0520700" }
      name { "秋田県湯沢市" }
      yomi { "あきたけんゆざわし" }
      short_name { "湯沢市" }
      short_yomi { "ゆざわし" }
    end

    factory :jmaxml_forecast_region_c0520900 do
      code { "0520900" }
      name { "秋田県鹿角市" }
      yomi { "あきたけんかづのし" }
      short_name { "鹿角市" }
      short_yomi { "かづのし" }
    end

    factory :jmaxml_forecast_region_c0521000 do
      code { "0521000" }
      name { "秋田県由利本荘市" }
      yomi { "あきたけんゆりほんじょうし" }
      short_name { "由利本荘市" }
      short_yomi { "ゆりほんじょうし" }
    end

    factory :jmaxml_forecast_region_c0521100 do
      code { "0521100" }
      name { "秋田県潟上市" }
      yomi { "あきたけんかたがみし" }
      short_name { "潟上市" }
      short_yomi { "かたがみし" }
    end

    factory :jmaxml_forecast_region_c0521200 do
      code { "0521200" }
      name { "秋田県大仙市" }
      yomi { "あきたけんだいせんし" }
      short_name { "大仙市" }
      short_yomi { "だいせんし" }
    end

    factory :jmaxml_forecast_region_c0521300 do
      code { "0521300" }
      name { "秋田県北秋田市" }
      yomi { "あきたけんきたあきたし" }
      short_name { "北秋田市" }
      short_yomi { "きたあきたし" }
    end

    factory :jmaxml_forecast_region_c0521400 do
      code { "0521400" }
      name { "秋田県にかほ市" }
      yomi { "あきたけんにかほし" }
      short_name { "にかほ市" }
      short_yomi { "にかほし" }
    end

    factory :jmaxml_forecast_region_c0521500 do
      code { "0521500" }
      name { "秋田県仙北市" }
      yomi { "あきたけんせんぼくし" }
      short_name { "仙北市" }
      short_yomi { "せんぼくし" }
    end

    factory :jmaxml_forecast_region_c0530300 do
      code { "0530300" }
      name { "秋田県小坂町" }
      yomi { "あきたけんこさかまち" }
      short_name { "小坂町" }
      short_yomi { "こさかまち" }
    end

    factory :jmaxml_forecast_region_c0532700 do
      code { "0532700" }
      name { "秋田県上小阿仁村" }
      yomi { "あきたけんかみこあにむら" }
      short_name { "上小阿仁村" }
      short_yomi { "かみこあにむら" }
    end

    factory :jmaxml_forecast_region_c0534600 do
      code { "0534600" }
      name { "秋田県藤里町" }
      yomi { "あきたけんふじさとまち" }
      short_name { "藤里町" }
      short_yomi { "ふじさとまち" }
    end

    factory :jmaxml_forecast_region_c0534800 do
      code { "0534800" }
      name { "秋田県三種町" }
      yomi { "あきたけんみたねちょう" }
      short_name { "三種町" }
      short_yomi { "みたねちょう" }
    end

    factory :jmaxml_forecast_region_c0534900 do
      code { "0534900" }
      name { "秋田県八峰町" }
      yomi { "あきたけんはっぽうちょう" }
      short_name { "八峰町" }
      short_yomi { "はっぽうちょう" }
    end

    factory :jmaxml_forecast_region_c0536100 do
      code { "0536100" }
      name { "秋田県五城目町" }
      yomi { "あきたけんごじょうめまち" }
      short_name { "五城目町" }
      short_yomi { "ごじょうめまち" }
    end

    factory :jmaxml_forecast_region_c0536300 do
      code { "0536300" }
      name { "秋田県八郎潟町" }
      yomi { "あきたけんはちろうがたまち" }
      short_name { "八郎潟町" }
      short_yomi { "はちろうがたまち" }
    end

    factory :jmaxml_forecast_region_c0536600 do
      code { "0536600" }
      name { "秋田県井川町" }
      yomi { "あきたけんいかわまち" }
      short_name { "井川町" }
      short_yomi { "いかわまち" }
    end

    factory :jmaxml_forecast_region_c0536800 do
      code { "0536800" }
      name { "秋田県大潟村" }
      yomi { "あきたけんおおがたむら" }
      short_name { "大潟村" }
      short_yomi { "おおがたむら" }
    end

    factory :jmaxml_forecast_region_c0543400 do
      code { "0543400" }
      name { "秋田県美郷町" }
      yomi { "あきたけんみさとちょう" }
      short_name { "美郷町" }
      short_yomi { "みさとちょう" }
    end

    factory :jmaxml_forecast_region_c0546300 do
      code { "0546300" }
      name { "秋田県羽後町" }
      yomi { "あきたけんうごまち" }
      short_name { "羽後町" }
      short_yomi { "うごまち" }
    end

    factory :jmaxml_forecast_region_c0546400 do
      code { "0546400" }
      name { "秋田県東成瀬村" }
      yomi { "あきたけんひがしなるせむら" }
      short_name { "東成瀬村" }
      short_yomi { "ひがしなるせむら" }
    end

    factory :jmaxml_forecast_region_c0620100 do
      code { "0620100" }
      name { "山形県山形市" }
      yomi { "やまがたけんやまがたし" }
      short_name { "山形市" }
      short_yomi { "やまがたし" }
    end

    factory :jmaxml_forecast_region_c0620200 do
      code { "0620200" }
      name { "山形県米沢市" }
      yomi { "やまがたけんよねざわし" }
      short_name { "米沢市" }
      short_yomi { "よねざわし" }
    end

    factory :jmaxml_forecast_region_c0620300 do
      code { "0620300" }
      name { "山形県鶴岡市" }
      yomi { "やまがたけんつるおかし" }
      short_name { "鶴岡市" }
      short_yomi { "つるおかし" }
    end

    factory :jmaxml_forecast_region_c0620400 do
      code { "0620400" }
      name { "山形県酒田市" }
      yomi { "やまがたけんさかたし" }
      short_name { "酒田市" }
      short_yomi { "さかたし" }
    end

    factory :jmaxml_forecast_region_c0620500 do
      code { "0620500" }
      name { "山形県新庄市" }
      yomi { "やまがたけんしんじょうし" }
      short_name { "新庄市" }
      short_yomi { "しんじょうし" }
    end

    factory :jmaxml_forecast_region_c0620600 do
      code { "0620600" }
      name { "山形県寒河江市" }
      yomi { "やまがたけんさがえし" }
      short_name { "寒河江市" }
      short_yomi { "さがえし" }
    end

    factory :jmaxml_forecast_region_c0620700 do
      code { "0620700" }
      name { "山形県上山市" }
      yomi { "やまがたけんかみのやまし" }
      short_name { "上山市" }
      short_yomi { "かみのやまし" }
    end

    factory :jmaxml_forecast_region_c0620800 do
      code { "0620800" }
      name { "山形県村山市" }
      yomi { "やまがたけんむらやまし" }
      short_name { "村山市" }
      short_yomi { "むらやまし" }
    end

    factory :jmaxml_forecast_region_c0620900 do
      code { "0620900" }
      name { "山形県長井市" }
      yomi { "やまがたけんながいし" }
      short_name { "長井市" }
      short_yomi { "ながいし" }
    end

    factory :jmaxml_forecast_region_c0621000 do
      code { "0621000" }
      name { "山形県天童市" }
      yomi { "やまがたけんてんどうし" }
      short_name { "天童市" }
      short_yomi { "てんどうし" }
    end

    factory :jmaxml_forecast_region_c0621100 do
      code { "0621100" }
      name { "山形県東根市" }
      yomi { "やまがたけんひがしねし" }
      short_name { "東根市" }
      short_yomi { "ひがしねし" }
    end

    factory :jmaxml_forecast_region_c0621200 do
      code { "0621200" }
      name { "山形県尾花沢市" }
      yomi { "やまがたけんおばなざわし" }
      short_name { "尾花沢市" }
      short_yomi { "おばなざわし" }
    end

    factory :jmaxml_forecast_region_c0621300 do
      code { "0621300" }
      name { "山形県南陽市" }
      yomi { "やまがたけんなんようし" }
      short_name { "南陽市" }
      short_yomi { "なんようし" }
    end

    factory :jmaxml_forecast_region_c0630100 do
      code { "0630100" }
      name { "山形県山辺町" }
      yomi { "やまがたけんやまのべまち" }
      short_name { "山辺町" }
      short_yomi { "やまのべまち" }
    end

    factory :jmaxml_forecast_region_c0630200 do
      code { "0630200" }
      name { "山形県中山町" }
      yomi { "やまがたけんなかやままち" }
      short_name { "中山町" }
      short_yomi { "なかやままち" }
    end

    factory :jmaxml_forecast_region_c0632100 do
      code { "0632100" }
      name { "山形県河北町" }
      yomi { "やまがたけんかほくちょう" }
      short_name { "河北町" }
      short_yomi { "かほくちょう" }
    end

    factory :jmaxml_forecast_region_c0632200 do
      code { "0632200" }
      name { "山形県西川町" }
      yomi { "やまがたけんにしかわまち" }
      short_name { "西川町" }
      short_yomi { "にしかわまち" }
    end

    factory :jmaxml_forecast_region_c0632300 do
      code { "0632300" }
      name { "山形県朝日町" }
      yomi { "やまがたけんあさひまち" }
      short_name { "朝日町" }
      short_yomi { "あさひまち" }
    end

    factory :jmaxml_forecast_region_c0632400 do
      code { "0632400" }
      name { "山形県大江町" }
      yomi { "やまがたけんおおえまち" }
      short_name { "大江町" }
      short_yomi { "おおえまち" }
    end

    factory :jmaxml_forecast_region_c0634100 do
      code { "0634100" }
      name { "山形県大石田町" }
      yomi { "やまがたけんおおいしだまち" }
      short_name { "大石田町" }
      short_yomi { "おおいしだまち" }
    end

    factory :jmaxml_forecast_region_c0636100 do
      code { "0636100" }
      name { "山形県金山町" }
      yomi { "やまがたけんかねやままち" }
      short_name { "金山町" }
      short_yomi { "かねやままち" }
    end

    factory :jmaxml_forecast_region_c0636200 do
      code { "0636200" }
      name { "山形県最上町" }
      yomi { "やまがたけんもがみまち" }
      short_name { "最上町" }
      short_yomi { "もがみまち" }
    end

    factory :jmaxml_forecast_region_c0636300 do
      code { "0636300" }
      name { "山形県舟形町" }
      yomi { "やまがたけんふながたまち" }
      short_name { "舟形町" }
      short_yomi { "ふながたまち" }
    end

    factory :jmaxml_forecast_region_c0636400 do
      code { "0636400" }
      name { "山形県真室川町" }
      yomi { "やまがたけんまむろがわまち" }
      short_name { "真室川町" }
      short_yomi { "まむろがわまち" }
    end

    factory :jmaxml_forecast_region_c0636500 do
      code { "0636500" }
      name { "山形県大蔵村" }
      yomi { "やまがたけんおおくらむら" }
      short_name { "大蔵村" }
      short_yomi { "おおくらむら" }
    end

    factory :jmaxml_forecast_region_c0636600 do
      code { "0636600" }
      name { "山形県鮭川村" }
      yomi { "やまがたけんさけがわむら" }
      short_name { "鮭川村" }
      short_yomi { "さけがわむら" }
    end

    factory :jmaxml_forecast_region_c0636700 do
      code { "0636700" }
      name { "山形県戸沢村" }
      yomi { "やまがたけんとざわむら" }
      short_name { "戸沢村" }
      short_yomi { "とざわむら" }
    end

    factory :jmaxml_forecast_region_c0638100 do
      code { "0638100" }
      name { "山形県高畠町" }
      yomi { "やまがたけんたかはたまち" }
      short_name { "高畠町" }
      short_yomi { "たかはたまち" }
    end

    factory :jmaxml_forecast_region_c0638200 do
      code { "0638200" }
      name { "山形県川西町" }
      yomi { "やまがたけんかわにしまち" }
      short_name { "川西町" }
      short_yomi { "かわにしまち" }
    end

    factory :jmaxml_forecast_region_c0640100 do
      code { "0640100" }
      name { "山形県小国町" }
      yomi { "やまがたけんおぐにまち" }
      short_name { "小国町" }
      short_yomi { "おぐにまち" }
    end

    factory :jmaxml_forecast_region_c0640200 do
      code { "0640200" }
      name { "山形県白鷹町" }
      yomi { "やまがたけんしらたかまち" }
      short_name { "白鷹町" }
      short_yomi { "しらたかまち" }
    end

    factory :jmaxml_forecast_region_c0640300 do
      code { "0640300" }
      name { "山形県飯豊町" }
      yomi { "やまがたけんいいでまち" }
      short_name { "飯豊町" }
      short_yomi { "いいでまち" }
    end

    factory :jmaxml_forecast_region_c0642600 do
      code { "0642600" }
      name { "山形県三川町" }
      yomi { "やまがたけんみかわまち" }
      short_name { "三川町" }
      short_yomi { "みかわまち" }
    end

    factory :jmaxml_forecast_region_c0642800 do
      code { "0642800" }
      name { "山形県庄内町" }
      yomi { "やまがたけんしょうないまち" }
      short_name { "庄内町" }
      short_yomi { "しょうないまち" }
    end

    factory :jmaxml_forecast_region_c0646100 do
      code { "0646100" }
      name { "山形県遊佐町" }
      yomi { "やまがたけんゆざまち" }
      short_name { "遊佐町" }
      short_yomi { "ゆざまち" }
    end

    factory :jmaxml_forecast_region_c0720100 do
      code { "0720100" }
      name { "福島県福島市" }
      yomi { "ふくしまけんふくしまし" }
      short_name { "福島市" }
      short_yomi { "ふくしまし" }
    end

    factory :jmaxml_forecast_region_c0720200 do
      code { "0720200" }
      name { "福島県会津若松市" }
      yomi { "ふくしまけんあいづわかまつし" }
      short_name { "会津若松市" }
      short_yomi { "あいづわかまつし" }
    end

    factory :jmaxml_forecast_region_c0720300 do
      code { "0720300" }
      name { "福島県郡山市" }
      yomi { "ふくしまけんこおりやまし" }
      short_name { "郡山市" }
      short_yomi { "こおりやまし" }
    end

    factory :jmaxml_forecast_region_c0720400 do
      code { "0720400" }
      name { "福島県いわき市" }
      yomi { "ふくしまけんいわきし" }
      short_name { "いわき市" }
      short_yomi { "いわきし" }
    end

    factory :jmaxml_forecast_region_c0720500 do
      code { "0720500" }
      name { "福島県白河市" }
      yomi { "ふくしまけんしらかわし" }
      short_name { "白河市" }
      short_yomi { "しらかわし" }
    end

    factory :jmaxml_forecast_region_c0720700 do
      code { "0720700" }
      name { "福島県須賀川市" }
      yomi { "ふくしまけんすかがわし" }
      short_name { "須賀川市" }
      short_yomi { "すかがわし" }
    end

    factory :jmaxml_forecast_region_c0720800 do
      code { "0720800" }
      name { "福島県喜多方市" }
      yomi { "ふくしまけんきたかたし" }
      short_name { "喜多方市" }
      short_yomi { "きたかたし" }
    end

    factory :jmaxml_forecast_region_c0720900 do
      code { "0720900" }
      name { "福島県相馬市" }
      yomi { "ふくしまけんそうまし" }
      short_name { "相馬市" }
      short_yomi { "そうまし" }
    end

    factory :jmaxml_forecast_region_c0721000 do
      code { "0721000" }
      name { "福島県二本松市" }
      yomi { "ふくしまけんにほんまつし" }
      short_name { "二本松市" }
      short_yomi { "にほんまつし" }
    end

    factory :jmaxml_forecast_region_c0721100 do
      code { "0721100" }
      name { "福島県田村市" }
      yomi { "ふくしまけんたむらし" }
      short_name { "田村市" }
      short_yomi { "たむらし" }
    end

    factory :jmaxml_forecast_region_c0721200 do
      code { "0721200" }
      name { "福島県南相馬市" }
      yomi { "ふくしまけんみなみそうまし" }
      short_name { "南相馬市" }
      short_yomi { "みなみそうまし" }
    end

    factory :jmaxml_forecast_region_c0721300 do
      code { "0721300" }
      name { "福島県伊達市" }
      yomi { "ふくしまけんだてし" }
      short_name { "伊達市" }
      short_yomi { "だてし" }
    end

    factory :jmaxml_forecast_region_c0721400 do
      code { "0721400" }
      name { "福島県本宮市" }
      yomi { "ふくしまけんもとみやし" }
      short_name { "本宮市" }
      short_yomi { "もとみやし" }
    end

    factory :jmaxml_forecast_region_c0730100 do
      code { "0730100" }
      name { "福島県桑折町" }
      yomi { "ふくしまけんこおりまち" }
      short_name { "桑折町" }
      short_yomi { "こおりまち" }
    end

    factory :jmaxml_forecast_region_c0730300 do
      code { "0730300" }
      name { "福島県国見町" }
      yomi { "ふくしまけんくにみまち" }
      short_name { "国見町" }
      short_yomi { "くにみまち" }
    end

    factory :jmaxml_forecast_region_c0730800 do
      code { "0730800" }
      name { "福島県川俣町" }
      yomi { "ふくしまけんかわまたまち" }
      short_name { "川俣町" }
      short_yomi { "かわまたまち" }
    end

    factory :jmaxml_forecast_region_c0732200 do
      code { "0732200" }
      name { "福島県大玉村" }
      yomi { "ふくしまけんおおたまむら" }
      short_name { "大玉村" }
      short_yomi { "おおたまむら" }
    end

    factory :jmaxml_forecast_region_c0734200 do
      code { "0734200" }
      name { "福島県鏡石町" }
      yomi { "ふくしまけんかがみいしまち" }
      short_name { "鏡石町" }
      short_yomi { "かがみいしまち" }
    end

    factory :jmaxml_forecast_region_c0734400 do
      code { "0734400" }
      name { "福島県天栄村" }
      yomi { "ふくしまけんてんえいむら" }
      short_name { "天栄村" }
      short_yomi { "てんえいむら" }
    end

    factory :jmaxml_forecast_region_c0736200 do
      code { "0736200" }
      name { "福島県下郷町" }
      yomi { "ふくしまけんしもごうまち" }
      short_name { "下郷町" }
      short_yomi { "しもごうまち" }
    end

    factory :jmaxml_forecast_region_c0736400 do
      code { "0736400" }
      name { "福島県檜枝岐村" }
      yomi { "ふくしまけんひのえまたむら" }
      short_name { "檜枝岐村" }
      short_yomi { "ひのえまたむら" }
    end

    factory :jmaxml_forecast_region_c0736700 do
      code { "0736700" }
      name { "福島県只見町" }
      yomi { "ふくしまけんただみまち" }
      short_name { "只見町" }
      short_yomi { "ただみまち" }
    end

    factory :jmaxml_forecast_region_c0736800 do
      code { "0736800" }
      name { "福島県南会津町" }
      yomi { "ふくしまけんみなみあいづまち" }
      short_name { "南会津町" }
      short_yomi { "みなみあいづまち" }
    end

    factory :jmaxml_forecast_region_c0740200 do
      code { "0740200" }
      name { "福島県北塩原村" }
      yomi { "ふくしまけんきたしおばらむら" }
      short_name { "北塩原村" }
      short_yomi { "きたしおばらむら" }
    end

    factory :jmaxml_forecast_region_c0740500 do
      code { "0740500" }
      name { "福島県西会津町" }
      yomi { "ふくしまけんにしあいづまち" }
      short_name { "西会津町" }
      short_yomi { "にしあいづまち" }
    end

    factory :jmaxml_forecast_region_c0740700 do
      code { "0740700" }
      name { "福島県磐梯町" }
      yomi { "ふくしまけんばんだいまち" }
      short_name { "磐梯町" }
      short_yomi { "ばんだいまち" }
    end

    factory :jmaxml_forecast_region_c0740800 do
      code { "0740800" }
      name { "福島県猪苗代町" }
      yomi { "ふくしまけんいなわしろまち" }
      short_name { "猪苗代町" }
      short_yomi { "いなわしろまち" }
    end

    factory :jmaxml_forecast_region_c0742100 do
      code { "0742100" }
      name { "福島県会津坂下町" }
      yomi { "ふくしまけんあいづばんげまち" }
      short_name { "会津坂下町" }
      short_yomi { "あいづばんげまち" }
    end

    factory :jmaxml_forecast_region_c0742200 do
      code { "0742200" }
      name { "福島県湯川村" }
      yomi { "ふくしまけんゆがわむら" }
      short_name { "湯川村" }
      short_yomi { "ゆがわむら" }
    end

    factory :jmaxml_forecast_region_c0742300 do
      code { "0742300" }
      name { "福島県柳津町" }
      yomi { "ふくしまけんやないづまち" }
      short_name { "柳津町" }
      short_yomi { "やないづまち" }
    end

    factory :jmaxml_forecast_region_c0744400 do
      code { "0744400" }
      name { "福島県三島町" }
      yomi { "ふくしまけんみしままち" }
      short_name { "三島町" }
      short_yomi { "みしままち" }
    end

    factory :jmaxml_forecast_region_c0744500 do
      code { "0744500" }
      name { "福島県金山町" }
      yomi { "ふくしまけんかねやままち" }
      short_name { "金山町" }
      short_yomi { "かねやままち" }
    end

    factory :jmaxml_forecast_region_c0744600 do
      code { "0744600" }
      name { "福島県昭和村" }
      yomi { "ふくしまけんしょうわむら" }
      short_name { "昭和村" }
      short_yomi { "しょうわむら" }
    end

    factory :jmaxml_forecast_region_c0744700 do
      code { "0744700" }
      name { "福島県会津美里町" }
      yomi { "ふくしまけんあいづみさとまち" }
      short_name { "会津美里町" }
      short_yomi { "あいづみさとまち" }
    end

    factory :jmaxml_forecast_region_c0746100 do
      code { "0746100" }
      name { "福島県西郷村" }
      yomi { "ふくしまけんにしごうむら" }
      short_name { "西郷村" }
      short_yomi { "にしごうむら" }
    end

    factory :jmaxml_forecast_region_c0746400 do
      code { "0746400" }
      name { "福島県泉崎村" }
      yomi { "ふくしまけんいずみざきむら" }
      short_name { "泉崎村" }
      short_yomi { "いずみざきむら" }
    end

    factory :jmaxml_forecast_region_c0746500 do
      code { "0746500" }
      name { "福島県中島村" }
      yomi { "ふくしまけんなかじまむら" }
      short_name { "中島村" }
      short_yomi { "なかじまむら" }
    end

    factory :jmaxml_forecast_region_c0746600 do
      code { "0746600" }
      name { "福島県矢吹町" }
      yomi { "ふくしまけんやぶきまち" }
      short_name { "矢吹町" }
      short_yomi { "やぶきまち" }
    end

    factory :jmaxml_forecast_region_c0748100 do
      code { "0748100" }
      name { "福島県棚倉町" }
      yomi { "ふくしまけんたなぐらまち" }
      short_name { "棚倉町" }
      short_yomi { "たなぐらまち" }
    end

    factory :jmaxml_forecast_region_c0748200 do
      code { "0748200" }
      name { "福島県矢祭町" }
      yomi { "ふくしまけんやまつりまち" }
      short_name { "矢祭町" }
      short_yomi { "やまつりまち" }
    end

    factory :jmaxml_forecast_region_c0748300 do
      code { "0748300" }
      name { "福島県塙町" }
      yomi { "ふくしまけんはなわまち" }
      short_name { "塙町" }
      short_yomi { "はなわまち" }
    end

    factory :jmaxml_forecast_region_c0748400 do
      code { "0748400" }
      name { "福島県鮫川村" }
      yomi { "ふくしまけんさめがわむら" }
      short_name { "鮫川村" }
      short_yomi { "さめがわむら" }
    end

    factory :jmaxml_forecast_region_c0750100 do
      code { "0750100" }
      name { "福島県石川町" }
      yomi { "ふくしまけんいしかわまち" }
      short_name { "石川町" }
      short_yomi { "いしかわまち" }
    end

    factory :jmaxml_forecast_region_c0750200 do
      code { "0750200" }
      name { "福島県玉川村" }
      yomi { "ふくしまけんたまかわむら" }
      short_name { "玉川村" }
      short_yomi { "たまかわむら" }
    end

    factory :jmaxml_forecast_region_c0750300 do
      code { "0750300" }
      name { "福島県平田村" }
      yomi { "ふくしまけんひらたむら" }
      short_name { "平田村" }
      short_yomi { "ひらたむら" }
    end

    factory :jmaxml_forecast_region_c0750400 do
      code { "0750400" }
      name { "福島県浅川町" }
      yomi { "ふくしまけんあさかわまち" }
      short_name { "浅川町" }
      short_yomi { "あさかわまち" }
    end

    factory :jmaxml_forecast_region_c0750500 do
      code { "0750500" }
      name { "福島県古殿町" }
      yomi { "ふくしまけんふるどのまち" }
      short_name { "古殿町" }
      short_yomi { "ふるどのまち" }
    end

    factory :jmaxml_forecast_region_c0752100 do
      code { "0752100" }
      name { "福島県三春町" }
      yomi { "ふくしまけんみはるまち" }
      short_name { "三春町" }
      short_yomi { "みはるまち" }
    end

    factory :jmaxml_forecast_region_c0752200 do
      code { "0752200" }
      name { "福島県小野町" }
      yomi { "ふくしまけんおのまち" }
      short_name { "小野町" }
      short_yomi { "おのまち" }
    end

    factory :jmaxml_forecast_region_c0754100 do
      code { "0754100" }
      name { "福島県広野町" }
      yomi { "ふくしまけんひろのまち" }
      short_name { "広野町" }
      short_yomi { "ひろのまち" }
    end

    factory :jmaxml_forecast_region_c0754200 do
      code { "0754200" }
      name { "福島県楢葉町" }
      yomi { "ふくしまけんならはまち" }
      short_name { "楢葉町" }
      short_yomi { "ならはまち" }
    end

    factory :jmaxml_forecast_region_c0754300 do
      code { "0754300" }
      name { "福島県富岡町" }
      yomi { "ふくしまけんとみおかまち" }
      short_name { "富岡町" }
      short_yomi { "とみおかまち" }
    end

    factory :jmaxml_forecast_region_c0754400 do
      code { "0754400" }
      name { "福島県川内村" }
      yomi { "ふくしまけんかわうちむら" }
      short_name { "川内村" }
      short_yomi { "かわうちむら" }
    end

    factory :jmaxml_forecast_region_c0754500 do
      code { "0754500" }
      name { "福島県大熊町" }
      yomi { "ふくしまけんおおくままち" }
      short_name { "大熊町" }
      short_yomi { "おおくままち" }
    end

    factory :jmaxml_forecast_region_c0754600 do
      code { "0754600" }
      name { "福島県双葉町" }
      yomi { "ふくしまけんふたばまち" }
      short_name { "双葉町" }
      short_yomi { "ふたばまち" }
    end

    factory :jmaxml_forecast_region_c0754700 do
      code { "0754700" }
      name { "福島県浪江町" }
      yomi { "ふくしまけんなみえまち" }
      short_name { "浪江町" }
      short_yomi { "なみえまち" }
    end

    factory :jmaxml_forecast_region_c0754800 do
      code { "0754800" }
      name { "福島県葛尾村" }
      yomi { "ふくしまけんかつらおむら" }
      short_name { "葛尾村" }
      short_yomi { "かつらおむら" }
    end

    factory :jmaxml_forecast_region_c0756100 do
      code { "0756100" }
      name { "福島県新地町" }
      yomi { "ふくしまけんしんちまち" }
      short_name { "新地町" }
      short_yomi { "しんちまち" }
    end

    factory :jmaxml_forecast_region_c0756400 do
      code { "0756400" }
      name { "福島県飯舘村" }
      yomi { "ふくしまけんいいたてむら" }
      short_name { "飯舘村" }
      short_yomi { "いいたてむら" }
    end

    factory :jmaxml_forecast_region_c0820100 do
      code { "0820100" }
      name { "茨城県水戸市" }
      yomi { "いばらきけんみとし" }
      short_name { "水戸市" }
      short_yomi { "みとし" }
    end

    factory :jmaxml_forecast_region_c0820200 do
      code { "0820200" }
      name { "茨城県日立市" }
      yomi { "いばらきけんひたちし" }
      short_name { "日立市" }
      short_yomi { "ひたちし" }
    end

    factory :jmaxml_forecast_region_c0820300 do
      code { "0820300" }
      name { "茨城県土浦市" }
      yomi { "いばらきけんつちうらし" }
      short_name { "土浦市" }
      short_yomi { "つちうらし" }
    end

    factory :jmaxml_forecast_region_c0820400 do
      code { "0820400" }
      name { "茨城県古河市" }
      yomi { "いばらきけんこがし" }
      short_name { "古河市" }
      short_yomi { "こがし" }
    end

    factory :jmaxml_forecast_region_c0820500 do
      code { "0820500" }
      name { "茨城県石岡市" }
      yomi { "いばらきけんいしおかし" }
      short_name { "石岡市" }
      short_yomi { "いしおかし" }
    end

    factory :jmaxml_forecast_region_c0820700 do
      code { "0820700" }
      name { "茨城県結城市" }
      yomi { "いばらきけんゆうきし" }
      short_name { "結城市" }
      short_yomi { "ゆうきし" }
    end

    factory :jmaxml_forecast_region_c0820800 do
      code { "0820800" }
      name { "茨城県龍ケ崎市" }
      yomi { "いばらきけんりゅうがさきし" }
      short_name { "龍ケ崎市" }
      short_yomi { "りゅうがさきし" }
    end

    factory :jmaxml_forecast_region_c0821000 do
      code { "0821000" }
      name { "茨城県下妻市" }
      yomi { "いばらきけんしもつまし" }
      short_name { "下妻市" }
      short_yomi { "しもつまし" }
    end

    factory :jmaxml_forecast_region_c0821100 do
      code { "0821100" }
      name { "茨城県常総市" }
      yomi { "いばらきけんじょうそうし" }
      short_name { "常総市" }
      short_yomi { "じょうそうし" }
    end

    factory :jmaxml_forecast_region_c0821200 do
      code { "0821200" }
      name { "茨城県常陸太田市" }
      yomi { "いばらきけんひたちおおたし" }
      short_name { "常陸太田市" }
      short_yomi { "ひたちおおたし" }
    end

    factory :jmaxml_forecast_region_c0821400 do
      code { "0821400" }
      name { "茨城県高萩市" }
      yomi { "いばらきけんたかはぎし" }
      short_name { "高萩市" }
      short_yomi { "たかはぎし" }
    end

    factory :jmaxml_forecast_region_c0821500 do
      code { "0821500" }
      name { "茨城県北茨城市" }
      yomi { "いばらきけんきたいばらきし" }
      short_name { "北茨城市" }
      short_yomi { "きたいばらきし" }
    end

    factory :jmaxml_forecast_region_c0821600 do
      code { "0821600" }
      name { "茨城県笠間市" }
      yomi { "いばらきけんかさまし" }
      short_name { "笠間市" }
      short_yomi { "かさまし" }
    end

    factory :jmaxml_forecast_region_c0821700 do
      code { "0821700" }
      name { "茨城県取手市" }
      yomi { "いばらきけんとりでし" }
      short_name { "取手市" }
      short_yomi { "とりでし" }
    end

    factory :jmaxml_forecast_region_c0821900 do
      code { "0821900" }
      name { "茨城県牛久市" }
      yomi { "いばらきけんうしくし" }
      short_name { "牛久市" }
      short_yomi { "うしくし" }
    end

    factory :jmaxml_forecast_region_c0822000 do
      code { "0822000" }
      name { "茨城県つくば市" }
      yomi { "いばらきけんつくばし" }
      short_name { "つくば市" }
      short_yomi { "つくばし" }
    end

    factory :jmaxml_forecast_region_c0822100 do
      code { "0822100" }
      name { "茨城県ひたちなか市" }
      yomi { "いばらきけんひたちなかし" }
      short_name { "ひたちなか市" }
      short_yomi { "ひたちなかし" }
    end

    factory :jmaxml_forecast_region_c0822200 do
      code { "0822200" }
      name { "茨城県鹿嶋市" }
      yomi { "いばらきけんかしまし" }
      short_name { "鹿嶋市" }
      short_yomi { "かしまし" }
    end

    factory :jmaxml_forecast_region_c0822300 do
      code { "0822300" }
      name { "茨城県潮来市" }
      yomi { "いばらきけんいたこし" }
      short_name { "潮来市" }
      short_yomi { "いたこし" }
    end

    factory :jmaxml_forecast_region_c0822400 do
      code { "0822400" }
      name { "茨城県守谷市" }
      yomi { "いばらきけんもりやし" }
      short_name { "守谷市" }
      short_yomi { "もりやし" }
    end

    factory :jmaxml_forecast_region_c0822500 do
      code { "0822500" }
      name { "茨城県常陸大宮市" }
      yomi { "いばらきけんひたちおおみやし" }
      short_name { "常陸大宮市" }
      short_yomi { "ひたちおおみやし" }
    end

    factory :jmaxml_forecast_region_c0822600 do
      code { "0822600" }
      name { "茨城県那珂市" }
      yomi { "いばらきけんなかし" }
      short_name { "那珂市" }
      short_yomi { "なかし" }
    end

    factory :jmaxml_forecast_region_c0822700 do
      code { "0822700" }
      name { "茨城県筑西市" }
      yomi { "いばらきけんちくせいし" }
      short_name { "筑西市" }
      short_yomi { "ちくせいし" }
    end

    factory :jmaxml_forecast_region_c0822800 do
      code { "0822800" }
      name { "茨城県坂東市" }
      yomi { "いばらきけんばんどうし" }
      short_name { "坂東市" }
      short_yomi { "ばんどうし" }
    end

    factory :jmaxml_forecast_region_c0822900 do
      code { "0822900" }
      name { "茨城県稲敷市" }
      yomi { "いばらきけんいなしきし" }
      short_name { "稲敷市" }
      short_yomi { "いなしきし" }
    end

    factory :jmaxml_forecast_region_c0823000 do
      code { "0823000" }
      name { "茨城県かすみがうら市" }
      yomi { "いばらきけんかすみがうらし" }
      short_name { "かすみがうら市" }
      short_yomi { "かすみがうらし" }
    end

    factory :jmaxml_forecast_region_c0823100 do
      code { "0823100" }
      name { "茨城県桜川市" }
      yomi { "いばらきけんさくらがわし" }
      short_name { "桜川市" }
      short_yomi { "さくらがわし" }
    end

    factory :jmaxml_forecast_region_c0823200 do
      code { "0823200" }
      name { "茨城県神栖市" }
      yomi { "いばらきけんかみすし" }
      short_name { "神栖市" }
      short_yomi { "かみすし" }
    end

    factory :jmaxml_forecast_region_c0823300 do
      code { "0823300" }
      name { "茨城県行方市" }
      yomi { "いばらきけんなめがたし" }
      short_name { "行方市" }
      short_yomi { "なめがたし" }
    end

    factory :jmaxml_forecast_region_c0823400 do
      code { "0823400" }
      name { "茨城県鉾田市" }
      yomi { "いばらきけんほこたし" }
      short_name { "鉾田市" }
      short_yomi { "ほこたし" }
    end

    factory :jmaxml_forecast_region_c0823500 do
      code { "0823500" }
      name { "茨城県つくばみらい市" }
      yomi { "いばらきけんつくばみらいし" }
      short_name { "つくばみらい市" }
      short_yomi { "つくばみらいし" }
    end

    factory :jmaxml_forecast_region_c0823600 do
      code { "0823600" }
      name { "茨城県小美玉市" }
      yomi { "いばらきけんおみたまし" }
      short_name { "小美玉市" }
      short_yomi { "おみたまし" }
    end

    factory :jmaxml_forecast_region_c0830200 do
      code { "0830200" }
      name { "茨城県茨城町" }
      yomi { "いばらきけんいばらきまち" }
      short_name { "茨城町" }
      short_yomi { "いばらきまち" }
    end

    factory :jmaxml_forecast_region_c0830900 do
      code { "0830900" }
      name { "茨城県大洗町" }
      yomi { "いばらきけんおおあらいまち" }
      short_name { "大洗町" }
      short_yomi { "おおあらいまち" }
    end

    factory :jmaxml_forecast_region_c0831000 do
      code { "0831000" }
      name { "茨城県城里町" }
      yomi { "いばらきけんしろさとまち" }
      short_name { "城里町" }
      short_yomi { "しろさとまち" }
    end

    factory :jmaxml_forecast_region_c0834100 do
      code { "0834100" }
      name { "茨城県東海村" }
      yomi { "いばらきけんとうかいむら" }
      short_name { "東海村" }
      short_yomi { "とうかいむら" }
    end

    factory :jmaxml_forecast_region_c0836400 do
      code { "0836400" }
      name { "茨城県大子町" }
      yomi { "いばらきけんだいごまち" }
      short_name { "大子町" }
      short_yomi { "だいごまち" }
    end

    factory :jmaxml_forecast_region_c0844200 do
      code { "0844200" }
      name { "茨城県美浦村" }
      yomi { "いばらきけんみほむら" }
      short_name { "美浦村" }
      short_yomi { "みほむら" }
    end

    factory :jmaxml_forecast_region_c0844300 do
      code { "0844300" }
      name { "茨城県阿見町" }
      yomi { "いばらきけんあみまち" }
      short_name { "阿見町" }
      short_yomi { "あみまち" }
    end

    factory :jmaxml_forecast_region_c0844700 do
      code { "0844700" }
      name { "茨城県河内町" }
      yomi { "いばらきけんかわちまち" }
      short_name { "河内町" }
      short_yomi { "かわちまち" }
    end

    factory :jmaxml_forecast_region_c0852100 do
      code { "0852100" }
      name { "茨城県八千代町" }
      yomi { "いばらきけんやちよまち" }
      short_name { "八千代町" }
      short_yomi { "やちよまち" }
    end

    factory :jmaxml_forecast_region_c0854200 do
      code { "0854200" }
      name { "茨城県五霞町" }
      yomi { "いばらきけんごかまち" }
      short_name { "五霞町" }
      short_yomi { "ごかまち" }
    end

    factory :jmaxml_forecast_region_c0854600 do
      code { "0854600" }
      name { "茨城県境町" }
      yomi { "いばらきけんさかいまち" }
      short_name { "境町" }
      short_yomi { "さかいまち" }
    end

    factory :jmaxml_forecast_region_c0856400 do
      code { "0856400" }
      name { "茨城県利根町" }
      yomi { "いばらきけんとねまち" }
      short_name { "利根町" }
      short_yomi { "とねまち" }
    end

    factory :jmaxml_forecast_region_c0920100 do
      code { "0920100" }
      name { "栃木県宇都宮市" }
      yomi { "とちぎけんうつのみやし" }
      short_name { "宇都宮市" }
      short_yomi { "うつのみやし" }
    end

    factory :jmaxml_forecast_region_c0920200 do
      code { "0920200" }
      name { "栃木県足利市" }
      yomi { "とちぎけんあしかがし" }
      short_name { "足利市" }
      short_yomi { "あしかがし" }
    end

    factory :jmaxml_forecast_region_c0920300 do
      code { "0920300" }
      name { "栃木県栃木市" }
      yomi { "とちぎけんとちぎし" }
      short_name { "栃木市" }
      short_yomi { "とちぎし" }
    end

    factory :jmaxml_forecast_region_c0920400 do
      code { "0920400" }
      name { "栃木県佐野市" }
      yomi { "とちぎけんさのし" }
      short_name { "佐野市" }
      short_yomi { "さのし" }
    end

    factory :jmaxml_forecast_region_c0920500 do
      code { "0920500" }
      name { "栃木県鹿沼市" }
      yomi { "とちぎけんかぬまし" }
      short_name { "鹿沼市" }
      short_yomi { "かぬまし" }
    end

    factory :jmaxml_forecast_region_c0920600 do
      code { "0920600" }
      name { "栃木県日光市" }
      yomi { "とちぎけんにっこうし" }
      short_name { "日光市" }
      short_yomi { "にっこうし" }
    end

    factory :jmaxml_forecast_region_c0920800 do
      code { "0920800" }
      name { "栃木県小山市" }
      yomi { "とちぎけんおやまし" }
      short_name { "小山市" }
      short_yomi { "おやまし" }
    end

    factory :jmaxml_forecast_region_c0920900 do
      code { "0920900" }
      name { "栃木県真岡市" }
      yomi { "とちぎけんもおかし" }
      short_name { "真岡市" }
      short_yomi { "もおかし" }
    end

    factory :jmaxml_forecast_region_c0921000 do
      code { "0921000" }
      name { "栃木県大田原市" }
      yomi { "とちぎけんおおたわらし" }
      short_name { "大田原市" }
      short_yomi { "おおたわらし" }
    end

    factory :jmaxml_forecast_region_c0921100 do
      code { "0921100" }
      name { "栃木県矢板市" }
      yomi { "とちぎけんやいたし" }
      short_name { "矢板市" }
      short_yomi { "やいたし" }
    end

    factory :jmaxml_forecast_region_c0921300 do
      code { "0921300" }
      name { "栃木県那須塩原市" }
      yomi { "とちぎけんなすしおばらし" }
      short_name { "那須塩原市" }
      short_yomi { "なすしおばらし" }
    end

    factory :jmaxml_forecast_region_c0921400 do
      code { "0921400" }
      name { "栃木県さくら市" }
      yomi { "とちぎけんさくらし" }
      short_name { "さくら市" }
      short_yomi { "さくらし" }
    end

    factory :jmaxml_forecast_region_c0921500 do
      code { "0921500" }
      name { "栃木県那須烏山市" }
      yomi { "とちぎけんなすからすやまし" }
      short_name { "那須烏山市" }
      short_yomi { "なすからすやまし" }
    end

    factory :jmaxml_forecast_region_c0921600 do
      code { "0921600" }
      name { "栃木県下野市" }
      yomi { "とちぎけんしもつけし" }
      short_name { "下野市" }
      short_yomi { "しもつけし" }
    end

    factory :jmaxml_forecast_region_c0930100 do
      code { "0930100" }
      name { "栃木県上三川町" }
      yomi { "とちぎけんかみのかわまち" }
      short_name { "上三川町" }
      short_yomi { "かみのかわまち" }
    end

    factory :jmaxml_forecast_region_c0934200 do
      code { "0934200" }
      name { "栃木県益子町" }
      yomi { "とちぎけんましこまち" }
      short_name { "益子町" }
      short_yomi { "ましこまち" }
    end

    factory :jmaxml_forecast_region_c0934300 do
      code { "0934300" }
      name { "栃木県茂木町" }
      yomi { "とちぎけんもてぎまち" }
      short_name { "茂木町" }
      short_yomi { "もてぎまち" }
    end

    factory :jmaxml_forecast_region_c0934400 do
      code { "0934400" }
      name { "栃木県市貝町" }
      yomi { "とちぎけんいちかいまち" }
      short_name { "市貝町" }
      short_yomi { "いちかいまち" }
    end

    factory :jmaxml_forecast_region_c0934500 do
      code { "0934500" }
      name { "栃木県芳賀町" }
      yomi { "とちぎけんはがまち" }
      short_name { "芳賀町" }
      short_yomi { "はがまち" }
    end

    factory :jmaxml_forecast_region_c0936100 do
      code { "0936100" }
      name { "栃木県壬生町" }
      yomi { "とちぎけんみぶまち" }
      short_name { "壬生町" }
      short_yomi { "みぶまち" }
    end

    factory :jmaxml_forecast_region_c0936400 do
      code { "0936400" }
      name { "栃木県野木町" }
      yomi { "とちぎけんのぎまち" }
      short_name { "野木町" }
      short_yomi { "のぎまち" }
    end

    factory :jmaxml_forecast_region_c0938400 do
      code { "0938400" }
      name { "栃木県塩谷町" }
      yomi { "とちぎけんしおやまち" }
      short_name { "塩谷町" }
      short_yomi { "しおやまち" }
    end

    factory :jmaxml_forecast_region_c0938600 do
      code { "0938600" }
      name { "栃木県高根沢町" }
      yomi { "とちぎけんたかねざわまち" }
      short_name { "高根沢町" }
      short_yomi { "たかねざわまち" }
    end

    factory :jmaxml_forecast_region_c0940700 do
      code { "0940700" }
      name { "栃木県那須町" }
      yomi { "とちぎけんなすまち" }
      short_name { "那須町" }
      short_yomi { "なすまち" }
    end

    factory :jmaxml_forecast_region_c0941100 do
      code { "0941100" }
      name { "栃木県那珂川町" }
      yomi { "とちぎけんなかがわまち" }
      short_name { "那珂川町" }
      short_yomi { "なかがわまち" }
    end

    factory :jmaxml_forecast_region_c1020100 do
      code { "1020100" }
      name { "群馬県前橋市" }
      yomi { "ぐんまけんまえばしし" }
      short_name { "前橋市" }
      short_yomi { "まえばしし" }
    end

    factory :jmaxml_forecast_region_c1020200 do
      code { "1020200" }
      name { "群馬県高崎市" }
      yomi { "ぐんまけんたかさきし" }
      short_name { "高崎市" }
      short_yomi { "たかさきし" }
    end

    factory :jmaxml_forecast_region_c1020300 do
      code { "1020300" }
      name { "群馬県桐生市" }
      yomi { "ぐんまけんきりゅうし" }
      short_name { "桐生市" }
      short_yomi { "きりゅうし" }
    end

    factory :jmaxml_forecast_region_c1020400 do
      code { "1020400" }
      name { "群馬県伊勢崎市" }
      yomi { "ぐんまけんいせさきし" }
      short_name { "伊勢崎市" }
      short_yomi { "いせさきし" }
    end

    factory :jmaxml_forecast_region_c1020500 do
      code { "1020500" }
      name { "群馬県太田市" }
      yomi { "ぐんまけんおおたし" }
      short_name { "太田市" }
      short_yomi { "おおたし" }
    end

    factory :jmaxml_forecast_region_c1020600 do
      code { "1020600" }
      name { "群馬県沼田市" }
      yomi { "ぐんまけんぬまたし" }
      short_name { "沼田市" }
      short_yomi { "ぬまたし" }
    end

    factory :jmaxml_forecast_region_c1020700 do
      code { "1020700" }
      name { "群馬県館林市" }
      yomi { "ぐんまけんたてばやしし" }
      short_name { "館林市" }
      short_yomi { "たてばやしし" }
    end

    factory :jmaxml_forecast_region_c1020800 do
      code { "1020800" }
      name { "群馬県渋川市" }
      yomi { "ぐんまけんしぶかわし" }
      short_name { "渋川市" }
      short_yomi { "しぶかわし" }
    end

    factory :jmaxml_forecast_region_c1020900 do
      code { "1020900" }
      name { "群馬県藤岡市" }
      yomi { "ぐんまけんふじおかし" }
      short_name { "藤岡市" }
      short_yomi { "ふじおかし" }
    end

    factory :jmaxml_forecast_region_c1021000 do
      code { "1021000" }
      name { "群馬県富岡市" }
      yomi { "ぐんまけんとみおかし" }
      short_name { "富岡市" }
      short_yomi { "とみおかし" }
    end

    factory :jmaxml_forecast_region_c1021100 do
      code { "1021100" }
      name { "群馬県安中市" }
      yomi { "ぐんまけんあんなかし" }
      short_name { "安中市" }
      short_yomi { "あんなかし" }
    end

    factory :jmaxml_forecast_region_c1021200 do
      code { "1021200" }
      name { "群馬県みどり市" }
      yomi { "ぐんまけんみどりし" }
      short_name { "みどり市" }
      short_yomi { "みどりし" }
    end

    factory :jmaxml_forecast_region_c1034400 do
      code { "1034400" }
      name { "群馬県榛東村" }
      yomi { "ぐんまけんしんとうむら" }
      short_name { "榛東村" }
      short_yomi { "しんとうむら" }
    end

    factory :jmaxml_forecast_region_c1034500 do
      code { "1034500" }
      name { "群馬県吉岡町" }
      yomi { "ぐんまけんよしおかまち" }
      short_name { "吉岡町" }
      short_yomi { "よしおかまち" }
    end

    factory :jmaxml_forecast_region_c1036600 do
      code { "1036600" }
      name { "群馬県上野村" }
      yomi { "ぐんまけんうえのむら" }
      short_name { "上野村" }
      short_yomi { "うえのむら" }
    end

    factory :jmaxml_forecast_region_c1036700 do
      code { "1036700" }
      name { "群馬県神流町" }
      yomi { "ぐんまけんかんなまち" }
      short_name { "神流町" }
      short_yomi { "かんなまち" }
    end

    factory :jmaxml_forecast_region_c1038200 do
      code { "1038200" }
      name { "群馬県下仁田町" }
      yomi { "ぐんまけんしもにたまち" }
      short_name { "下仁田町" }
      short_yomi { "しもにたまち" }
    end

    factory :jmaxml_forecast_region_c1038300 do
      code { "1038300" }
      name { "群馬県南牧村" }
      yomi { "ぐんまけんなんもくむら" }
      short_name { "南牧村" }
      short_yomi { "なんもくむら" }
    end

    factory :jmaxml_forecast_region_c1038400 do
      code { "1038400" }
      name { "群馬県甘楽町" }
      yomi { "ぐんまけんかんらまち" }
      short_name { "甘楽町" }
      short_yomi { "かんらまち" }
    end

    factory :jmaxml_forecast_region_c1042100 do
      code { "1042100" }
      name { "群馬県中之条町" }
      yomi { "ぐんまけんなかのじょうまち" }
      short_name { "中之条町" }
      short_yomi { "なかのじょうまち" }
    end

    factory :jmaxml_forecast_region_c1042400 do
      code { "1042400" }
      name { "群馬県長野原町" }
      yomi { "ぐんまけんながのはらまち" }
      short_name { "長野原町" }
      short_yomi { "ながのはらまち" }
    end

    factory :jmaxml_forecast_region_c1042500 do
      code { "1042500" }
      name { "群馬県嬬恋村" }
      yomi { "ぐんまけんつまごいむら" }
      short_name { "嬬恋村" }
      short_yomi { "つまごいむら" }
    end

    factory :jmaxml_forecast_region_c1042600 do
      code { "1042600" }
      name { "群馬県草津町" }
      yomi { "ぐんまけんくさつまち" }
      short_name { "草津町" }
      short_yomi { "くさつまち" }
    end

    factory :jmaxml_forecast_region_c1042800 do
      code { "1042800" }
      name { "群馬県高山村" }
      yomi { "ぐんまけんたかやまむら" }
      short_name { "高山村" }
      short_yomi { "たかやまむら" }
    end

    factory :jmaxml_forecast_region_c1042900 do
      code { "1042900" }
      name { "群馬県東吾妻町" }
      yomi { "ぐんまけんひがしあがつままち" }
      short_name { "東吾妻町" }
      short_yomi { "ひがしあがつままち" }
    end

    factory :jmaxml_forecast_region_c1044300 do
      code { "1044300" }
      name { "群馬県片品村" }
      yomi { "ぐんまけんかたしなむら" }
      short_name { "片品村" }
      short_yomi { "かたしなむら" }
    end

    factory :jmaxml_forecast_region_c1044400 do
      code { "1044400" }
      name { "群馬県川場村" }
      yomi { "ぐんまけんかわばむら" }
      short_name { "川場村" }
      short_yomi { "かわばむら" }
    end

    factory :jmaxml_forecast_region_c1044800 do
      code { "1044800" }
      name { "群馬県昭和村" }
      yomi { "ぐんまけんしょうわむら" }
      short_name { "昭和村" }
      short_yomi { "しょうわむら" }
    end

    factory :jmaxml_forecast_region_c1044900 do
      code { "1044900" }
      name { "群馬県みなかみ町" }
      yomi { "ぐんまけんみなかみまち" }
      short_name { "みなかみ町" }
      short_yomi { "みなかみまち" }
    end

    factory :jmaxml_forecast_region_c1046400 do
      code { "1046400" }
      name { "群馬県玉村町" }
      yomi { "ぐんまけんたまむらまち" }
      short_name { "玉村町" }
      short_yomi { "たまむらまち" }
    end

    factory :jmaxml_forecast_region_c1052100 do
      code { "1052100" }
      name { "群馬県板倉町" }
      yomi { "ぐんまけんいたくらまち" }
      short_name { "板倉町" }
      short_yomi { "いたくらまち" }
    end

    factory :jmaxml_forecast_region_c1052200 do
      code { "1052200" }
      name { "群馬県明和町" }
      yomi { "ぐんまけんめいわまち" }
      short_name { "明和町" }
      short_yomi { "めいわまち" }
    end

    factory :jmaxml_forecast_region_c1052300 do
      code { "1052300" }
      name { "群馬県千代田町" }
      yomi { "ぐんまけんちよだまち" }
      short_name { "千代田町" }
      short_yomi { "ちよだまち" }
    end

    factory :jmaxml_forecast_region_c1052400 do
      code { "1052400" }
      name { "群馬県大泉町" }
      yomi { "ぐんまけんおおいずみまち" }
      short_name { "大泉町" }
      short_yomi { "おおいずみまち" }
    end

    factory :jmaxml_forecast_region_c1052500 do
      code { "1052500" }
      name { "群馬県邑楽町" }
      yomi { "ぐんまけんおうらまち" }
      short_name { "邑楽町" }
      short_yomi { "おうらまち" }
    end

    factory :jmaxml_forecast_region_c1110000 do
      code { "1110000" }
      name { "埼玉県さいたま市" }
      yomi { "さいたまけんさいたまし" }
      short_name { "さいたま市" }
      short_yomi { "さいたまし" }
    end

    factory :jmaxml_forecast_region_c1120100 do
      code { "1120100" }
      name { "埼玉県川越市" }
      yomi { "さいたまけんかわごえし" }
      short_name { "川越市" }
      short_yomi { "かわごえし" }
    end

    factory :jmaxml_forecast_region_c1120200 do
      code { "1120200" }
      name { "埼玉県熊谷市" }
      yomi { "さいたまけんくまがやし" }
      short_name { "熊谷市" }
      short_yomi { "くまがやし" }
    end

    factory :jmaxml_forecast_region_c1120300 do
      code { "1120300" }
      name { "埼玉県川口市" }
      yomi { "さいたまけんかわぐちし" }
      short_name { "川口市" }
      short_yomi { "かわぐちし" }
    end

    factory :jmaxml_forecast_region_c1120600 do
      code { "1120600" }
      name { "埼玉県行田市" }
      yomi { "さいたまけんぎょうだし" }
      short_name { "行田市" }
      short_yomi { "ぎょうだし" }
    end

    factory :jmaxml_forecast_region_c1120700 do
      code { "1120700" }
      name { "埼玉県秩父市" }
      yomi { "さいたまけんちちぶし" }
      short_name { "秩父市" }
      short_yomi { "ちちぶし" }
    end

    factory :jmaxml_forecast_region_c1120800 do
      code { "1120800" }
      name { "埼玉県所沢市" }
      yomi { "さいたまけんところざわし" }
      short_name { "所沢市" }
      short_yomi { "ところざわし" }
    end

    factory :jmaxml_forecast_region_c1120900 do
      code { "1120900" }
      name { "埼玉県飯能市" }
      yomi { "さいたまけんはんのうし" }
      short_name { "飯能市" }
      short_yomi { "はんのうし" }
    end

    factory :jmaxml_forecast_region_c1121000 do
      code { "1121000" }
      name { "埼玉県加須市" }
      yomi { "さいたまけんかぞし" }
      short_name { "加須市" }
      short_yomi { "かぞし" }
    end

    factory :jmaxml_forecast_region_c1121100 do
      code { "1121100" }
      name { "埼玉県本庄市" }
      yomi { "さいたまけんほんじょうし" }
      short_name { "本庄市" }
      short_yomi { "ほんじょうし" }
    end

    factory :jmaxml_forecast_region_c1121200 do
      code { "1121200" }
      name { "埼玉県東松山市" }
      yomi { "さいたまけんひがしまつやまし" }
      short_name { "東松山市" }
      short_yomi { "ひがしまつやまし" }
    end

    factory :jmaxml_forecast_region_c1121400 do
      code { "1121400" }
      name { "埼玉県春日部市" }
      yomi { "さいたまけんかすかべし" }
      short_name { "春日部市" }
      short_yomi { "かすかべし" }
    end

    factory :jmaxml_forecast_region_c1121500 do
      code { "1121500" }
      name { "埼玉県狭山市" }
      yomi { "さいたまけんさやまし" }
      short_name { "狭山市" }
      short_yomi { "さやまし" }
    end

    factory :jmaxml_forecast_region_c1121600 do
      code { "1121600" }
      name { "埼玉県羽生市" }
      yomi { "さいたまけんはにゅうし" }
      short_name { "羽生市" }
      short_yomi { "はにゅうし" }
    end

    factory :jmaxml_forecast_region_c1121700 do
      code { "1121700" }
      name { "埼玉県鴻巣市" }
      yomi { "さいたまけんこうのすし" }
      short_name { "鴻巣市" }
      short_yomi { "こうのすし" }
    end

    factory :jmaxml_forecast_region_c1121800 do
      code { "1121800" }
      name { "埼玉県深谷市" }
      yomi { "さいたまけんふかやし" }
      short_name { "深谷市" }
      short_yomi { "ふかやし" }
    end

    factory :jmaxml_forecast_region_c1121900 do
      code { "1121900" }
      name { "埼玉県上尾市" }
      yomi { "さいたまけんあげおし" }
      short_name { "上尾市" }
      short_yomi { "あげおし" }
    end

    factory :jmaxml_forecast_region_c1122100 do
      code { "1122100" }
      name { "埼玉県草加市" }
      yomi { "さいたまけんそうかし" }
      short_name { "草加市" }
      short_yomi { "そうかし" }
    end

    factory :jmaxml_forecast_region_c1122200 do
      code { "1122200" }
      name { "埼玉県越谷市" }
      yomi { "さいたまけんこしがやし" }
      short_name { "越谷市" }
      short_yomi { "こしがやし" }
    end

    factory :jmaxml_forecast_region_c1122300 do
      code { "1122300" }
      name { "埼玉県蕨市" }
      yomi { "さいたまけんわらびし" }
      short_name { "蕨市" }
      short_yomi { "わらびし" }
    end

    factory :jmaxml_forecast_region_c1122400 do
      code { "1122400" }
      name { "埼玉県戸田市" }
      yomi { "さいたまけんとだし" }
      short_name { "戸田市" }
      short_yomi { "とだし" }
    end

    factory :jmaxml_forecast_region_c1122500 do
      code { "1122500" }
      name { "埼玉県入間市" }
      yomi { "さいたまけんいるまし" }
      short_name { "入間市" }
      short_yomi { "いるまし" }
    end

    factory :jmaxml_forecast_region_c1122700 do
      code { "1122700" }
      name { "埼玉県朝霞市" }
      yomi { "さいたまけんあさかし" }
      short_name { "朝霞市" }
      short_yomi { "あさかし" }
    end

    factory :jmaxml_forecast_region_c1122800 do
      code { "1122800" }
      name { "埼玉県志木市" }
      yomi { "さいたまけんしきし" }
      short_name { "志木市" }
      short_yomi { "しきし" }
    end

    factory :jmaxml_forecast_region_c1122900 do
      code { "1122900" }
      name { "埼玉県和光市" }
      yomi { "さいたまけんわこうし" }
      short_name { "和光市" }
      short_yomi { "わこうし" }
    end

    factory :jmaxml_forecast_region_c1123000 do
      code { "1123000" }
      name { "埼玉県新座市" }
      yomi { "さいたまけんにいざし" }
      short_name { "新座市" }
      short_yomi { "にいざし" }
    end

    factory :jmaxml_forecast_region_c1123100 do
      code { "1123100" }
      name { "埼玉県桶川市" }
      yomi { "さいたまけんおけがわし" }
      short_name { "桶川市" }
      short_yomi { "おけがわし" }
    end

    factory :jmaxml_forecast_region_c1123200 do
      code { "1123200" }
      name { "埼玉県久喜市" }
      yomi { "さいたまけんくきし" }
      short_name { "久喜市" }
      short_yomi { "くきし" }
    end

    factory :jmaxml_forecast_region_c1123300 do
      code { "1123300" }
      name { "埼玉県北本市" }
      yomi { "さいたまけんきたもとし" }
      short_name { "北本市" }
      short_yomi { "きたもとし" }
    end

    factory :jmaxml_forecast_region_c1123400 do
      code { "1123400" }
      name { "埼玉県八潮市" }
      yomi { "さいたまけんやしおし" }
      short_name { "八潮市" }
      short_yomi { "やしおし" }
    end

    factory :jmaxml_forecast_region_c1123500 do
      code { "1123500" }
      name { "埼玉県富士見市" }
      yomi { "さいたまけんふじみし" }
      short_name { "富士見市" }
      short_yomi { "ふじみし" }
    end

    factory :jmaxml_forecast_region_c1123700 do
      code { "1123700" }
      name { "埼玉県三郷市" }
      yomi { "さいたまけんみさとし" }
      short_name { "三郷市" }
      short_yomi { "みさとし" }
    end

    factory :jmaxml_forecast_region_c1123800 do
      code { "1123800" }
      name { "埼玉県蓮田市" }
      yomi { "さいたまけんはすだし" }
      short_name { "蓮田市" }
      short_yomi { "はすだし" }
    end

    factory :jmaxml_forecast_region_c1123900 do
      code { "1123900" }
      name { "埼玉県坂戸市" }
      yomi { "さいたまけんさかどし" }
      short_name { "坂戸市" }
      short_yomi { "さかどし" }
    end

    factory :jmaxml_forecast_region_c1124000 do
      code { "1124000" }
      name { "埼玉県幸手市" }
      yomi { "さいたまけんさってし" }
      short_name { "幸手市" }
      short_yomi { "さってし" }
    end

    factory :jmaxml_forecast_region_c1124100 do
      code { "1124100" }
      name { "埼玉県鶴ヶ島市" }
      yomi { "さいたまけんつるがしまし" }
      short_name { "鶴ヶ島市" }
      short_yomi { "つるがしまし" }
    end

    factory :jmaxml_forecast_region_c1124200 do
      code { "1124200" }
      name { "埼玉県日高市" }
      yomi { "さいたまけんひだかし" }
      short_name { "日高市" }
      short_yomi { "ひだかし" }
    end

    factory :jmaxml_forecast_region_c1124300 do
      code { "1124300" }
      name { "埼玉県吉川市" }
      yomi { "さいたまけんよしかわし" }
      short_name { "吉川市" }
      short_yomi { "よしかわし" }
    end

    factory :jmaxml_forecast_region_c1124500 do
      code { "1124500" }
      name { "埼玉県ふじみ野市" }
      yomi { "さいたまけんふじみのし" }
      short_name { "ふじみ野市" }
      short_yomi { "ふじみのし" }
    end

    factory :jmaxml_forecast_region_c1124600 do
      code { "1124600" }
      name { "埼玉県白岡市" }
      yomi { "さいたまけんしらおかし" }
      short_name { "白岡市" }
      short_yomi { "しらおかし" }
    end

    factory :jmaxml_forecast_region_c1130100 do
      code { "1130100" }
      name { "埼玉県伊奈町" }
      yomi { "さいたまけんいなまち" }
      short_name { "伊奈町" }
      short_yomi { "いなまち" }
    end

    factory :jmaxml_forecast_region_c1132400 do
      code { "1132400" }
      name { "埼玉県三芳町" }
      yomi { "さいたまけんみよしまち" }
      short_name { "三芳町" }
      short_yomi { "みよしまち" }
    end

    factory :jmaxml_forecast_region_c1132600 do
      code { "1132600" }
      name { "埼玉県毛呂山町" }
      yomi { "さいたまけんもろやままち" }
      short_name { "毛呂山町" }
      short_yomi { "もろやままち" }
    end

    factory :jmaxml_forecast_region_c1132700 do
      code { "1132700" }
      name { "埼玉県越生町" }
      yomi { "さいたまけんおごせまち" }
      short_name { "越生町" }
      short_yomi { "おごせまち" }
    end

    factory :jmaxml_forecast_region_c1134100 do
      code { "1134100" }
      name { "埼玉県滑川町" }
      yomi { "さいたまけんなめがわまち" }
      short_name { "滑川町" }
      short_yomi { "なめがわまち" }
    end

    factory :jmaxml_forecast_region_c1134200 do
      code { "1134200" }
      name { "埼玉県嵐山町" }
      yomi { "さいたまけんらんざんまち" }
      short_name { "嵐山町" }
      short_yomi { "らんざんまち" }
    end

    factory :jmaxml_forecast_region_c1134300 do
      code { "1134300" }
      name { "埼玉県小川町" }
      yomi { "さいたまけんおがわまち" }
      short_name { "小川町" }
      short_yomi { "おがわまち" }
    end

    factory :jmaxml_forecast_region_c1134600 do
      code { "1134600" }
      name { "埼玉県川島町" }
      yomi { "さいたまけんかわじままち" }
      short_name { "川島町" }
      short_yomi { "かわじままち" }
    end

    factory :jmaxml_forecast_region_c1134700 do
      code { "1134700" }
      name { "埼玉県吉見町" }
      yomi { "さいたまけんよしみまち" }
      short_name { "吉見町" }
      short_yomi { "よしみまち" }
    end

    factory :jmaxml_forecast_region_c1134800 do
      code { "1134800" }
      name { "埼玉県鳩山町" }
      yomi { "さいたまけんはとやままち" }
      short_name { "鳩山町" }
      short_yomi { "はとやままち" }
    end

    factory :jmaxml_forecast_region_c1134900 do
      code { "1134900" }
      name { "埼玉県ときがわ町" }
      yomi { "さいたまけんときがわまち" }
      short_name { "ときがわ町" }
      short_yomi { "ときがわまち" }
    end

    factory :jmaxml_forecast_region_c1136100 do
      code { "1136100" }
      name { "埼玉県横瀬町" }
      yomi { "さいたまけんよこぜまち" }
      short_name { "横瀬町" }
      short_yomi { "よこぜまち" }
    end

    factory :jmaxml_forecast_region_c1136200 do
      code { "1136200" }
      name { "埼玉県皆野町" }
      yomi { "さいたまけんみなのまち" }
      short_name { "皆野町" }
      short_yomi { "みなのまち" }
    end

    factory :jmaxml_forecast_region_c1136300 do
      code { "1136300" }
      name { "埼玉県長瀞町" }
      yomi { "さいたまけんながとろまち" }
      short_name { "長瀞町" }
      short_yomi { "ながとろまち" }
    end

    factory :jmaxml_forecast_region_c1136500 do
      code { "1136500" }
      name { "埼玉県小鹿野町" }
      yomi { "さいたまけんおがのまち" }
      short_name { "小鹿野町" }
      short_yomi { "おがのまち" }
    end

    factory :jmaxml_forecast_region_c1136900 do
      code { "1136900" }
      name { "埼玉県東秩父村" }
      yomi { "さいたまけんひがしちちぶむら" }
      short_name { "東秩父村" }
      short_yomi { "ひがしちちぶむら" }
    end

    factory :jmaxml_forecast_region_c1138100 do
      code { "1138100" }
      name { "埼玉県美里町" }
      yomi { "さいたまけんみさとまち" }
      short_name { "美里町" }
      short_yomi { "みさとまち" }
    end

    factory :jmaxml_forecast_region_c1138300 do
      code { "1138300" }
      name { "埼玉県神川町" }
      yomi { "さいたまけんかみかわまち" }
      short_name { "神川町" }
      short_yomi { "かみかわまち" }
    end

    factory :jmaxml_forecast_region_c1138500 do
      code { "1138500" }
      name { "埼玉県上里町" }
      yomi { "さいたまけんかみさとまち" }
      short_name { "上里町" }
      short_yomi { "かみさとまち" }
    end

    factory :jmaxml_forecast_region_c1140800 do
      code { "1140800" }
      name { "埼玉県寄居町" }
      yomi { "さいたまけんよりいまち" }
      short_name { "寄居町" }
      short_yomi { "よりいまち" }
    end

    factory :jmaxml_forecast_region_c1144200 do
      code { "1144200" }
      name { "埼玉県宮代町" }
      yomi { "さいたまけんみやしろまち" }
      short_name { "宮代町" }
      short_yomi { "みやしろまち" }
    end

    factory :jmaxml_forecast_region_c1146400 do
      code { "1146400" }
      name { "埼玉県杉戸町" }
      yomi { "さいたまけんすぎとまち" }
      short_name { "杉戸町" }
      short_yomi { "すぎとまち" }
    end

    factory :jmaxml_forecast_region_c1146500 do
      code { "1146500" }
      name { "埼玉県松伏町" }
      yomi { "さいたまけんまつぶしまち" }
      short_name { "松伏町" }
      short_yomi { "まつぶしまち" }
    end

    factory :jmaxml_forecast_region_c1210000 do
      code { "1210000" }
      name { "千葉県千葉市" }
      yomi { "ちばけんちばし" }
      short_name { "千葉市" }
      short_yomi { "ちばし" }
    end

    factory :jmaxml_forecast_region_c1220200 do
      code { "1220200" }
      name { "千葉県銚子市" }
      yomi { "ちばけんちょうしし" }
      short_name { "銚子市" }
      short_yomi { "ちょうしし" }
    end

    factory :jmaxml_forecast_region_c1220300 do
      code { "1220300" }
      name { "千葉県市川市" }
      yomi { "ちばけんいちかわし" }
      short_name { "市川市" }
      short_yomi { "いちかわし" }
    end

    factory :jmaxml_forecast_region_c1220400 do
      code { "1220400" }
      name { "千葉県船橋市" }
      yomi { "ちばけんふなばしし" }
      short_name { "船橋市" }
      short_yomi { "ふなばしし" }
    end

    factory :jmaxml_forecast_region_c1220500 do
      code { "1220500" }
      name { "千葉県館山市" }
      yomi { "ちばけんたてやまし" }
      short_name { "館山市" }
      short_yomi { "たてやまし" }
    end

    factory :jmaxml_forecast_region_c1220600 do
      code { "1220600" }
      name { "千葉県木更津市" }
      yomi { "ちばけんきさらづし" }
      short_name { "木更津市" }
      short_yomi { "きさらづし" }
    end

    factory :jmaxml_forecast_region_c1220700 do
      code { "1220700" }
      name { "千葉県松戸市" }
      yomi { "ちばけんまつどし" }
      short_name { "松戸市" }
      short_yomi { "まつどし" }
    end

    factory :jmaxml_forecast_region_c1220800 do
      code { "1220800" }
      name { "千葉県野田市" }
      yomi { "ちばけんのだし" }
      short_name { "野田市" }
      short_yomi { "のだし" }
    end

    factory :jmaxml_forecast_region_c1221000 do
      code { "1221000" }
      name { "千葉県茂原市" }
      yomi { "ちばけんもばらし" }
      short_name { "茂原市" }
      short_yomi { "もばらし" }
    end

    factory :jmaxml_forecast_region_c1221100 do
      code { "1221100" }
      name { "千葉県成田市" }
      yomi { "ちばけんなりたし" }
      short_name { "成田市" }
      short_yomi { "なりたし" }
    end

    factory :jmaxml_forecast_region_c1221200 do
      code { "1221200" }
      name { "千葉県佐倉市" }
      yomi { "ちばけんさくらし" }
      short_name { "佐倉市" }
      short_yomi { "さくらし" }
    end

    factory :jmaxml_forecast_region_c1221300 do
      code { "1221300" }
      name { "千葉県東金市" }
      yomi { "ちばけんとうがねし" }
      short_name { "東金市" }
      short_yomi { "とうがねし" }
    end

    factory :jmaxml_forecast_region_c1221500 do
      code { "1221500" }
      name { "千葉県旭市" }
      yomi { "ちばけんあさひし" }
      short_name { "旭市" }
      short_yomi { "あさひし" }
    end

    factory :jmaxml_forecast_region_c1221600 do
      code { "1221600" }
      name { "千葉県習志野市" }
      yomi { "ちばけんならしのし" }
      short_name { "習志野市" }
      short_yomi { "ならしのし" }
    end

    factory :jmaxml_forecast_region_c1221700 do
      code { "1221700" }
      name { "千葉県柏市" }
      yomi { "ちばけんかしわし" }
      short_name { "柏市" }
      short_yomi { "かしわし" }
    end

    factory :jmaxml_forecast_region_c1221800 do
      code { "1221800" }
      name { "千葉県勝浦市" }
      yomi { "ちばけんかつうらし" }
      short_name { "勝浦市" }
      short_yomi { "かつうらし" }
    end

    factory :jmaxml_forecast_region_c1221900 do
      code { "1221900" }
      name { "千葉県市原市" }
      yomi { "ちばけんいちはらし" }
      short_name { "市原市" }
      short_yomi { "いちはらし" }
    end

    factory :jmaxml_forecast_region_c1222000 do
      code { "1222000" }
      name { "千葉県流山市" }
      yomi { "ちばけんながれやまし" }
      short_name { "流山市" }
      short_yomi { "ながれやまし" }
    end

    factory :jmaxml_forecast_region_c1222100 do
      code { "1222100" }
      name { "千葉県八千代市" }
      yomi { "ちばけんやちよし" }
      short_name { "八千代市" }
      short_yomi { "やちよし" }
    end

    factory :jmaxml_forecast_region_c1222200 do
      code { "1222200" }
      name { "千葉県我孫子市" }
      yomi { "ちばけんあびこし" }
      short_name { "我孫子市" }
      short_yomi { "あびこし" }
    end

    factory :jmaxml_forecast_region_c1222300 do
      code { "1222300" }
      name { "千葉県鴨川市" }
      yomi { "ちばけんかもがわし" }
      short_name { "鴨川市" }
      short_yomi { "かもがわし" }
    end

    factory :jmaxml_forecast_region_c1222400 do
      code { "1222400" }
      name { "千葉県鎌ケ谷市" }
      yomi { "ちばけんかまがやし" }
      short_name { "鎌ケ谷市" }
      short_yomi { "かまがやし" }
    end

    factory :jmaxml_forecast_region_c1222500 do
      code { "1222500" }
      name { "千葉県君津市" }
      yomi { "ちばけんきみつし" }
      short_name { "君津市" }
      short_yomi { "きみつし" }
    end

    factory :jmaxml_forecast_region_c1222600 do
      code { "1222600" }
      name { "千葉県富津市" }
      yomi { "ちばけんふっつし" }
      short_name { "富津市" }
      short_yomi { "ふっつし" }
    end

    factory :jmaxml_forecast_region_c1222700 do
      code { "1222700" }
      name { "千葉県浦安市" }
      yomi { "ちばけんうらやすし" }
      short_name { "浦安市" }
      short_yomi { "うらやすし" }
    end

    factory :jmaxml_forecast_region_c1222800 do
      code { "1222800" }
      name { "千葉県四街道市" }
      yomi { "ちばけんよつかいどうし" }
      short_name { "四街道市" }
      short_yomi { "よつかいどうし" }
    end

    factory :jmaxml_forecast_region_c1222900 do
      code { "1222900" }
      name { "千葉県袖ケ浦市" }
      yomi { "ちばけんそでがうらし" }
      short_name { "袖ケ浦市" }
      short_yomi { "そでがうらし" }
    end

    factory :jmaxml_forecast_region_c1223000 do
      code { "1223000" }
      name { "千葉県八街市" }
      yomi { "ちばけんやちまたし" }
      short_name { "八街市" }
      short_yomi { "やちまたし" }
    end

    factory :jmaxml_forecast_region_c1223100 do
      code { "1223100" }
      name { "千葉県印西市" }
      yomi { "ちばけんいんざいし" }
      short_name { "印西市" }
      short_yomi { "いんざいし" }
    end

    factory :jmaxml_forecast_region_c1223200 do
      code { "1223200" }
      name { "千葉県白井市" }
      yomi { "ちばけんしろいし" }
      short_name { "白井市" }
      short_yomi { "しろいし" }
    end

    factory :jmaxml_forecast_region_c1223300 do
      code { "1223300" }
      name { "千葉県富里市" }
      yomi { "ちばけんとみさとし" }
      short_name { "富里市" }
      short_yomi { "とみさとし" }
    end

    factory :jmaxml_forecast_region_c1223400 do
      code { "1223400" }
      name { "千葉県南房総市" }
      yomi { "ちばけんみなみぼうそうし" }
      short_name { "南房総市" }
      short_yomi { "みなみぼうそうし" }
    end

    factory :jmaxml_forecast_region_c1223500 do
      code { "1223500" }
      name { "千葉県匝瑳市" }
      yomi { "ちばけんそうさし" }
      short_name { "匝瑳市" }
      short_yomi { "そうさし" }
    end

    factory :jmaxml_forecast_region_c1223600 do
      code { "1223600" }
      name { "千葉県香取市" }
      yomi { "ちばけんかとりし" }
      short_name { "香取市" }
      short_yomi { "かとりし" }
    end

    factory :jmaxml_forecast_region_c1223700 do
      code { "1223700" }
      name { "千葉県山武市" }
      yomi { "ちばけんさんむし" }
      short_name { "山武市" }
      short_yomi { "さんむし" }
    end

    factory :jmaxml_forecast_region_c1223800 do
      code { "1223800" }
      name { "千葉県いすみ市" }
      yomi { "ちばけんいすみし" }
      short_name { "いすみ市" }
      short_yomi { "いすみし" }
    end

    factory :jmaxml_forecast_region_c1223900 do
      code { "1223900" }
      name { "千葉県大網白里市" }
      yomi { "ちばけんおおあみしらさとし" }
      short_name { "大網白里市" }
      short_yomi { "おおあみしらさとし" }
    end

    factory :jmaxml_forecast_region_c1232200 do
      code { "1232200" }
      name { "千葉県酒々井町" }
      yomi { "ちばけんしすいまち" }
      short_name { "酒々井町" }
      short_yomi { "しすいまち" }
    end

    factory :jmaxml_forecast_region_c1232900 do
      code { "1232900" }
      name { "千葉県栄町" }
      yomi { "ちばけんさかえまち" }
      short_name { "栄町" }
      short_yomi { "さかえまち" }
    end

    factory :jmaxml_forecast_region_c1234200 do
      code { "1234200" }
      name { "千葉県神崎町" }
      yomi { "ちばけんこうざきまち" }
      short_name { "神崎町" }
      short_yomi { "こうざきまち" }
    end

    factory :jmaxml_forecast_region_c1234700 do
      code { "1234700" }
      name { "千葉県多古町" }
      yomi { "ちばけんたこまち" }
      short_name { "多古町" }
      short_yomi { "たこまち" }
    end

    factory :jmaxml_forecast_region_c1234900 do
      code { "1234900" }
      name { "千葉県東庄町" }
      yomi { "ちばけんとうのしょうまち" }
      short_name { "東庄町" }
      short_yomi { "とうのしょうまち" }
    end

    factory :jmaxml_forecast_region_c1240300 do
      code { "1240300" }
      name { "千葉県九十九里町" }
      yomi { "ちばけんくじゅうくりまち" }
      short_name { "九十九里町" }
      short_yomi { "くじゅうくりまち" }
    end

    factory :jmaxml_forecast_region_c1240900 do
      code { "1240900" }
      name { "千葉県芝山町" }
      yomi { "ちばけんしばやままち" }
      short_name { "芝山町" }
      short_yomi { "しばやままち" }
    end

    factory :jmaxml_forecast_region_c1241000 do
      code { "1241000" }
      name { "千葉県横芝光町" }
      yomi { "ちばけんよこしばひかりまち" }
      short_name { "横芝光町" }
      short_yomi { "よこしばひかりまち" }
    end

    factory :jmaxml_forecast_region_c1242100 do
      code { "1242100" }
      name { "千葉県一宮町" }
      yomi { "ちばけんいちのみやまち" }
      short_name { "一宮町" }
      short_yomi { "いちのみやまち" }
    end

    factory :jmaxml_forecast_region_c1242200 do
      code { "1242200" }
      name { "千葉県睦沢町" }
      yomi { "ちばけんむつざわまち" }
      short_name { "睦沢町" }
      short_yomi { "むつざわまち" }
    end

    factory :jmaxml_forecast_region_c1242300 do
      code { "1242300" }
      name { "千葉県長生村" }
      yomi { "ちばけんちょうせいむら" }
      short_name { "長生村" }
      short_yomi { "ちょうせいむら" }
    end

    factory :jmaxml_forecast_region_c1242400 do
      code { "1242400" }
      name { "千葉県白子町" }
      yomi { "ちばけんしらこまち" }
      short_name { "白子町" }
      short_yomi { "しらこまち" }
    end

    factory :jmaxml_forecast_region_c1242600 do
      code { "1242600" }
      name { "千葉県長柄町" }
      yomi { "ちばけんながらまち" }
      short_name { "長柄町" }
      short_yomi { "ながらまち" }
    end

    factory :jmaxml_forecast_region_c1242700 do
      code { "1242700" }
      name { "千葉県長南町" }
      yomi { "ちばけんちょうなんまち" }
      short_name { "長南町" }
      short_yomi { "ちょうなんまち" }
    end

    factory :jmaxml_forecast_region_c1244100 do
      code { "1244100" }
      name { "千葉県大多喜町" }
      yomi { "ちばけんおおたきまち" }
      short_name { "大多喜町" }
      short_yomi { "おおたきまち" }
    end

    factory :jmaxml_forecast_region_c1244300 do
      code { "1244300" }
      name { "千葉県御宿町" }
      yomi { "ちばけんおんじゅくまち" }
      short_name { "御宿町" }
      short_yomi { "おんじゅくまち" }
    end

    factory :jmaxml_forecast_region_c1246300 do
      code { "1246300" }
      name { "千葉県鋸南町" }
      yomi { "ちばけんきょなんまち" }
      short_name { "鋸南町" }
      short_yomi { "きょなんまち" }
    end

    factory :jmaxml_forecast_region_c1310100 do
      code { "1310100" }
      name { "東京都千代田区" }
      yomi { "とうきょうとちよだく" }
      short_name { "千代田区" }
      short_yomi { "ちよだく" }
    end

    factory :jmaxml_forecast_region_c1310200 do
      code { "1310200" }
      name { "東京都中央区" }
      yomi { "とうきょうとちゅうおうく" }
      short_name { "中央区" }
      short_yomi { "ちゅうおうく" }
    end

    factory :jmaxml_forecast_region_c1310300 do
      code { "1310300" }
      name { "東京都港区" }
      yomi { "とうきょうとみなとく" }
      short_name { "港区" }
      short_yomi { "みなとく" }
    end

    factory :jmaxml_forecast_region_c1310400 do
      code { "1310400" }
      name { "東京都新宿区" }
      yomi { "とうきょうとしんじゅくく" }
      short_name { "新宿区" }
      short_yomi { "しんじゅくく" }
    end

    factory :jmaxml_forecast_region_c1310500 do
      code { "1310500" }
      name { "東京都文京区" }
      yomi { "とうきょうとぶんきょうく" }
      short_name { "文京区" }
      short_yomi { "ぶんきょうく" }
    end

    factory :jmaxml_forecast_region_c1310600 do
      code { "1310600" }
      name { "東京都台東区" }
      yomi { "とうきょうとたいとうく" }
      short_name { "台東区" }
      short_yomi { "たいとうく" }
    end

    factory :jmaxml_forecast_region_c1310700 do
      code { "1310700" }
      name { "東京都墨田区" }
      yomi { "とうきょうとすみだく" }
      short_name { "墨田区" }
      short_yomi { "すみだく" }
    end

    factory :jmaxml_forecast_region_c1310800 do
      code { "1310800" }
      name { "東京都江東区" }
      yomi { "とうきょうとこうとうく" }
      short_name { "江東区" }
      short_yomi { "こうとうく" }
    end

    factory :jmaxml_forecast_region_c1310900 do
      code { "1310900" }
      name { "東京都品川区" }
      yomi { "とうきょうとしながわく" }
      short_name { "品川区" }
      short_yomi { "しながわく" }
    end

    factory :jmaxml_forecast_region_c1311000 do
      code { "1311000" }
      name { "東京都目黒区" }
      yomi { "とうきょうとめぐろく" }
      short_name { "目黒区" }
      short_yomi { "めぐろく" }
    end

    factory :jmaxml_forecast_region_c1311100 do
      code { "1311100" }
      name { "東京都大田区" }
      yomi { "とうきょうとおおたく" }
      short_name { "大田区" }
      short_yomi { "おおたく" }
    end

    factory :jmaxml_forecast_region_c1311200 do
      code { "1311200" }
      name { "東京都世田谷区" }
      yomi { "とうきょうとせたがやく" }
      short_name { "世田谷区" }
      short_yomi { "せたがやく" }
    end

    factory :jmaxml_forecast_region_c1311300 do
      code { "1311300" }
      name { "東京都渋谷区" }
      yomi { "とうきょうとしぶやく" }
      short_name { "渋谷区" }
      short_yomi { "しぶやく" }
    end

    factory :jmaxml_forecast_region_c1311400 do
      code { "1311400" }
      name { "東京都中野区" }
      yomi { "とうきょうとなかのく" }
      short_name { "中野区" }
      short_yomi { "なかのく" }
    end

    factory :jmaxml_forecast_region_c1311500 do
      code { "1311500" }
      name { "東京都杉並区" }
      yomi { "とうきょうとすぎなみく" }
      short_name { "杉並区" }
      short_yomi { "すぎなみく" }
    end

    factory :jmaxml_forecast_region_c1311600 do
      code { "1311600" }
      name { "東京都豊島区" }
      yomi { "とうきょうととしまく" }
      short_name { "豊島区" }
      short_yomi { "としまく" }
    end

    factory :jmaxml_forecast_region_c1311700 do
      code { "1311700" }
      name { "東京都北区" }
      yomi { "とうきょうときたく" }
      short_name { "北区" }
      short_yomi { "きたく" }
    end

    factory :jmaxml_forecast_region_c1311800 do
      code { "1311800" }
      name { "東京都荒川区" }
      yomi { "とうきょうとあらかわく" }
      short_name { "荒川区" }
      short_yomi { "あらかわく" }
    end

    factory :jmaxml_forecast_region_c1311900 do
      code { "1311900" }
      name { "東京都板橋区" }
      yomi { "とうきょうといたばしく" }
      short_name { "板橋区" }
      short_yomi { "いたばしく" }
    end

    factory :jmaxml_forecast_region_c1312000 do
      code { "1312000" }
      name { "東京都練馬区" }
      yomi { "とうきょうとねりまく" }
      short_name { "練馬区" }
      short_yomi { "ねりまく" }
    end

    factory :jmaxml_forecast_region_c1312100 do
      code { "1312100" }
      name { "東京都足立区" }
      yomi { "とうきょうとあだちく" }
      short_name { "足立区" }
      short_yomi { "あだちく" }
    end

    factory :jmaxml_forecast_region_c1312200 do
      code { "1312200" }
      name { "東京都葛飾区" }
      yomi { "とうきょうとかつしかく" }
      short_name { "葛飾区" }
      short_yomi { "かつしかく" }
    end

    factory :jmaxml_forecast_region_c1312300 do
      code { "1312300" }
      name { "東京都江戸川区" }
      yomi { "とうきょうとえどがわく" }
      short_name { "江戸川区" }
      short_yomi { "えどがわく" }
    end

    factory :jmaxml_forecast_region_c1320100 do
      code { "1320100" }
      name { "東京都八王子市" }
      yomi { "とうきょうとはちおうじし" }
      short_name { "八王子市" }
      short_yomi { "はちおうじし" }
    end

    factory :jmaxml_forecast_region_c1320200 do
      code { "1320200" }
      name { "東京都立川市" }
      yomi { "とうきょうとたちかわし" }
      short_name { "立川市" }
      short_yomi { "たちかわし" }
    end

    factory :jmaxml_forecast_region_c1320300 do
      code { "1320300" }
      name { "東京都武蔵野市" }
      yomi { "とうきょうとむさしのし" }
      short_name { "武蔵野市" }
      short_yomi { "むさしのし" }
    end

    factory :jmaxml_forecast_region_c1320400 do
      code { "1320400" }
      name { "東京都三鷹市" }
      yomi { "とうきょうとみたかし" }
      short_name { "三鷹市" }
      short_yomi { "みたかし" }
    end

    factory :jmaxml_forecast_region_c1320500 do
      code { "1320500" }
      name { "東京都青梅市" }
      yomi { "とうきょうとおうめし" }
      short_name { "青梅市" }
      short_yomi { "おうめし" }
    end

    factory :jmaxml_forecast_region_c1320600 do
      code { "1320600" }
      name { "東京都府中市" }
      yomi { "とうきょうとふちゅうし" }
      short_name { "府中市" }
      short_yomi { "ふちゅうし" }
    end

    factory :jmaxml_forecast_region_c1320700 do
      code { "1320700" }
      name { "東京都昭島市" }
      yomi { "とうきょうとあきしまし" }
      short_name { "昭島市" }
      short_yomi { "あきしまし" }
    end

    factory :jmaxml_forecast_region_c1320800 do
      code { "1320800" }
      name { "東京都調布市" }
      yomi { "とうきょうとちょうふし" }
      short_name { "調布市" }
      short_yomi { "ちょうふし" }
    end

    factory :jmaxml_forecast_region_c1320900 do
      code { "1320900" }
      name { "東京都町田市" }
      yomi { "とうきょうとまちだし" }
      short_name { "町田市" }
      short_yomi { "まちだし" }
    end

    factory :jmaxml_forecast_region_c1321000 do
      code { "1321000" }
      name { "東京都小金井市" }
      yomi { "とうきょうとこがねいし" }
      short_name { "小金井市" }
      short_yomi { "こがねいし" }
    end

    factory :jmaxml_forecast_region_c1321100 do
      code { "1321100" }
      name { "東京都小平市" }
      yomi { "とうきょうとこだいらし" }
      short_name { "小平市" }
      short_yomi { "こだいらし" }
    end

    factory :jmaxml_forecast_region_c1321200 do
      code { "1321200" }
      name { "東京都日野市" }
      yomi { "とうきょうとひのし" }
      short_name { "日野市" }
      short_yomi { "ひのし" }
    end

    factory :jmaxml_forecast_region_c1321300 do
      code { "1321300" }
      name { "東京都東村山市" }
      yomi { "とうきょうとひがしむらやまし" }
      short_name { "東村山市" }
      short_yomi { "ひがしむらやまし" }
    end

    factory :jmaxml_forecast_region_c1321400 do
      code { "1321400" }
      name { "東京都国分寺市" }
      yomi { "とうきょうとこくぶんじし" }
      short_name { "国分寺市" }
      short_yomi { "こくぶんじし" }
    end

    factory :jmaxml_forecast_region_c1321500 do
      code { "1321500" }
      name { "東京都国立市" }
      yomi { "とうきょうとくにたちし" }
      short_name { "国立市" }
      short_yomi { "くにたちし" }
    end

    factory :jmaxml_forecast_region_c1321800 do
      code { "1321800" }
      name { "東京都福生市" }
      yomi { "とうきょうとふっさし" }
      short_name { "福生市" }
      short_yomi { "ふっさし" }
    end

    factory :jmaxml_forecast_region_c1321900 do
      code { "1321900" }
      name { "東京都狛江市" }
      yomi { "とうきょうとこまえし" }
      short_name { "狛江市" }
      short_yomi { "こまえし" }
    end

    factory :jmaxml_forecast_region_c1322000 do
      code { "1322000" }
      name { "東京都東大和市" }
      yomi { "とうきょうとひがしやまとし" }
      short_name { "東大和市" }
      short_yomi { "ひがしやまとし" }
    end

    factory :jmaxml_forecast_region_c1322100 do
      code { "1322100" }
      name { "東京都清瀬市" }
      yomi { "とうきょうときよせし" }
      short_name { "清瀬市" }
      short_yomi { "きよせし" }
    end

    factory :jmaxml_forecast_region_c1322200 do
      code { "1322200" }
      name { "東京都東久留米市" }
      yomi { "とうきょうとひがしくるめし" }
      short_name { "東久留米市" }
      short_yomi { "ひがしくるめし" }
    end

    factory :jmaxml_forecast_region_c1322300 do
      code { "1322300" }
      name { "東京都武蔵村山市" }
      yomi { "とうきょうとむさしむらやまし" }
      short_name { "武蔵村山市" }
      short_yomi { "むさしむらやまし" }
    end

    factory :jmaxml_forecast_region_c1322400 do
      code { "1322400" }
      name { "東京都多摩市" }
      yomi { "とうきょうとたまし" }
      short_name { "多摩市" }
      short_yomi { "たまし" }
    end

    factory :jmaxml_forecast_region_c1322500 do
      code { "1322500" }
      name { "東京都稲城市" }
      yomi { "とうきょうといなぎし" }
      short_name { "稲城市" }
      short_yomi { "いなぎし" }
    end

    factory :jmaxml_forecast_region_c1322700 do
      code { "1322700" }
      name { "東京都羽村市" }
      yomi { "とうきょうとはむらし" }
      short_name { "羽村市" }
      short_yomi { "はむらし" }
    end

    factory :jmaxml_forecast_region_c1322800 do
      code { "1322800" }
      name { "東京都あきる野市" }
      yomi { "とうきょうとあきるのし" }
      short_name { "あきる野市" }
      short_yomi { "あきるのし" }
    end

    factory :jmaxml_forecast_region_c1322900 do
      code { "1322900" }
      name { "東京都西東京市" }
      yomi { "とうきょうとにしとうきょうし" }
      short_name { "西東京市" }
      short_yomi { "にしとうきょうし" }
    end

    factory :jmaxml_forecast_region_c1330300 do
      code { "1330300" }
      name { "東京都瑞穂町" }
      yomi { "とうきょうとみずほまち" }
      short_name { "瑞穂町" }
      short_yomi { "みずほまち" }
    end

    factory :jmaxml_forecast_region_c1330500 do
      code { "1330500" }
      name { "東京都日の出町" }
      yomi { "とうきょうとひのでまち" }
      short_name { "日の出町" }
      short_yomi { "ひのでまち" }
    end

    factory :jmaxml_forecast_region_c1330700 do
      code { "1330700" }
      name { "東京都檜原村" }
      yomi { "とうきょうとひのはらむら" }
      short_name { "檜原村" }
      short_yomi { "ひのはらむら" }
    end

    factory :jmaxml_forecast_region_c1330800 do
      code { "1330800" }
      name { "東京都奥多摩町" }
      yomi { "とうきょうとおくたままち" }
      short_name { "奥多摩町" }
      short_yomi { "おくたままち" }
    end

    factory :jmaxml_forecast_region_c1336100 do
      code { "1336100" }
      name { "東京都大島町" }
      yomi { "とうきょうとおおしままち" }
      short_name { "大島町" }
      short_yomi { "おおしままち" }
    end

    factory :jmaxml_forecast_region_c1336200 do
      code { "1336200" }
      name { "東京都利島村" }
      yomi { "とうきょうととしまむら" }
      short_name { "利島村" }
      short_yomi { "としまむら" }
    end

    factory :jmaxml_forecast_region_c1336300 do
      code { "1336300" }
      name { "東京都新島村" }
      yomi { "とうきょうとにいじまむら" }
      short_name { "新島村" }
      short_yomi { "にいじまむら" }
    end

    factory :jmaxml_forecast_region_c1336400 do
      code { "1336400" }
      name { "東京都神津島村" }
      yomi { "とうきょうとこうづしまむら" }
      short_name { "神津島村" }
      short_yomi { "こうづしまむら" }
    end

    factory :jmaxml_forecast_region_c1338100 do
      code { "1338100" }
      name { "東京都三宅村" }
      yomi { "とうきょうとみやけむら" }
      short_name { "三宅村" }
      short_yomi { "みやけむら" }
    end

    factory :jmaxml_forecast_region_c1338200 do
      code { "1338200" }
      name { "東京都御蔵島村" }
      yomi { "とうきょうとみくらじまむら" }
      short_name { "御蔵島村" }
      short_yomi { "みくらじまむら" }
    end

    factory :jmaxml_forecast_region_c1340000 do
      code { "1340000" }
      name { "東京都のうち八丈支庁管内" }
      yomi { "とうきょうとはちじょうしちょう" }
      short_name { "0" }
      short_yomi { "0" }
    end

    factory :jmaxml_forecast_region_c1340100 do
      code { "1340100" }
      name { "東京都八丈町" }
      yomi { "とうきょうとはちじょうまち" }
      short_name { "八丈町" }
      short_yomi { "はちじょうまち" }
    end

    factory :jmaxml_forecast_region_c1340200 do
      code { "1340200" }
      name { "東京都青ヶ島村" }
      yomi { "とうきょうとあおがしまむら" }
      short_name { "青ヶ島村" }
      short_yomi { "あおがしまむら" }
    end

    factory :jmaxml_forecast_region_c1342100 do
      code { "1342100" }
      name { "東京都小笠原村" }
      yomi { "とうきょうとおがさわらむら" }
      short_name { "小笠原村" }
      short_yomi { "おがさわらむら" }
    end

    factory :jmaxml_forecast_region_c1410000 do
      code { "1410000" }
      name { "神奈川県横浜市" }
      yomi { "かながわけんよこはまし" }
      short_name { "横浜市" }
      short_yomi { "よこはまし" }
    end

    factory :jmaxml_forecast_region_c1413000 do
      code { "1413000" }
      name { "神奈川県川崎市" }
      yomi { "かながわけんかわさきし" }
      short_name { "川崎市" }
      short_yomi { "かわさきし" }
    end

    factory :jmaxml_forecast_region_c1415000 do
      code { "1415000" }
      name { "神奈川県相模原市" }
      yomi { "かながわけんさがみはらし" }
      short_name { "相模原市" }
      short_yomi { "さがみはらし" }
    end

    factory :jmaxml_forecast_region_c1420100 do
      code { "1420100" }
      name { "神奈川県横須賀市" }
      yomi { "かながわけんよこすかし" }
      short_name { "横須賀市" }
      short_yomi { "よこすかし" }
    end

    factory :jmaxml_forecast_region_c1420300 do
      code { "1420300" }
      name { "神奈川県平塚市" }
      yomi { "かながわけんひらつかし" }
      short_name { "平塚市" }
      short_yomi { "ひらつかし" }
    end

    factory :jmaxml_forecast_region_c1420400 do
      code { "1420400" }
      name { "神奈川県鎌倉市" }
      yomi { "かながわけんかまくらし" }
      short_name { "鎌倉市" }
      short_yomi { "かまくらし" }
    end

    factory :jmaxml_forecast_region_c1420500 do
      code { "1420500" }
      name { "神奈川県藤沢市" }
      yomi { "かながわけんふじさわし" }
      short_name { "藤沢市" }
      short_yomi { "ふじさわし" }
    end

    factory :jmaxml_forecast_region_c1420600 do
      code { "1420600" }
      name { "神奈川県小田原市" }
      yomi { "かながわけんおだわらし" }
      short_name { "小田原市" }
      short_yomi { "おだわらし" }
    end

    factory :jmaxml_forecast_region_c1420700 do
      code { "1420700" }
      name { "神奈川県茅ヶ崎市" }
      yomi { "かながわけんちがさきし" }
      short_name { "茅ヶ崎市" }
      short_yomi { "ちがさきし" }
    end

    factory :jmaxml_forecast_region_c1420800 do
      code { "1420800" }
      name { "神奈川県逗子市" }
      yomi { "かながわけんずしし" }
      short_name { "逗子市" }
      short_yomi { "ずしし" }
    end

    factory :jmaxml_forecast_region_c1421000 do
      code { "1421000" }
      name { "神奈川県三浦市" }
      yomi { "かながわけんみうらし" }
      short_name { "三浦市" }
      short_yomi { "みうらし" }
    end

    factory :jmaxml_forecast_region_c1421100 do
      code { "1421100" }
      name { "神奈川県秦野市" }
      yomi { "かながわけんはだのし" }
      short_name { "秦野市" }
      short_yomi { "はだのし" }
    end

    factory :jmaxml_forecast_region_c1421200 do
      code { "1421200" }
      name { "神奈川県厚木市" }
      yomi { "かながわけんあつぎし" }
      short_name { "厚木市" }
      short_yomi { "あつぎし" }
    end

    factory :jmaxml_forecast_region_c1421300 do
      code { "1421300" }
      name { "神奈川県大和市" }
      yomi { "かながわけんやまとし" }
      short_name { "大和市" }
      short_yomi { "やまとし" }
    end

    factory :jmaxml_forecast_region_c1421400 do
      code { "1421400" }
      name { "神奈川県伊勢原市" }
      yomi { "かながわけんいせはらし" }
      short_name { "伊勢原市" }
      short_yomi { "いせはらし" }
    end

    factory :jmaxml_forecast_region_c1421500 do
      code { "1421500" }
      name { "神奈川県海老名市" }
      yomi { "かながわけんえびなし" }
      short_name { "海老名市" }
      short_yomi { "えびなし" }
    end

    factory :jmaxml_forecast_region_c1421600 do
      code { "1421600" }
      name { "神奈川県座間市" }
      yomi { "かながわけんざまし" }
      short_name { "座間市" }
      short_yomi { "ざまし" }
    end

    factory :jmaxml_forecast_region_c1421700 do
      code { "1421700" }
      name { "神奈川県南足柄市" }
      yomi { "かながわけんみなみあしがらし" }
      short_name { "南足柄市" }
      short_yomi { "みなみあしがらし" }
    end

    factory :jmaxml_forecast_region_c1421800 do
      code { "1421800" }
      name { "神奈川県綾瀬市" }
      yomi { "かながわけんあやせし" }
      short_name { "綾瀬市" }
      short_yomi { "あやせし" }
    end

    factory :jmaxml_forecast_region_c1430100 do
      code { "1430100" }
      name { "神奈川県葉山町" }
      yomi { "かながわけんはやままち" }
      short_name { "葉山町" }
      short_yomi { "はやままち" }
    end

    factory :jmaxml_forecast_region_c1432100 do
      code { "1432100" }
      name { "神奈川県寒川町" }
      yomi { "かながわけんさむかわまち" }
      short_name { "寒川町" }
      short_yomi { "さむかわまち" }
    end

    factory :jmaxml_forecast_region_c1434100 do
      code { "1434100" }
      name { "神奈川県大磯町" }
      yomi { "かながわけんおおいそまち" }
      short_name { "大磯町" }
      short_yomi { "おおいそまち" }
    end

    factory :jmaxml_forecast_region_c1434200 do
      code { "1434200" }
      name { "神奈川県二宮町" }
      yomi { "かながわけんにのみやまち" }
      short_name { "二宮町" }
      short_yomi { "にのみやまち" }
    end

    factory :jmaxml_forecast_region_c1436100 do
      code { "1436100" }
      name { "神奈川県中井町" }
      yomi { "かながわけんなかいまち" }
      short_name { "中井町" }
      short_yomi { "なかいまち" }
    end

    factory :jmaxml_forecast_region_c1436200 do
      code { "1436200" }
      name { "神奈川県大井町" }
      yomi { "かながわけんおおいまち" }
      short_name { "大井町" }
      short_yomi { "おおいまち" }
    end

    factory :jmaxml_forecast_region_c1436300 do
      code { "1436300" }
      name { "神奈川県松田町" }
      yomi { "かながわけんまつだまち" }
      short_name { "松田町" }
      short_yomi { "まつだまち" }
    end

    factory :jmaxml_forecast_region_c1436400 do
      code { "1436400" }
      name { "神奈川県山北町" }
      yomi { "かながわけんやまきたまち" }
      short_name { "山北町" }
      short_yomi { "やまきたまち" }
    end

    factory :jmaxml_forecast_region_c1436600 do
      code { "1436600" }
      name { "神奈川県開成町" }
      yomi { "かながわけんかいせいまち" }
      short_name { "開成町" }
      short_yomi { "かいせいまち" }
    end

    factory :jmaxml_forecast_region_c1438200 do
      code { "1438200" }
      name { "神奈川県箱根町" }
      yomi { "かながわけんはこねまち" }
      short_name { "箱根町" }
      short_yomi { "はこねまち" }
    end

    factory :jmaxml_forecast_region_c1438300 do
      code { "1438300" }
      name { "神奈川県真鶴町" }
      yomi { "かながわけんまなづるまち" }
      short_name { "真鶴町" }
      short_yomi { "まなづるまち" }
    end

    factory :jmaxml_forecast_region_c1438400 do
      code { "1438400" }
      name { "神奈川県湯河原町" }
      yomi { "かながわけんゆがわらまち" }
      short_name { "湯河原町" }
      short_yomi { "ゆがわらまち" }
    end

    factory :jmaxml_forecast_region_c1440100 do
      code { "1440100" }
      name { "神奈川県愛川町" }
      yomi { "かながわけんあいかわまち" }
      short_name { "愛川町" }
      short_yomi { "あいかわまち" }
    end

    factory :jmaxml_forecast_region_c1440200 do
      code { "1440200" }
      name { "神奈川県清川村" }
      yomi { "かながわけんきよかわむら" }
      short_name { "清川村" }
      short_yomi { "きよかわむら" }
    end

    factory :jmaxml_forecast_region_c1510000 do
      code { "1510000" }
      name { "新潟県新潟市" }
      yomi { "にいがたけんにいがたし" }
      short_name { "新潟市" }
      short_yomi { "にいがたし" }
    end

    factory :jmaxml_forecast_region_c1520200 do
      code { "1520200" }
      name { "新潟県長岡市" }
      yomi { "にいがたけんながおかし" }
      short_name { "長岡市" }
      short_yomi { "ながおかし" }
    end

    factory :jmaxml_forecast_region_c1520400 do
      code { "1520400" }
      name { "新潟県三条市" }
      yomi { "にいがたけんさんじょうし" }
      short_name { "三条市" }
      short_yomi { "さんじょうし" }
    end

    factory :jmaxml_forecast_region_c1520500 do
      code { "1520500" }
      name { "新潟県柏崎市" }
      yomi { "にいがたけんかしわざきし" }
      short_name { "柏崎市" }
      short_yomi { "かしわざきし" }
    end

    factory :jmaxml_forecast_region_c1520600 do
      code { "1520600" }
      name { "新潟県新発田市" }
      yomi { "にいがたけんしばたし" }
      short_name { "新発田市" }
      short_yomi { "しばたし" }
    end

    factory :jmaxml_forecast_region_c1520800 do
      code { "1520800" }
      name { "新潟県小千谷市" }
      yomi { "にいがたけんおぢやし" }
      short_name { "小千谷市" }
      short_yomi { "おぢやし" }
    end

    factory :jmaxml_forecast_region_c1520900 do
      code { "1520900" }
      name { "新潟県加茂市" }
      yomi { "にいがたけんかもし" }
      short_name { "加茂市" }
      short_yomi { "かもし" }
    end

    factory :jmaxml_forecast_region_c1521000 do
      code { "1521000" }
      name { "新潟県十日町市" }
      yomi { "にいがたけんとおかまちし" }
      short_name { "十日町市" }
      short_yomi { "とおかまちし" }
    end

    factory :jmaxml_forecast_region_c1521100 do
      code { "1521100" }
      name { "新潟県見附市" }
      yomi { "にいがたけんみつけし" }
      short_name { "見附市" }
      short_yomi { "みつけし" }
    end

    factory :jmaxml_forecast_region_c1521200 do
      code { "1521200" }
      name { "新潟県村上市" }
      yomi { "にいがたけんむらかみし" }
      short_name { "村上市" }
      short_yomi { "むらかみし" }
    end

    factory :jmaxml_forecast_region_c1521300 do
      code { "1521300" }
      name { "新潟県燕市" }
      yomi { "にいがたけんつばめし" }
      short_name { "燕市" }
      short_yomi { "つばめし" }
    end

    factory :jmaxml_forecast_region_c1521600 do
      code { "1521600" }
      name { "新潟県糸魚川市" }
      yomi { "にいがたけんいといがわし" }
      short_name { "糸魚川市" }
      short_yomi { "いといがわし" }
    end

    factory :jmaxml_forecast_region_c1521700 do
      code { "1521700" }
      name { "新潟県妙高市" }
      yomi { "にいがたけんみょうこうし" }
      short_name { "妙高市" }
      short_yomi { "みょうこうし" }
    end

    factory :jmaxml_forecast_region_c1521800 do
      code { "1521800" }
      name { "新潟県五泉市" }
      yomi { "にいがたけんごせんし" }
      short_name { "五泉市" }
      short_yomi { "ごせんし" }
    end

    factory :jmaxml_forecast_region_c1522200 do
      code { "1522200" }
      name { "新潟県上越市" }
      yomi { "にいがたけんじょうえつし" }
      short_name { "上越市" }
      short_yomi { "じょうえつし" }
    end

    factory :jmaxml_forecast_region_c1522300 do
      code { "1522300" }
      name { "新潟県阿賀野市" }
      yomi { "にいがたけんあがのし" }
      short_name { "阿賀野市" }
      short_yomi { "あがのし" }
    end

    factory :jmaxml_forecast_region_c1522400 do
      code { "1522400" }
      name { "新潟県佐渡市" }
      yomi { "にいがたけんさどし" }
      short_name { "佐渡市" }
      short_yomi { "さどし" }
    end

    factory :jmaxml_forecast_region_c1522500 do
      code { "1522500" }
      name { "新潟県魚沼市" }
      yomi { "にいがたけんうおぬまし" }
      short_name { "魚沼市" }
      short_yomi { "うおぬまし" }
    end

    factory :jmaxml_forecast_region_c1522600 do
      code { "1522600" }
      name { "新潟県南魚沼市" }
      yomi { "にいがたけんみなみうおぬまし" }
      short_name { "南魚沼市" }
      short_yomi { "みなみうおぬまし" }
    end

    factory :jmaxml_forecast_region_c1522700 do
      code { "1522700" }
      name { "新潟県胎内市" }
      yomi { "にいがたけんたいないし" }
      short_name { "胎内市" }
      short_yomi { "たいないし" }
    end

    factory :jmaxml_forecast_region_c1530700 do
      code { "1530700" }
      name { "新潟県聖籠町" }
      yomi { "にいがたけんせいろうまち" }
      short_name { "聖籠町" }
      short_yomi { "せいろうまち" }
    end

    factory :jmaxml_forecast_region_c1534200 do
      code { "1534200" }
      name { "新潟県弥彦村" }
      yomi { "にいがたけんやひこむら" }
      short_name { "弥彦村" }
      short_yomi { "やひこむら" }
    end

    factory :jmaxml_forecast_region_c1536100 do
      code { "1536100" }
      name { "新潟県田上町" }
      yomi { "にいがたけんたがみまち" }
      short_name { "田上町" }
      short_yomi { "たがみまち" }
    end

    factory :jmaxml_forecast_region_c1538500 do
      code { "1538500" }
      name { "新潟県阿賀町" }
      yomi { "にいがたけんあがまち" }
      short_name { "阿賀町" }
      short_yomi { "あがまち" }
    end

    factory :jmaxml_forecast_region_c1540500 do
      code { "1540500" }
      name { "新潟県出雲崎町" }
      yomi { "にいがたけんいずもざきまち" }
      short_name { "出雲崎町" }
      short_yomi { "いずもざきまち" }
    end

    factory :jmaxml_forecast_region_c1546100 do
      code { "1546100" }
      name { "新潟県湯沢町" }
      yomi { "にいがたけんゆざわまち" }
      short_name { "湯沢町" }
      short_yomi { "ゆざわまち" }
    end

    factory :jmaxml_forecast_region_c1548200 do
      code { "1548200" }
      name { "新潟県津南町" }
      yomi { "にいがたけんつなんまち" }
      short_name { "津南町" }
      short_yomi { "つなんまち" }
    end

    factory :jmaxml_forecast_region_c1550400 do
      code { "1550400" }
      name { "新潟県刈羽村" }
      yomi { "にいがたけんかりわむら" }
      short_name { "刈羽村" }
      short_yomi { "かりわむら" }
    end

    factory :jmaxml_forecast_region_c1558100 do
      code { "1558100" }
      name { "新潟県関川村" }
      yomi { "にいがたけんせきかわむら" }
      short_name { "関川村" }
      short_yomi { "せきかわむら" }
    end

    factory :jmaxml_forecast_region_c1558600 do
      code { "1558600" }
      name { "新潟県粟島浦村" }
      yomi { "にいがたけんあわしまうらむら" }
      short_name { "粟島浦村" }
      short_yomi { "あわしまうらむら" }
    end

    factory :jmaxml_forecast_region_c1620100 do
      code { "1620100" }
      name { "富山県富山市" }
      yomi { "とやまけんとやまし" }
      short_name { "富山市" }
      short_yomi { "とやまし" }
    end

    factory :jmaxml_forecast_region_c1620200 do
      code { "1620200" }
      name { "富山県高岡市" }
      yomi { "とやまけんたかおかし" }
      short_name { "高岡市" }
      short_yomi { "たかおかし" }
    end

    factory :jmaxml_forecast_region_c1620400 do
      code { "1620400" }
      name { "富山県魚津市" }
      yomi { "とやまけんうおづし" }
      short_name { "魚津市" }
      short_yomi { "うおづし" }
    end

    factory :jmaxml_forecast_region_c1620500 do
      code { "1620500" }
      name { "富山県氷見市" }
      yomi { "とやまけんひみし" }
      short_name { "氷見市" }
      short_yomi { "ひみし" }
    end

    factory :jmaxml_forecast_region_c1620600 do
      code { "1620600" }
      name { "富山県滑川市" }
      yomi { "とやまけんなめりかわし" }
      short_name { "滑川市" }
      short_yomi { "なめりかわし" }
    end

    factory :jmaxml_forecast_region_c1620700 do
      code { "1620700" }
      name { "富山県黒部市" }
      yomi { "とやまけんくろべし" }
      short_name { "黒部市" }
      short_yomi { "くろべし" }
    end

    factory :jmaxml_forecast_region_c1620800 do
      code { "1620800" }
      name { "富山県砺波市" }
      yomi { "とやまけんとなみし" }
      short_name { "砺波市" }
      short_yomi { "となみし" }
    end

    factory :jmaxml_forecast_region_c1620900 do
      code { "1620900" }
      name { "富山県小矢部市" }
      yomi { "とやまけんおやべし" }
      short_name { "小矢部市" }
      short_yomi { "おやべし" }
    end

    factory :jmaxml_forecast_region_c1621000 do
      code { "1621000" }
      name { "富山県南砺市" }
      yomi { "とやまけんなんとし" }
      short_name { "南砺市" }
      short_yomi { "なんとし" }
    end

    factory :jmaxml_forecast_region_c1621100 do
      code { "1621100" }
      name { "富山県射水市" }
      yomi { "とやまけんいみずし" }
      short_name { "射水市" }
      short_yomi { "いみずし" }
    end

    factory :jmaxml_forecast_region_c1632100 do
      code { "1632100" }
      name { "富山県舟橋村" }
      yomi { "とやまけんふなはしむら" }
      short_name { "舟橋村" }
      short_yomi { "ふなはしむら" }
    end

    factory :jmaxml_forecast_region_c1632200 do
      code { "1632200" }
      name { "富山県上市町" }
      yomi { "とやまけんかみいちまち" }
      short_name { "上市町" }
      short_yomi { "かみいちまち" }
    end

    factory :jmaxml_forecast_region_c1632300 do
      code { "1632300" }
      name { "富山県立山町" }
      yomi { "とやまけんたてやままち" }
      short_name { "立山町" }
      short_yomi { "たてやままち" }
    end

    factory :jmaxml_forecast_region_c1634200 do
      code { "1634200" }
      name { "富山県入善町" }
      yomi { "とやまけんにゅうぜんまち" }
      short_name { "入善町" }
      short_yomi { "にゅうぜんまち" }
    end

    factory :jmaxml_forecast_region_c1634300 do
      code { "1634300" }
      name { "富山県朝日町" }
      yomi { "とやまけんあさひまち" }
      short_name { "朝日町" }
      short_yomi { "あさひまち" }
    end

    factory :jmaxml_forecast_region_c1720100 do
      code { "1720100" }
      name { "石川県金沢市" }
      yomi { "いしかわけんかなざわし" }
      short_name { "金沢市" }
      short_yomi { "かなざわし" }
    end

    factory :jmaxml_forecast_region_c1720200 do
      code { "1720200" }
      name { "石川県七尾市" }
      yomi { "いしかわけんななおし" }
      short_name { "七尾市" }
      short_yomi { "ななおし" }
    end

    factory :jmaxml_forecast_region_c1720300 do
      code { "1720300" }
      name { "石川県小松市" }
      yomi { "いしかわけんこまつし" }
      short_name { "小松市" }
      short_yomi { "こまつし" }
    end

    factory :jmaxml_forecast_region_c1720400 do
      code { "1720400" }
      name { "石川県輪島市" }
      yomi { "いしかわけんわじまし" }
      short_name { "輪島市" }
      short_yomi { "わじまし" }
    end

    factory :jmaxml_forecast_region_c1720500 do
      code { "1720500" }
      name { "石川県珠洲市" }
      yomi { "いしかわけんすずし" }
      short_name { "珠洲市" }
      short_yomi { "すずし" }
    end

    factory :jmaxml_forecast_region_c1720600 do
      code { "1720600" }
      name { "石川県加賀市" }
      yomi { "いしかわけんかがし" }
      short_name { "加賀市" }
      short_yomi { "かがし" }
    end

    factory :jmaxml_forecast_region_c1720700 do
      code { "1720700" }
      name { "石川県羽咋市" }
      yomi { "いしかわけんはくいし" }
      short_name { "羽咋市" }
      short_yomi { "はくいし" }
    end

    factory :jmaxml_forecast_region_c1720900 do
      code { "1720900" }
      name { "石川県かほく市" }
      yomi { "いしかわけんかほくし" }
      short_name { "かほく市" }
      short_yomi { "かほくし" }
    end

    factory :jmaxml_forecast_region_c1721000 do
      code { "1721000" }
      name { "石川県白山市" }
      yomi { "いしかわけんはくさんし" }
      short_name { "白山市" }
      short_yomi { "はくさんし" }
    end

    factory :jmaxml_forecast_region_c1721100 do
      code { "1721100" }
      name { "石川県能美市" }
      yomi { "いしかわけんのみし" }
      short_name { "能美市" }
      short_yomi { "のみし" }
    end

    factory :jmaxml_forecast_region_c1721200 do
      code { "1721200" }
      name { "石川県野々市市" }
      yomi { "いしかわけんののいちし" }
      short_name { "野々市市" }
      short_yomi { "ののいちし" }
    end

    factory :jmaxml_forecast_region_c1732400 do
      code { "1732400" }
      name { "石川県川北町" }
      yomi { "いしかわけんかわきたまち" }
      short_name { "川北町" }
      short_yomi { "かわきたまち" }
    end

    factory :jmaxml_forecast_region_c1736100 do
      code { "1736100" }
      name { "石川県津幡町" }
      yomi { "いしかわけんつばたまち" }
      short_name { "津幡町" }
      short_yomi { "つばたまち" }
    end

    factory :jmaxml_forecast_region_c1736500 do
      code { "1736500" }
      name { "石川県内灘町" }
      yomi { "いしかわけんうちなだまち" }
      short_name { "内灘町" }
      short_yomi { "うちなだまち" }
    end

    factory :jmaxml_forecast_region_c1738400 do
      code { "1738400" }
      name { "石川県志賀町" }
      yomi { "いしかわけんしかまち" }
      short_name { "志賀町" }
      short_yomi { "しかまち" }
    end

    factory :jmaxml_forecast_region_c1738600 do
      code { "1738600" }
      name { "石川県宝達志水町" }
      yomi { "いしかわけんほうだつしみずちょう" }
      short_name { "宝達志水町" }
      short_yomi { "ほうだつしみずちょう" }
    end

    factory :jmaxml_forecast_region_c1740700 do
      code { "1740700" }
      name { "石川県中能登町" }
      yomi { "いしかわけんなかのとまち" }
      short_name { "中能登町" }
      short_yomi { "なかのとまち" }
    end

    factory :jmaxml_forecast_region_c1746100 do
      code { "1746100" }
      name { "石川県穴水町" }
      yomi { "いしかわけんあなみずまち" }
      short_name { "穴水町" }
      short_yomi { "あなみずまち" }
    end

    factory :jmaxml_forecast_region_c1746300 do
      code { "1746300" }
      name { "石川県能登町" }
      yomi { "いしかわけんのとちょう" }
      short_name { "能登町" }
      short_yomi { "のとちょう" }
    end

    factory :jmaxml_forecast_region_c1820100 do
      code { "1820100" }
      name { "福井県福井市" }
      yomi { "ふくいけんふくいし" }
      short_name { "福井市" }
      short_yomi { "ふくいし" }
    end

    factory :jmaxml_forecast_region_c1820200 do
      code { "1820200" }
      name { "福井県敦賀市" }
      yomi { "ふくいけんつるがし" }
      short_name { "敦賀市" }
      short_yomi { "つるがし" }
    end

    factory :jmaxml_forecast_region_c1820400 do
      code { "1820400" }
      name { "福井県小浜市" }
      yomi { "ふくいけんおばまし" }
      short_name { "小浜市" }
      short_yomi { "おばまし" }
    end

    factory :jmaxml_forecast_region_c1820500 do
      code { "1820500" }
      name { "福井県大野市" }
      yomi { "ふくいけんおおのし" }
      short_name { "大野市" }
      short_yomi { "おおのし" }
    end

    factory :jmaxml_forecast_region_c1820600 do
      code { "1820600" }
      name { "福井県勝山市" }
      yomi { "ふくいけんかつやまし" }
      short_name { "勝山市" }
      short_yomi { "かつやまし" }
    end

    factory :jmaxml_forecast_region_c1820700 do
      code { "1820700" }
      name { "福井県鯖江市" }
      yomi { "ふくいけんさばえし" }
      short_name { "鯖江市" }
      short_yomi { "さばえし" }
    end

    factory :jmaxml_forecast_region_c1820800 do
      code { "1820800" }
      name { "福井県あわら市" }
      yomi { "ふくいけんあわらし" }
      short_name { "あわら市" }
      short_yomi { "あわらし" }
    end

    factory :jmaxml_forecast_region_c1820900 do
      code { "1820900" }
      name { "福井県越前市" }
      yomi { "ふくいけんえちぜんし" }
      short_name { "越前市" }
      short_yomi { "えちぜんし" }
    end

    factory :jmaxml_forecast_region_c1821000 do
      code { "1821000" }
      name { "福井県坂井市" }
      yomi { "ふくいけんさかいし" }
      short_name { "坂井市" }
      short_yomi { "さかいし" }
    end

    factory :jmaxml_forecast_region_c1832200 do
      code { "1832200" }
      name { "福井県永平寺町" }
      yomi { "ふくいけんえいへいじちょう" }
      short_name { "永平寺町" }
      short_yomi { "えいへいじちょう" }
    end

    factory :jmaxml_forecast_region_c1838200 do
      code { "1838200" }
      name { "福井県池田町" }
      yomi { "ふくいけんいけだちょう" }
      short_name { "池田町" }
      short_yomi { "いけだちょう" }
    end

    factory :jmaxml_forecast_region_c1840400 do
      code { "1840400" }
      name { "福井県南越前町" }
      yomi { "ふくいけんみなみえちぜんちょう" }
      short_name { "南越前町" }
      short_yomi { "みなみえちぜんちょう" }
    end

    factory :jmaxml_forecast_region_c1842300 do
      code { "1842300" }
      name { "福井県越前町" }
      yomi { "ふくいけんえちぜんちょう" }
      short_name { "越前町" }
      short_yomi { "えちぜんちょう" }
    end

    factory :jmaxml_forecast_region_c1844200 do
      code { "1844200" }
      name { "福井県美浜町" }
      yomi { "ふくいけんみはまちょう" }
      short_name { "美浜町" }
      short_yomi { "みはまちょう" }
    end

    factory :jmaxml_forecast_region_c1848100 do
      code { "1848100" }
      name { "福井県高浜町" }
      yomi { "ふくいけんたかはまちょう" }
      short_name { "高浜町" }
      short_yomi { "たかはまちょう" }
    end

    factory :jmaxml_forecast_region_c1848300 do
      code { "1848300" }
      name { "福井県おおい町" }
      yomi { "ふくいけんおおいちょう" }
      short_name { "おおい町" }
      short_yomi { "おおいちょう" }
    end

    factory :jmaxml_forecast_region_c1850100 do
      code { "1850100" }
      name { "福井県若狭町" }
      yomi { "ふくいけんわかさちょう" }
      short_name { "若狭町" }
      short_yomi { "わかさちょう" }
    end

    factory :jmaxml_forecast_region_c1920100 do
      code { "1920100" }
      name { "山梨県甲府市" }
      yomi { "やまなしけんこうふし" }
      short_name { "甲府市" }
      short_yomi { "こうふし" }
    end

    factory :jmaxml_forecast_region_c1920200 do
      code { "1920200" }
      name { "山梨県富士吉田市" }
      yomi { "やまなしけんふじよしだし" }
      short_name { "富士吉田市" }
      short_yomi { "ふじよしだし" }
    end

    factory :jmaxml_forecast_region_c1920400 do
      code { "1920400" }
      name { "山梨県都留市" }
      yomi { "やまなしけんつるし" }
      short_name { "都留市" }
      short_yomi { "つるし" }
    end

    factory :jmaxml_forecast_region_c1920500 do
      code { "1920500" }
      name { "山梨県山梨市" }
      yomi { "やまなしけんやまなしし" }
      short_name { "山梨市" }
      short_yomi { "やまなしし" }
    end

    factory :jmaxml_forecast_region_c1920600 do
      code { "1920600" }
      name { "山梨県大月市" }
      yomi { "やまなしけんおおつきし" }
      short_name { "大月市" }
      short_yomi { "おおつきし" }
    end

    factory :jmaxml_forecast_region_c1920700 do
      code { "1920700" }
      name { "山梨県韮崎市" }
      yomi { "やまなしけんにらさきし" }
      short_name { "韮崎市" }
      short_yomi { "にらさきし" }
    end

    factory :jmaxml_forecast_region_c1920800 do
      code { "1920800" }
      name { "山梨県南アルプス市" }
      yomi { "やまなしけんみなみあるぷすし" }
      short_name { "南アルプス市" }
      short_yomi { "みなみあるぷすし" }
    end

    factory :jmaxml_forecast_region_c1920900 do
      code { "1920900" }
      name { "山梨県北杜市" }
      yomi { "やまなしけんほくとし" }
      short_name { "北杜市" }
      short_yomi { "ほくとし" }
    end

    factory :jmaxml_forecast_region_c1921000 do
      code { "1921000" }
      name { "山梨県甲斐市" }
      yomi { "やまなしけんかいし" }
      short_name { "甲斐市" }
      short_yomi { "かいし" }
    end

    factory :jmaxml_forecast_region_c1921100 do
      code { "1921100" }
      name { "山梨県笛吹市" }
      yomi { "やまなしけんふえふきし" }
      short_name { "笛吹市" }
      short_yomi { "ふえふきし" }
    end

    factory :jmaxml_forecast_region_c1921200 do
      code { "1921200" }
      name { "山梨県上野原市" }
      yomi { "やまなしけんうえのはらし" }
      short_name { "上野原市" }
      short_yomi { "うえのはらし" }
    end

    factory :jmaxml_forecast_region_c1921300 do
      code { "1921300" }
      name { "山梨県甲州市" }
      yomi { "やまなしけんこうしゅうし" }
      short_name { "甲州市" }
      short_yomi { "こうしゅうし" }
    end

    factory :jmaxml_forecast_region_c1921400 do
      code { "1921400" }
      name { "山梨県中央市" }
      yomi { "やまなしけんちゅうおうし" }
      short_name { "中央市" }
      short_yomi { "ちゅうおうし" }
    end

    factory :jmaxml_forecast_region_c1934600 do
      code { "1934600" }
      name { "山梨県市川三郷町" }
      yomi { "やまなしけんいちかわみさとちょう" }
      short_name { "市川三郷町" }
      short_yomi { "いちかわみさとちょう" }
    end

    factory :jmaxml_forecast_region_c1936400 do
      code { "1936400" }
      name { "山梨県早川町" }
      yomi { "やまなしけんはやかわちょう" }
      short_name { "早川町" }
      short_yomi { "はやかわちょう" }
    end

    factory :jmaxml_forecast_region_c1936500 do
      code { "1936500" }
      name { "山梨県身延町" }
      yomi { "やまなしけんみのぶちょう" }
      short_name { "身延町" }
      short_yomi { "みのぶちょう" }
    end

    factory :jmaxml_forecast_region_c1936600 do
      code { "1936600" }
      name { "山梨県南部町" }
      yomi { "やまなしけんなんぶちょう" }
      short_name { "南部町" }
      short_yomi { "なんぶちょう" }
    end

    factory :jmaxml_forecast_region_c1936800 do
      code { "1936800" }
      name { "山梨県富士川町" }
      yomi { "やまなしけんふじかわちょう" }
      short_name { "富士川町" }
      short_yomi { "ふじかわちょう" }
    end

    factory :jmaxml_forecast_region_c1938400 do
      code { "1938400" }
      name { "山梨県昭和町" }
      yomi { "やまなしけんしょうわちょう" }
      short_name { "昭和町" }
      short_yomi { "しょうわちょう" }
    end

    factory :jmaxml_forecast_region_c1942200 do
      code { "1942200" }
      name { "山梨県道志村" }
      yomi { "やまなしけんどうしむら" }
      short_name { "道志村" }
      short_yomi { "どうしむら" }
    end

    factory :jmaxml_forecast_region_c1942300 do
      code { "1942300" }
      name { "山梨県西桂町" }
      yomi { "やまなしけんにしかつらちょう" }
      short_name { "西桂町" }
      short_yomi { "にしかつらちょう" }
    end

    factory :jmaxml_forecast_region_c1942400 do
      code { "1942400" }
      name { "山梨県忍野村" }
      yomi { "やまなしけんおしのむら" }
      short_name { "忍野村" }
      short_yomi { "おしのむら" }
    end

    factory :jmaxml_forecast_region_c1942500 do
      code { "1942500" }
      name { "山梨県山中湖村" }
      yomi { "やまなしけんやまなかこむら" }
      short_name { "山中湖村" }
      short_yomi { "やまなかこむら" }
    end

    factory :jmaxml_forecast_region_c1942900 do
      code { "1942900" }
      name { "山梨県鳴沢村" }
      yomi { "やまなしけんなるさわむら" }
      short_name { "鳴沢村" }
      short_yomi { "なるさわむら" }
    end

    factory :jmaxml_forecast_region_c1943000 do
      code { "1943000" }
      name { "山梨県富士河口湖町" }
      yomi { "やまなしけんふじかわぐちこまち" }
      short_name { "富士河口湖町" }
      short_yomi { "ふじかわぐちこまち" }
    end

    factory :jmaxml_forecast_region_c1944200 do
      code { "1944200" }
      name { "山梨県小菅村" }
      yomi { "やまなしけんこすげむら" }
      short_name { "小菅村" }
      short_yomi { "こすげむら" }
    end

    factory :jmaxml_forecast_region_c1944300 do
      code { "1944300" }
      name { "山梨県丹波山村" }
      yomi { "やまなしけんたばやまむら" }
      short_name { "丹波山村" }
      short_yomi { "たばやまむら" }
    end

    factory :jmaxml_forecast_region_c2020100 do
      code { "2020100" }
      name { "長野県長野市" }
      yomi { "ながのけんながのし" }
      short_name { "長野市" }
      short_yomi { "ながのし" }
    end

    factory :jmaxml_forecast_region_c2020200 do
      code { "2020200" }
      name { "長野県松本市" }
      yomi { "ながのけんまつもとし" }
      short_name { "松本市" }
      short_yomi { "まつもとし" }
    end

    factory :jmaxml_forecast_region_c2020300 do
      code { "2020300" }
      name { "長野県上田市" }
      yomi { "ながのけんうえだし" }
      short_name { "上田市" }
      short_yomi { "うえだし" }
    end

    factory :jmaxml_forecast_region_c2020400 do
      code { "2020400" }
      name { "長野県岡谷市" }
      yomi { "ながのけんおかやし" }
      short_name { "岡谷市" }
      short_yomi { "おかやし" }
    end

    factory :jmaxml_forecast_region_c2020500 do
      code { "2020500" }
      name { "長野県飯田市" }
      yomi { "ながのけんいいだし" }
      short_name { "飯田市" }
      short_yomi { "いいだし" }
    end

    factory :jmaxml_forecast_region_c2020600 do
      code { "2020600" }
      name { "長野県諏訪市" }
      yomi { "ながのけんすわし" }
      short_name { "諏訪市" }
      short_yomi { "すわし" }
    end

    factory :jmaxml_forecast_region_c2020700 do
      code { "2020700" }
      name { "長野県須坂市" }
      yomi { "ながのけんすざかし" }
      short_name { "須坂市" }
      short_yomi { "すざかし" }
    end

    factory :jmaxml_forecast_region_c2020800 do
      code { "2020800" }
      name { "長野県小諸市" }
      yomi { "ながのけんこもろし" }
      short_name { "小諸市" }
      short_yomi { "こもろし" }
    end

    factory :jmaxml_forecast_region_c2020900 do
      code { "2020900" }
      name { "長野県伊那市" }
      yomi { "ながのけんいなし" }
      short_name { "伊那市" }
      short_yomi { "いなし" }
    end

    factory :jmaxml_forecast_region_c2021000 do
      code { "2021000" }
      name { "長野県駒ヶ根市" }
      yomi { "ながのけんこまがねし" }
      short_name { "駒ヶ根市" }
      short_yomi { "こまがねし" }
    end

    factory :jmaxml_forecast_region_c2021100 do
      code { "2021100" }
      name { "長野県中野市" }
      yomi { "ながのけんなかのし" }
      short_name { "中野市" }
      short_yomi { "なかのし" }
    end

    factory :jmaxml_forecast_region_c2021200 do
      code { "2021200" }
      name { "長野県大町市" }
      yomi { "ながのけんおおまちし" }
      short_name { "大町市" }
      short_yomi { "おおまちし" }
    end

    factory :jmaxml_forecast_region_c2021300 do
      code { "2021300" }
      name { "長野県飯山市" }
      yomi { "ながのけんいいやまし" }
      short_name { "飯山市" }
      short_yomi { "いいやまし" }
    end

    factory :jmaxml_forecast_region_c2021400 do
      code { "2021400" }
      name { "長野県茅野市" }
      yomi { "ながのけんちのし" }
      short_name { "茅野市" }
      short_yomi { "ちのし" }
    end

    factory :jmaxml_forecast_region_c2021500 do
      code { "2021500" }
      name { "長野県塩尻市" }
      yomi { "ながのけんしおじりし" }
      short_name { "塩尻市" }
      short_yomi { "しおじりし" }
    end

    factory :jmaxml_forecast_region_c2021700 do
      code { "2021700" }
      name { "長野県佐久市" }
      yomi { "ながのけんさくし" }
      short_name { "佐久市" }
      short_yomi { "さくし" }
    end

    factory :jmaxml_forecast_region_c2021800 do
      code { "2021800" }
      name { "長野県千曲市" }
      yomi { "ながのけんちくまし" }
      short_name { "千曲市" }
      short_yomi { "ちくまし" }
    end

    factory :jmaxml_forecast_region_c2021900 do
      code { "2021900" }
      name { "長野県東御市" }
      yomi { "ながのけんとうみし" }
      short_name { "東御市" }
      short_yomi { "とうみし" }
    end

    factory :jmaxml_forecast_region_c2022000 do
      code { "2022000" }
      name { "長野県安曇野市" }
      yomi { "ながのけんあづみのし" }
      short_name { "安曇野市" }
      short_yomi { "あづみのし" }
    end

    factory :jmaxml_forecast_region_c2030300 do
      code { "2030300" }
      name { "長野県小海町" }
      yomi { "ながのけんこうみまち" }
      short_name { "小海町" }
      short_yomi { "こうみまち" }
    end

    factory :jmaxml_forecast_region_c2030400 do
      code { "2030400" }
      name { "長野県川上村" }
      yomi { "ながのけんかわかみむら" }
      short_name { "川上村" }
      short_yomi { "かわかみむら" }
    end

    factory :jmaxml_forecast_region_c2030500 do
      code { "2030500" }
      name { "長野県南牧村" }
      yomi { "ながのけんみなみまきむら" }
      short_name { "南牧村" }
      short_yomi { "みなみまきむら" }
    end

    factory :jmaxml_forecast_region_c2030600 do
      code { "2030600" }
      name { "長野県南相木村" }
      yomi { "ながのけんみなみあいきむら" }
      short_name { "南相木村" }
      short_yomi { "みなみあいきむら" }
    end

    factory :jmaxml_forecast_region_c2030700 do
      code { "2030700" }
      name { "長野県北相木村" }
      yomi { "ながのけんきたあいきむら" }
      short_name { "北相木村" }
      short_yomi { "きたあいきむら" }
    end

    factory :jmaxml_forecast_region_c2030900 do
      code { "2030900" }
      name { "長野県佐久穂町" }
      yomi { "ながのけんさくほまち" }
      short_name { "佐久穂町" }
      short_yomi { "さくほまち" }
    end

    factory :jmaxml_forecast_region_c2032100 do
      code { "2032100" }
      name { "長野県軽井沢町" }
      yomi { "ながのけんかるいざわまち" }
      short_name { "軽井沢町" }
      short_yomi { "かるいざわまち" }
    end

    factory :jmaxml_forecast_region_c2032300 do
      code { "2032300" }
      name { "長野県御代田町" }
      yomi { "ながのけんみよたまち" }
      short_name { "御代田町" }
      short_yomi { "みよたまち" }
    end

    factory :jmaxml_forecast_region_c2032400 do
      code { "2032400" }
      name { "長野県立科町" }
      yomi { "ながのけんたてしなまち" }
      short_name { "立科町" }
      short_yomi { "たてしなまち" }
    end

    factory :jmaxml_forecast_region_c2034900 do
      code { "2034900" }
      name { "長野県青木村" }
      yomi { "ながのけんあおきむら" }
      short_name { "青木村" }
      short_yomi { "あおきむら" }
    end

    factory :jmaxml_forecast_region_c2035000 do
      code { "2035000" }
      name { "長野県長和町" }
      yomi { "ながのけんながわまち" }
      short_name { "長和町" }
      short_yomi { "ながわまち" }
    end

    factory :jmaxml_forecast_region_c2036100 do
      code { "2036100" }
      name { "長野県下諏訪町" }
      yomi { "ながのけんしもすわまち" }
      short_name { "下諏訪町" }
      short_yomi { "しもすわまち" }
    end

    factory :jmaxml_forecast_region_c2036200 do
      code { "2036200" }
      name { "長野県富士見町" }
      yomi { "ながのけんふじみまち" }
      short_name { "富士見町" }
      short_yomi { "ふじみまち" }
    end

    factory :jmaxml_forecast_region_c2036300 do
      code { "2036300" }
      name { "長野県原村" }
      yomi { "ながのけんはらむら" }
      short_name { "原村" }
      short_yomi { "はらむら" }
    end

    factory :jmaxml_forecast_region_c2038200 do
      code { "2038200" }
      name { "長野県辰野町" }
      yomi { "ながのけんたつのまち" }
      short_name { "辰野町" }
      short_yomi { "たつのまち" }
    end

    factory :jmaxml_forecast_region_c2038300 do
      code { "2038300" }
      name { "長野県箕輪町" }
      yomi { "ながのけんみのわまち" }
      short_name { "箕輪町" }
      short_yomi { "みのわまち" }
    end

    factory :jmaxml_forecast_region_c2038400 do
      code { "2038400" }
      name { "長野県飯島町" }
      yomi { "ながのけんいいじままち" }
      short_name { "飯島町" }
      short_yomi { "いいじままち" }
    end

    factory :jmaxml_forecast_region_c2038500 do
      code { "2038500" }
      name { "長野県南箕輪村" }
      yomi { "ながのけんみなみみのわむら" }
      short_name { "南箕輪村" }
      short_yomi { "みなみみのわむら" }
    end

    factory :jmaxml_forecast_region_c2038600 do
      code { "2038600" }
      name { "長野県中川村" }
      yomi { "ながのけんなかがわむら" }
      short_name { "中川村" }
      short_yomi { "なかがわむら" }
    end

    factory :jmaxml_forecast_region_c2038800 do
      code { "2038800" }
      name { "長野県宮田村" }
      yomi { "ながのけんみやだむら" }
      short_name { "宮田村" }
      short_yomi { "みやだむら" }
    end

    factory :jmaxml_forecast_region_c2040200 do
      code { "2040200" }
      name { "長野県松川町" }
      yomi { "ながのけんまつかわまち" }
      short_name { "松川町" }
      short_yomi { "まつかわまち" }
    end

    factory :jmaxml_forecast_region_c2040300 do
      code { "2040300" }
      name { "長野県高森町" }
      yomi { "ながのけんたかもりまち" }
      short_name { "高森町" }
      short_yomi { "たかもりまち" }
    end

    factory :jmaxml_forecast_region_c2040400 do
      code { "2040400" }
      name { "長野県阿南町" }
      yomi { "ながのけんあなんちょう" }
      short_name { "阿南町" }
      short_yomi { "あなんちょう" }
    end

    factory :jmaxml_forecast_region_c2040700 do
      code { "2040700" }
      name { "長野県阿智村" }
      yomi { "ながのけんあちむら" }
      short_name { "阿智村" }
      short_yomi { "あちむら" }
    end

    factory :jmaxml_forecast_region_c2040900 do
      code { "2040900" }
      name { "長野県平谷村" }
      yomi { "ながのけんひらやむら" }
      short_name { "平谷村" }
      short_yomi { "ひらやむら" }
    end

    factory :jmaxml_forecast_region_c2041000 do
      code { "2041000" }
      name { "長野県根羽村" }
      yomi { "ながのけんねばむら" }
      short_name { "根羽村" }
      short_yomi { "ねばむら" }
    end

    factory :jmaxml_forecast_region_c2041100 do
      code { "2041100" }
      name { "長野県下條村" }
      yomi { "ながのけんしもじょうむら" }
      short_name { "下條村" }
      short_yomi { "しもじょうむら" }
    end

    factory :jmaxml_forecast_region_c2041200 do
      code { "2041200" }
      name { "長野県売木村" }
      yomi { "ながのけんうるぎむら" }
      short_name { "売木村" }
      short_yomi { "うるぎむら" }
    end

    factory :jmaxml_forecast_region_c2041300 do
      code { "2041300" }
      name { "長野県天龍村" }
      yomi { "ながのけんてんりゅうむら" }
      short_name { "天龍村" }
      short_yomi { "てんりゅうむら" }
    end

    factory :jmaxml_forecast_region_c2041400 do
      code { "2041400" }
      name { "長野県泰阜村" }
      yomi { "ながのけんやすおかむら" }
      short_name { "泰阜村" }
      short_yomi { "やすおかむら" }
    end

    factory :jmaxml_forecast_region_c2041500 do
      code { "2041500" }
      name { "長野県喬木村" }
      yomi { "ながのけんたかぎむら" }
      short_name { "喬木村" }
      short_yomi { "たかぎむら" }
    end

    factory :jmaxml_forecast_region_c2041600 do
      code { "2041600" }
      name { "長野県豊丘村" }
      yomi { "ながのけんとよおかむら" }
      short_name { "豊丘村" }
      short_yomi { "とよおかむら" }
    end

    factory :jmaxml_forecast_region_c2041700 do
      code { "2041700" }
      name { "長野県大鹿村" }
      yomi { "ながのけんおおしかむら" }
      short_name { "大鹿村" }
      short_yomi { "おおしかむら" }
    end

    factory :jmaxml_forecast_region_c2042200 do
      code { "2042200" }
      name { "長野県上松町" }
      yomi { "ながのけんあげまつまち" }
      short_name { "上松町" }
      short_yomi { "あげまつまち" }
    end

    factory :jmaxml_forecast_region_c2042300 do
      code { "2042300" }
      name { "長野県南木曽町" }
      yomi { "ながのけんなぎそまち" }
      short_name { "南木曽町" }
      short_yomi { "なぎそまち" }
    end

    factory :jmaxml_forecast_region_c2042500 do
      code { "2042500" }
      name { "長野県木祖村" }
      yomi { "ながのけんきそむら" }
      short_name { "木祖村" }
      short_yomi { "きそむら" }
    end

    factory :jmaxml_forecast_region_c2042900 do
      code { "2042900" }
      name { "長野県王滝村" }
      yomi { "ながのけんおうたきむら" }
      short_name { "王滝村" }
      short_yomi { "おうたきむら" }
    end

    factory :jmaxml_forecast_region_c2043000 do
      code { "2043000" }
      name { "長野県大桑村" }
      yomi { "ながのけんおおくわむら" }
      short_name { "大桑村" }
      short_yomi { "おおくわむら" }
    end

    factory :jmaxml_forecast_region_c2043200 do
      code { "2043200" }
      name { "長野県木曽町" }
      yomi { "ながのけんきそまち" }
      short_name { "木曽町" }
      short_yomi { "きそまち" }
    end

    factory :jmaxml_forecast_region_c2044600 do
      code { "2044600" }
      name { "長野県麻績村" }
      yomi { "ながのけんおみむら" }
      short_name { "麻績村" }
      short_yomi { "おみむら" }
    end

    factory :jmaxml_forecast_region_c2044800 do
      code { "2044800" }
      name { "長野県生坂村" }
      yomi { "ながのけんいくさかむら" }
      short_name { "生坂村" }
      short_yomi { "いくさかむら" }
    end

    factory :jmaxml_forecast_region_c2045000 do
      code { "2045000" }
      name { "長野県山形村" }
      yomi { "ながのけんやまがたむら" }
      short_name { "山形村" }
      short_yomi { "やまがたむら" }
    end

    factory :jmaxml_forecast_region_c2045100 do
      code { "2045100" }
      name { "長野県朝日村" }
      yomi { "ながのけんあさひむら" }
      short_name { "朝日村" }
      short_yomi { "あさひむら" }
    end

    factory :jmaxml_forecast_region_c2045200 do
      code { "2045200" }
      name { "長野県筑北村" }
      yomi { "ながのけんちくほくむら" }
      short_name { "筑北村" }
      short_yomi { "ちくほくむら" }
    end

    factory :jmaxml_forecast_region_c2048100 do
      code { "2048100" }
      name { "長野県池田町" }
      yomi { "ながのけんいけだまち" }
      short_name { "池田町" }
      short_yomi { "いけだまち" }
    end

    factory :jmaxml_forecast_region_c2048200 do
      code { "2048200" }
      name { "長野県松川村" }
      yomi { "ながのけんまつかわむら" }
      short_name { "松川村" }
      short_yomi { "まつかわむら" }
    end

    factory :jmaxml_forecast_region_c2048500 do
      code { "2048500" }
      name { "長野県白馬村" }
      yomi { "ながのけんはくばむら" }
      short_name { "白馬村" }
      short_yomi { "はくばむら" }
    end

    factory :jmaxml_forecast_region_c2048600 do
      code { "2048600" }
      name { "長野県小谷村" }
      yomi { "ながのけんおたりむら" }
      short_name { "小谷村" }
      short_yomi { "おたりむら" }
    end

    factory :jmaxml_forecast_region_c2052100 do
      code { "2052100" }
      name { "長野県坂城町" }
      yomi { "ながのけんさかきまち" }
      short_name { "坂城町" }
      short_yomi { "さかきまち" }
    end

    factory :jmaxml_forecast_region_c2054100 do
      code { "2054100" }
      name { "長野県小布施町" }
      yomi { "ながのけんおぶせまち" }
      short_name { "小布施町" }
      short_yomi { "おぶせまち" }
    end

    factory :jmaxml_forecast_region_c2054300 do
      code { "2054300" }
      name { "長野県高山村" }
      yomi { "ながのけんたかやまむら" }
      short_name { "高山村" }
      short_yomi { "たかやまむら" }
    end

    factory :jmaxml_forecast_region_c2056100 do
      code { "2056100" }
      name { "長野県山ノ内町" }
      yomi { "ながのけんやまのうちまち" }
      short_name { "山ノ内町" }
      short_yomi { "やまのうちまち" }
    end

    factory :jmaxml_forecast_region_c2056200 do
      code { "2056200" }
      name { "長野県木島平村" }
      yomi { "ながのけんきじまだいらむら" }
      short_name { "木島平村" }
      short_yomi { "きじまだいらむら" }
    end

    factory :jmaxml_forecast_region_c2056300 do
      code { "2056300" }
      name { "長野県野沢温泉村" }
      yomi { "ながのけんのざわおんせんむら" }
      short_name { "野沢温泉村" }
      short_yomi { "のざわおんせんむら" }
    end

    factory :jmaxml_forecast_region_c2058300 do
      code { "2058300" }
      name { "長野県信濃町" }
      yomi { "ながのけんしなのまち" }
      short_name { "信濃町" }
      short_yomi { "しなのまち" }
    end

    factory :jmaxml_forecast_region_c2058800 do
      code { "2058800" }
      name { "長野県小川村" }
      yomi { "ながのけんおがわむら" }
      short_name { "小川村" }
      short_yomi { "おがわむら" }
    end

    factory :jmaxml_forecast_region_c2059000 do
      code { "2059000" }
      name { "長野県飯綱町" }
      yomi { "ながのけんいいづなまち" }
      short_name { "飯綱町" }
      short_yomi { "いいづなまち" }
    end

    factory :jmaxml_forecast_region_c2060200 do
      code { "2060200" }
      name { "長野県栄村" }
      yomi { "ながのけんさかえむら" }
      short_name { "栄村" }
      short_yomi { "さかえむら" }
    end

    factory :jmaxml_forecast_region_c2120100 do
      code { "2120100" }
      name { "岐阜県岐阜市" }
      yomi { "ぎふけんぎふし" }
      short_name { "岐阜市" }
      short_yomi { "ぎふし" }
    end

    factory :jmaxml_forecast_region_c2120200 do
      code { "2120200" }
      name { "岐阜県大垣市" }
      yomi { "ぎふけんおおがきし" }
      short_name { "大垣市" }
      short_yomi { "おおがきし" }
    end

    factory :jmaxml_forecast_region_c2120300 do
      code { "2120300" }
      name { "岐阜県高山市" }
      yomi { "ぎふけんたかやまし" }
      short_name { "高山市" }
      short_yomi { "たかやまし" }
    end

    factory :jmaxml_forecast_region_c2120400 do
      code { "2120400" }
      name { "岐阜県多治見市" }
      yomi { "ぎふけんたじみし" }
      short_name { "多治見市" }
      short_yomi { "たじみし" }
    end

    factory :jmaxml_forecast_region_c2120500 do
      code { "2120500" }
      name { "岐阜県関市" }
      yomi { "ぎふけんせきし" }
      short_name { "関市" }
      short_yomi { "せきし" }
    end

    factory :jmaxml_forecast_region_c2120600 do
      code { "2120600" }
      name { "岐阜県中津川市" }
      yomi { "ぎふけんなかつがわし" }
      short_name { "中津川市" }
      short_yomi { "なかつがわし" }
    end

    factory :jmaxml_forecast_region_c2120700 do
      code { "2120700" }
      name { "岐阜県美濃市" }
      yomi { "ぎふけんみのし" }
      short_name { "美濃市" }
      short_yomi { "みのし" }
    end

    factory :jmaxml_forecast_region_c2120800 do
      code { "2120800" }
      name { "岐阜県瑞浪市" }
      yomi { "ぎふけんみずなみし" }
      short_name { "瑞浪市" }
      short_yomi { "みずなみし" }
    end

    factory :jmaxml_forecast_region_c2120900 do
      code { "2120900" }
      name { "岐阜県羽島市" }
      yomi { "ぎふけんはしまし" }
      short_name { "羽島市" }
      short_yomi { "はしまし" }
    end

    factory :jmaxml_forecast_region_c2121000 do
      code { "2121000" }
      name { "岐阜県恵那市" }
      yomi { "ぎふけんえなし" }
      short_name { "恵那市" }
      short_yomi { "えなし" }
    end

    factory :jmaxml_forecast_region_c2121100 do
      code { "2121100" }
      name { "岐阜県美濃加茂市" }
      yomi { "ぎふけんみのかもし" }
      short_name { "美濃加茂市" }
      short_yomi { "みのかもし" }
    end

    factory :jmaxml_forecast_region_c2121200 do
      code { "2121200" }
      name { "岐阜県土岐市" }
      yomi { "ぎふけんときし" }
      short_name { "土岐市" }
      short_yomi { "ときし" }
    end

    factory :jmaxml_forecast_region_c2121300 do
      code { "2121300" }
      name { "岐阜県各務原市" }
      yomi { "ぎふけんかかみがはらし" }
      short_name { "各務原市" }
      short_yomi { "かかみがはらし" }
    end

    factory :jmaxml_forecast_region_c2121400 do
      code { "2121400" }
      name { "岐阜県可児市" }
      yomi { "ぎふけんかにし" }
      short_name { "可児市" }
      short_yomi { "かにし" }
    end

    factory :jmaxml_forecast_region_c2121500 do
      code { "2121500" }
      name { "岐阜県山県市" }
      yomi { "ぎふけんやまがたし" }
      short_name { "山県市" }
      short_yomi { "やまがたし" }
    end

    factory :jmaxml_forecast_region_c2121600 do
      code { "2121600" }
      name { "岐阜県瑞穂市" }
      yomi { "ぎふけんみずほし" }
      short_name { "瑞穂市" }
      short_yomi { "みずほし" }
    end

    factory :jmaxml_forecast_region_c2121700 do
      code { "2121700" }
      name { "岐阜県飛騨市" }
      yomi { "ぎふけんひだし" }
      short_name { "飛騨市" }
      short_yomi { "ひだし" }
    end

    factory :jmaxml_forecast_region_c2121800 do
      code { "2121800" }
      name { "岐阜県本巣市" }
      yomi { "ぎふけんもとすし" }
      short_name { "本巣市" }
      short_yomi { "もとすし" }
    end

    factory :jmaxml_forecast_region_c2121900 do
      code { "2121900" }
      name { "岐阜県郡上市" }
      yomi { "ぎふけんぐじょうし" }
      short_name { "郡上市" }
      short_yomi { "ぐじょうし" }
    end

    factory :jmaxml_forecast_region_c2122000 do
      code { "2122000" }
      name { "岐阜県下呂市" }
      yomi { "ぎふけんげろし" }
      short_name { "下呂市" }
      short_yomi { "げろし" }
    end

    factory :jmaxml_forecast_region_c2122100 do
      code { "2122100" }
      name { "岐阜県海津市" }
      yomi { "ぎふけんかいづし" }
      short_name { "海津市" }
      short_yomi { "かいづし" }
    end

    factory :jmaxml_forecast_region_c2130200 do
      code { "2130200" }
      name { "岐阜県岐南町" }
      yomi { "ぎふけんぎなんちょう" }
      short_name { "岐南町" }
      short_yomi { "ぎなんちょう" }
    end

    factory :jmaxml_forecast_region_c2130300 do
      code { "2130300" }
      name { "岐阜県笠松町" }
      yomi { "ぎふけんかさまつちょう" }
      short_name { "笠松町" }
      short_yomi { "かさまつちょう" }
    end

    factory :jmaxml_forecast_region_c2134100 do
      code { "2134100" }
      name { "岐阜県養老町" }
      yomi { "ぎふけんようろうちょう" }
      short_name { "養老町" }
      short_yomi { "ようろうちょう" }
    end

    factory :jmaxml_forecast_region_c2136100 do
      code { "2136100" }
      name { "岐阜県垂井町" }
      yomi { "ぎふけんたるいちょう" }
      short_name { "垂井町" }
      short_yomi { "たるいちょう" }
    end

    factory :jmaxml_forecast_region_c2136200 do
      code { "2136200" }
      name { "岐阜県関ケ原町" }
      yomi { "ぎふけんせきがはらちょう" }
      short_name { "関ケ原町" }
      short_yomi { "せきがはらちょう" }
    end

    factory :jmaxml_forecast_region_c2138100 do
      code { "2138100" }
      name { "岐阜県神戸町" }
      yomi { "ぎふけんごうどちょう" }
      short_name { "神戸町" }
      short_yomi { "ごうどちょう" }
    end

    factory :jmaxml_forecast_region_c2138200 do
      code { "2138200" }
      name { "岐阜県輪之内町" }
      yomi { "ぎふけんわのうちちょう" }
      short_name { "輪之内町" }
      short_yomi { "わのうちちょう" }
    end

    factory :jmaxml_forecast_region_c2138300 do
      code { "2138300" }
      name { "岐阜県安八町" }
      yomi { "ぎふけんあんぱちちょう" }
      short_name { "安八町" }
      short_yomi { "あんぱちちょう" }
    end

    factory :jmaxml_forecast_region_c2140100 do
      code { "2140100" }
      name { "岐阜県揖斐川町" }
      yomi { "ぎふけんいびがわちょう" }
      short_name { "揖斐川町" }
      short_yomi { "いびがわちょう" }
    end

    factory :jmaxml_forecast_region_c2140300 do
      code { "2140300" }
      name { "岐阜県大野町" }
      yomi { "ぎふけんおおのちょう" }
      short_name { "大野町" }
      short_yomi { "おおのちょう" }
    end

    factory :jmaxml_forecast_region_c2140400 do
      code { "2140400" }
      name { "岐阜県池田町" }
      yomi { "ぎふけんいけだちょう" }
      short_name { "池田町" }
      short_yomi { "いけだちょう" }
    end

    factory :jmaxml_forecast_region_c2142100 do
      code { "2142100" }
      name { "岐阜県北方町" }
      yomi { "ぎふけんきたがたちょう" }
      short_name { "北方町" }
      short_yomi { "きたがたちょう" }
    end

    factory :jmaxml_forecast_region_c2150100 do
      code { "2150100" }
      name { "岐阜県坂祝町" }
      yomi { "ぎふけんさかほぎちょう" }
      short_name { "坂祝町" }
      short_yomi { "さかほぎちょう" }
    end

    factory :jmaxml_forecast_region_c2150200 do
      code { "2150200" }
      name { "岐阜県富加町" }
      yomi { "ぎふけんとみかちょう" }
      short_name { "富加町" }
      short_yomi { "とみかちょう" }
    end

    factory :jmaxml_forecast_region_c2150300 do
      code { "2150300" }
      name { "岐阜県川辺町" }
      yomi { "ぎふけんかわべちょう" }
      short_name { "川辺町" }
      short_yomi { "かわべちょう" }
    end

    factory :jmaxml_forecast_region_c2150400 do
      code { "2150400" }
      name { "岐阜県七宗町" }
      yomi { "ぎふけんひちそうちょう" }
      short_name { "七宗町" }
      short_yomi { "ひちそうちょう" }
    end

    factory :jmaxml_forecast_region_c2150500 do
      code { "2150500" }
      name { "岐阜県八百津町" }
      yomi { "ぎふけんやおつちょう" }
      short_name { "八百津町" }
      short_yomi { "やおつちょう" }
    end

    factory :jmaxml_forecast_region_c2150600 do
      code { "2150600" }
      name { "岐阜県白川町" }
      yomi { "ぎふけんしらかわちょう" }
      short_name { "白川町" }
      short_yomi { "しらかわちょう" }
    end

    factory :jmaxml_forecast_region_c2150700 do
      code { "2150700" }
      name { "岐阜県東白川村" }
      yomi { "ぎふけんひがししらかわむら" }
      short_name { "東白川村" }
      short_yomi { "ひがししらかわむら" }
    end

    factory :jmaxml_forecast_region_c2152100 do
      code { "2152100" }
      name { "岐阜県御嵩町" }
      yomi { "ぎふけんみたけちょう" }
      short_name { "御嵩町" }
      short_yomi { "みたけちょう" }
    end

    factory :jmaxml_forecast_region_c2160400 do
      code { "2160400" }
      name { "岐阜県白川村" }
      yomi { "ぎふけんしらかわむら" }
      short_name { "白川村" }
      short_yomi { "しらかわむら" }
    end

    factory :jmaxml_forecast_region_c2210000 do
      code { "2210000" }
      name { "静岡県静岡市" }
      yomi { "しずおかけんしずおかし" }
      short_name { "静岡市" }
      short_yomi { "しずおかし" }
    end

    factory :jmaxml_forecast_region_c2213000 do
      code { "2213000" }
      name { "静岡県浜松市" }
      yomi { "しずおかけんはままつし" }
      short_name { "浜松市" }
      short_yomi { "はままつし" }
    end

    factory :jmaxml_forecast_region_c2220300 do
      code { "2220300" }
      name { "静岡県沼津市" }
      yomi { "しずおかけんぬまづし" }
      short_name { "沼津市" }
      short_yomi { "ぬまづし" }
    end

    factory :jmaxml_forecast_region_c2220500 do
      code { "2220500" }
      name { "静岡県熱海市" }
      yomi { "しずおかけんあたみし" }
      short_name { "熱海市" }
      short_yomi { "あたみし" }
    end

    factory :jmaxml_forecast_region_c2220600 do
      code { "2220600" }
      name { "静岡県三島市" }
      yomi { "しずおかけんみしまし" }
      short_name { "三島市" }
      short_yomi { "みしまし" }
    end

    factory :jmaxml_forecast_region_c2220700 do
      code { "2220700" }
      name { "静岡県富士宮市" }
      yomi { "しずおかけんふじのみやし" }
      short_name { "富士宮市" }
      short_yomi { "ふじのみやし" }
    end

    factory :jmaxml_forecast_region_c2220800 do
      code { "2220800" }
      name { "静岡県伊東市" }
      yomi { "しずおかけんいとうし" }
      short_name { "伊東市" }
      short_yomi { "いとうし" }
    end

    factory :jmaxml_forecast_region_c2220900 do
      code { "2220900" }
      name { "静岡県島田市" }
      yomi { "しずおかけんしまだし" }
      short_name { "島田市" }
      short_yomi { "しまだし" }
    end

    factory :jmaxml_forecast_region_c2221000 do
      code { "2221000" }
      name { "静岡県富士市" }
      yomi { "しずおかけんふじし" }
      short_name { "富士市" }
      short_yomi { "ふじし" }
    end

    factory :jmaxml_forecast_region_c2221100 do
      code { "2221100" }
      name { "静岡県磐田市" }
      yomi { "しずおかけんいわたし" }
      short_name { "磐田市" }
      short_yomi { "いわたし" }
    end

    factory :jmaxml_forecast_region_c2221200 do
      code { "2221200" }
      name { "静岡県焼津市" }
      yomi { "しずおかけんやいづし" }
      short_name { "焼津市" }
      short_yomi { "やいづし" }
    end

    factory :jmaxml_forecast_region_c2221300 do
      code { "2221300" }
      name { "静岡県掛川市" }
      yomi { "しずおかけんかけがわし" }
      short_name { "掛川市" }
      short_yomi { "かけがわし" }
    end

    factory :jmaxml_forecast_region_c2221400 do
      code { "2221400" }
      name { "静岡県藤枝市" }
      yomi { "しずおかけんふじえだし" }
      short_name { "藤枝市" }
      short_yomi { "ふじえだし" }
    end

    factory :jmaxml_forecast_region_c2221500 do
      code { "2221500" }
      name { "静岡県御殿場市" }
      yomi { "しずおかけんごてんばし" }
      short_name { "御殿場市" }
      short_yomi { "ごてんばし" }
    end

    factory :jmaxml_forecast_region_c2221600 do
      code { "2221600" }
      name { "静岡県袋井市" }
      yomi { "しずおかけんふくろいし" }
      short_name { "袋井市" }
      short_yomi { "ふくろいし" }
    end

    factory :jmaxml_forecast_region_c2221900 do
      code { "2221900" }
      name { "静岡県下田市" }
      yomi { "しずおかけんしもだし" }
      short_name { "下田市" }
      short_yomi { "しもだし" }
    end

    factory :jmaxml_forecast_region_c2222000 do
      code { "2222000" }
      name { "静岡県裾野市" }
      yomi { "しずおかけんすそのし" }
      short_name { "裾野市" }
      short_yomi { "すそのし" }
    end

    factory :jmaxml_forecast_region_c2222100 do
      code { "2222100" }
      name { "静岡県湖西市" }
      yomi { "しずおかけんこさいし" }
      short_name { "湖西市" }
      short_yomi { "こさいし" }
    end

    factory :jmaxml_forecast_region_c2222200 do
      code { "2222200" }
      name { "静岡県伊豆市" }
      yomi { "しずおかけんいずし" }
      short_name { "伊豆市" }
      short_yomi { "いずし" }
    end

    factory :jmaxml_forecast_region_c2222300 do
      code { "2222300" }
      name { "静岡県御前崎市" }
      yomi { "しずおかけんおまえざきし" }
      short_name { "御前崎市" }
      short_yomi { "おまえざきし" }
    end

    factory :jmaxml_forecast_region_c2222400 do
      code { "2222400" }
      name { "静岡県菊川市" }
      yomi { "しずおかけんきくがわし" }
      short_name { "菊川市" }
      short_yomi { "きくがわし" }
    end

    factory :jmaxml_forecast_region_c2222500 do
      code { "2222500" }
      name { "静岡県伊豆の国市" }
      yomi { "しずおかけんいずのくにし" }
      short_name { "伊豆の国市" }
      short_yomi { "いずのくにし" }
    end

    factory :jmaxml_forecast_region_c2222600 do
      code { "2222600" }
      name { "静岡県牧之原市" }
      yomi { "しずおかけんまきのはらし" }
      short_name { "牧之原市" }
      short_yomi { "まきのはらし" }
    end

    factory :jmaxml_forecast_region_c2230100 do
      code { "2230100" }
      name { "静岡県東伊豆町" }
      yomi { "しずおかけんひがしいずちょう" }
      short_name { "東伊豆町" }
      short_yomi { "ひがしいずちょう" }
    end

    factory :jmaxml_forecast_region_c2230200 do
      code { "2230200" }
      name { "静岡県河津町" }
      yomi { "しずおかけんかわづちょう" }
      short_name { "河津町" }
      short_yomi { "かわづちょう" }
    end

    factory :jmaxml_forecast_region_c2230400 do
      code { "2230400" }
      name { "静岡県南伊豆町" }
      yomi { "しずおかけんみなみいずちょう" }
      short_name { "南伊豆町" }
      short_yomi { "みなみいずちょう" }
    end

    factory :jmaxml_forecast_region_c2230500 do
      code { "2230500" }
      name { "静岡県松崎町" }
      yomi { "しずおかけんまつざきちょう" }
      short_name { "松崎町" }
      short_yomi { "まつざきちょう" }
    end

    factory :jmaxml_forecast_region_c2230600 do
      code { "2230600" }
      name { "静岡県西伊豆町" }
      yomi { "しずおかけんにしいずちょう" }
      short_name { "西伊豆町" }
      short_yomi { "にしいずちょう" }
    end

    factory :jmaxml_forecast_region_c2232500 do
      code { "2232500" }
      name { "静岡県函南町" }
      yomi { "しずおかけんかんなみちょう" }
      short_name { "函南町" }
      short_yomi { "かんなみちょう" }
    end

    factory :jmaxml_forecast_region_c2234100 do
      code { "2234100" }
      name { "静岡県清水町" }
      yomi { "しずおかけんしみずちょう" }
      short_name { "清水町" }
      short_yomi { "しみずちょう" }
    end

    factory :jmaxml_forecast_region_c2234200 do
      code { "2234200" }
      name { "静岡県長泉町" }
      yomi { "しずおかけんながいずみちょう" }
      short_name { "長泉町" }
      short_yomi { "ながいずみちょう" }
    end

    factory :jmaxml_forecast_region_c2234400 do
      code { "2234400" }
      name { "静岡県小山町" }
      yomi { "しずおかけんおやまちょう" }
      short_name { "小山町" }
      short_yomi { "おやまちょう" }
    end

    factory :jmaxml_forecast_region_c2242400 do
      code { "2242400" }
      name { "静岡県吉田町" }
      yomi { "しずおかけんよしだちょう" }
      short_name { "吉田町" }
      short_yomi { "よしだちょう" }
    end

    factory :jmaxml_forecast_region_c2242900 do
      code { "2242900" }
      name { "静岡県川根本町" }
      yomi { "しずおかけんかわねほんちょう" }
      short_name { "川根本町" }
      short_yomi { "かわねほんちょう" }
    end

    factory :jmaxml_forecast_region_c2246100 do
      code { "2246100" }
      name { "静岡県森町" }
      yomi { "しずおかけんもりまち" }
      short_name { "森町" }
      short_yomi { "もりまち" }
    end

    factory :jmaxml_forecast_region_c2310000 do
      code { "2310000" }
      name { "愛知県名古屋市" }
      yomi { "あいちけんなごやし" }
      short_name { "名古屋市" }
      short_yomi { "なごやし" }
    end

    factory :jmaxml_forecast_region_c2320100 do
      code { "2320100" }
      name { "愛知県豊橋市" }
      yomi { "あいちけんとよはしし" }
      short_name { "豊橋市" }
      short_yomi { "とよはしし" }
    end

    factory :jmaxml_forecast_region_c2320200 do
      code { "2320200" }
      name { "愛知県岡崎市" }
      yomi { "あいちけんおかざきし" }
      short_name { "岡崎市" }
      short_yomi { "おかざきし" }
    end

    factory :jmaxml_forecast_region_c2320300 do
      code { "2320300" }
      name { "愛知県一宮市" }
      yomi { "あいちけんいちのみやし" }
      short_name { "一宮市" }
      short_yomi { "いちのみやし" }
    end

    factory :jmaxml_forecast_region_c2320400 do
      code { "2320400" }
      name { "愛知県瀬戸市" }
      yomi { "あいちけんせとし" }
      short_name { "瀬戸市" }
      short_yomi { "せとし" }
    end

    factory :jmaxml_forecast_region_c2320500 do
      code { "2320500" }
      name { "愛知県半田市" }
      yomi { "あいちけんはんだし" }
      short_name { "半田市" }
      short_yomi { "はんだし" }
    end

    factory :jmaxml_forecast_region_c2320600 do
      code { "2320600" }
      name { "愛知県春日井市" }
      yomi { "あいちけんかすがいし" }
      short_name { "春日井市" }
      short_yomi { "かすがいし" }
    end

    factory :jmaxml_forecast_region_c2320700 do
      code { "2320700" }
      name { "愛知県豊川市" }
      yomi { "あいちけんとよかわし" }
      short_name { "豊川市" }
      short_yomi { "とよかわし" }
    end

    factory :jmaxml_forecast_region_c2320800 do
      code { "2320800" }
      name { "愛知県津島市" }
      yomi { "あいちけんつしまし" }
      short_name { "津島市" }
      short_yomi { "つしまし" }
    end

    factory :jmaxml_forecast_region_c2320900 do
      code { "2320900" }
      name { "愛知県碧南市" }
      yomi { "あいちけんへきなんし" }
      short_name { "碧南市" }
      short_yomi { "へきなんし" }
    end

    factory :jmaxml_forecast_region_c2321000 do
      code { "2321000" }
      name { "愛知県刈谷市" }
      yomi { "あいちけんかりやし" }
      short_name { "刈谷市" }
      short_yomi { "かりやし" }
    end

    factory :jmaxml_forecast_region_c2321100 do
      code { "2321100" }
      name { "愛知県豊田市" }
      yomi { "あいちけんとよたし" }
      short_name { "豊田市" }
      short_yomi { "とよたし" }
    end

    factory :jmaxml_forecast_region_c2321200 do
      code { "2321200" }
      name { "愛知県安城市" }
      yomi { "あいちけんあんじょうし" }
      short_name { "安城市" }
      short_yomi { "あんじょうし" }
    end

    factory :jmaxml_forecast_region_c2321300 do
      code { "2321300" }
      name { "愛知県西尾市" }
      yomi { "あいちけんにしおし" }
      short_name { "西尾市" }
      short_yomi { "にしおし" }
    end

    factory :jmaxml_forecast_region_c2321400 do
      code { "2321400" }
      name { "愛知県蒲郡市" }
      yomi { "あいちけんがまごおりし" }
      short_name { "蒲郡市" }
      short_yomi { "がまごおりし" }
    end

    factory :jmaxml_forecast_region_c2321500 do
      code { "2321500" }
      name { "愛知県犬山市" }
      yomi { "あいちけんいぬやまし" }
      short_name { "犬山市" }
      short_yomi { "いぬやまし" }
    end

    factory :jmaxml_forecast_region_c2321600 do
      code { "2321600" }
      name { "愛知県常滑市" }
      yomi { "あいちけんとこなめし" }
      short_name { "常滑市" }
      short_yomi { "とこなめし" }
    end

    factory :jmaxml_forecast_region_c2321700 do
      code { "2321700" }
      name { "愛知県江南市" }
      yomi { "あいちけんこうなんし" }
      short_name { "江南市" }
      short_yomi { "こうなんし" }
    end

    factory :jmaxml_forecast_region_c2321900 do
      code { "2321900" }
      name { "愛知県小牧市" }
      yomi { "あいちけんこまきし" }
      short_name { "小牧市" }
      short_yomi { "こまきし" }
    end

    factory :jmaxml_forecast_region_c2322000 do
      code { "2322000" }
      name { "愛知県稲沢市" }
      yomi { "あいちけんいなざわし" }
      short_name { "稲沢市" }
      short_yomi { "いなざわし" }
    end

    factory :jmaxml_forecast_region_c2322100 do
      code { "2322100" }
      name { "愛知県新城市" }
      yomi { "あいちけんしんしろし" }
      short_name { "新城市" }
      short_yomi { "しんしろし" }
    end

    factory :jmaxml_forecast_region_c2322200 do
      code { "2322200" }
      name { "愛知県東海市" }
      yomi { "あいちけんとうかいし" }
      short_name { "東海市" }
      short_yomi { "とうかいし" }
    end

    factory :jmaxml_forecast_region_c2322300 do
      code { "2322300" }
      name { "愛知県大府市" }
      yomi { "あいちけんおおぶし" }
      short_name { "大府市" }
      short_yomi { "おおぶし" }
    end

    factory :jmaxml_forecast_region_c2322400 do
      code { "2322400" }
      name { "愛知県知多市" }
      yomi { "あいちけんちたし" }
      short_name { "知多市" }
      short_yomi { "ちたし" }
    end

    factory :jmaxml_forecast_region_c2322500 do
      code { "2322500" }
      name { "愛知県知立市" }
      yomi { "あいちけんちりゅうし" }
      short_name { "知立市" }
      short_yomi { "ちりゅうし" }
    end

    factory :jmaxml_forecast_region_c2322600 do
      code { "2322600" }
      name { "愛知県尾張旭市" }
      yomi { "あいちけんおわりあさひし" }
      short_name { "尾張旭市" }
      short_yomi { "おわりあさひし" }
    end

    factory :jmaxml_forecast_region_c2322700 do
      code { "2322700" }
      name { "愛知県高浜市" }
      yomi { "あいちけんたかはまし" }
      short_name { "高浜市" }
      short_yomi { "たかはまし" }
    end

    factory :jmaxml_forecast_region_c2322800 do
      code { "2322800" }
      name { "愛知県岩倉市" }
      yomi { "あいちけんいわくらし" }
      short_name { "岩倉市" }
      short_yomi { "いわくらし" }
    end

    factory :jmaxml_forecast_region_c2322900 do
      code { "2322900" }
      name { "愛知県豊明市" }
      yomi { "あいちけんとよあけし" }
      short_name { "豊明市" }
      short_yomi { "とよあけし" }
    end

    factory :jmaxml_forecast_region_c2323000 do
      code { "2323000" }
      name { "愛知県日進市" }
      yomi { "あいちけんにっしんし" }
      short_name { "日進市" }
      short_yomi { "にっしんし" }
    end

    factory :jmaxml_forecast_region_c2323100 do
      code { "2323100" }
      name { "愛知県田原市" }
      yomi { "あいちけんたはらし" }
      short_name { "田原市" }
      short_yomi { "たはらし" }
    end

    factory :jmaxml_forecast_region_c2323200 do
      code { "2323200" }
      name { "愛知県愛西市" }
      yomi { "あいちけんあいさいし" }
      short_name { "愛西市" }
      short_yomi { "あいさいし" }
    end

    factory :jmaxml_forecast_region_c2323300 do
      code { "2323300" }
      name { "愛知県清須市" }
      yomi { "あいちけんきよすし" }
      short_name { "清須市" }
      short_yomi { "きよすし" }
    end

    factory :jmaxml_forecast_region_c2323400 do
      code { "2323400" }
      name { "愛知県北名古屋市" }
      yomi { "あいちけんきたなごやし" }
      short_name { "北名古屋市" }
      short_yomi { "きたなごやし" }
    end

    factory :jmaxml_forecast_region_c2323500 do
      code { "2323500" }
      name { "愛知県弥富市" }
      yomi { "あいちけんやとみし" }
      short_name { "弥富市" }
      short_yomi { "やとみし" }
    end

    factory :jmaxml_forecast_region_c2323600 do
      code { "2323600" }
      name { "愛知県みよし市" }
      yomi { "あいちけんみよしし" }
      short_name { "みよし市" }
      short_yomi { "みよしし" }
    end

    factory :jmaxml_forecast_region_c2323700 do
      code { "2323700" }
      name { "愛知県あま市" }
      yomi { "あいちけんあまし" }
      short_name { "あま市" }
      short_yomi { "あまし" }
    end

    factory :jmaxml_forecast_region_c2323800 do
      code { "2323800" }
      name { "愛知県長久手市" }
      yomi { "あいちけんながくてし" }
      short_name { "長久手市" }
      short_yomi { "ながくてし" }
    end

    factory :jmaxml_forecast_region_c2330200 do
      code { "2330200" }
      name { "愛知県東郷町" }
      yomi { "あいちけんとうごうちょう" }
      short_name { "東郷町" }
      short_yomi { "とうごうちょう" }
    end

    factory :jmaxml_forecast_region_c2334200 do
      code { "2334200" }
      name { "愛知県豊山町" }
      yomi { "あいちけんとよやまちょう" }
      short_name { "豊山町" }
      short_yomi { "とよやまちょう" }
    end

    factory :jmaxml_forecast_region_c2336100 do
      code { "2336100" }
      name { "愛知県大口町" }
      yomi { "あいちけんおおぐちちょう" }
      short_name { "大口町" }
      short_yomi { "おおぐちちょう" }
    end

    factory :jmaxml_forecast_region_c2336200 do
      code { "2336200" }
      name { "愛知県扶桑町" }
      yomi { "あいちけんふそうちょう" }
      short_name { "扶桑町" }
      short_yomi { "ふそうちょう" }
    end

    factory :jmaxml_forecast_region_c2342400 do
      code { "2342400" }
      name { "愛知県大治町" }
      yomi { "あいちけんおおはるちょう" }
      short_name { "大治町" }
      short_yomi { "おおはるちょう" }
    end

    factory :jmaxml_forecast_region_c2342500 do
      code { "2342500" }
      name { "愛知県蟹江町" }
      yomi { "あいちけんかにえちょう" }
      short_name { "蟹江町" }
      short_yomi { "かにえちょう" }
    end

    factory :jmaxml_forecast_region_c2342700 do
      code { "2342700" }
      name { "愛知県飛島村" }
      yomi { "あいちけんとびしまむら" }
      short_name { "飛島村" }
      short_yomi { "とびしまむら" }
    end

    factory :jmaxml_forecast_region_c2344100 do
      code { "2344100" }
      name { "愛知県阿久比町" }
      yomi { "あいちけんあぐいちょう" }
      short_name { "阿久比町" }
      short_yomi { "あぐいちょう" }
    end

    factory :jmaxml_forecast_region_c2344200 do
      code { "2344200" }
      name { "愛知県東浦町" }
      yomi { "あいちけんひがしうらちょう" }
      short_name { "東浦町" }
      short_yomi { "ひがしうらちょう" }
    end

    factory :jmaxml_forecast_region_c2344500 do
      code { "2344500" }
      name { "愛知県南知多町" }
      yomi { "あいちけんみなみちたちょう" }
      short_name { "南知多町" }
      short_yomi { "みなみちたちょう" }
    end

    factory :jmaxml_forecast_region_c2344600 do
      code { "2344600" }
      name { "愛知県美浜町" }
      yomi { "あいちけんみはまちょう" }
      short_name { "美浜町" }
      short_yomi { "みはまちょう" }
    end

    factory :jmaxml_forecast_region_c2344700 do
      code { "2344700" }
      name { "愛知県武豊町" }
      yomi { "あいちけんたけとよちょう" }
      short_name { "武豊町" }
      short_yomi { "たけとよちょう" }
    end

    factory :jmaxml_forecast_region_c2350100 do
      code { "2350100" }
      name { "愛知県幸田町" }
      yomi { "あいちけんこうたちょう" }
      short_name { "幸田町" }
      short_yomi { "こうたちょう" }
    end

    factory :jmaxml_forecast_region_c2356100 do
      code { "2356100" }
      name { "愛知県設楽町" }
      yomi { "あいちけんしたらちょう" }
      short_name { "設楽町" }
      short_yomi { "したらちょう" }
    end

    factory :jmaxml_forecast_region_c2356200 do
      code { "2356200" }
      name { "愛知県東栄町" }
      yomi { "あいちけんとうえいちょう" }
      short_name { "東栄町" }
      short_yomi { "とうえいちょう" }
    end

    factory :jmaxml_forecast_region_c2356300 do
      code { "2356300" }
      name { "愛知県豊根村" }
      yomi { "あいちけんとよねむら" }
      short_name { "豊根村" }
      short_yomi { "とよねむら" }
    end

    factory :jmaxml_forecast_region_c2420100 do
      code { "2420100" }
      name { "三重県津市" }
      yomi { "みえけんつし" }
      short_name { "津市" }
      short_yomi { "つし" }
    end

    factory :jmaxml_forecast_region_c2420200 do
      code { "2420200" }
      name { "三重県四日市市" }
      yomi { "みえけんよっかいちし" }
      short_name { "四日市市" }
      short_yomi { "よっかいちし" }
    end

    factory :jmaxml_forecast_region_c2420300 do
      code { "2420300" }
      name { "三重県伊勢市" }
      yomi { "みえけんいせし" }
      short_name { "伊勢市" }
      short_yomi { "いせし" }
    end

    factory :jmaxml_forecast_region_c2420400 do
      code { "2420400" }
      name { "三重県松阪市" }
      yomi { "みえけんまつさかし" }
      short_name { "松阪市" }
      short_yomi { "まつさかし" }
    end

    factory :jmaxml_forecast_region_c2420500 do
      code { "2420500" }
      name { "三重県桑名市" }
      yomi { "みえけんくわなし" }
      short_name { "桑名市" }
      short_yomi { "くわなし" }
    end

    factory :jmaxml_forecast_region_c2420700 do
      code { "2420700" }
      name { "三重県鈴鹿市" }
      yomi { "みえけんすずかし" }
      short_name { "鈴鹿市" }
      short_yomi { "すずかし" }
    end

    factory :jmaxml_forecast_region_c2420800 do
      code { "2420800" }
      name { "三重県名張市" }
      yomi { "みえけんなばりし" }
      short_name { "名張市" }
      short_yomi { "なばりし" }
    end

    factory :jmaxml_forecast_region_c2420900 do
      code { "2420900" }
      name { "三重県尾鷲市" }
      yomi { "みえけんおわせし" }
      short_name { "尾鷲市" }
      short_yomi { "おわせし" }
    end

    factory :jmaxml_forecast_region_c2421000 do
      code { "2421000" }
      name { "三重県亀山市" }
      yomi { "みえけんかめやまし" }
      short_name { "亀山市" }
      short_yomi { "かめやまし" }
    end

    factory :jmaxml_forecast_region_c2421100 do
      code { "2421100" }
      name { "三重県鳥羽市" }
      yomi { "みえけんとばし" }
      short_name { "鳥羽市" }
      short_yomi { "とばし" }
    end

    factory :jmaxml_forecast_region_c2421200 do
      code { "2421200" }
      name { "三重県熊野市" }
      yomi { "みえけんくまのし" }
      short_name { "熊野市" }
      short_yomi { "くまのし" }
    end

    factory :jmaxml_forecast_region_c2421400 do
      code { "2421400" }
      name { "三重県いなべ市" }
      yomi { "みえけんいなべし" }
      short_name { "いなべ市" }
      short_yomi { "いなべし" }
    end

    factory :jmaxml_forecast_region_c2421500 do
      code { "2421500" }
      name { "三重県志摩市" }
      yomi { "みえけんしまし" }
      short_name { "志摩市" }
      short_yomi { "しまし" }
    end

    factory :jmaxml_forecast_region_c2421600 do
      code { "2421600" }
      name { "三重県伊賀市" }
      yomi { "みえけんいがし" }
      short_name { "伊賀市" }
      short_yomi { "いがし" }
    end

    factory :jmaxml_forecast_region_c2430300 do
      code { "2430300" }
      name { "三重県木曽岬町" }
      yomi { "みえけんきそさきちょう" }
      short_name { "木曽岬町" }
      short_yomi { "きそさきちょう" }
    end

    factory :jmaxml_forecast_region_c2432400 do
      code { "2432400" }
      name { "三重県東員町" }
      yomi { "みえけんとういんちょう" }
      short_name { "東員町" }
      short_yomi { "とういんちょう" }
    end

    factory :jmaxml_forecast_region_c2434100 do
      code { "2434100" }
      name { "三重県菰野町" }
      yomi { "みえけんこものちょう" }
      short_name { "菰野町" }
      short_yomi { "こものちょう" }
    end

    factory :jmaxml_forecast_region_c2434300 do
      code { "2434300" }
      name { "三重県朝日町" }
      yomi { "みえけんあさひちょう" }
      short_name { "朝日町" }
      short_yomi { "あさひちょう" }
    end

    factory :jmaxml_forecast_region_c2434400 do
      code { "2434400" }
      name { "三重県川越町" }
      yomi { "みえけんかわごえちょう" }
      short_name { "川越町" }
      short_yomi { "かわごえちょう" }
    end

    factory :jmaxml_forecast_region_c2444100 do
      code { "2444100" }
      name { "三重県多気町" }
      yomi { "みえけんたきちょう" }
      short_name { "多気町" }
      short_yomi { "たきちょう" }
    end

    factory :jmaxml_forecast_region_c2444200 do
      code { "2444200" }
      name { "三重県明和町" }
      yomi { "みえけんめいわちょう" }
      short_name { "明和町" }
      short_yomi { "めいわちょう" }
    end

    factory :jmaxml_forecast_region_c2444300 do
      code { "2444300" }
      name { "三重県大台町" }
      yomi { "みえけんおおだいちょう" }
      short_name { "大台町" }
      short_yomi { "おおだいちょう" }
    end

    factory :jmaxml_forecast_region_c2446100 do
      code { "2446100" }
      name { "三重県玉城町" }
      yomi { "みえけんたまきちょう" }
      short_name { "玉城町" }
      short_yomi { "たまきちょう" }
    end

    factory :jmaxml_forecast_region_c2447000 do
      code { "2447000" }
      name { "三重県度会町" }
      yomi { "みえけんわたらいちょう" }
      short_name { "度会町" }
      short_yomi { "わたらいちょう" }
    end

    factory :jmaxml_forecast_region_c2447100 do
      code { "2447100" }
      name { "三重県大紀町" }
      yomi { "みえけんたいきちょう" }
      short_name { "大紀町" }
      short_yomi { "たいきちょう" }
    end

    factory :jmaxml_forecast_region_c2447200 do
      code { "2447200" }
      name { "三重県南伊勢町" }
      yomi { "みえけんみなみいせちょう" }
      short_name { "南伊勢町" }
      short_yomi { "みなみいせちょう" }
    end

    factory :jmaxml_forecast_region_c2454300 do
      code { "2454300" }
      name { "三重県紀北町" }
      yomi { "みえけんきほくちょう" }
      short_name { "紀北町" }
      short_yomi { "きほくちょう" }
    end

    factory :jmaxml_forecast_region_c2456100 do
      code { "2456100" }
      name { "三重県御浜町" }
      yomi { "みえけんみはまちょう" }
      short_name { "御浜町" }
      short_yomi { "みはまちょう" }
    end

    factory :jmaxml_forecast_region_c2456200 do
      code { "2456200" }
      name { "三重県紀宝町" }
      yomi { "みえけんきほうちょう" }
      short_name { "紀宝町" }
      short_yomi { "きほうちょう" }
    end

    factory :jmaxml_forecast_region_c2520100 do
      code { "2520100" }
      name { "滋賀県大津市" }
      yomi { "しがけんおおつし" }
      short_name { "大津市" }
      short_yomi { "おおつし" }
    end

    factory :jmaxml_forecast_region_c2520200 do
      code { "2520200" }
      name { "滋賀県彦根市" }
      yomi { "しがけんひこねし" }
      short_name { "彦根市" }
      short_yomi { "ひこねし" }
    end

    factory :jmaxml_forecast_region_c2520300 do
      code { "2520300" }
      name { "滋賀県長浜市" }
      yomi { "しがけんながはまし" }
      short_name { "長浜市" }
      short_yomi { "ながはまし" }
    end

    factory :jmaxml_forecast_region_c2520400 do
      code { "2520400" }
      name { "滋賀県近江八幡市" }
      yomi { "しがけんおうみはちまんし" }
      short_name { "近江八幡市" }
      short_yomi { "おうみはちまんし" }
    end

    factory :jmaxml_forecast_region_c2520600 do
      code { "2520600" }
      name { "滋賀県草津市" }
      yomi { "しがけんくさつし" }
      short_name { "草津市" }
      short_yomi { "くさつし" }
    end

    factory :jmaxml_forecast_region_c2520700 do
      code { "2520700" }
      name { "滋賀県守山市" }
      yomi { "しがけんもりやまし" }
      short_name { "守山市" }
      short_yomi { "もりやまし" }
    end

    factory :jmaxml_forecast_region_c2520800 do
      code { "2520800" }
      name { "滋賀県栗東市" }
      yomi { "しがけんりっとうし" }
      short_name { "栗東市" }
      short_yomi { "りっとうし" }
    end

    factory :jmaxml_forecast_region_c2520900 do
      code { "2520900" }
      name { "滋賀県甲賀市" }
      yomi { "しがけんこうかし" }
      short_name { "甲賀市" }
      short_yomi { "こうかし" }
    end

    factory :jmaxml_forecast_region_c2521000 do
      code { "2521000" }
      name { "滋賀県野洲市" }
      yomi { "しがけんやすし" }
      short_name { "野洲市" }
      short_yomi { "やすし" }
    end

    factory :jmaxml_forecast_region_c2521100 do
      code { "2521100" }
      name { "滋賀県湖南市" }
      yomi { "しがけんこなんし" }
      short_name { "湖南市" }
      short_yomi { "こなんし" }
    end

    factory :jmaxml_forecast_region_c2521200 do
      code { "2521200" }
      name { "滋賀県高島市" }
      yomi { "しがけんたかしまし" }
      short_name { "高島市" }
      short_yomi { "たかしまし" }
    end

    factory :jmaxml_forecast_region_c2521300 do
      code { "2521300" }
      name { "滋賀県東近江市" }
      yomi { "しがけんひがしおうみし" }
      short_name { "東近江市" }
      short_yomi { "ひがしおうみし" }
    end

    factory :jmaxml_forecast_region_c2521400 do
      code { "2521400" }
      name { "滋賀県米原市" }
      yomi { "しがけんまいばらし" }
      short_name { "米原市" }
      short_yomi { "まいばらし" }
    end

    factory :jmaxml_forecast_region_c2538300 do
      code { "2538300" }
      name { "滋賀県日野町" }
      yomi { "しがけんひのちょう" }
      short_name { "日野町" }
      short_yomi { "ひのちょう" }
    end

    factory :jmaxml_forecast_region_c2538400 do
      code { "2538400" }
      name { "滋賀県竜王町" }
      yomi { "しがけんりゅうおうちょう" }
      short_name { "竜王町" }
      short_yomi { "りゅうおうちょう" }
    end

    factory :jmaxml_forecast_region_c2542500 do
      code { "2542500" }
      name { "滋賀県愛荘町" }
      yomi { "しがけんあいしょうちょう" }
      short_name { "愛荘町" }
      short_yomi { "あいしょうちょう" }
    end

    factory :jmaxml_forecast_region_c2544100 do
      code { "2544100" }
      name { "滋賀県豊郷町" }
      yomi { "しがけんとよさとちょう" }
      short_name { "豊郷町" }
      short_yomi { "とよさとちょう" }
    end

    factory :jmaxml_forecast_region_c2544200 do
      code { "2544200" }
      name { "滋賀県甲良町" }
      yomi { "しがけんこうらちょう" }
      short_name { "甲良町" }
      short_yomi { "こうらちょう" }
    end

    factory :jmaxml_forecast_region_c2544300 do
      code { "2544300" }
      name { "滋賀県多賀町" }
      yomi { "しがけんたがちょう" }
      short_name { "多賀町" }
      short_yomi { "たがちょう" }
    end

    factory :jmaxml_forecast_region_c2610000 do
      code { "2610000" }
      name { "京都府京都市" }
      yomi { "きょうとふきょうとし" }
      short_name { "京都市" }
      short_yomi { "きょうとし" }
    end

    factory :jmaxml_forecast_region_c2620100 do
      code { "2620100" }
      name { "京都府福知山市" }
      yomi { "きょうとふふくちやまし" }
      short_name { "福知山市" }
      short_yomi { "ふくちやまし" }
    end

    factory :jmaxml_forecast_region_c2620200 do
      code { "2620200" }
      name { "京都府舞鶴市" }
      yomi { "きょうとふまいづるし" }
      short_name { "舞鶴市" }
      short_yomi { "まいづるし" }
    end

    factory :jmaxml_forecast_region_c2620300 do
      code { "2620300" }
      name { "京都府綾部市" }
      yomi { "きょうとふあやべし" }
      short_name { "綾部市" }
      short_yomi { "あやべし" }
    end

    factory :jmaxml_forecast_region_c2620400 do
      code { "2620400" }
      name { "京都府宇治市" }
      yomi { "きょうとふうじし" }
      short_name { "宇治市" }
      short_yomi { "うじし" }
    end

    factory :jmaxml_forecast_region_c2620500 do
      code { "2620500" }
      name { "京都府宮津市" }
      yomi { "きょうとふみやづし" }
      short_name { "宮津市" }
      short_yomi { "みやづし" }
    end

    factory :jmaxml_forecast_region_c2620600 do
      code { "2620600" }
      name { "京都府亀岡市" }
      yomi { "きょうとふかめおかし" }
      short_name { "亀岡市" }
      short_yomi { "かめおかし" }
    end

    factory :jmaxml_forecast_region_c2620700 do
      code { "2620700" }
      name { "京都府城陽市" }
      yomi { "きょうとふじょうようし" }
      short_name { "城陽市" }
      short_yomi { "じょうようし" }
    end

    factory :jmaxml_forecast_region_c2620800 do
      code { "2620800" }
      name { "京都府向日市" }
      yomi { "きょうとふむこうし" }
      short_name { "向日市" }
      short_yomi { "むこうし" }
    end

    factory :jmaxml_forecast_region_c2620900 do
      code { "2620900" }
      name { "京都府長岡京市" }
      yomi { "きょうとふながおかきょうし" }
      short_name { "長岡京市" }
      short_yomi { "ながおかきょうし" }
    end

    factory :jmaxml_forecast_region_c2621000 do
      code { "2621000" }
      name { "京都府八幡市" }
      yomi { "きょうとふやわたし" }
      short_name { "八幡市" }
      short_yomi { "やわたし" }
    end

    factory :jmaxml_forecast_region_c2621100 do
      code { "2621100" }
      name { "京都府京田辺市" }
      yomi { "きょうとふきょうたなべし" }
      short_name { "京田辺市" }
      short_yomi { "きょうたなべし" }
    end

    factory :jmaxml_forecast_region_c2621200 do
      code { "2621200" }
      name { "京都府京丹後市" }
      yomi { "きょうとふきょうたんごし" }
      short_name { "京丹後市" }
      short_yomi { "きょうたんごし" }
    end

    factory :jmaxml_forecast_region_c2621300 do
      code { "2621300" }
      name { "京都府南丹市" }
      yomi { "きょうとふなんたんし" }
      short_name { "南丹市" }
      short_yomi { "なんたんし" }
    end

    factory :jmaxml_forecast_region_c2621400 do
      code { "2621400" }
      name { "京都府木津川市" }
      yomi { "きょうとふきづがわし" }
      short_name { "木津川市" }
      short_yomi { "きづがわし" }
    end

    factory :jmaxml_forecast_region_c2630300 do
      code { "2630300" }
      name { "京都府大山崎町" }
      yomi { "きょうとふおおやまざきちょう" }
      short_name { "大山崎町" }
      short_yomi { "おおやまざきちょう" }
    end

    factory :jmaxml_forecast_region_c2632200 do
      code { "2632200" }
      name { "京都府久御山町" }
      yomi { "きょうとふくみやまちょう" }
      short_name { "久御山町" }
      short_yomi { "くみやまちょう" }
    end

    factory :jmaxml_forecast_region_c2634300 do
      code { "2634300" }
      name { "京都府井手町" }
      yomi { "きょうとふいでちょう" }
      short_name { "井手町" }
      short_yomi { "いでちょう" }
    end

    factory :jmaxml_forecast_region_c2634400 do
      code { "2634400" }
      name { "京都府宇治田原町" }
      yomi { "きょうとふうじたわらちょう" }
      short_name { "宇治田原町" }
      short_yomi { "うじたわらちょう" }
    end

    factory :jmaxml_forecast_region_c2636400 do
      code { "2636400" }
      name { "京都府笠置町" }
      yomi { "きょうとふかさぎちょう" }
      short_name { "笠置町" }
      short_yomi { "かさぎちょう" }
    end

    factory :jmaxml_forecast_region_c2636500 do
      code { "2636500" }
      name { "京都府和束町" }
      yomi { "きょうとふわづかちょう" }
      short_name { "和束町" }
      short_yomi { "わづかちょう" }
    end

    factory :jmaxml_forecast_region_c2636600 do
      code { "2636600" }
      name { "京都府精華町" }
      yomi { "きょうとふせいかちょう" }
      short_name { "精華町" }
      short_yomi { "せいかちょう" }
    end

    factory :jmaxml_forecast_region_c2636700 do
      code { "2636700" }
      name { "京都府南山城村" }
      yomi { "きょうとふみなみやましろむら" }
      short_name { "南山城村" }
      short_yomi { "みなみやましろむら" }
    end

    factory :jmaxml_forecast_region_c2640700 do
      code { "2640700" }
      name { "京都府京丹波町" }
      yomi { "きょうとふきょうたんばちょう" }
      short_name { "京丹波町" }
      short_yomi { "きょうたんばちょう" }
    end

    factory :jmaxml_forecast_region_c2646300 do
      code { "2646300" }
      name { "京都府伊根町" }
      yomi { "きょうとふいねちょう" }
      short_name { "伊根町" }
      short_yomi { "いねちょう" }
    end

    factory :jmaxml_forecast_region_c2646500 do
      code { "2646500" }
      name { "京都府与謝野町" }
      yomi { "きょうとふよさのちょう" }
      short_name { "与謝野町" }
      short_yomi { "よさのちょう" }
    end

    factory :jmaxml_forecast_region_c2710000 do
      code { "2710000" }
      name { "大阪府大阪市" }
      yomi { "おおさかふおおさかし" }
      short_name { "大阪市" }
      short_yomi { "おおさかし" }
    end

    factory :jmaxml_forecast_region_c2714000 do
      code { "2714000" }
      name { "大阪府堺市" }
      yomi { "おおさかふさかいし" }
      short_name { "堺市" }
      short_yomi { "さかいし" }
    end

    factory :jmaxml_forecast_region_c2720200 do
      code { "2720200" }
      name { "大阪府岸和田市" }
      yomi { "おおさかふきしわだし" }
      short_name { "岸和田市" }
      short_yomi { "きしわだし" }
    end

    factory :jmaxml_forecast_region_c2720300 do
      code { "2720300" }
      name { "大阪府豊中市" }
      yomi { "おおさかふとよなかし" }
      short_name { "豊中市" }
      short_yomi { "とよなかし" }
    end

    factory :jmaxml_forecast_region_c2720400 do
      code { "2720400" }
      name { "大阪府池田市" }
      yomi { "おおさかふいけだし" }
      short_name { "池田市" }
      short_yomi { "いけだし" }
    end

    factory :jmaxml_forecast_region_c2720500 do
      code { "2720500" }
      name { "大阪府吹田市" }
      yomi { "おおさかふすいたし" }
      short_name { "吹田市" }
      short_yomi { "すいたし" }
    end

    factory :jmaxml_forecast_region_c2720600 do
      code { "2720600" }
      name { "大阪府泉大津市" }
      yomi { "おおさかふいずみおおつし" }
      short_name { "泉大津市" }
      short_yomi { "いずみおおつし" }
    end

    factory :jmaxml_forecast_region_c2720700 do
      code { "2720700" }
      name { "大阪府高槻市" }
      yomi { "おおさかふたかつきし" }
      short_name { "高槻市" }
      short_yomi { "たかつきし" }
    end

    factory :jmaxml_forecast_region_c2720800 do
      code { "2720800" }
      name { "大阪府貝塚市" }
      yomi { "おおさかふかいづかし" }
      short_name { "貝塚市" }
      short_yomi { "かいづかし" }
    end

    factory :jmaxml_forecast_region_c2720900 do
      code { "2720900" }
      name { "大阪府守口市" }
      yomi { "おおさかふもりぐちし" }
      short_name { "守口市" }
      short_yomi { "もりぐちし" }
    end

    factory :jmaxml_forecast_region_c2721000 do
      code { "2721000" }
      name { "大阪府枚方市" }
      yomi { "おおさかふひらかたし" }
      short_name { "枚方市" }
      short_yomi { "ひらかたし" }
    end

    factory :jmaxml_forecast_region_c2721100 do
      code { "2721100" }
      name { "大阪府茨木市" }
      yomi { "おおさかふいばらきし" }
      short_name { "茨木市" }
      short_yomi { "いばらきし" }
    end

    factory :jmaxml_forecast_region_c2721200 do
      code { "2721200" }
      name { "大阪府八尾市" }
      yomi { "おおさかふやおし" }
      short_name { "八尾市" }
      short_yomi { "やおし" }
    end

    factory :jmaxml_forecast_region_c2721300 do
      code { "2721300" }
      name { "大阪府泉佐野市" }
      yomi { "おおさかふいずみさのし" }
      short_name { "泉佐野市" }
      short_yomi { "いずみさのし" }
    end

    factory :jmaxml_forecast_region_c2721400 do
      code { "2721400" }
      name { "大阪府富田林市" }
      yomi { "おおさかふとんだばやしし" }
      short_name { "富田林市" }
      short_yomi { "とんだばやしし" }
    end

    factory :jmaxml_forecast_region_c2721500 do
      code { "2721500" }
      name { "大阪府寝屋川市" }
      yomi { "おおさかふねやがわし" }
      short_name { "寝屋川市" }
      short_yomi { "ねやがわし" }
    end

    factory :jmaxml_forecast_region_c2721600 do
      code { "2721600" }
      name { "大阪府河内長野市" }
      yomi { "おおさかふかわちながのし" }
      short_name { "河内長野市" }
      short_yomi { "かわちながのし" }
    end

    factory :jmaxml_forecast_region_c2721700 do
      code { "2721700" }
      name { "大阪府松原市" }
      yomi { "おおさかふまつばらし" }
      short_name { "松原市" }
      short_yomi { "まつばらし" }
    end

    factory :jmaxml_forecast_region_c2721800 do
      code { "2721800" }
      name { "大阪府大東市" }
      yomi { "おおさかふだいとうし" }
      short_name { "大東市" }
      short_yomi { "だいとうし" }
    end

    factory :jmaxml_forecast_region_c2721900 do
      code { "2721900" }
      name { "大阪府和泉市" }
      yomi { "おおさかふいずみし" }
      short_name { "和泉市" }
      short_yomi { "いずみし" }
    end

    factory :jmaxml_forecast_region_c2722000 do
      code { "2722000" }
      name { "大阪府箕面市" }
      yomi { "おおさかふみのおし" }
      short_name { "箕面市" }
      short_yomi { "みのおし" }
    end

    factory :jmaxml_forecast_region_c2722100 do
      code { "2722100" }
      name { "大阪府柏原市" }
      yomi { "おおさかふかしわらし" }
      short_name { "柏原市" }
      short_yomi { "かしわらし" }
    end

    factory :jmaxml_forecast_region_c2722200 do
      code { "2722200" }
      name { "大阪府羽曳野市" }
      yomi { "おおさかふはびきのし" }
      short_name { "羽曳野市" }
      short_yomi { "はびきのし" }
    end

    factory :jmaxml_forecast_region_c2722300 do
      code { "2722300" }
      name { "大阪府門真市" }
      yomi { "おおさかふかどまし" }
      short_name { "門真市" }
      short_yomi { "かどまし" }
    end

    factory :jmaxml_forecast_region_c2722400 do
      code { "2722400" }
      name { "大阪府摂津市" }
      yomi { "おおさかふせっつし" }
      short_name { "摂津市" }
      short_yomi { "せっつし" }
    end

    factory :jmaxml_forecast_region_c2722500 do
      code { "2722500" }
      name { "大阪府高石市" }
      yomi { "おおさかふたかいしし" }
      short_name { "高石市" }
      short_yomi { "たかいしし" }
    end

    factory :jmaxml_forecast_region_c2722600 do
      code { "2722600" }
      name { "大阪府藤井寺市" }
      yomi { "おおさかふふじいでらし" }
      short_name { "藤井寺市" }
      short_yomi { "ふじいでらし" }
    end

    factory :jmaxml_forecast_region_c2722700 do
      code { "2722700" }
      name { "大阪府東大阪市" }
      yomi { "おおさかふひがしおおさかし" }
      short_name { "東大阪市" }
      short_yomi { "ひがしおおさかし" }
    end

    factory :jmaxml_forecast_region_c2722800 do
      code { "2722800" }
      name { "大阪府泉南市" }
      yomi { "おおさかふせんなんし" }
      short_name { "泉南市" }
      short_yomi { "せんなんし" }
    end

    factory :jmaxml_forecast_region_c2722900 do
      code { "2722900" }
      name { "大阪府四條畷市" }
      yomi { "おおさかふしじょうなわてし" }
      short_name { "四條畷市" }
      short_yomi { "しじょうなわてし" }
    end

    factory :jmaxml_forecast_region_c2723000 do
      code { "2723000" }
      name { "大阪府交野市" }
      yomi { "おおさかふかたのし" }
      short_name { "交野市" }
      short_yomi { "かたのし" }
    end

    factory :jmaxml_forecast_region_c2723100 do
      code { "2723100" }
      name { "大阪府大阪狭山市" }
      yomi { "おおさかふおおさかさやまし" }
      short_name { "大阪狭山市" }
      short_yomi { "おおさかさやまし" }
    end

    factory :jmaxml_forecast_region_c2723200 do
      code { "2723200" }
      name { "大阪府阪南市" }
      yomi { "おおさかふはんなんし" }
      short_name { "阪南市" }
      short_yomi { "はんなんし" }
    end

    factory :jmaxml_forecast_region_c2730100 do
      code { "2730100" }
      name { "大阪府島本町" }
      yomi { "おおさかふしまもとちょう" }
      short_name { "島本町" }
      short_yomi { "しまもとちょう" }
    end

    factory :jmaxml_forecast_region_c2732100 do
      code { "2732100" }
      name { "大阪府豊能町" }
      yomi { "おおさかふとよのちょう" }
      short_name { "豊能町" }
      short_yomi { "とよのちょう" }
    end

    factory :jmaxml_forecast_region_c2732200 do
      code { "2732200" }
      name { "大阪府能勢町" }
      yomi { "おおさかふのせちょう" }
      short_name { "能勢町" }
      short_yomi { "のせちょう" }
    end

    factory :jmaxml_forecast_region_c2734100 do
      code { "2734100" }
      name { "大阪府忠岡町" }
      yomi { "おおさかふただおかちょう" }
      short_name { "忠岡町" }
      short_yomi { "ただおかちょう" }
    end

    factory :jmaxml_forecast_region_c2736100 do
      code { "2736100" }
      name { "大阪府熊取町" }
      yomi { "おおさかふくまとりちょう" }
      short_name { "熊取町" }
      short_yomi { "くまとりちょう" }
    end

    factory :jmaxml_forecast_region_c2736200 do
      code { "2736200" }
      name { "大阪府田尻町" }
      yomi { "おおさかふたじりちょう" }
      short_name { "田尻町" }
      short_yomi { "たじりちょう" }
    end

    factory :jmaxml_forecast_region_c2736600 do
      code { "2736600" }
      name { "大阪府岬町" }
      yomi { "おおさかふみさきちょう" }
      short_name { "岬町" }
      short_yomi { "みさきちょう" }
    end

    factory :jmaxml_forecast_region_c2738100 do
      code { "2738100" }
      name { "大阪府太子町" }
      yomi { "おおさかふたいしちょう" }
      short_name { "太子町" }
      short_yomi { "たいしちょう" }
    end

    factory :jmaxml_forecast_region_c2738200 do
      code { "2738200" }
      name { "大阪府河南町" }
      yomi { "おおさかふかなんちょう" }
      short_name { "河南町" }
      short_yomi { "かなんちょう" }
    end

    factory :jmaxml_forecast_region_c2738300 do
      code { "2738300" }
      name { "大阪府千早赤阪村" }
      yomi { "おおさかふちはやあかさかむら" }
      short_name { "千早赤阪村" }
      short_yomi { "ちはやあかさかむら" }
    end

    factory :jmaxml_forecast_region_c2810000 do
      code { "2810000" }
      name { "兵庫県神戸市" }
      yomi { "ひょうごけんこうべし" }
      short_name { "神戸市" }
      short_yomi { "こうべし" }
    end

    factory :jmaxml_forecast_region_c2820100 do
      code { "2820100" }
      name { "兵庫県姫路市" }
      yomi { "ひょうごけんひめじし" }
      short_name { "姫路市" }
      short_yomi { "ひめじし" }
    end

    factory :jmaxml_forecast_region_c2820200 do
      code { "2820200" }
      name { "兵庫県尼崎市" }
      yomi { "ひょうごけんあまがさきし" }
      short_name { "尼崎市" }
      short_yomi { "あまがさきし" }
    end

    factory :jmaxml_forecast_region_c2820300 do
      code { "2820300" }
      name { "兵庫県明石市" }
      yomi { "ひょうごけんあかしし" }
      short_name { "明石市" }
      short_yomi { "あかしし" }
    end

    factory :jmaxml_forecast_region_c2820400 do
      code { "2820400" }
      name { "兵庫県西宮市" }
      yomi { "ひょうごけんにしのみやし" }
      short_name { "西宮市" }
      short_yomi { "にしのみやし" }
    end

    factory :jmaxml_forecast_region_c2820500 do
      code { "2820500" }
      name { "兵庫県洲本市" }
      yomi { "ひょうごけんすもとし" }
      short_name { "洲本市" }
      short_yomi { "すもとし" }
    end

    factory :jmaxml_forecast_region_c2820600 do
      code { "2820600" }
      name { "兵庫県芦屋市" }
      yomi { "ひょうごけんあしやし" }
      short_name { "芦屋市" }
      short_yomi { "あしやし" }
    end

    factory :jmaxml_forecast_region_c2820700 do
      code { "2820700" }
      name { "兵庫県伊丹市" }
      yomi { "ひょうごけんいたみし" }
      short_name { "伊丹市" }
      short_yomi { "いたみし" }
    end

    factory :jmaxml_forecast_region_c2820800 do
      code { "2820800" }
      name { "兵庫県相生市" }
      yomi { "ひょうごけんあいおいし" }
      short_name { "相生市" }
      short_yomi { "あいおいし" }
    end

    factory :jmaxml_forecast_region_c2820900 do
      code { "2820900" }
      name { "兵庫県豊岡市" }
      yomi { "ひょうごけんとよおかし" }
      short_name { "豊岡市" }
      short_yomi { "とよおかし" }
    end

    factory :jmaxml_forecast_region_c2821000 do
      code { "2821000" }
      name { "兵庫県加古川市" }
      yomi { "ひょうごけんかこがわし" }
      short_name { "加古川市" }
      short_yomi { "かこがわし" }
    end

    factory :jmaxml_forecast_region_c2821200 do
      code { "2821200" }
      name { "兵庫県赤穂市" }
      yomi { "ひょうごけんあこうし" }
      short_name { "赤穂市" }
      short_yomi { "あこうし" }
    end

    factory :jmaxml_forecast_region_c2821300 do
      code { "2821300" }
      name { "兵庫県西脇市" }
      yomi { "ひょうごけんにしわきし" }
      short_name { "西脇市" }
      short_yomi { "にしわきし" }
    end

    factory :jmaxml_forecast_region_c2821400 do
      code { "2821400" }
      name { "兵庫県宝塚市" }
      yomi { "ひょうごけんたからづかし" }
      short_name { "宝塚市" }
      short_yomi { "たからづかし" }
    end

    factory :jmaxml_forecast_region_c2821500 do
      code { "2821500" }
      name { "兵庫県三木市" }
      yomi { "ひょうごけんみきし" }
      short_name { "三木市" }
      short_yomi { "みきし" }
    end

    factory :jmaxml_forecast_region_c2821600 do
      code { "2821600" }
      name { "兵庫県高砂市" }
      yomi { "ひょうごけんたかさごし" }
      short_name { "高砂市" }
      short_yomi { "たかさごし" }
    end

    factory :jmaxml_forecast_region_c2821700 do
      code { "2821700" }
      name { "兵庫県川西市" }
      yomi { "ひょうごけんかわにしし" }
      short_name { "川西市" }
      short_yomi { "かわにしし" }
    end

    factory :jmaxml_forecast_region_c2821800 do
      code { "2821800" }
      name { "兵庫県小野市" }
      yomi { "ひょうごけんおのし" }
      short_name { "小野市" }
      short_yomi { "おのし" }
    end

    factory :jmaxml_forecast_region_c2821900 do
      code { "2821900" }
      name { "兵庫県三田市" }
      yomi { "ひょうごけんさんだし" }
      short_name { "三田市" }
      short_yomi { "さんだし" }
    end

    factory :jmaxml_forecast_region_c2822000 do
      code { "2822000" }
      name { "兵庫県加西市" }
      yomi { "ひょうごけんかさいし" }
      short_name { "加西市" }
      short_yomi { "かさいし" }
    end

    factory :jmaxml_forecast_region_c2822100 do
      code { "2822100" }
      name { "兵庫県篠山市" }
      yomi { "ひょうごけんささやまし" }
      short_name { "篠山市" }
      short_yomi { "ささやまし" }
    end

    factory :jmaxml_forecast_region_c2822200 do
      code { "2822200" }
      name { "兵庫県養父市" }
      yomi { "ひょうごけんやぶし" }
      short_name { "養父市" }
      short_yomi { "やぶし" }
    end

    factory :jmaxml_forecast_region_c2822300 do
      code { "2822300" }
      name { "兵庫県丹波市" }
      yomi { "ひょうごけんたんばし" }
      short_name { "丹波市" }
      short_yomi { "たんばし" }
    end

    factory :jmaxml_forecast_region_c2822400 do
      code { "2822400" }
      name { "兵庫県南あわじ市" }
      yomi { "ひょうごけんみなみあわじし" }
      short_name { "南あわじ市" }
      short_yomi { "みなみあわじし" }
    end

    factory :jmaxml_forecast_region_c2822500 do
      code { "2822500" }
      name { "兵庫県朝来市" }
      yomi { "ひょうごけんあさごし" }
      short_name { "朝来市" }
      short_yomi { "あさごし" }
    end

    factory :jmaxml_forecast_region_c2822600 do
      code { "2822600" }
      name { "兵庫県淡路市" }
      yomi { "ひょうごけんあわじし" }
      short_name { "淡路市" }
      short_yomi { "あわじし" }
    end

    factory :jmaxml_forecast_region_c2822700 do
      code { "2822700" }
      name { "兵庫県宍粟市" }
      yomi { "ひょうごけんしそうし" }
      short_name { "宍粟市" }
      short_yomi { "しそうし" }
    end

    factory :jmaxml_forecast_region_c2822800 do
      code { "2822800" }
      name { "兵庫県加東市" }
      yomi { "ひょうごけんかとうし" }
      short_name { "加東市" }
      short_yomi { "かとうし" }
    end

    factory :jmaxml_forecast_region_c2822900 do
      code { "2822900" }
      name { "兵庫県たつの市" }
      yomi { "ひょうごけんたつのし" }
      short_name { "たつの市" }
      short_yomi { "たつのし" }
    end

    factory :jmaxml_forecast_region_c2830100 do
      code { "2830100" }
      name { "兵庫県猪名川町" }
      yomi { "ひょうごけんいながわちょう" }
      short_name { "猪名川町" }
      short_yomi { "いながわちょう" }
    end

    factory :jmaxml_forecast_region_c2836500 do
      code { "2836500" }
      name { "兵庫県多可町" }
      yomi { "ひょうごけんたかちょう" }
      short_name { "多可町" }
      short_yomi { "たかちょう" }
    end

    factory :jmaxml_forecast_region_c2838100 do
      code { "2838100" }
      name { "兵庫県稲美町" }
      yomi { "ひょうごけんいなみちょう" }
      short_name { "稲美町" }
      short_yomi { "いなみちょう" }
    end

    factory :jmaxml_forecast_region_c2838200 do
      code { "2838200" }
      name { "兵庫県播磨町" }
      yomi { "ひょうごけんはりまちょう" }
      short_name { "播磨町" }
      short_yomi { "はりまちょう" }
    end

    factory :jmaxml_forecast_region_c2844200 do
      code { "2844200" }
      name { "兵庫県市川町" }
      yomi { "ひょうごけんいちかわちょう" }
      short_name { "市川町" }
      short_yomi { "いちかわちょう" }
    end

    factory :jmaxml_forecast_region_c2844300 do
      code { "2844300" }
      name { "兵庫県福崎町" }
      yomi { "ひょうごけんふくさきちょう" }
      short_name { "福崎町" }
      short_yomi { "ふくさきちょう" }
    end

    factory :jmaxml_forecast_region_c2844600 do
      code { "2844600" }
      name { "兵庫県神河町" }
      yomi { "ひょうごけんかみかわちょう" }
      short_name { "神河町" }
      short_yomi { "かみかわちょう" }
    end

    factory :jmaxml_forecast_region_c2846400 do
      code { "2846400" }
      name { "兵庫県太子町" }
      yomi { "ひょうごけんたいしちょう" }
      short_name { "太子町" }
      short_yomi { "たいしちょう" }
    end

    factory :jmaxml_forecast_region_c2848100 do
      code { "2848100" }
      name { "兵庫県上郡町" }
      yomi { "ひょうごけんかみごおりちょう" }
      short_name { "上郡町" }
      short_yomi { "かみごおりちょう" }
    end

    factory :jmaxml_forecast_region_c2850100 do
      code { "2850100" }
      name { "兵庫県佐用町" }
      yomi { "ひょうごけんさようちょう" }
      short_name { "佐用町" }
      short_yomi { "さようちょう" }
    end

    factory :jmaxml_forecast_region_c2858500 do
      code { "2858500" }
      name { "兵庫県香美町" }
      yomi { "ひょうごけんかみちょう" }
      short_name { "香美町" }
      short_yomi { "かみちょう" }
    end

    factory :jmaxml_forecast_region_c2858600 do
      code { "2858600" }
      name { "兵庫県新温泉町" }
      yomi { "ひょうごけんしんおんせんちょう" }
      short_name { "新温泉町" }
      short_yomi { "しんおんせんちょう" }
    end

    factory :jmaxml_forecast_region_c2920100 do
      code { "2920100" }
      name { "奈良県奈良市" }
      yomi { "ならけんならし" }
      short_name { "奈良市" }
      short_yomi { "ならし" }
    end

    factory :jmaxml_forecast_region_c2920200 do
      code { "2920200" }
      name { "奈良県大和高田市" }
      yomi { "ならけんやまとたかだし" }
      short_name { "大和高田市" }
      short_yomi { "やまとたかだし" }
    end

    factory :jmaxml_forecast_region_c2920300 do
      code { "2920300" }
      name { "奈良県大和郡山市" }
      yomi { "ならけんやまとこおりやまし" }
      short_name { "大和郡山市" }
      short_yomi { "やまとこおりやまし" }
    end

    factory :jmaxml_forecast_region_c2920400 do
      code { "2920400" }
      name { "奈良県天理市" }
      yomi { "ならけんてんりし" }
      short_name { "天理市" }
      short_yomi { "てんりし" }
    end

    factory :jmaxml_forecast_region_c2920500 do
      code { "2920500" }
      name { "奈良県橿原市" }
      yomi { "ならけんかしはらし" }
      short_name { "橿原市" }
      short_yomi { "かしはらし" }
    end

    factory :jmaxml_forecast_region_c2920600 do
      code { "2920600" }
      name { "奈良県桜井市" }
      yomi { "ならけんさくらいし" }
      short_name { "桜井市" }
      short_yomi { "さくらいし" }
    end

    factory :jmaxml_forecast_region_c2920700 do
      code { "2920700" }
      name { "奈良県五條市" }
      yomi { "ならけんごじょうし" }
      short_name { "五條市" }
      short_yomi { "ごじょうし" }
    end

    factory :jmaxml_forecast_region_c2920800 do
      code { "2920800" }
      name { "奈良県御所市" }
      yomi { "ならけんごせし" }
      short_name { "御所市" }
      short_yomi { "ごせし" }
    end

    factory :jmaxml_forecast_region_c2920900 do
      code { "2920900" }
      name { "奈良県生駒市" }
      yomi { "ならけんいこまし" }
      short_name { "生駒市" }
      short_yomi { "いこまし" }
    end

    factory :jmaxml_forecast_region_c2921000 do
      code { "2921000" }
      name { "奈良県香芝市" }
      yomi { "ならけんかしばし" }
      short_name { "香芝市" }
      short_yomi { "かしばし" }
    end

    factory :jmaxml_forecast_region_c2921100 do
      code { "2921100" }
      name { "奈良県葛城市" }
      yomi { "ならけんかつらぎし" }
      short_name { "葛城市" }
      short_yomi { "かつらぎし" }
    end

    factory :jmaxml_forecast_region_c2921200 do
      code { "2921200" }
      name { "奈良県宇陀市" }
      yomi { "ならけんうだし" }
      short_name { "宇陀市" }
      short_yomi { "うだし" }
    end

    factory :jmaxml_forecast_region_c2932200 do
      code { "2932200" }
      name { "奈良県山添村" }
      yomi { "ならけんやまぞえむら" }
      short_name { "山添村" }
      short_yomi { "やまぞえむら" }
    end

    factory :jmaxml_forecast_region_c2934200 do
      code { "2934200" }
      name { "奈良県平群町" }
      yomi { "ならけんへぐりちょう" }
      short_name { "平群町" }
      short_yomi { "へぐりちょう" }
    end

    factory :jmaxml_forecast_region_c2934300 do
      code { "2934300" }
      name { "奈良県三郷町" }
      yomi { "ならけんさんごうちょう" }
      short_name { "三郷町" }
      short_yomi { "さんごうちょう" }
    end

    factory :jmaxml_forecast_region_c2934400 do
      code { "2934400" }
      name { "奈良県斑鳩町" }
      yomi { "ならけんいかるがちょう" }
      short_name { "斑鳩町" }
      short_yomi { "いかるがちょう" }
    end

    factory :jmaxml_forecast_region_c2934500 do
      code { "2934500" }
      name { "奈良県安堵町" }
      yomi { "ならけんあんどちょう" }
      short_name { "安堵町" }
      short_yomi { "あんどちょう" }
    end

    factory :jmaxml_forecast_region_c2936100 do
      code { "2936100" }
      name { "奈良県川西町" }
      yomi { "ならけんかわにしちょう" }
      short_name { "川西町" }
      short_yomi { "かわにしちょう" }
    end

    factory :jmaxml_forecast_region_c2936200 do
      code { "2936200" }
      name { "奈良県三宅町" }
      yomi { "ならけんみやけちょう" }
      short_name { "三宅町" }
      short_yomi { "みやけちょう" }
    end

    factory :jmaxml_forecast_region_c2936300 do
      code { "2936300" }
      name { "奈良県田原本町" }
      yomi { "ならけんたわらもとちょう" }
      short_name { "田原本町" }
      short_yomi { "たわらもとちょう" }
    end

    factory :jmaxml_forecast_region_c2938500 do
      code { "2938500" }
      name { "奈良県曽爾村" }
      yomi { "ならけんそにむら" }
      short_name { "曽爾村" }
      short_yomi { "そにむら" }
    end

    factory :jmaxml_forecast_region_c2938600 do
      code { "2938600" }
      name { "奈良県御杖村" }
      yomi { "ならけんみつえむら" }
      short_name { "御杖村" }
      short_yomi { "みつえむら" }
    end

    factory :jmaxml_forecast_region_c2940100 do
      code { "2940100" }
      name { "奈良県高取町" }
      yomi { "ならけんたかとりちょう" }
      short_name { "高取町" }
      short_yomi { "たかとりちょう" }
    end

    factory :jmaxml_forecast_region_c2940200 do
      code { "2940200" }
      name { "奈良県明日香村" }
      yomi { "ならけんあすかむら" }
      short_name { "明日香村" }
      short_yomi { "あすかむら" }
    end

    factory :jmaxml_forecast_region_c2942400 do
      code { "2942400" }
      name { "奈良県上牧町" }
      yomi { "ならけんかんまきちょう" }
      short_name { "上牧町" }
      short_yomi { "かんまきちょう" }
    end

    factory :jmaxml_forecast_region_c2942500 do
      code { "2942500" }
      name { "奈良県王寺町" }
      yomi { "ならけんおうじちょう" }
      short_name { "王寺町" }
      short_yomi { "おうじちょう" }
    end

    factory :jmaxml_forecast_region_c2942600 do
      code { "2942600" }
      name { "奈良県広陵町" }
      yomi { "ならけんこうりょうちょう" }
      short_name { "広陵町" }
      short_yomi { "こうりょうちょう" }
    end

    factory :jmaxml_forecast_region_c2942700 do
      code { "2942700" }
      name { "奈良県河合町" }
      yomi { "ならけんかわいちょう" }
      short_name { "河合町" }
      short_yomi { "かわいちょう" }
    end

    factory :jmaxml_forecast_region_c2944100 do
      code { "2944100" }
      name { "奈良県吉野町" }
      yomi { "ならけんよしのちょう" }
      short_name { "吉野町" }
      short_yomi { "よしのちょう" }
    end

    factory :jmaxml_forecast_region_c2944200 do
      code { "2944200" }
      name { "奈良県大淀町" }
      yomi { "ならけんおおよどちょう" }
      short_name { "大淀町" }
      short_yomi { "おおよどちょう" }
    end

    factory :jmaxml_forecast_region_c2944300 do
      code { "2944300" }
      name { "奈良県下市町" }
      yomi { "ならけんしもいちちょう" }
      short_name { "下市町" }
      short_yomi { "しもいちちょう" }
    end

    factory :jmaxml_forecast_region_c2944400 do
      code { "2944400" }
      name { "奈良県黒滝村" }
      yomi { "ならけんくろたきむら" }
      short_name { "黒滝村" }
      short_yomi { "くろたきむら" }
    end

    factory :jmaxml_forecast_region_c2944600 do
      code { "2944600" }
      name { "奈良県天川村" }
      yomi { "ならけんてんかわむら" }
      short_name { "天川村" }
      short_yomi { "てんかわむら" }
    end

    factory :jmaxml_forecast_region_c2944700 do
      code { "2944700" }
      name { "奈良県野迫川村" }
      yomi { "ならけんのせがわむら" }
      short_name { "野迫川村" }
      short_yomi { "のせがわむら" }
    end

    factory :jmaxml_forecast_region_c2944900 do
      code { "2944900" }
      name { "奈良県十津川村" }
      yomi { "ならけんとつかわむら" }
      short_name { "十津川村" }
      short_yomi { "とつかわむら" }
    end

    factory :jmaxml_forecast_region_c2945000 do
      code { "2945000" }
      name { "奈良県下北山村" }
      yomi { "ならけんしもきたやまむら" }
      short_name { "下北山村" }
      short_yomi { "しもきたやまむら" }
    end

    factory :jmaxml_forecast_region_c2945100 do
      code { "2945100" }
      name { "奈良県上北山村" }
      yomi { "ならけんかみきたやまむら" }
      short_name { "上北山村" }
      short_yomi { "かみきたやまむら" }
    end

    factory :jmaxml_forecast_region_c2945200 do
      code { "2945200" }
      name { "奈良県川上村" }
      yomi { "ならけんかわかみむら" }
      short_name { "川上村" }
      short_yomi { "かわかみむら" }
    end

    factory :jmaxml_forecast_region_c2945300 do
      code { "2945300" }
      name { "奈良県東吉野村" }
      yomi { "ならけんひがしよしのむら" }
      short_name { "東吉野村" }
      short_yomi { "ひがしよしのむら" }
    end

    factory :jmaxml_forecast_region_c3020100 do
      code { "3020100" }
      name { "和歌山県和歌山市" }
      yomi { "わかやまけんわかやまし" }
      short_name { "和歌山市" }
      short_yomi { "わかやまし" }
    end

    factory :jmaxml_forecast_region_c3020200 do
      code { "3020200" }
      name { "和歌山県海南市" }
      yomi { "わかやまけんかいなんし" }
      short_name { "海南市" }
      short_yomi { "かいなんし" }
    end

    factory :jmaxml_forecast_region_c3020300 do
      code { "3020300" }
      name { "和歌山県橋本市" }
      yomi { "わかやまけんはしもとし" }
      short_name { "橋本市" }
      short_yomi { "はしもとし" }
    end

    factory :jmaxml_forecast_region_c3020400 do
      code { "3020400" }
      name { "和歌山県有田市" }
      yomi { "わかやまけんありだし" }
      short_name { "有田市" }
      short_yomi { "ありだし" }
    end

    factory :jmaxml_forecast_region_c3020500 do
      code { "3020500" }
      name { "和歌山県御坊市" }
      yomi { "わかやまけんごぼうし" }
      short_name { "御坊市" }
      short_yomi { "ごぼうし" }
    end

    factory :jmaxml_forecast_region_c3020600 do
      code { "3020600" }
      name { "和歌山県田辺市" }
      yomi { "わかやまけんたなべし" }
      short_name { "田辺市" }
      short_yomi { "たなべし" }
    end

    factory :jmaxml_forecast_region_c3020700 do
      code { "3020700" }
      name { "和歌山県新宮市" }
      yomi { "わかやまけんしんぐうし" }
      short_name { "新宮市" }
      short_yomi { "しんぐうし" }
    end

    factory :jmaxml_forecast_region_c3020800 do
      code { "3020800" }
      name { "和歌山県紀の川市" }
      yomi { "わかやまけんきのかわし" }
      short_name { "紀の川市" }
      short_yomi { "きのかわし" }
    end

    factory :jmaxml_forecast_region_c3020900 do
      code { "3020900" }
      name { "和歌山県岩出市" }
      yomi { "わかやまけんいわでし" }
      short_name { "岩出市" }
      short_yomi { "いわでし" }
    end

    factory :jmaxml_forecast_region_c3030400 do
      code { "3030400" }
      name { "和歌山県紀美野町" }
      yomi { "わかやまけんきみのちょう" }
      short_name { "紀美野町" }
      short_yomi { "きみのちょう" }
    end

    factory :jmaxml_forecast_region_c3034100 do
      code { "3034100" }
      name { "和歌山県かつらぎ町" }
      yomi { "わかやまけんかつらぎちょう" }
      short_name { "かつらぎ町" }
      short_yomi { "かつらぎちょう" }
    end

    factory :jmaxml_forecast_region_c3034300 do
      code { "3034300" }
      name { "和歌山県九度山町" }
      yomi { "わかやまけんくどやまちょう" }
      short_name { "九度山町" }
      short_yomi { "くどやまちょう" }
    end

    factory :jmaxml_forecast_region_c3034400 do
      code { "3034400" }
      name { "和歌山県高野町" }
      yomi { "わかやまけんこうやちょう" }
      short_name { "高野町" }
      short_yomi { "こうやちょう" }
    end

    factory :jmaxml_forecast_region_c3036100 do
      code { "3036100" }
      name { "和歌山県湯浅町" }
      yomi { "わかやまけんゆあさちょう" }
      short_name { "湯浅町" }
      short_yomi { "ゆあさちょう" }
    end

    factory :jmaxml_forecast_region_c3036200 do
      code { "3036200" }
      name { "和歌山県広川町" }
      yomi { "わかやまけんひろがわちょう" }
      short_name { "広川町" }
      short_yomi { "ひろがわちょう" }
    end

    factory :jmaxml_forecast_region_c3036600 do
      code { "3036600" }
      name { "和歌山県有田川町" }
      yomi { "わかやまけんありだがわちょう" }
      short_name { "有田川町" }
      short_yomi { "ありだがわちょう" }
    end

    factory :jmaxml_forecast_region_c3038100 do
      code { "3038100" }
      name { "和歌山県美浜町" }
      yomi { "わかやまけんみはまちょう" }
      short_name { "美浜町" }
      short_yomi { "みはまちょう" }
    end

    factory :jmaxml_forecast_region_c3038200 do
      code { "3038200" }
      name { "和歌山県日高町" }
      yomi { "わかやまけんひだかちょう" }
      short_name { "日高町" }
      short_yomi { "ひだかちょう" }
    end

    factory :jmaxml_forecast_region_c3038300 do
      code { "3038300" }
      name { "和歌山県由良町" }
      yomi { "わかやまけんゆらちょう" }
      short_name { "由良町" }
      short_yomi { "ゆらちょう" }
    end

    factory :jmaxml_forecast_region_c3039000 do
      code { "3039000" }
      name { "和歌山県印南町" }
      yomi { "わかやまけんいなみちょう" }
      short_name { "印南町" }
      short_yomi { "いなみちょう" }
    end

    factory :jmaxml_forecast_region_c3039100 do
      code { "3039100" }
      name { "和歌山県みなべ町" }
      yomi { "わかやまけんみなべちょう" }
      short_name { "みなべ町" }
      short_yomi { "みなべちょう" }
    end

    factory :jmaxml_forecast_region_c3039200 do
      code { "3039200" }
      name { "和歌山県日高川町" }
      yomi { "わかやまけんひだかがわちょう" }
      short_name { "日高川町" }
      short_yomi { "ひだかがわちょう" }
    end

    factory :jmaxml_forecast_region_c3040100 do
      code { "3040100" }
      name { "和歌山県白浜町" }
      yomi { "わかやまけんしらはまちょう" }
      short_name { "白浜町" }
      short_yomi { "しらはまちょう" }
    end

    factory :jmaxml_forecast_region_c3040400 do
      code { "3040400" }
      name { "和歌山県上富田町" }
      yomi { "わかやまけんかみとんだちょう" }
      short_name { "上富田町" }
      short_yomi { "かみとんだちょう" }
    end

    factory :jmaxml_forecast_region_c3040600 do
      code { "3040600" }
      name { "和歌山県すさみ町" }
      yomi { "わかやまけんすさみちょう" }
      short_name { "すさみ町" }
      short_yomi { "すさみちょう" }
    end

    factory :jmaxml_forecast_region_c3042100 do
      code { "3042100" }
      name { "和歌山県那智勝浦町" }
      yomi { "わかやまけんなちかつうらちょう" }
      short_name { "那智勝浦町" }
      short_yomi { "なちかつうらちょう" }
    end

    factory :jmaxml_forecast_region_c3042200 do
      code { "3042200" }
      name { "和歌山県太地町" }
      yomi { "わかやまけんたいじちょう" }
      short_name { "太地町" }
      short_yomi { "たいじちょう" }
    end

    factory :jmaxml_forecast_region_c3042400 do
      code { "3042400" }
      name { "和歌山県古座川町" }
      yomi { "わかやまけんこざがわちょう" }
      short_name { "古座川町" }
      short_yomi { "こざがわちょう" }
    end

    factory :jmaxml_forecast_region_c3042700 do
      code { "3042700" }
      name { "和歌山県北山村" }
      yomi { "わかやまけんきたやまむら" }
      short_name { "北山村" }
      short_yomi { "きたやまむら" }
    end

    factory :jmaxml_forecast_region_c3042800 do
      code { "3042800" }
      name { "和歌山県串本町" }
      yomi { "わかやまけんくしもとちょう" }
      short_name { "串本町" }
      short_yomi { "くしもとちょう" }
    end

    factory :jmaxml_forecast_region_c3120100 do
      code { "3120100" }
      name { "鳥取県鳥取市" }
      yomi { "とっとりけんとっとりし" }
      short_name { "鳥取市" }
      short_yomi { "とっとりし" }
    end

    factory :jmaxml_forecast_region_c3120200 do
      code { "3120200" }
      name { "鳥取県米子市" }
      yomi { "とっとりけんよなごし" }
      short_name { "米子市" }
      short_yomi { "よなごし" }
    end

    factory :jmaxml_forecast_region_c3120300 do
      code { "3120300" }
      name { "鳥取県倉吉市" }
      yomi { "とっとりけんくらよしし" }
      short_name { "倉吉市" }
      short_yomi { "くらよしし" }
    end

    factory :jmaxml_forecast_region_c3120400 do
      code { "3120400" }
      name { "鳥取県境港市" }
      yomi { "とっとりけんさかいみなとし" }
      short_name { "境港市" }
      short_yomi { "さかいみなとし" }
    end

    factory :jmaxml_forecast_region_c3130200 do
      code { "3130200" }
      name { "鳥取県岩美町" }
      yomi { "とっとりけんいわみちょう" }
      short_name { "岩美町" }
      short_yomi { "いわみちょう" }
    end

    factory :jmaxml_forecast_region_c3132500 do
      code { "3132500" }
      name { "鳥取県若桜町" }
      yomi { "とっとりけんわかさちょう" }
      short_name { "若桜町" }
      short_yomi { "わかさちょう" }
    end

    factory :jmaxml_forecast_region_c3132800 do
      code { "3132800" }
      name { "鳥取県智頭町" }
      yomi { "とっとりけんちづちょう" }
      short_name { "智頭町" }
      short_yomi { "ちづちょう" }
    end

    factory :jmaxml_forecast_region_c3132900 do
      code { "3132900" }
      name { "鳥取県八頭町" }
      yomi { "とっとりけんやずちょう" }
      short_name { "八頭町" }
      short_yomi { "やずちょう" }
    end

    factory :jmaxml_forecast_region_c3136400 do
      code { "3136400" }
      name { "鳥取県三朝町" }
      yomi { "とっとりけんみささちょう" }
      short_name { "三朝町" }
      short_yomi { "みささちょう" }
    end

    factory :jmaxml_forecast_region_c3137000 do
      code { "3137000" }
      name { "鳥取県湯梨浜町" }
      yomi { "とっとりけんゆりはまちょう" }
      short_name { "湯梨浜町" }
      short_yomi { "ゆりはまちょう" }
    end

    factory :jmaxml_forecast_region_c3137100 do
      code { "3137100" }
      name { "鳥取県琴浦町" }
      yomi { "とっとりけんことうらちょう" }
      short_name { "琴浦町" }
      short_yomi { "ことうらちょう" }
    end

    factory :jmaxml_forecast_region_c3137200 do
      code { "3137200" }
      name { "鳥取県北栄町" }
      yomi { "とっとりけんほくえいちょう" }
      short_name { "北栄町" }
      short_yomi { "ほくえいちょう" }
    end

    factory :jmaxml_forecast_region_c3138400 do
      code { "3138400" }
      name { "鳥取県日吉津村" }
      yomi { "とっとりけんひえづそん" }
      short_name { "日吉津村" }
      short_yomi { "ひえづそん" }
    end

    factory :jmaxml_forecast_region_c3138600 do
      code { "3138600" }
      name { "鳥取県大山町" }
      yomi { "とっとりけんだいせんちょう" }
      short_name { "大山町" }
      short_yomi { "だいせんちょう" }
    end

    factory :jmaxml_forecast_region_c3138900 do
      code { "3138900" }
      name { "鳥取県南部町" }
      yomi { "とっとりけんなんぶちょう" }
      short_name { "南部町" }
      short_yomi { "なんぶちょう" }
    end

    factory :jmaxml_forecast_region_c3139000 do
      code { "3139000" }
      name { "鳥取県伯耆町" }
      yomi { "とっとりけんほうきちょう" }
      short_name { "伯耆町" }
      short_yomi { "ほうきちょう" }
    end

    factory :jmaxml_forecast_region_c3140100 do
      code { "3140100" }
      name { "鳥取県日南町" }
      yomi { "とっとりけんにちなんちょう" }
      short_name { "日南町" }
      short_yomi { "にちなんちょう" }
    end

    factory :jmaxml_forecast_region_c3140200 do
      code { "3140200" }
      name { "鳥取県日野町" }
      yomi { "とっとりけんひのちょう" }
      short_name { "日野町" }
      short_yomi { "ひのちょう" }
    end

    factory :jmaxml_forecast_region_c3140300 do
      code { "3140300" }
      name { "鳥取県江府町" }
      yomi { "とっとりけんこうふちょう" }
      short_name { "江府町" }
      short_yomi { "こうふちょう" }
    end

    factory :jmaxml_forecast_region_c3220100 do
      code { "3220100" }
      name { "島根県松江市" }
      yomi { "しまねけんまつえし" }
      short_name { "松江市" }
      short_yomi { "まつえし" }
    end

    factory :jmaxml_forecast_region_c3220200 do
      code { "3220200" }
      name { "島根県浜田市" }
      yomi { "しまねけんはまだし" }
      short_name { "浜田市" }
      short_yomi { "はまだし" }
    end

    factory :jmaxml_forecast_region_c3220300 do
      code { "3220300" }
      name { "島根県出雲市" }
      yomi { "しまねけんいずもし" }
      short_name { "出雲市" }
      short_yomi { "いずもし" }
    end

    factory :jmaxml_forecast_region_c3220400 do
      code { "3220400" }
      name { "島根県益田市" }
      yomi { "しまねけんますだし" }
      short_name { "益田市" }
      short_yomi { "ますだし" }
    end

    factory :jmaxml_forecast_region_c3220500 do
      code { "3220500" }
      name { "島根県大田市" }
      yomi { "しまねけんおおだし" }
      short_name { "大田市" }
      short_yomi { "おおだし" }
    end

    factory :jmaxml_forecast_region_c3220600 do
      code { "3220600" }
      name { "島根県安来市" }
      yomi { "しまねけんやすぎし" }
      short_name { "安来市" }
      short_yomi { "やすぎし" }
    end

    factory :jmaxml_forecast_region_c3220700 do
      code { "3220700" }
      name { "島根県江津市" }
      yomi { "しまねけんごうつし" }
      short_name { "江津市" }
      short_yomi { "ごうつし" }
    end

    factory :jmaxml_forecast_region_c3220900 do
      code { "3220900" }
      name { "島根県雲南市" }
      yomi { "しまねけんうんなんし" }
      short_name { "雲南市" }
      short_yomi { "うんなんし" }
    end

    factory :jmaxml_forecast_region_c3234300 do
      code { "3234300" }
      name { "島根県奥出雲町" }
      yomi { "しまねけんおくいずもちょう" }
      short_name { "奥出雲町" }
      short_yomi { "おくいずもちょう" }
    end

    factory :jmaxml_forecast_region_c3238600 do
      code { "3238600" }
      name { "島根県飯南町" }
      yomi { "しまねけんいいなんちょう" }
      short_name { "飯南町" }
      short_yomi { "いいなんちょう" }
    end

    factory :jmaxml_forecast_region_c3244100 do
      code { "3244100" }
      name { "島根県川本町" }
      yomi { "しまねけんかわもとまち" }
      short_name { "川本町" }
      short_yomi { "かわもとまち" }
    end

    factory :jmaxml_forecast_region_c3244800 do
      code { "3244800" }
      name { "島根県美郷町" }
      yomi { "しまねけんみさとちょう" }
      short_name { "美郷町" }
      short_yomi { "みさとちょう" }
    end

    factory :jmaxml_forecast_region_c3244900 do
      code { "3244900" }
      name { "島根県邑南町" }
      yomi { "しまねけんおおなんちょう" }
      short_name { "邑南町" }
      short_yomi { "おおなんちょう" }
    end

    factory :jmaxml_forecast_region_c3250100 do
      code { "3250100" }
      name { "島根県津和野町" }
      yomi { "しまねけんつわのちょう" }
      short_name { "津和野町" }
      short_yomi { "つわのちょう" }
    end

    factory :jmaxml_forecast_region_c3250500 do
      code { "3250500" }
      name { "島根県吉賀町" }
      yomi { "しまねけんよしかちょう" }
      short_name { "吉賀町" }
      short_yomi { "よしかちょう" }
    end

    factory :jmaxml_forecast_region_c3252500 do
      code { "3252500" }
      name { "島根県海士町" }
      yomi { "しまねけんあまちょう" }
      short_name { "海士町" }
      short_yomi { "あまちょう" }
    end

    factory :jmaxml_forecast_region_c3252600 do
      code { "3252600" }
      name { "島根県西ノ島町" }
      yomi { "しまねけんにしのしまちょう" }
      short_name { "西ノ島町" }
      short_yomi { "にしのしまちょう" }
    end

    factory :jmaxml_forecast_region_c3252700 do
      code { "3252700" }
      name { "島根県知夫村" }
      yomi { "しまねけんちぶむら" }
      short_name { "知夫村" }
      short_yomi { "ちぶむら" }
    end

    factory :jmaxml_forecast_region_c3252800 do
      code { "3252800" }
      name { "島根県隠岐の島町" }
      yomi { "しまねけんおきのしまちょう" }
      short_name { "隠岐の島町" }
      short_yomi { "おきのしまちょう" }
    end

    factory :jmaxml_forecast_region_c3310000 do
      code { "3310000" }
      name { "岡山県岡山市" }
      yomi { "おかやまけんおかやまし" }
      short_name { "岡山市" }
      short_yomi { "おかやまし" }
    end

    factory :jmaxml_forecast_region_c3320200 do
      code { "3320200" }
      name { "岡山県倉敷市" }
      yomi { "おかやまけんくらしきし" }
      short_name { "倉敷市" }
      short_yomi { "くらしきし" }
    end

    factory :jmaxml_forecast_region_c3320300 do
      code { "3320300" }
      name { "岡山県津山市" }
      yomi { "おかやまけんつやまし" }
      short_name { "津山市" }
      short_yomi { "つやまし" }
    end

    factory :jmaxml_forecast_region_c3320400 do
      code { "3320400" }
      name { "岡山県玉野市" }
      yomi { "おかやまけんたまのし" }
      short_name { "玉野市" }
      short_yomi { "たまのし" }
    end

    factory :jmaxml_forecast_region_c3320500 do
      code { "3320500" }
      name { "岡山県笠岡市" }
      yomi { "おかやまけんかさおかし" }
      short_name { "笠岡市" }
      short_yomi { "かさおかし" }
    end

    factory :jmaxml_forecast_region_c3320700 do
      code { "3320700" }
      name { "岡山県井原市" }
      yomi { "おかやまけんいばらし" }
      short_name { "井原市" }
      short_yomi { "いばらし" }
    end

    factory :jmaxml_forecast_region_c3320800 do
      code { "3320800" }
      name { "岡山県総社市" }
      yomi { "おかやまけんそうじゃし" }
      short_name { "総社市" }
      short_yomi { "そうじゃし" }
    end

    factory :jmaxml_forecast_region_c3320900 do
      code { "3320900" }
      name { "岡山県高梁市" }
      yomi { "おかやまけんたかはしし" }
      short_name { "高梁市" }
      short_yomi { "たかはしし" }
    end

    factory :jmaxml_forecast_region_c3321000 do
      code { "3321000" }
      name { "岡山県新見市" }
      yomi { "おかやまけんにいみし" }
      short_name { "新見市" }
      short_yomi { "にいみし" }
    end

    factory :jmaxml_forecast_region_c3321100 do
      code { "3321100" }
      name { "岡山県備前市" }
      yomi { "おかやまけんびぜんし" }
      short_name { "備前市" }
      short_yomi { "びぜんし" }
    end

    factory :jmaxml_forecast_region_c3321200 do
      code { "3321200" }
      name { "岡山県瀬戸内市" }
      yomi { "おかやまけんせとうちし" }
      short_name { "瀬戸内市" }
      short_yomi { "せとうちし" }
    end

    factory :jmaxml_forecast_region_c3321300 do
      code { "3321300" }
      name { "岡山県赤磐市" }
      yomi { "おかやまけんあかいわし" }
      short_name { "赤磐市" }
      short_yomi { "あかいわし" }
    end

    factory :jmaxml_forecast_region_c3321400 do
      code { "3321400" }
      name { "岡山県真庭市" }
      yomi { "おかやまけんまにわし" }
      short_name { "真庭市" }
      short_yomi { "まにわし" }
    end

    factory :jmaxml_forecast_region_c3321500 do
      code { "3321500" }
      name { "岡山県美作市" }
      yomi { "おかやまけんみまさかし" }
      short_name { "美作市" }
      short_yomi { "みまさかし" }
    end

    factory :jmaxml_forecast_region_c3321600 do
      code { "3321600" }
      name { "岡山県浅口市" }
      yomi { "おかやまけんあさくちし" }
      short_name { "浅口市" }
      short_yomi { "あさくちし" }
    end

    factory :jmaxml_forecast_region_c3334600 do
      code { "3334600" }
      name { "岡山県和気町" }
      yomi { "おかやまけんわけちょう" }
      short_name { "和気町" }
      short_yomi { "わけちょう" }
    end

    factory :jmaxml_forecast_region_c3342300 do
      code { "3342300" }
      name { "岡山県早島町" }
      yomi { "おかやまけんはやしまちょう" }
      short_name { "早島町" }
      short_yomi { "はやしまちょう" }
    end

    factory :jmaxml_forecast_region_c3344500 do
      code { "3344500" }
      name { "岡山県里庄町" }
      yomi { "おかやまけんさとしょうちょう" }
      short_name { "里庄町" }
      short_yomi { "さとしょうちょう" }
    end

    factory :jmaxml_forecast_region_c3346100 do
      code { "3346100" }
      name { "岡山県矢掛町" }
      yomi { "おかやまけんやかげちょう" }
      short_name { "矢掛町" }
      short_yomi { "やかげちょう" }
    end

    factory :jmaxml_forecast_region_c3358600 do
      code { "3358600" }
      name { "岡山県新庄村" }
      yomi { "おかやまけんしんじょうそん" }
      short_name { "新庄村" }
      short_yomi { "しんじょうそん" }
    end

    factory :jmaxml_forecast_region_c3360600 do
      code { "3360600" }
      name { "岡山県鏡野町" }
      yomi { "おかやまけんかがみのちょう" }
      short_name { "鏡野町" }
      short_yomi { "かがみのちょう" }
    end

    factory :jmaxml_forecast_region_c3362200 do
      code { "3362200" }
      name { "岡山県勝央町" }
      yomi { "おかやまけんしょうおうちょう" }
      short_name { "勝央町" }
      short_yomi { "しょうおうちょう" }
    end

    factory :jmaxml_forecast_region_c3362300 do
      code { "3362300" }
      name { "岡山県奈義町" }
      yomi { "おかやまけんなぎちょう" }
      short_name { "奈義町" }
      short_yomi { "なぎちょう" }
    end

    factory :jmaxml_forecast_region_c3364300 do
      code { "3364300" }
      name { "岡山県西粟倉村" }
      yomi { "おかやまけんにしあわくらそん" }
      short_name { "西粟倉村" }
      short_yomi { "にしあわくらそん" }
    end

    factory :jmaxml_forecast_region_c3366300 do
      code { "3366300" }
      name { "岡山県久米南町" }
      yomi { "おかやまけんくめなんちょう" }
      short_name { "久米南町" }
      short_yomi { "くめなんちょう" }
    end

    factory :jmaxml_forecast_region_c3366600 do
      code { "3366600" }
      name { "岡山県美咲町" }
      yomi { "おかやまけんみさきちょう" }
      short_name { "美咲町" }
      short_yomi { "みさきちょう" }
    end

    factory :jmaxml_forecast_region_c3368100 do
      code { "3368100" }
      name { "岡山県吉備中央町" }
      yomi { "おかやまけんきびちゅうおうちょう" }
      short_name { "吉備中央町" }
      short_yomi { "きびちゅうおうちょう" }
    end

    factory :jmaxml_forecast_region_c3410000 do
      code { "3410000" }
      name { "広島県広島市" }
      yomi { "ひろしまけんひろしまし" }
      short_name { "広島市" }
      short_yomi { "ひろしまし" }
    end

    factory :jmaxml_forecast_region_c3420200 do
      code { "3420200" }
      name { "広島県呉市" }
      yomi { "ひろしまけんくれし" }
      short_name { "呉市" }
      short_yomi { "くれし" }
    end

    factory :jmaxml_forecast_region_c3420300 do
      code { "3420300" }
      name { "広島県竹原市" }
      yomi { "ひろしまけんたけはらし" }
      short_name { "竹原市" }
      short_yomi { "たけはらし" }
    end

    factory :jmaxml_forecast_region_c3420400 do
      code { "3420400" }
      name { "広島県三原市" }
      yomi { "ひろしまけんみはらし" }
      short_name { "三原市" }
      short_yomi { "みはらし" }
    end

    factory :jmaxml_forecast_region_c3420500 do
      code { "3420500" }
      name { "広島県尾道市" }
      yomi { "ひろしまけんおのみちし" }
      short_name { "尾道市" }
      short_yomi { "おのみちし" }
    end

    factory :jmaxml_forecast_region_c3420700 do
      code { "3420700" }
      name { "広島県福山市" }
      yomi { "ひろしまけんふくやまし" }
      short_name { "福山市" }
      short_yomi { "ふくやまし" }
    end

    factory :jmaxml_forecast_region_c3420800 do
      code { "3420800" }
      name { "広島県府中市" }
      yomi { "ひろしまけんふちゅうし" }
      short_name { "府中市" }
      short_yomi { "ふちゅうし" }
    end

    factory :jmaxml_forecast_region_c3420900 do
      code { "3420900" }
      name { "広島県三次市" }
      yomi { "ひろしまけんみよしし" }
      short_name { "三次市" }
      short_yomi { "みよしし" }
    end

    factory :jmaxml_forecast_region_c3421000 do
      code { "3421000" }
      name { "広島県庄原市" }
      yomi { "ひろしまけんしょうばらし" }
      short_name { "庄原市" }
      short_yomi { "しょうばらし" }
    end

    factory :jmaxml_forecast_region_c3421100 do
      code { "3421100" }
      name { "広島県大竹市" }
      yomi { "ひろしまけんおおたけし" }
      short_name { "大竹市" }
      short_yomi { "おおたけし" }
    end

    factory :jmaxml_forecast_region_c3421200 do
      code { "3421200" }
      name { "広島県東広島市" }
      yomi { "ひろしまけんひがしひろしまし" }
      short_name { "東広島市" }
      short_yomi { "ひがしひろしまし" }
    end

    factory :jmaxml_forecast_region_c3421300 do
      code { "3421300" }
      name { "広島県廿日市市" }
      yomi { "ひろしまけんはつかいちし" }
      short_name { "廿日市市" }
      short_yomi { "はつかいちし" }
    end

    factory :jmaxml_forecast_region_c3421400 do
      code { "3421400" }
      name { "広島県安芸高田市" }
      yomi { "ひろしまけんあきたかたし" }
      short_name { "安芸高田市" }
      short_yomi { "あきたかたし" }
    end

    factory :jmaxml_forecast_region_c3421500 do
      code { "3421500" }
      name { "広島県江田島市" }
      yomi { "ひろしまけんえたじまし" }
      short_name { "江田島市" }
      short_yomi { "えたじまし" }
    end

    factory :jmaxml_forecast_region_c3430200 do
      code { "3430200" }
      name { "広島県府中町" }
      yomi { "ひろしまけんふちゅうちょう" }
      short_name { "府中町" }
      short_yomi { "ふちゅうちょう" }
    end

    factory :jmaxml_forecast_region_c3430400 do
      code { "3430400" }
      name { "広島県海田町" }
      yomi { "ひろしまけんかいたちょう" }
      short_name { "海田町" }
      short_yomi { "かいたちょう" }
    end

    factory :jmaxml_forecast_region_c3430700 do
      code { "3430700" }
      name { "広島県熊野町" }
      yomi { "ひろしまけんくまのちょう" }
      short_name { "熊野町" }
      short_yomi { "くまのちょう" }
    end

    factory :jmaxml_forecast_region_c3430900 do
      code { "3430900" }
      name { "広島県坂町" }
      yomi { "ひろしまけんさかちょう" }
      short_name { "坂町" }
      short_yomi { "さかちょう" }
    end

    factory :jmaxml_forecast_region_c3436800 do
      code { "3436800" }
      name { "広島県安芸太田町" }
      yomi { "ひろしまけんあきおおたちょう" }
      short_name { "安芸太田町" }
      short_yomi { "あきおおたちょう" }
    end

    factory :jmaxml_forecast_region_c3436900 do
      code { "3436900" }
      name { "広島県北広島町" }
      yomi { "ひろしまけんきたひろしまちょう" }
      short_name { "北広島町" }
      short_yomi { "きたひろしまちょう" }
    end

    factory :jmaxml_forecast_region_c3443100 do
      code { "3443100" }
      name { "広島県大崎上島町" }
      yomi { "ひろしまけんおおさきかみじまちょう" }
      short_name { "大崎上島町" }
      short_yomi { "おおさきかみじまちょう" }
    end

    factory :jmaxml_forecast_region_c3446200 do
      code { "3446200" }
      name { "広島県世羅町" }
      yomi { "ひろしまけんせらちょう" }
      short_name { "世羅町" }
      short_yomi { "せらちょう" }
    end

    factory :jmaxml_forecast_region_c3454500 do
      code { "3454500" }
      name { "広島県神石高原町" }
      yomi { "ひろしまけんじんせきこうげんちょう" }
      short_name { "神石高原町" }
      short_yomi { "じんせきこうげんちょう" }
    end

    factory :jmaxml_forecast_region_c3520100 do
      code { "3520100" }
      name { "山口県下関市" }
      yomi { "やまぐちけんしものせきし" }
      short_name { "下関市" }
      short_yomi { "しものせきし" }
    end

    factory :jmaxml_forecast_region_c3520200 do
      code { "3520200" }
      name { "山口県宇部市" }
      yomi { "やまぐちけんうべし" }
      short_name { "宇部市" }
      short_yomi { "うべし" }
    end

    factory :jmaxml_forecast_region_c3520300 do
      code { "3520300" }
      name { "山口県山口市" }
      yomi { "やまぐちけんやまぐちし" }
      short_name { "山口市" }
      short_yomi { "やまぐちし" }
    end

    factory :jmaxml_forecast_region_c3520400 do
      code { "3520400" }
      name { "山口県萩市" }
      yomi { "やまぐちけんはぎし" }
      short_name { "萩市" }
      short_yomi { "はぎし" }
    end

    factory :jmaxml_forecast_region_c3520600 do
      code { "3520600" }
      name { "山口県防府市" }
      yomi { "やまぐちけんほうふし" }
      short_name { "防府市" }
      short_yomi { "ほうふし" }
    end

    factory :jmaxml_forecast_region_c3520700 do
      code { "3520700" }
      name { "山口県下松市" }
      yomi { "やまぐちけんくだまつし" }
      short_name { "下松市" }
      short_yomi { "くだまつし" }
    end

    factory :jmaxml_forecast_region_c3520800 do
      code { "3520800" }
      name { "山口県岩国市" }
      yomi { "やまぐちけんいわくにし" }
      short_name { "岩国市" }
      short_yomi { "いわくにし" }
    end

    factory :jmaxml_forecast_region_c3521000 do
      code { "3521000" }
      name { "山口県光市" }
      yomi { "やまぐちけんひかりし" }
      short_name { "光市" }
      short_yomi { "ひかりし" }
    end

    factory :jmaxml_forecast_region_c3521100 do
      code { "3521100" }
      name { "山口県長門市" }
      yomi { "やまぐちけんながとし" }
      short_name { "長門市" }
      short_yomi { "ながとし" }
    end

    factory :jmaxml_forecast_region_c3521200 do
      code { "3521200" }
      name { "山口県柳井市" }
      yomi { "やまぐちけんやないし" }
      short_name { "柳井市" }
      short_yomi { "やないし" }
    end

    factory :jmaxml_forecast_region_c3521300 do
      code { "3521300" }
      name { "山口県美祢市" }
      yomi { "やまぐちけんみねし" }
      short_name { "美祢市" }
      short_yomi { "みねし" }
    end

    factory :jmaxml_forecast_region_c3521500 do
      code { "3521500" }
      name { "山口県周南市" }
      yomi { "やまぐちけんしゅうなんし" }
      short_name { "周南市" }
      short_yomi { "しゅうなんし" }
    end

    factory :jmaxml_forecast_region_c3521600 do
      code { "3521600" }
      name { "山口県山陽小野田市" }
      yomi { "やまぐちけんさんようおのだし" }
      short_name { "山陽小野田市" }
      short_yomi { "さんようおのだし" }
    end

    factory :jmaxml_forecast_region_c3530500 do
      code { "3530500" }
      name { "山口県周防大島町" }
      yomi { "やまぐちけんすおうおおしまちょう" }
      short_name { "周防大島町" }
      short_yomi { "すおうおおしまちょう" }
    end

    factory :jmaxml_forecast_region_c3532100 do
      code { "3532100" }
      name { "山口県和木町" }
      yomi { "やまぐちけんわきちょう" }
      short_name { "和木町" }
      short_yomi { "わきちょう" }
    end

    factory :jmaxml_forecast_region_c3534100 do
      code { "3534100" }
      name { "山口県上関町" }
      yomi { "やまぐちけんかみのせきちょう" }
      short_name { "上関町" }
      short_yomi { "かみのせきちょう" }
    end

    factory :jmaxml_forecast_region_c3534300 do
      code { "3534300" }
      name { "山口県田布施町" }
      yomi { "やまぐちけんたぶせちょう" }
      short_name { "田布施町" }
      short_yomi { "たぶせちょう" }
    end

    factory :jmaxml_forecast_region_c3534400 do
      code { "3534400" }
      name { "山口県平生町" }
      yomi { "やまぐちけんひらおちょう" }
      short_name { "平生町" }
      short_yomi { "ひらおちょう" }
    end

    factory :jmaxml_forecast_region_c3550200 do
      code { "3550200" }
      name { "山口県阿武町" }
      yomi { "やまぐちけんあぶちょう" }
      short_name { "阿武町" }
      short_yomi { "あぶちょう" }
    end

    factory :jmaxml_forecast_region_c3620100 do
      code { "3620100" }
      name { "徳島県徳島市" }
      yomi { "とくしまけんとくしまし" }
      short_name { "徳島市" }
      short_yomi { "とくしまし" }
    end

    factory :jmaxml_forecast_region_c3620200 do
      code { "3620200" }
      name { "徳島県鳴門市" }
      yomi { "とくしまけんなるとし" }
      short_name { "鳴門市" }
      short_yomi { "なるとし" }
    end

    factory :jmaxml_forecast_region_c3620300 do
      code { "3620300" }
      name { "徳島県小松島市" }
      yomi { "とくしまけんこまつしまし" }
      short_name { "小松島市" }
      short_yomi { "こまつしまし" }
    end

    factory :jmaxml_forecast_region_c3620400 do
      code { "3620400" }
      name { "徳島県阿南市" }
      yomi { "とくしまけんあなんし" }
      short_name { "阿南市" }
      short_yomi { "あなんし" }
    end

    factory :jmaxml_forecast_region_c3620500 do
      code { "3620500" }
      name { "徳島県吉野川市" }
      yomi { "とくしまけんよしのがわし" }
      short_name { "吉野川市" }
      short_yomi { "よしのがわし" }
    end

    factory :jmaxml_forecast_region_c3620600 do
      code { "3620600" }
      name { "徳島県阿波市" }
      yomi { "とくしまけんあわし" }
      short_name { "阿波市" }
      short_yomi { "あわし" }
    end

    factory :jmaxml_forecast_region_c3620700 do
      code { "3620700" }
      name { "徳島県美馬市" }
      yomi { "とくしまけんみまし" }
      short_name { "美馬市" }
      short_yomi { "みまし" }
    end

    factory :jmaxml_forecast_region_c3620800 do
      code { "3620800" }
      name { "徳島県三好市" }
      yomi { "とくしまけんみよしし" }
      short_name { "三好市" }
      short_yomi { "みよしし" }
    end

    factory :jmaxml_forecast_region_c3630100 do
      code { "3630100" }
      name { "徳島県勝浦町" }
      yomi { "とくしまけんかつうらちょう" }
      short_name { "勝浦町" }
      short_yomi { "かつうらちょう" }
    end

    factory :jmaxml_forecast_region_c3630200 do
      code { "3630200" }
      name { "徳島県上勝町" }
      yomi { "とくしまけんかみかつちょう" }
      short_name { "上勝町" }
      short_yomi { "かみかつちょう" }
    end

    factory :jmaxml_forecast_region_c3632100 do
      code { "3632100" }
      name { "徳島県佐那河内村" }
      yomi { "とくしまけんさなごうちそん" }
      short_name { "佐那河内村" }
      short_yomi { "さなごうちそん" }
    end

    factory :jmaxml_forecast_region_c3634100 do
      code { "3634100" }
      name { "徳島県石井町" }
      yomi { "とくしまけんいしいちょう" }
      short_name { "石井町" }
      short_yomi { "いしいちょう" }
    end

    factory :jmaxml_forecast_region_c3634200 do
      code { "3634200" }
      name { "徳島県神山町" }
      yomi { "とくしまけんかみやまちょう" }
      short_name { "神山町" }
      short_yomi { "かみやまちょう" }
    end

    factory :jmaxml_forecast_region_c3636800 do
      code { "3636800" }
      name { "徳島県那賀町" }
      yomi { "とくしまけんなかちょう" }
      short_name { "那賀町" }
      short_yomi { "なかちょう" }
    end

    factory :jmaxml_forecast_region_c3638300 do
      code { "3638300" }
      name { "徳島県牟岐町" }
      yomi { "とくしまけんむぎちょう" }
      short_name { "牟岐町" }
      short_yomi { "むぎちょう" }
    end

    factory :jmaxml_forecast_region_c3638700 do
      code { "3638700" }
      name { "徳島県美波町" }
      yomi { "とくしまけんみなみちょう" }
      short_name { "美波町" }
      short_yomi { "みなみちょう" }
    end

    factory :jmaxml_forecast_region_c3638800 do
      code { "3638800" }
      name { "徳島県海陽町" }
      yomi { "とくしまけんかいようちょう" }
      short_name { "海陽町" }
      short_yomi { "かいようちょう" }
    end

    factory :jmaxml_forecast_region_c3640100 do
      code { "3640100" }
      name { "徳島県松茂町" }
      yomi { "とくしまけんまつしげちょう" }
      short_name { "松茂町" }
      short_yomi { "まつしげちょう" }
    end

    factory :jmaxml_forecast_region_c3640200 do
      code { "3640200" }
      name { "徳島県北島町" }
      yomi { "とくしまけんきたじまちょう" }
      short_name { "北島町" }
      short_yomi { "きたじまちょう" }
    end

    factory :jmaxml_forecast_region_c3640300 do
      code { "3640300" }
      name { "徳島県藍住町" }
      yomi { "とくしまけんあいずみちょう" }
      short_name { "藍住町" }
      short_yomi { "あいずみちょう" }
    end

    factory :jmaxml_forecast_region_c3640400 do
      code { "3640400" }
      name { "徳島県板野町" }
      yomi { "とくしまけんいたのちょう" }
      short_name { "板野町" }
      short_yomi { "いたのちょう" }
    end

    factory :jmaxml_forecast_region_c3640500 do
      code { "3640500" }
      name { "徳島県上板町" }
      yomi { "とくしまけんかみいたちょう" }
      short_name { "上板町" }
      short_yomi { "かみいたちょう" }
    end

    factory :jmaxml_forecast_region_c3646800 do
      code { "3646800" }
      name { "徳島県つるぎ町" }
      yomi { "とくしまけんつるぎちょう" }
      short_name { "つるぎ町" }
      short_yomi { "つるぎちょう" }
    end

    factory :jmaxml_forecast_region_c3648900 do
      code { "3648900" }
      name { "徳島県東みよし町" }
      yomi { "とくしまけんひがしみよしちょう" }
      short_name { "東みよし町" }
      short_yomi { "ひがしみよしちょう" }
    end

    factory :jmaxml_forecast_region_c3720100 do
      code { "3720100" }
      name { "香川県高松市" }
      yomi { "かがわけんたかまつし" }
      short_name { "高松市" }
      short_yomi { "たかまつし" }
    end

    factory :jmaxml_forecast_region_c3720200 do
      code { "3720200" }
      name { "香川県丸亀市" }
      yomi { "かがわけんまるがめし" }
      short_name { "丸亀市" }
      short_yomi { "まるがめし" }
    end

    factory :jmaxml_forecast_region_c3720300 do
      code { "3720300" }
      name { "香川県坂出市" }
      yomi { "かがわけんさかいでし" }
      short_name { "坂出市" }
      short_yomi { "さかいでし" }
    end

    factory :jmaxml_forecast_region_c3720400 do
      code { "3720400" }
      name { "香川県善通寺市" }
      yomi { "かがわけんぜんつうじし" }
      short_name { "善通寺市" }
      short_yomi { "ぜんつうじし" }
    end

    factory :jmaxml_forecast_region_c3720500 do
      code { "3720500" }
      name { "香川県観音寺市" }
      yomi { "かがわけんかんおんじし" }
      short_name { "観音寺市" }
      short_yomi { "かんおんじし" }
    end

    factory :jmaxml_forecast_region_c3720600 do
      code { "3720600" }
      name { "香川県さぬき市" }
      yomi { "かがわけんさぬきし" }
      short_name { "さぬき市" }
      short_yomi { "さぬきし" }
    end

    factory :jmaxml_forecast_region_c3720700 do
      code { "3720700" }
      name { "香川県東かがわ市" }
      yomi { "かがわけんひがしかがわし" }
      short_name { "東かがわ市" }
      short_yomi { "ひがしかがわし" }
    end

    factory :jmaxml_forecast_region_c3720800 do
      code { "3720800" }
      name { "香川県三豊市" }
      yomi { "かがわけんみとよし" }
      short_name { "三豊市" }
      short_yomi { "みとよし" }
    end

    factory :jmaxml_forecast_region_c3732200 do
      code { "3732200" }
      name { "香川県土庄町" }
      yomi { "かがわけんとのしょうちょう" }
      short_name { "土庄町" }
      short_yomi { "とのしょうちょう" }
    end

    factory :jmaxml_forecast_region_c3732400 do
      code { "3732400" }
      name { "香川県小豆島町" }
      yomi { "かがわけんしょうどしまちょう" }
      short_name { "小豆島町" }
      short_yomi { "しょうどしまちょう" }
    end

    factory :jmaxml_forecast_region_c3734100 do
      code { "3734100" }
      name { "香川県三木町" }
      yomi { "かがわけんみきちょう" }
      short_name { "三木町" }
      short_yomi { "みきちょう" }
    end

    factory :jmaxml_forecast_region_c3736400 do
      code { "3736400" }
      name { "香川県直島町" }
      yomi { "かがわけんなおしまちょう" }
      short_name { "直島町" }
      short_yomi { "なおしまちょう" }
    end

    factory :jmaxml_forecast_region_c3738600 do
      code { "3738600" }
      name { "香川県宇多津町" }
      yomi { "かがわけんうたづちょう" }
      short_name { "宇多津町" }
      short_yomi { "うたづちょう" }
    end

    factory :jmaxml_forecast_region_c3738700 do
      code { "3738700" }
      name { "香川県綾川町" }
      yomi { "かがわけんあやがわちょう" }
      short_name { "綾川町" }
      short_yomi { "あやがわちょう" }
    end

    factory :jmaxml_forecast_region_c3740300 do
      code { "3740300" }
      name { "香川県琴平町" }
      yomi { "かがわけんことひらちょう" }
      short_name { "琴平町" }
      short_yomi { "ことひらちょう" }
    end

    factory :jmaxml_forecast_region_c3740400 do
      code { "3740400" }
      name { "香川県多度津町" }
      yomi { "かがわけんたどつちょう" }
      short_name { "多度津町" }
      short_yomi { "たどつちょう" }
    end

    factory :jmaxml_forecast_region_c3740600 do
      code { "3740600" }
      name { "香川県まんのう町" }
      yomi { "かがわけんまんのうちょう" }
      short_name { "まんのう町" }
      short_yomi { "まんのうちょう" }
    end

    factory :jmaxml_forecast_region_c3820100 do
      code { "3820100" }
      name { "愛媛県松山市" }
      yomi { "えひめけんまつやまし" }
      short_name { "松山市" }
      short_yomi { "まつやまし" }
    end

    factory :jmaxml_forecast_region_c3820200 do
      code { "3820200" }
      name { "愛媛県今治市" }
      yomi { "えひめけんいまばりし" }
      short_name { "今治市" }
      short_yomi { "いまばりし" }
    end

    factory :jmaxml_forecast_region_c3820300 do
      code { "3820300" }
      name { "愛媛県宇和島市" }
      yomi { "えひめけんうわじまし" }
      short_name { "宇和島市" }
      short_yomi { "うわじまし" }
    end

    factory :jmaxml_forecast_region_c3820400 do
      code { "3820400" }
      name { "愛媛県八幡浜市" }
      yomi { "えひめけんやわたはまし" }
      short_name { "八幡浜市" }
      short_yomi { "やわたはまし" }
    end

    factory :jmaxml_forecast_region_c3820500 do
      code { "3820500" }
      name { "愛媛県新居浜市" }
      yomi { "えひめけんにいはまし" }
      short_name { "新居浜市" }
      short_yomi { "にいはまし" }
    end

    factory :jmaxml_forecast_region_c3820600 do
      code { "3820600" }
      name { "愛媛県西条市" }
      yomi { "えひめけんさいじょうし" }
      short_name { "西条市" }
      short_yomi { "さいじょうし" }
    end

    factory :jmaxml_forecast_region_c3820700 do
      code { "3820700" }
      name { "愛媛県大洲市" }
      yomi { "えひめけんおおずし" }
      short_name { "大洲市" }
      short_yomi { "おおずし" }
    end

    factory :jmaxml_forecast_region_c3821000 do
      code { "3821000" }
      name { "愛媛県伊予市" }
      yomi { "えひめけんいよし" }
      short_name { "伊予市" }
      short_yomi { "いよし" }
    end

    factory :jmaxml_forecast_region_c3821300 do
      code { "3821300" }
      name { "愛媛県四国中央市" }
      yomi { "えひめけんしこくちゅうおうし" }
      short_name { "四国中央市" }
      short_yomi { "しこくちゅうおうし" }
    end

    factory :jmaxml_forecast_region_c3821400 do
      code { "3821400" }
      name { "愛媛県西予市" }
      yomi { "えひめけんせいよし" }
      short_name { "西予市" }
      short_yomi { "せいよし" }
    end

    factory :jmaxml_forecast_region_c3821500 do
      code { "3821500" }
      name { "愛媛県東温市" }
      yomi { "えひめけんとうおんし" }
      short_name { "東温市" }
      short_yomi { "とうおんし" }
    end

    factory :jmaxml_forecast_region_c3835600 do
      code { "3835600" }
      name { "愛媛県上島町" }
      yomi { "えひめけんかみじまちょう" }
      short_name { "上島町" }
      short_yomi { "かみじまちょう" }
    end

    factory :jmaxml_forecast_region_c3838600 do
      code { "3838600" }
      name { "愛媛県久万高原町" }
      yomi { "えひめけんくまこうげんちょう" }
      short_name { "久万高原町" }
      short_yomi { "くまこうげんちょう" }
    end

    factory :jmaxml_forecast_region_c3840100 do
      code { "3840100" }
      name { "愛媛県松前町" }
      yomi { "えひめけんまさきちょう" }
      short_name { "松前町" }
      short_yomi { "まさきちょう" }
    end

    factory :jmaxml_forecast_region_c3840200 do
      code { "3840200" }
      name { "愛媛県砥部町" }
      yomi { "えひめけんとべちょう" }
      short_name { "砥部町" }
      short_yomi { "とべちょう" }
    end

    factory :jmaxml_forecast_region_c3842200 do
      code { "3842200" }
      name { "愛媛県内子町" }
      yomi { "えひめけんうちこちょう" }
      short_name { "内子町" }
      short_yomi { "うちこちょう" }
    end

    factory :jmaxml_forecast_region_c3844200 do
      code { "3844200" }
      name { "愛媛県伊方町" }
      yomi { "えひめけんいかたちょう" }
      short_name { "伊方町" }
      short_yomi { "いかたちょう" }
    end

    factory :jmaxml_forecast_region_c3848400 do
      code { "3848400" }
      name { "愛媛県松野町" }
      yomi { "えひめけんまつのちょう" }
      short_name { "松野町" }
      short_yomi { "まつのちょう" }
    end

    factory :jmaxml_forecast_region_c3848800 do
      code { "3848800" }
      name { "愛媛県鬼北町" }
      yomi { "えひめけんきほくちょう" }
      short_name { "鬼北町" }
      short_yomi { "きほくちょう" }
    end

    factory :jmaxml_forecast_region_c3850600 do
      code { "3850600" }
      name { "愛媛県愛南町" }
      yomi { "えひめけんあいなんちょう" }
      short_name { "愛南町" }
      short_yomi { "あいなんちょう" }
    end

    factory :jmaxml_forecast_region_c3920100 do
      code { "3920100" }
      name { "高知県高知市" }
      yomi { "こうちけんこうちし" }
      short_name { "高知市" }
      short_yomi { "こうちし" }
    end

    factory :jmaxml_forecast_region_c3920200 do
      code { "3920200" }
      name { "高知県室戸市" }
      yomi { "こうちけんむろとし" }
      short_name { "室戸市" }
      short_yomi { "むろとし" }
    end

    factory :jmaxml_forecast_region_c3920300 do
      code { "3920300" }
      name { "高知県安芸市" }
      yomi { "こうちけんあきし" }
      short_name { "安芸市" }
      short_yomi { "あきし" }
    end

    factory :jmaxml_forecast_region_c3920400 do
      code { "3920400" }
      name { "高知県南国市" }
      yomi { "こうちけんなんこくし" }
      short_name { "南国市" }
      short_yomi { "なんこくし" }
    end

    factory :jmaxml_forecast_region_c3920500 do
      code { "3920500" }
      name { "高知県土佐市" }
      yomi { "こうちけんとさし" }
      short_name { "土佐市" }
      short_yomi { "とさし" }
    end

    factory :jmaxml_forecast_region_c3920600 do
      code { "3920600" }
      name { "高知県須崎市" }
      yomi { "こうちけんすさきし" }
      short_name { "須崎市" }
      short_yomi { "すさきし" }
    end

    factory :jmaxml_forecast_region_c3920800 do
      code { "3920800" }
      name { "高知県宿毛市" }
      yomi { "こうちけんすくもし" }
      short_name { "宿毛市" }
      short_yomi { "すくもし" }
    end

    factory :jmaxml_forecast_region_c3920900 do
      code { "3920900" }
      name { "高知県土佐清水市" }
      yomi { "こうちけんとさしみずし" }
      short_name { "土佐清水市" }
      short_yomi { "とさしみずし" }
    end

    factory :jmaxml_forecast_region_c3921000 do
      code { "3921000" }
      name { "高知県四万十市" }
      yomi { "こうちけんしまんとし" }
      short_name { "四万十市" }
      short_yomi { "しまんとし" }
    end

    factory :jmaxml_forecast_region_c3921100 do
      code { "3921100" }
      name { "高知県香南市" }
      yomi { "こうちけんこうなんし" }
      short_name { "香南市" }
      short_yomi { "こうなんし" }
    end

    factory :jmaxml_forecast_region_c3921200 do
      code { "3921200" }
      name { "高知県香美市" }
      yomi { "こうちけんかみし" }
      short_name { "香美市" }
      short_yomi { "かみし" }
    end

    factory :jmaxml_forecast_region_c3930100 do
      code { "3930100" }
      name { "高知県東洋町" }
      yomi { "こうちけんとうようちょう" }
      short_name { "東洋町" }
      short_yomi { "とうようちょう" }
    end

    factory :jmaxml_forecast_region_c3930200 do
      code { "3930200" }
      name { "高知県奈半利町" }
      yomi { "こうちけんなはりちょう" }
      short_name { "奈半利町" }
      short_yomi { "なはりちょう" }
    end

    factory :jmaxml_forecast_region_c3930300 do
      code { "3930300" }
      name { "高知県田野町" }
      yomi { "こうちけんたのちょう" }
      short_name { "田野町" }
      short_yomi { "たのちょう" }
    end

    factory :jmaxml_forecast_region_c3930400 do
      code { "3930400" }
      name { "高知県安田町" }
      yomi { "こうちけんやすだちょう" }
      short_name { "安田町" }
      short_yomi { "やすだちょう" }
    end

    factory :jmaxml_forecast_region_c3930500 do
      code { "3930500" }
      name { "高知県北川村" }
      yomi { "こうちけんきたがわむら" }
      short_name { "北川村" }
      short_yomi { "きたがわむら" }
    end

    factory :jmaxml_forecast_region_c3930600 do
      code { "3930600" }
      name { "高知県馬路村" }
      yomi { "こうちけんうまじむら" }
      short_name { "馬路村" }
      short_yomi { "うまじむら" }
    end

    factory :jmaxml_forecast_region_c3930700 do
      code { "3930700" }
      name { "高知県芸西村" }
      yomi { "こうちけんげいせいむら" }
      short_name { "芸西村" }
      short_yomi { "げいせいむら" }
    end

    factory :jmaxml_forecast_region_c3934100 do
      code { "3934100" }
      name { "高知県本山町" }
      yomi { "こうちけんもとやまちょう" }
      short_name { "本山町" }
      short_yomi { "もとやまちょう" }
    end

    factory :jmaxml_forecast_region_c3934400 do
      code { "3934400" }
      name { "高知県大豊町" }
      yomi { "こうちけんおおとよちょう" }
      short_name { "大豊町" }
      short_yomi { "おおとよちょう" }
    end

    factory :jmaxml_forecast_region_c3936300 do
      code { "3936300" }
      name { "高知県土佐町" }
      yomi { "こうちけんとさちょう" }
      short_name { "土佐町" }
      short_yomi { "とさちょう" }
    end

    factory :jmaxml_forecast_region_c3936400 do
      code { "3936400" }
      name { "高知県大川村" }
      yomi { "こうちけんおおかわむら" }
      short_name { "大川村" }
      short_yomi { "おおかわむら" }
    end

    factory :jmaxml_forecast_region_c3938600 do
      code { "3938600" }
      name { "高知県いの町" }
      yomi { "こうちけんいのちょう" }
      short_name { "いの町" }
      short_yomi { "いのちょう" }
    end

    factory :jmaxml_forecast_region_c3938700 do
      code { "3938700" }
      name { "高知県仁淀川町" }
      yomi { "こうちけんによどがわちょう" }
      short_name { "仁淀川町" }
      short_yomi { "によどがわちょう" }
    end

    factory :jmaxml_forecast_region_c3940100 do
      code { "3940100" }
      name { "高知県中土佐町" }
      yomi { "こうちけんなかとさちょう" }
      short_name { "中土佐町" }
      short_yomi { "なかとさちょう" }
    end

    factory :jmaxml_forecast_region_c3940200 do
      code { "3940200" }
      name { "高知県佐川町" }
      yomi { "こうちけんさかわちょう" }
      short_name { "佐川町" }
      short_yomi { "さかわちょう" }
    end

    factory :jmaxml_forecast_region_c3940300 do
      code { "3940300" }
      name { "高知県越知町" }
      yomi { "こうちけんおちちょう" }
      short_name { "越知町" }
      short_yomi { "おちちょう" }
    end

    factory :jmaxml_forecast_region_c3940500 do
      code { "3940500" }
      name { "高知県檮原町" }
      yomi { "こうちけんゆすはらちょう" }
      short_name { "檮原町" }
      short_yomi { "ゆすはらちょう" }
    end

    factory :jmaxml_forecast_region_c3941000 do
      code { "3941000" }
      name { "高知県日高村" }
      yomi { "こうちけんひだかむら" }
      short_name { "日高村" }
      short_yomi { "ひだかむら" }
    end

    factory :jmaxml_forecast_region_c3941100 do
      code { "3941100" }
      name { "高知県津野町" }
      yomi { "こうちけんつのちょう" }
      short_name { "津野町" }
      short_yomi { "つのちょう" }
    end

    factory :jmaxml_forecast_region_c3941200 do
      code { "3941200" }
      name { "高知県四万十町" }
      yomi { "こうちけんしまんとちょう" }
      short_name { "四万十町" }
      short_yomi { "しまんとちょう" }
    end

    factory :jmaxml_forecast_region_c3942400 do
      code { "3942400" }
      name { "高知県大月町" }
      yomi { "こうちけんおおつきちょう" }
      short_name { "大月町" }
      short_yomi { "おおつきちょう" }
    end

    factory :jmaxml_forecast_region_c3942700 do
      code { "3942700" }
      name { "高知県三原村" }
      yomi { "こうちけんみはらむら" }
      short_name { "三原村" }
      short_yomi { "みはらむら" }
    end

    factory :jmaxml_forecast_region_c3942800 do
      code { "3942800" }
      name { "高知県黒潮町" }
      yomi { "こうちけんくろしおちょう" }
      short_name { "黒潮町" }
      short_yomi { "くろしおちょう" }
    end

    factory :jmaxml_forecast_region_c4010000 do
      code { "4010000" }
      name { "福岡県北九州市" }
      yomi { "ふくおかけんきたきゅうしゅうし" }
      short_name { "北九州市" }
      short_yomi { "きたきゅうしゅうし" }
    end

    factory :jmaxml_forecast_region_c4013000 do
      code { "4013000" }
      name { "福岡県福岡市" }
      yomi { "ふくおかけんふくおかし" }
      short_name { "福岡市" }
      short_yomi { "ふくおかし" }
    end

    factory :jmaxml_forecast_region_c4020200 do
      code { "4020200" }
      name { "福岡県大牟田市" }
      yomi { "ふくおかけんおおむたし" }
      short_name { "大牟田市" }
      short_yomi { "おおむたし" }
    end

    factory :jmaxml_forecast_region_c4020300 do
      code { "4020300" }
      name { "福岡県久留米市" }
      yomi { "ふくおかけんくるめし" }
      short_name { "久留米市" }
      short_yomi { "くるめし" }
    end

    factory :jmaxml_forecast_region_c4020400 do
      code { "4020400" }
      name { "福岡県直方市" }
      yomi { "ふくおかけんのおがたし" }
      short_name { "直方市" }
      short_yomi { "のおがたし" }
    end

    factory :jmaxml_forecast_region_c4020500 do
      code { "4020500" }
      name { "福岡県飯塚市" }
      yomi { "ふくおかけんいいづかし" }
      short_name { "飯塚市" }
      short_yomi { "いいづかし" }
    end

    factory :jmaxml_forecast_region_c4020600 do
      code { "4020600" }
      name { "福岡県田川市" }
      yomi { "ふくおかけんたがわし" }
      short_name { "田川市" }
      short_yomi { "たがわし" }
    end

    factory :jmaxml_forecast_region_c4020700 do
      code { "4020700" }
      name { "福岡県柳川市" }
      yomi { "ふくおかけんやながわし" }
      short_name { "柳川市" }
      short_yomi { "やながわし" }
    end

    factory :jmaxml_forecast_region_c4021000 do
      code { "4021000" }
      name { "福岡県八女市" }
      yomi { "ふくおかけんやめし" }
      short_name { "八女市" }
      short_yomi { "やめし" }
    end

    factory :jmaxml_forecast_region_c4021100 do
      code { "4021100" }
      name { "福岡県筑後市" }
      yomi { "ふくおかけんちくごし" }
      short_name { "筑後市" }
      short_yomi { "ちくごし" }
    end

    factory :jmaxml_forecast_region_c4021200 do
      code { "4021200" }
      name { "福岡県大川市" }
      yomi { "ふくおかけんおおかわし" }
      short_name { "大川市" }
      short_yomi { "おおかわし" }
    end

    factory :jmaxml_forecast_region_c4021300 do
      code { "4021300" }
      name { "福岡県行橋市" }
      yomi { "ふくおかけんゆくはしし" }
      short_name { "行橋市" }
      short_yomi { "ゆくはしし" }
    end

    factory :jmaxml_forecast_region_c4021400 do
      code { "4021400" }
      name { "福岡県豊前市" }
      yomi { "ふくおかけんぶぜんし" }
      short_name { "豊前市" }
      short_yomi { "ぶぜんし" }
    end

    factory :jmaxml_forecast_region_c4021500 do
      code { "4021500" }
      name { "福岡県中間市" }
      yomi { "ふくおかけんなかまし" }
      short_name { "中間市" }
      short_yomi { "なかまし" }
    end

    factory :jmaxml_forecast_region_c4021600 do
      code { "4021600" }
      name { "福岡県小郡市" }
      yomi { "ふくおかけんおごおりし" }
      short_name { "小郡市" }
      short_yomi { "おごおりし" }
    end

    factory :jmaxml_forecast_region_c4021700 do
      code { "4021700" }
      name { "福岡県筑紫野市" }
      yomi { "ふくおかけんちくしのし" }
      short_name { "筑紫野市" }
      short_yomi { "ちくしのし" }
    end

    factory :jmaxml_forecast_region_c4021800 do
      code { "4021800" }
      name { "福岡県春日市" }
      yomi { "ふくおかけんかすがし" }
      short_name { "春日市" }
      short_yomi { "かすがし" }
    end

    factory :jmaxml_forecast_region_c4021900 do
      code { "4021900" }
      name { "福岡県大野城市" }
      yomi { "ふくおかけんおおのじょうし" }
      short_name { "大野城市" }
      short_yomi { "おおのじょうし" }
    end

    factory :jmaxml_forecast_region_c4022000 do
      code { "4022000" }
      name { "福岡県宗像市" }
      yomi { "ふくおかけんむなかたし" }
      short_name { "宗像市" }
      short_yomi { "むなかたし" }
    end

    factory :jmaxml_forecast_region_c4022100 do
      code { "4022100" }
      name { "福岡県太宰府市" }
      yomi { "ふくおかけんだざいふし" }
      short_name { "太宰府市" }
      short_yomi { "だざいふし" }
    end

    factory :jmaxml_forecast_region_c4022300 do
      code { "4022300" }
      name { "福岡県古賀市" }
      yomi { "ふくおかけんこがし" }
      short_name { "古賀市" }
      short_yomi { "こがし" }
    end

    factory :jmaxml_forecast_region_c4022400 do
      code { "4022400" }
      name { "福岡県福津市" }
      yomi { "ふくおかけんふくつし" }
      short_name { "福津市" }
      short_yomi { "ふくつし" }
    end

    factory :jmaxml_forecast_region_c4022500 do
      code { "4022500" }
      name { "福岡県うきは市" }
      yomi { "ふくおかけんうきはし" }
      short_name { "うきは市" }
      short_yomi { "うきはし" }
    end

    factory :jmaxml_forecast_region_c4022600 do
      code { "4022600" }
      name { "福岡県宮若市" }
      yomi { "ふくおかけんみやわかし" }
      short_name { "宮若市" }
      short_yomi { "みやわかし" }
    end

    factory :jmaxml_forecast_region_c4022700 do
      code { "4022700" }
      name { "福岡県嘉麻市" }
      yomi { "ふくおかけんかまし" }
      short_name { "嘉麻市" }
      short_yomi { "かまし" }
    end

    factory :jmaxml_forecast_region_c4022800 do
      code { "4022800" }
      name { "福岡県朝倉市" }
      yomi { "ふくおかけんあさくらし" }
      short_name { "朝倉市" }
      short_yomi { "あさくらし" }
    end

    factory :jmaxml_forecast_region_c4022900 do
      code { "4022900" }
      name { "福岡県みやま市" }
      yomi { "ふくおかけんみやまし" }
      short_name { "みやま市" }
      short_yomi { "みやまし" }
    end

    factory :jmaxml_forecast_region_c4023000 do
      code { "4023000" }
      name { "福岡県糸島市" }
      yomi { "ふくおかけんいとしまし" }
      short_name { "糸島市" }
      short_yomi { "いとしまし" }
    end

    factory :jmaxml_forecast_region_c4030500 do
      code { "4030500" }
      name { "福岡県那珂川町" }
      yomi { "ふくおかけんなかがわまち" }
      short_name { "那珂川町" }
      short_yomi { "なかがわまち" }
    end

    factory :jmaxml_forecast_region_c4034100 do
      code { "4034100" }
      name { "福岡県宇美町" }
      yomi { "ふくおかけんうみまち" }
      short_name { "宇美町" }
      short_yomi { "うみまち" }
    end

    factory :jmaxml_forecast_region_c4034200 do
      code { "4034200" }
      name { "福岡県篠栗町" }
      yomi { "ふくおかけんささぐりまち" }
      short_name { "篠栗町" }
      short_yomi { "ささぐりまち" }
    end

    factory :jmaxml_forecast_region_c4034300 do
      code { "4034300" }
      name { "福岡県志免町" }
      yomi { "ふくおかけんしめまち" }
      short_name { "志免町" }
      short_yomi { "しめまち" }
    end

    factory :jmaxml_forecast_region_c4034400 do
      code { "4034400" }
      name { "福岡県須恵町" }
      yomi { "ふくおかけんすえまち" }
      short_name { "須恵町" }
      short_yomi { "すえまち" }
    end

    factory :jmaxml_forecast_region_c4034500 do
      code { "4034500" }
      name { "福岡県新宮町" }
      yomi { "ふくおかけんしんぐうまち" }
      short_name { "新宮町" }
      short_yomi { "しんぐうまち" }
    end

    factory :jmaxml_forecast_region_c4034800 do
      code { "4034800" }
      name { "福岡県久山町" }
      yomi { "ふくおかけんひさやままち" }
      short_name { "久山町" }
      short_yomi { "ひさやままち" }
    end

    factory :jmaxml_forecast_region_c4034900 do
      code { "4034900" }
      name { "福岡県粕屋町" }
      yomi { "ふくおかけんかすやまち" }
      short_name { "粕屋町" }
      short_yomi { "かすやまち" }
    end

    factory :jmaxml_forecast_region_c4038100 do
      code { "4038100" }
      name { "福岡県芦屋町" }
      yomi { "ふくおかけんあしやまち" }
      short_name { "芦屋町" }
      short_yomi { "あしやまち" }
    end

    factory :jmaxml_forecast_region_c4038200 do
      code { "4038200" }
      name { "福岡県水巻町" }
      yomi { "ふくおかけんみずまきまち" }
      short_name { "水巻町" }
      short_yomi { "みずまきまち" }
    end

    factory :jmaxml_forecast_region_c4038300 do
      code { "4038300" }
      name { "福岡県岡垣町" }
      yomi { "ふくおかけんおかがきまち" }
      short_name { "岡垣町" }
      short_yomi { "おかがきまち" }
    end

    factory :jmaxml_forecast_region_c4038400 do
      code { "4038400" }
      name { "福岡県遠賀町" }
      yomi { "ふくおかけんおんがちょう" }
      short_name { "遠賀町" }
      short_yomi { "おんがちょう" }
    end

    factory :jmaxml_forecast_region_c4040100 do
      code { "4040100" }
      name { "福岡県小竹町" }
      yomi { "ふくおかけんこたけまち" }
      short_name { "小竹町" }
      short_yomi { "こたけまち" }
    end

    factory :jmaxml_forecast_region_c4040200 do
      code { "4040200" }
      name { "福岡県鞍手町" }
      yomi { "ふくおかけんくらてまち" }
      short_name { "鞍手町" }
      short_yomi { "くらてまち" }
    end

    factory :jmaxml_forecast_region_c4042100 do
      code { "4042100" }
      name { "福岡県桂川町" }
      yomi { "ふくおかけんけいせんまち" }
      short_name { "桂川町" }
      short_yomi { "けいせんまち" }
    end

    factory :jmaxml_forecast_region_c4044700 do
      code { "4044700" }
      name { "福岡県筑前町" }
      yomi { "ふくおかけんちくぜんまち" }
      short_name { "筑前町" }
      short_yomi { "ちくぜんまち" }
    end

    factory :jmaxml_forecast_region_c4044800 do
      code { "4044800" }
      name { "福岡県東峰村" }
      yomi { "ふくおかけんとうほうむら" }
      short_name { "東峰村" }
      short_yomi { "とうほうむら" }
    end

    factory :jmaxml_forecast_region_c4050300 do
      code { "4050300" }
      name { "福岡県大刀洗町" }
      yomi { "ふくおかけんたちあらいまち" }
      short_name { "大刀洗町" }
      short_yomi { "たちあらいまち" }
    end

    factory :jmaxml_forecast_region_c4052200 do
      code { "4052200" }
      name { "福岡県大木町" }
      yomi { "ふくおかけんおおきまち" }
      short_name { "大木町" }
      short_yomi { "おおきまち" }
    end

    factory :jmaxml_forecast_region_c4054400 do
      code { "4054400" }
      name { "福岡県広川町" }
      yomi { "ふくおかけんひろかわまち" }
      short_name { "広川町" }
      short_yomi { "ひろかわまち" }
    end

    factory :jmaxml_forecast_region_c4060100 do
      code { "4060100" }
      name { "福岡県香春町" }
      yomi { "ふくおかけんかわらまち" }
      short_name { "香春町" }
      short_yomi { "かわらまち" }
    end

    factory :jmaxml_forecast_region_c4060200 do
      code { "4060200" }
      name { "福岡県添田町" }
      yomi { "ふくおかけんそえだまち" }
      short_name { "添田町" }
      short_yomi { "そえだまち" }
    end

    factory :jmaxml_forecast_region_c4060400 do
      code { "4060400" }
      name { "福岡県糸田町" }
      yomi { "ふくおかけんいとだまち" }
      short_name { "糸田町" }
      short_yomi { "いとだまち" }
    end

    factory :jmaxml_forecast_region_c4060500 do
      code { "4060500" }
      name { "福岡県川崎町" }
      yomi { "ふくおかけんかわさきまち" }
      short_name { "川崎町" }
      short_yomi { "かわさきまち" }
    end

    factory :jmaxml_forecast_region_c4060800 do
      code { "4060800" }
      name { "福岡県大任町" }
      yomi { "ふくおかけんおおとうまち" }
      short_name { "大任町" }
      short_yomi { "おおとうまち" }
    end

    factory :jmaxml_forecast_region_c4060900 do
      code { "4060900" }
      name { "福岡県赤村" }
      yomi { "ふくおかけんあかむら" }
      short_name { "赤村" }
      short_yomi { "あかむら" }
    end

    factory :jmaxml_forecast_region_c4061000 do
      code { "4061000" }
      name { "福岡県福智町" }
      yomi { "ふくおかけんふくちまち" }
      short_name { "福智町" }
      short_yomi { "ふくちまち" }
    end

    factory :jmaxml_forecast_region_c4062100 do
      code { "4062100" }
      name { "福岡県苅田町" }
      yomi { "ふくおかけんかんだまち" }
      short_name { "苅田町" }
      short_yomi { "かんだまち" }
    end

    factory :jmaxml_forecast_region_c4062500 do
      code { "4062500" }
      name { "福岡県みやこ町" }
      yomi { "ふくおかけんみやこまち" }
      short_name { "みやこ町" }
      short_yomi { "みやこまち" }
    end

    factory :jmaxml_forecast_region_c4064200 do
      code { "4064200" }
      name { "福岡県吉富町" }
      yomi { "ふくおかけんよしとみまち" }
      short_name { "吉富町" }
      short_yomi { "よしとみまち" }
    end

    factory :jmaxml_forecast_region_c4064600 do
      code { "4064600" }
      name { "福岡県上毛町" }
      yomi { "ふくおかけんこうげまち" }
      short_name { "上毛町" }
      short_yomi { "こうげまち" }
    end

    factory :jmaxml_forecast_region_c4064700 do
      code { "4064700" }
      name { "福岡県築上町" }
      yomi { "ふくおかけんちくじょうまち" }
      short_name { "築上町" }
      short_yomi { "ちくじょうまち" }
    end

    factory :jmaxml_forecast_region_c4120100 do
      code { "4120100" }
      name { "佐賀県佐賀市" }
      yomi { "さがけんさがし" }
      short_name { "佐賀市" }
      short_yomi { "さがし" }
    end

    factory :jmaxml_forecast_region_c4120200 do
      code { "4120200" }
      name { "佐賀県唐津市" }
      yomi { "さがけんからつし" }
      short_name { "唐津市" }
      short_yomi { "からつし" }
    end

    factory :jmaxml_forecast_region_c4120300 do
      code { "4120300" }
      name { "佐賀県鳥栖市" }
      yomi { "さがけんとすし" }
      short_name { "鳥栖市" }
      short_yomi { "とすし" }
    end

    factory :jmaxml_forecast_region_c4120400 do
      code { "4120400" }
      name { "佐賀県多久市" }
      yomi { "さがけんたくし" }
      short_name { "多久市" }
      short_yomi { "たくし" }
    end

    factory :jmaxml_forecast_region_c4120500 do
      code { "4120500" }
      name { "佐賀県伊万里市" }
      yomi { "さがけんいまりし" }
      short_name { "伊万里市" }
      short_yomi { "いまりし" }
    end

    factory :jmaxml_forecast_region_c4120600 do
      code { "4120600" }
      name { "佐賀県武雄市" }
      yomi { "さがけんたけおし" }
      short_name { "武雄市" }
      short_yomi { "たけおし" }
    end

    factory :jmaxml_forecast_region_c4120700 do
      code { "4120700" }
      name { "佐賀県鹿島市" }
      yomi { "さがけんかしまし" }
      short_name { "鹿島市" }
      short_yomi { "かしまし" }
    end

    factory :jmaxml_forecast_region_c4120800 do
      code { "4120800" }
      name { "佐賀県小城市" }
      yomi { "さがけんおぎし" }
      short_name { "小城市" }
      short_yomi { "おぎし" }
    end

    factory :jmaxml_forecast_region_c4120900 do
      code { "4120900" }
      name { "佐賀県嬉野市" }
      yomi { "さがけんうれしのし" }
      short_name { "嬉野市" }
      short_yomi { "うれしのし" }
    end

    factory :jmaxml_forecast_region_c4121000 do
      code { "4121000" }
      name { "佐賀県神埼市" }
      yomi { "さがけんかんざきし" }
      short_name { "神埼市" }
      short_yomi { "かんざきし" }
    end

    factory :jmaxml_forecast_region_c4132700 do
      code { "4132700" }
      name { "佐賀県吉野ヶ里町" }
      yomi { "さがけんよしのがりちょう" }
      short_name { "吉野ヶ里町" }
      short_yomi { "よしのがりちょう" }
    end

    factory :jmaxml_forecast_region_c4134100 do
      code { "4134100" }
      name { "佐賀県基山町" }
      yomi { "さがけんきやまちょう" }
      short_name { "基山町" }
      short_yomi { "きやまちょう" }
    end

    factory :jmaxml_forecast_region_c4134500 do
      code { "4134500" }
      name { "佐賀県上峰町" }
      yomi { "さがけんかみみねちょう" }
      short_name { "上峰町" }
      short_yomi { "かみみねちょう" }
    end

    factory :jmaxml_forecast_region_c4134600 do
      code { "4134600" }
      name { "佐賀県みやき町" }
      yomi { "さがけんみやきちょう" }
      short_name { "みやき町" }
      short_yomi { "みやきちょう" }
    end

    factory :jmaxml_forecast_region_c4138700 do
      code { "4138700" }
      name { "佐賀県玄海町" }
      yomi { "さがけんげんかいちょう" }
      short_name { "玄海町" }
      short_yomi { "げんかいちょう" }
    end

    factory :jmaxml_forecast_region_c4140100 do
      code { "4140100" }
      name { "佐賀県有田町" }
      yomi { "さがけんありたちょう" }
      short_name { "有田町" }
      short_yomi { "ありたちょう" }
    end

    factory :jmaxml_forecast_region_c4142300 do
      code { "4142300" }
      name { "佐賀県大町町" }
      yomi { "さがけんおおまちちょう" }
      short_name { "大町町" }
      short_yomi { "おおまちちょう" }
    end

    factory :jmaxml_forecast_region_c4142400 do
      code { "4142400" }
      name { "佐賀県江北町" }
      yomi { "さがけんこうほくまち" }
      short_name { "江北町" }
      short_yomi { "こうほくまち" }
    end

    factory :jmaxml_forecast_region_c4142500 do
      code { "4142500" }
      name { "佐賀県白石町" }
      yomi { "さがけんしろいしちょう" }
      short_name { "白石町" }
      short_yomi { "しろいしちょう" }
    end

    factory :jmaxml_forecast_region_c4144100 do
      code { "4144100" }
      name { "佐賀県太良町" }
      yomi { "さがけんたらちょう" }
      short_name { "太良町" }
      short_yomi { "たらちょう" }
    end

    factory :jmaxml_forecast_region_c4220100 do
      code { "4220100" }
      name { "長崎県長崎市" }
      yomi { "ながさきけんながさきし" }
      short_name { "長崎市" }
      short_yomi { "ながさきし" }
    end

    factory :jmaxml_forecast_region_c4220200 do
      code { "4220200" }
      name { "長崎県佐世保市" }
      yomi { "ながさきけんさせぼし" }
      short_name { "佐世保市" }
      short_yomi { "させぼし" }
    end

    factory :jmaxml_forecast_region_c4220300 do
      code { "4220300" }
      name { "長崎県島原市" }
      yomi { "ながさきけんしまばらし" }
      short_name { "島原市" }
      short_yomi { "しまばらし" }
    end

    factory :jmaxml_forecast_region_c4220400 do
      code { "4220400" }
      name { "長崎県諫早市" }
      yomi { "ながさきけんいさはやし" }
      short_name { "諫早市" }
      short_yomi { "いさはやし" }
    end

    factory :jmaxml_forecast_region_c4220500 do
      code { "4220500" }
      name { "長崎県大村市" }
      yomi { "ながさきけんおおむらし" }
      short_name { "大村市" }
      short_yomi { "おおむらし" }
    end

    factory :jmaxml_forecast_region_c4220700 do
      code { "4220700" }
      name { "長崎県平戸市" }
      yomi { "ながさきけんひらどし" }
      short_name { "平戸市" }
      short_yomi { "ひらどし" }
    end

    factory :jmaxml_forecast_region_c4220800 do
      code { "4220800" }
      name { "長崎県松浦市" }
      yomi { "ながさきけんまつうらし" }
      short_name { "松浦市" }
      short_yomi { "まつうらし" }
    end

    factory :jmaxml_forecast_region_c4220900 do
      code { "4220900" }
      name { "長崎県対馬市" }
      yomi { "ながさきけんつしまし" }
      short_name { "対馬市" }
      short_yomi { "つしまし" }
    end

    factory :jmaxml_forecast_region_c4221000 do
      code { "4221000" }
      name { "長崎県壱岐市" }
      yomi { "ながさきけんいきし" }
      short_name { "壱岐市" }
      short_yomi { "いきし" }
    end

    factory :jmaxml_forecast_region_c4221100 do
      code { "4221100" }
      name { "長崎県五島市" }
      yomi { "ながさきけんごとうし" }
      short_name { "五島市" }
      short_yomi { "ごとうし" }
    end

    factory :jmaxml_forecast_region_c4221200 do
      code { "4221200" }
      name { "長崎県西海市" }
      yomi { "ながさきけんさいかいし" }
      short_name { "西海市" }
      short_yomi { "さいかいし" }
    end

    factory :jmaxml_forecast_region_c4221300 do
      code { "4221300" }
      name { "長崎県雲仙市" }
      yomi { "ながさきけんうんぜんし" }
      short_name { "雲仙市" }
      short_yomi { "うんぜんし" }
    end

    factory :jmaxml_forecast_region_c4221400 do
      code { "4221400" }
      name { "長崎県南島原市" }
      yomi { "ながさきけんみなみしまばらし" }
      short_name { "南島原市" }
      short_yomi { "みなみしまばらし" }
    end

    factory :jmaxml_forecast_region_c4230700 do
      code { "4230700" }
      name { "長崎県長与町" }
      yomi { "ながさきけんながよちょう" }
      short_name { "長与町" }
      short_yomi { "ながよちょう" }
    end

    factory :jmaxml_forecast_region_c4230800 do
      code { "4230800" }
      name { "長崎県時津町" }
      yomi { "ながさきけんとぎつちょう" }
      short_name { "時津町" }
      short_yomi { "とぎつちょう" }
    end

    factory :jmaxml_forecast_region_c4232100 do
      code { "4232100" }
      name { "長崎県東彼杵町" }
      yomi { "ながさきけんひがしそのぎちょう" }
      short_name { "東彼杵町" }
      short_yomi { "ひがしそのぎちょう" }
    end

    factory :jmaxml_forecast_region_c4232200 do
      code { "4232200" }
      name { "長崎県川棚町" }
      yomi { "ながさきけんかわたなちょう" }
      short_name { "川棚町" }
      short_yomi { "かわたなちょう" }
    end

    factory :jmaxml_forecast_region_c4232300 do
      code { "4232300" }
      name { "長崎県波佐見町" }
      yomi { "ながさきけんはさみちょう" }
      short_name { "波佐見町" }
      short_yomi { "はさみちょう" }
    end

    factory :jmaxml_forecast_region_c4238300 do
      code { "4238300" }
      name { "長崎県小値賀町" }
      yomi { "ながさきけんおぢかちょう" }
      short_name { "小値賀町" }
      short_yomi { "おぢかちょう" }
    end

    factory :jmaxml_forecast_region_c4239100 do
      code { "4239100" }
      name { "長崎県佐々町" }
      yomi { "ながさきけんさざちょう" }
      short_name { "佐々町" }
      short_yomi { "さざちょう" }
    end

    factory :jmaxml_forecast_region_c4241100 do
      code { "4241100" }
      name { "長崎県新上五島町" }
      yomi { "ながさきけんしんかみごとうちょう" }
      short_name { "新上五島町" }
      short_yomi { "しんかみごとうちょう" }
    end

    factory :jmaxml_forecast_region_c4310000 do
      code { "4310000" }
      name { "熊本県熊本市" }
      yomi { "くまもとけんくまもとし" }
      short_name { "熊本市" }
      short_yomi { "くまもとし" }
    end

    factory :jmaxml_forecast_region_c4320200 do
      code { "4320200" }
      name { "熊本県八代市" }
      yomi { "くまもとけんやつしろし" }
      short_name { "八代市" }
      short_yomi { "やつしろし" }
    end

    factory :jmaxml_forecast_region_c4320300 do
      code { "4320300" }
      name { "熊本県人吉市" }
      yomi { "くまもとけんひとよしし" }
      short_name { "人吉市" }
      short_yomi { "ひとよしし" }
    end

    factory :jmaxml_forecast_region_c4320400 do
      code { "4320400" }
      name { "熊本県荒尾市" }
      yomi { "くまもとけんあらおし" }
      short_name { "荒尾市" }
      short_yomi { "あらおし" }
    end

    factory :jmaxml_forecast_region_c4320500 do
      code { "4320500" }
      name { "熊本県水俣市" }
      yomi { "くまもとけんみなまたし" }
      short_name { "水俣市" }
      short_yomi { "みなまたし" }
    end

    factory :jmaxml_forecast_region_c4320600 do
      code { "4320600" }
      name { "熊本県玉名市" }
      yomi { "くまもとけんたまなし" }
      short_name { "玉名市" }
      short_yomi { "たまなし" }
    end

    factory :jmaxml_forecast_region_c4320800 do
      code { "4320800" }
      name { "熊本県山鹿市" }
      yomi { "くまもとけんやまがし" }
      short_name { "山鹿市" }
      short_yomi { "やまがし" }
    end

    factory :jmaxml_forecast_region_c4321000 do
      code { "4321000" }
      name { "熊本県菊池市" }
      yomi { "くまもとけんきくちし" }
      short_name { "菊池市" }
      short_yomi { "きくちし" }
    end

    factory :jmaxml_forecast_region_c4321100 do
      code { "4321100" }
      name { "熊本県宇土市" }
      yomi { "くまもとけんうとし" }
      short_name { "宇土市" }
      short_yomi { "うとし" }
    end

    factory :jmaxml_forecast_region_c4321200 do
      code { "4321200" }
      name { "熊本県上天草市" }
      yomi { "くまもとけんかみあまくさし" }
      short_name { "上天草市" }
      short_yomi { "かみあまくさし" }
    end

    factory :jmaxml_forecast_region_c4321300 do
      code { "4321300" }
      name { "熊本県宇城市" }
      yomi { "くまもとけんうきし" }
      short_name { "宇城市" }
      short_yomi { "うきし" }
    end

    factory :jmaxml_forecast_region_c4321400 do
      code { "4321400" }
      name { "熊本県阿蘇市" }
      yomi { "くまもとけんあそし" }
      short_name { "阿蘇市" }
      short_yomi { "あそし" }
    end

    factory :jmaxml_forecast_region_c4321500 do
      code { "4321500" }
      name { "熊本県天草市" }
      yomi { "くまもとけんあまくさし" }
      short_name { "天草市" }
      short_yomi { "あまくさし" }
    end

    factory :jmaxml_forecast_region_c4321600 do
      code { "4321600" }
      name { "熊本県合志市" }
      yomi { "くまもとけんこうしし" }
      short_name { "合志市" }
      short_yomi { "こうしし" }
    end

    factory :jmaxml_forecast_region_c4334800 do
      code { "4334800" }
      name { "熊本県美里町" }
      yomi { "くまもとけんみさとまち" }
      short_name { "美里町" }
      short_yomi { "みさとまち" }
    end

    factory :jmaxml_forecast_region_c4336400 do
      code { "4336400" }
      name { "熊本県玉東町" }
      yomi { "くまもとけんぎょくとうまち" }
      short_name { "玉東町" }
      short_yomi { "ぎょくとうまち" }
    end

    factory :jmaxml_forecast_region_c4336700 do
      code { "4336700" }
      name { "熊本県南関町" }
      yomi { "くまもとけんなんかんまち" }
      short_name { "南関町" }
      short_yomi { "なんかんまち" }
    end

    factory :jmaxml_forecast_region_c4336800 do
      code { "4336800" }
      name { "熊本県長洲町" }
      yomi { "くまもとけんながすまち" }
      short_name { "長洲町" }
      short_yomi { "ながすまち" }
    end

    factory :jmaxml_forecast_region_c4336900 do
      code { "4336900" }
      name { "熊本県和水町" }
      yomi { "くまもとけんなごみまち" }
      short_name { "和水町" }
      short_yomi { "なごみまち" }
    end

    factory :jmaxml_forecast_region_c4340300 do
      code { "4340300" }
      name { "熊本県大津町" }
      yomi { "くまもとけんおおづまち" }
      short_name { "大津町" }
      short_yomi { "おおづまち" }
    end

    factory :jmaxml_forecast_region_c4340400 do
      code { "4340400" }
      name { "熊本県菊陽町" }
      yomi { "くまもとけんきくようまち" }
      short_name { "菊陽町" }
      short_yomi { "きくようまち" }
    end

    factory :jmaxml_forecast_region_c4342300 do
      code { "4342300" }
      name { "熊本県南小国町" }
      yomi { "くまもとけんみなみおぐにまち" }
      short_name { "南小国町" }
      short_yomi { "みなみおぐにまち" }
    end

    factory :jmaxml_forecast_region_c4342400 do
      code { "4342400" }
      name { "熊本県小国町" }
      yomi { "くまもとけんおぐにまち" }
      short_name { "小国町" }
      short_yomi { "おぐにまち" }
    end

    factory :jmaxml_forecast_region_c4342500 do
      code { "4342500" }
      name { "熊本県産山村" }
      yomi { "くまもとけんうぶやまむら" }
      short_name { "産山村" }
      short_yomi { "うぶやまむら" }
    end

    factory :jmaxml_forecast_region_c4342800 do
      code { "4342800" }
      name { "熊本県高森町" }
      yomi { "くまもとけんたかもりまち" }
      short_name { "高森町" }
      short_yomi { "たかもりまち" }
    end

    factory :jmaxml_forecast_region_c4343200 do
      code { "4343200" }
      name { "熊本県西原村" }
      yomi { "くまもとけんにしはらむら" }
      short_name { "西原村" }
      short_yomi { "にしはらむら" }
    end

    factory :jmaxml_forecast_region_c4343300 do
      code { "4343300" }
      name { "熊本県南阿蘇村" }
      yomi { "くまもとけんみなみあそむら" }
      short_name { "南阿蘇村" }
      short_yomi { "みなみあそむら" }
    end

    factory :jmaxml_forecast_region_c4344100 do
      code { "4344100" }
      name { "熊本県御船町" }
      yomi { "くまもとけんみふねまち" }
      short_name { "御船町" }
      short_yomi { "みふねまち" }
    end

    factory :jmaxml_forecast_region_c4344200 do
      code { "4344200" }
      name { "熊本県嘉島町" }
      yomi { "くまもとけんかしままち" }
      short_name { "嘉島町" }
      short_yomi { "かしままち" }
    end

    factory :jmaxml_forecast_region_c4344300 do
      code { "4344300" }
      name { "熊本県益城町" }
      yomi { "くまもとけんましきまち" }
      short_name { "益城町" }
      short_yomi { "ましきまち" }
    end

    factory :jmaxml_forecast_region_c4344400 do
      code { "4344400" }
      name { "熊本県甲佐町" }
      yomi { "くまもとけんこうさまち" }
      short_name { "甲佐町" }
      short_yomi { "こうさまち" }
    end

    factory :jmaxml_forecast_region_c4344700 do
      code { "4344700" }
      name { "熊本県山都町" }
      yomi { "くまもとけんやまとちょう" }
      short_name { "山都町" }
      short_yomi { "やまとちょう" }
    end

    factory :jmaxml_forecast_region_c4346800 do
      code { "4346800" }
      name { "熊本県氷川町" }
      yomi { "くまもとけんひかわちょう" }
      short_name { "氷川町" }
      short_yomi { "ひかわちょう" }
    end

    factory :jmaxml_forecast_region_c4348200 do
      code { "4348200" }
      name { "熊本県芦北町" }
      yomi { "くまもとけんあしきたまち" }
      short_name { "芦北町" }
      short_yomi { "あしきたまち" }
    end

    factory :jmaxml_forecast_region_c4348400 do
      code { "4348400" }
      name { "熊本県津奈木町" }
      yomi { "くまもとけんつなぎまち" }
      short_name { "津奈木町" }
      short_yomi { "つなぎまち" }
    end

    factory :jmaxml_forecast_region_c4350100 do
      code { "4350100" }
      name { "熊本県錦町" }
      yomi { "くまもとけんにしきまち" }
      short_name { "錦町" }
      short_yomi { "にしきまち" }
    end

    factory :jmaxml_forecast_region_c4350500 do
      code { "4350500" }
      name { "熊本県多良木町" }
      yomi { "くまもとけんたらぎまち" }
      short_name { "多良木町" }
      short_yomi { "たらぎまち" }
    end

    factory :jmaxml_forecast_region_c4350600 do
      code { "4350600" }
      name { "熊本県湯前町" }
      yomi { "くまもとけんゆのまえまち" }
      short_name { "湯前町" }
      short_yomi { "ゆのまえまち" }
    end

    factory :jmaxml_forecast_region_c4350700 do
      code { "4350700" }
      name { "熊本県水上村" }
      yomi { "くまもとけんみずかみむら" }
      short_name { "水上村" }
      short_yomi { "みずかみむら" }
    end

    factory :jmaxml_forecast_region_c4351000 do
      code { "4351000" }
      name { "熊本県相良村" }
      yomi { "くまもとけんさがらむら" }
      short_name { "相良村" }
      short_yomi { "さがらむら" }
    end

    factory :jmaxml_forecast_region_c4351100 do
      code { "4351100" }
      name { "熊本県五木村" }
      yomi { "くまもとけんいつきむら" }
      short_name { "五木村" }
      short_yomi { "いつきむら" }
    end

    factory :jmaxml_forecast_region_c4351200 do
      code { "4351200" }
      name { "熊本県山江村" }
      yomi { "くまもとけんやまえむら" }
      short_name { "山江村" }
      short_yomi { "やまえむら" }
    end

    factory :jmaxml_forecast_region_c4351300 do
      code { "4351300" }
      name { "熊本県球磨村" }
      yomi { "くまもとけんくまむら" }
      short_name { "球磨村" }
      short_yomi { "くまむら" }
    end

    factory :jmaxml_forecast_region_c4351400 do
      code { "4351400" }
      name { "熊本県あさぎり町" }
      yomi { "くまもとけんあさぎりちょう" }
      short_name { "あさぎり町" }
      short_yomi { "あさぎりちょう" }
    end

    factory :jmaxml_forecast_region_c4353100 do
      code { "4353100" }
      name { "熊本県苓北町" }
      yomi { "くまもとけんれいほくまち" }
      short_name { "苓北町" }
      short_yomi { "れいほくまち" }
    end

    factory :jmaxml_forecast_region_c4420100 do
      code { "4420100" }
      name { "大分県大分市" }
      yomi { "おおいたけんおおいたし" }
      short_name { "大分市" }
      short_yomi { "おおいたし" }
    end

    factory :jmaxml_forecast_region_c4420200 do
      code { "4420200" }
      name { "大分県別府市" }
      yomi { "おおいたけんべっぷし" }
      short_name { "別府市" }
      short_yomi { "べっぷし" }
    end

    factory :jmaxml_forecast_region_c4420300 do
      code { "4420300" }
      name { "大分県中津市" }
      yomi { "おおいたけんなかつし" }
      short_name { "中津市" }
      short_yomi { "なかつし" }
    end

    factory :jmaxml_forecast_region_c4420400 do
      code { "4420400" }
      name { "大分県日田市" }
      yomi { "おおいたけんひたし" }
      short_name { "日田市" }
      short_yomi { "ひたし" }
    end

    factory :jmaxml_forecast_region_c4420500 do
      code { "4420500" }
      name { "大分県佐伯市" }
      yomi { "おおいたけんさいきし" }
      short_name { "佐伯市" }
      short_yomi { "さいきし" }
    end

    factory :jmaxml_forecast_region_c4420600 do
      code { "4420600" }
      name { "大分県臼杵市" }
      yomi { "おおいたけんうすきし" }
      short_name { "臼杵市" }
      short_yomi { "うすきし" }
    end

    factory :jmaxml_forecast_region_c4420700 do
      code { "4420700" }
      name { "大分県津久見市" }
      yomi { "おおいたけんつくみし" }
      short_name { "津久見市" }
      short_yomi { "つくみし" }
    end

    factory :jmaxml_forecast_region_c4420800 do
      code { "4420800" }
      name { "大分県竹田市" }
      yomi { "おおいたけんたけたし" }
      short_name { "竹田市" }
      short_yomi { "たけたし" }
    end

    factory :jmaxml_forecast_region_c4420900 do
      code { "4420900" }
      name { "大分県豊後高田市" }
      yomi { "おおいたけんぶんごたかだし" }
      short_name { "豊後高田市" }
      short_yomi { "ぶんごたかだし" }
    end

    factory :jmaxml_forecast_region_c4421000 do
      code { "4421000" }
      name { "大分県杵築市" }
      yomi { "おおいたけんきつきし" }
      short_name { "杵築市" }
      short_yomi { "きつきし" }
    end

    factory :jmaxml_forecast_region_c4421100 do
      code { "4421100" }
      name { "大分県宇佐市" }
      yomi { "おおいたけんうさし" }
      short_name { "宇佐市" }
      short_yomi { "うさし" }
    end

    factory :jmaxml_forecast_region_c4421200 do
      code { "4421200" }
      name { "大分県豊後大野市" }
      yomi { "おおいたけんぶんごおおのし" }
      short_name { "豊後大野市" }
      short_yomi { "ぶんごおおのし" }
    end

    factory :jmaxml_forecast_region_c4421300 do
      code { "4421300" }
      name { "大分県由布市" }
      yomi { "おおいたけんゆふし" }
      short_name { "由布市" }
      short_yomi { "ゆふし" }
    end

    factory :jmaxml_forecast_region_c4421400 do
      code { "4421400" }
      name { "大分県国東市" }
      yomi { "おおいたけんくにさきし" }
      short_name { "国東市" }
      short_yomi { "くにさきし" }
    end

    factory :jmaxml_forecast_region_c4432200 do
      code { "4432200" }
      name { "大分県姫島村" }
      yomi { "おおいたけんひめしまむら" }
      short_name { "姫島村" }
      short_yomi { "ひめしまむら" }
    end

    factory :jmaxml_forecast_region_c4434100 do
      code { "4434100" }
      name { "大分県日出町" }
      yomi { "おおいたけんひじまち" }
      short_name { "日出町" }
      short_yomi { "ひじまち" }
    end

    factory :jmaxml_forecast_region_c4446100 do
      code { "4446100" }
      name { "大分県九重町" }
      yomi { "おおいたけんここのえまち" }
      short_name { "九重町" }
      short_yomi { "ここのえまち" }
    end

    factory :jmaxml_forecast_region_c4446200 do
      code { "4446200" }
      name { "大分県玖珠町" }
      yomi { "おおいたけんくすまち" }
      short_name { "玖珠町" }
      short_yomi { "くすまち" }
    end

    factory :jmaxml_forecast_region_c4520100 do
      code { "4520100" }
      name { "宮崎県宮崎市" }
      yomi { "みやざきけんみやざきし" }
      short_name { "宮崎市" }
      short_yomi { "みやざきし" }
    end

    factory :jmaxml_forecast_region_c4520200 do
      code { "4520200" }
      name { "宮崎県都城市" }
      yomi { "みやざきけんみやこのじょうし" }
      short_name { "都城市" }
      short_yomi { "みやこのじょうし" }
    end

    factory :jmaxml_forecast_region_c4520300 do
      code { "4520300" }
      name { "宮崎県延岡市" }
      yomi { "みやざきけんのべおかし" }
      short_name { "延岡市" }
      short_yomi { "のべおかし" }
    end

    factory :jmaxml_forecast_region_c4520400 do
      code { "4520400" }
      name { "宮崎県日南市" }
      yomi { "みやざきけんにちなんし" }
      short_name { "日南市" }
      short_yomi { "にちなんし" }
    end

    factory :jmaxml_forecast_region_c4520500 do
      code { "4520500" }
      name { "宮崎県小林市" }
      yomi { "みやざきけんこばやしし" }
      short_name { "小林市" }
      short_yomi { "こばやしし" }
    end

    factory :jmaxml_forecast_region_c4520600 do
      code { "4520600" }
      name { "宮崎県日向市" }
      yomi { "みやざきけんひゅうがし" }
      short_name { "日向市" }
      short_yomi { "ひゅうがし" }
    end

    factory :jmaxml_forecast_region_c4520700 do
      code { "4520700" }
      name { "宮崎県串間市" }
      yomi { "みやざきけんくしまし" }
      short_name { "串間市" }
      short_yomi { "くしまし" }
    end

    factory :jmaxml_forecast_region_c4520800 do
      code { "4520800" }
      name { "宮崎県西都市" }
      yomi { "みやざきけんさいとし" }
      short_name { "西都市" }
      short_yomi { "さいとし" }
    end

    factory :jmaxml_forecast_region_c4520900 do
      code { "4520900" }
      name { "宮崎県えびの市" }
      yomi { "みやざきけんえびのし" }
      short_name { "えびの市" }
      short_yomi { "えびのし" }
    end

    factory :jmaxml_forecast_region_c4534100 do
      code { "4534100" }
      name { "宮崎県三股町" }
      yomi { "みやざきけんみまたちょう" }
      short_name { "三股町" }
      short_yomi { "みまたちょう" }
    end

    factory :jmaxml_forecast_region_c4536100 do
      code { "4536100" }
      name { "宮崎県高原町" }
      yomi { "みやざきけんたかはるちょう" }
      short_name { "高原町" }
      short_yomi { "たかはるちょう" }
    end

    factory :jmaxml_forecast_region_c4538200 do
      code { "4538200" }
      name { "宮崎県国富町" }
      yomi { "みやざきけんくにとみちょう" }
      short_name { "国富町" }
      short_yomi { "くにとみちょう" }
    end

    factory :jmaxml_forecast_region_c4538300 do
      code { "4538300" }
      name { "宮崎県綾町" }
      yomi { "みやざきけんあやちょう" }
      short_name { "綾町" }
      short_yomi { "あやちょう" }
    end

    factory :jmaxml_forecast_region_c4540100 do
      code { "4540100" }
      name { "宮崎県高鍋町" }
      yomi { "みやざきけんたかなべちょう" }
      short_name { "高鍋町" }
      short_yomi { "たかなべちょう" }
    end

    factory :jmaxml_forecast_region_c4540200 do
      code { "4540200" }
      name { "宮崎県新富町" }
      yomi { "みやざきけんしんとみちょう" }
      short_name { "新富町" }
      short_yomi { "しんとみちょう" }
    end

    factory :jmaxml_forecast_region_c4540300 do
      code { "4540300" }
      name { "宮崎県西米良村" }
      yomi { "みやざきけんにしめらそん" }
      short_name { "西米良村" }
      short_yomi { "にしめらそん" }
    end

    factory :jmaxml_forecast_region_c4540400 do
      code { "4540400" }
      name { "宮崎県木城町" }
      yomi { "みやざきけんきじょうちょう" }
      short_name { "木城町" }
      short_yomi { "きじょうちょう" }
    end

    factory :jmaxml_forecast_region_c4540500 do
      code { "4540500" }
      name { "宮崎県川南町" }
      yomi { "みやざきけんかわみなみちょう" }
      short_name { "川南町" }
      short_yomi { "かわみなみちょう" }
    end

    factory :jmaxml_forecast_region_c4540600 do
      code { "4540600" }
      name { "宮崎県都農町" }
      yomi { "みやざきけんつのちょう" }
      short_name { "都農町" }
      short_yomi { "つのちょう" }
    end

    factory :jmaxml_forecast_region_c4542100 do
      code { "4542100" }
      name { "宮崎県門川町" }
      yomi { "みやざきけんかどがわちょう" }
      short_name { "門川町" }
      short_yomi { "かどがわちょう" }
    end

    factory :jmaxml_forecast_region_c4542900 do
      code { "4542900" }
      name { "宮崎県諸塚村" }
      yomi { "みやざきけんもろつかそん" }
      short_name { "諸塚村" }
      short_yomi { "もろつかそん" }
    end

    factory :jmaxml_forecast_region_c4543000 do
      code { "4543000" }
      name { "宮崎県椎葉村" }
      yomi { "みやざきけんしいばそん" }
      short_name { "椎葉村" }
      short_yomi { "しいばそん" }
    end

    factory :jmaxml_forecast_region_c4543100 do
      code { "4543100" }
      name { "宮崎県美郷町" }
      yomi { "みやざきけんみさとちょう" }
      short_name { "美郷町" }
      short_yomi { "みさとちょう" }
    end

    factory :jmaxml_forecast_region_c4544100 do
      code { "4544100" }
      name { "宮崎県高千穂町" }
      yomi { "みやざきけんたかちほちょう" }
      short_name { "高千穂町" }
      short_yomi { "たかちほちょう" }
    end

    factory :jmaxml_forecast_region_c4544200 do
      code { "4544200" }
      name { "宮崎県日之影町" }
      yomi { "みやざきけんひのかげちょう" }
      short_name { "日之影町" }
      short_yomi { "ひのかげちょう" }
    end

    factory :jmaxml_forecast_region_c4544300 do
      code { "4544300" }
      name { "宮崎県五ヶ瀬町" }
      yomi { "みやざきけんごかせちょう" }
      short_name { "五ヶ瀬町" }
      short_yomi { "ごかせちょう" }
    end

    factory :jmaxml_forecast_region_c4620100 do
      code { "4620100" }
      name { "鹿児島県鹿児島市" }
      yomi { "かごしまけんかごしまし" }
      short_name { "鹿児島市" }
      short_yomi { "かごしまし" }
    end

    factory :jmaxml_forecast_region_c4620300 do
      code { "4620300" }
      name { "鹿児島県鹿屋市" }
      yomi { "かごしまけんかのやし" }
      short_name { "鹿屋市" }
      short_yomi { "かのやし" }
    end

    factory :jmaxml_forecast_region_c4620400 do
      code { "4620400" }
      name { "鹿児島県枕崎市" }
      yomi { "かごしまけんまくらざきし" }
      short_name { "枕崎市" }
      short_yomi { "まくらざきし" }
    end

    factory :jmaxml_forecast_region_c4620600 do
      code { "4620600" }
      name { "鹿児島県阿久根市" }
      yomi { "かごしまけんあくねし" }
      short_name { "阿久根市" }
      short_yomi { "あくねし" }
    end

    factory :jmaxml_forecast_region_c4620800 do
      code { "4620800" }
      name { "鹿児島県出水市" }
      yomi { "かごしまけんいずみし" }
      short_name { "出水市" }
      short_yomi { "いずみし" }
    end

    factory :jmaxml_forecast_region_c4621000 do
      code { "4621000" }
      name { "鹿児島県指宿市" }
      yomi { "かごしまけんいぶすきし" }
      short_name { "指宿市" }
      short_yomi { "いぶすきし" }
    end

    factory :jmaxml_forecast_region_c4621300 do
      code { "4621300" }
      name { "鹿児島県西之表市" }
      yomi { "かごしまけんにしのおもてし" }
      short_name { "西之表市" }
      short_yomi { "にしのおもてし" }
    end

    factory :jmaxml_forecast_region_c4621400 do
      code { "4621400" }
      name { "鹿児島県垂水市" }
      yomi { "かごしまけんたるみずし" }
      short_name { "垂水市" }
      short_yomi { "たるみずし" }
    end

    factory :jmaxml_forecast_region_c4621500 do
      code { "4621500" }
      name { "鹿児島県薩摩川内市" }
      yomi { "かごしまけんさつませんだいし" }
      short_name { "薩摩川内市" }
      short_yomi { "さつませんだいし" }
    end

    factory :jmaxml_forecast_region_c4621600 do
      code { "4621600" }
      name { "鹿児島県日置市" }
      yomi { "かごしまけんひおきし" }
      short_name { "日置市" }
      short_yomi { "ひおきし" }
    end

    factory :jmaxml_forecast_region_c4621700 do
      code { "4621700" }
      name { "鹿児島県曽於市" }
      yomi { "かごしまけんそおし" }
      short_name { "曽於市" }
      short_yomi { "そおし" }
    end

    factory :jmaxml_forecast_region_c4621800 do
      code { "4621800" }
      name { "鹿児島県霧島市" }
      yomi { "かごしまけんきりしまし" }
      short_name { "霧島市" }
      short_yomi { "きりしまし" }
    end

    factory :jmaxml_forecast_region_c4621900 do
      code { "4621900" }
      name { "鹿児島県いちき串木野市" }
      yomi { "かごしまけんいちきくしきのし" }
      short_name { "いちき串木野市" }
      short_yomi { "いちきくしきのし" }
    end

    factory :jmaxml_forecast_region_c4622000 do
      code { "4622000" }
      name { "鹿児島県南さつま市" }
      yomi { "かごしまけんみなみさつまし" }
      short_name { "南さつま市" }
      short_yomi { "みなみさつまし" }
    end

    factory :jmaxml_forecast_region_c4622100 do
      code { "4622100" }
      name { "鹿児島県志布志市" }
      yomi { "かごしまけんしぶしし" }
      short_name { "志布志市" }
      short_yomi { "しぶしし" }
    end

    factory :jmaxml_forecast_region_c4622200 do
      code { "4622200" }
      name { "鹿児島県奄美市" }
      yomi { "かごしまけんあまみし" }
      short_name { "奄美市" }
      short_yomi { "あまみし" }
    end

    factory :jmaxml_forecast_region_c4622300 do
      code { "4622300" }
      name { "鹿児島県南九州市" }
      yomi { "かごしまけんみなみきゅうしゅうし" }
      short_name { "南九州市" }
      short_yomi { "みなみきゅうしゅうし" }
    end

    factory :jmaxml_forecast_region_c4622400 do
      code { "4622400" }
      name { "鹿児島県伊佐市" }
      yomi { "かごしまけんいさし" }
      short_name { "伊佐市" }
      short_yomi { "いさし" }
    end

    factory :jmaxml_forecast_region_c4622500 do
      code { "4622500" }
      name { "鹿児島県姶良市" }
      yomi { "かごしまけんあいらし" }
      short_name { "姶良市" }
      short_yomi { "あいらし" }
    end

    factory :jmaxml_forecast_region_c4630300 do
      code { "4630300" }
      name { "鹿児島県三島村" }
      yomi { "かごしまけんみしまむら" }
      short_name { "三島村" }
      short_yomi { "みしまむら" }
    end

    factory :jmaxml_forecast_region_c4630400 do
      code { "4630400" }
      name { "鹿児島県十島村" }
      yomi { "かごしまけんとしまむら" }
      short_name { "十島村" }
      short_yomi { "としまむら" }
    end

    factory :jmaxml_forecast_region_c4639200 do
      code { "4639200" }
      name { "鹿児島県さつま町" }
      yomi { "かごしまけんさつまちょう" }
      short_name { "さつま町" }
      short_yomi { "さつまちょう" }
    end

    factory :jmaxml_forecast_region_c4640400 do
      code { "4640400" }
      name { "鹿児島県長島町" }
      yomi { "かごしまけんながしまちょう" }
      short_name { "長島町" }
      short_yomi { "ながしまちょう" }
    end

    factory :jmaxml_forecast_region_c4645200 do
      code { "4645200" }
      name { "鹿児島県湧水町" }
      yomi { "かごしまけんゆうすいちょう" }
      short_name { "湧水町" }
      short_yomi { "ゆうすいちょう" }
    end

    factory :jmaxml_forecast_region_c4646800 do
      code { "4646800" }
      name { "鹿児島県大崎町" }
      yomi { "かごしまけんおおさきちょう" }
      short_name { "大崎町" }
      short_yomi { "おおさきちょう" }
    end

    factory :jmaxml_forecast_region_c4648200 do
      code { "4648200" }
      name { "鹿児島県東串良町" }
      yomi { "かごしまけんひがしくしらちょう" }
      short_name { "東串良町" }
      short_yomi { "ひがしくしらちょう" }
    end

    factory :jmaxml_forecast_region_c4649000 do
      code { "4649000" }
      name { "鹿児島県錦江町" }
      yomi { "かごしまけんきんこうちょう" }
      short_name { "錦江町" }
      short_yomi { "きんこうちょう" }
    end

    factory :jmaxml_forecast_region_c4649100 do
      code { "4649100" }
      name { "鹿児島県南大隅町" }
      yomi { "かごしまけんみなみおおすみちょう" }
      short_name { "南大隅町" }
      short_yomi { "みなみおおすみちょう" }
    end

    factory :jmaxml_forecast_region_c4649200 do
      code { "4649200" }
      name { "鹿児島県肝付町" }
      yomi { "かごしまけんきもつきちょう" }
      short_name { "肝付町" }
      short_yomi { "きもつきちょう" }
    end

    factory :jmaxml_forecast_region_c4650100 do
      code { "4650100" }
      name { "鹿児島県中種子町" }
      yomi { "かごしまけんなかたねちょう" }
      short_name { "中種子町" }
      short_yomi { "なかたねちょう" }
    end

    factory :jmaxml_forecast_region_c4650200 do
      code { "4650200" }
      name { "鹿児島県南種子町" }
      yomi { "かごしまけんみなみたねちょう" }
      short_name { "南種子町" }
      short_yomi { "みなみたねちょう" }
    end

    factory :jmaxml_forecast_region_c4650500 do
      code { "4650500" }
      name { "鹿児島県屋久島町" }
      yomi { "かごしまけんやくしまちょう" }
      short_name { "屋久島町" }
      short_yomi { "やくしまちょう" }
    end

    factory :jmaxml_forecast_region_c4652300 do
      code { "4652300" }
      name { "鹿児島県大和村" }
      yomi { "かごしまけんやまとそん" }
      short_name { "大和村" }
      short_yomi { "やまとそん" }
    end

    factory :jmaxml_forecast_region_c4652400 do
      code { "4652400" }
      name { "鹿児島県宇検村" }
      yomi { "かごしまけんうけんそん" }
      short_name { "宇検村" }
      short_yomi { "うけんそん" }
    end

    factory :jmaxml_forecast_region_c4652500 do
      code { "4652500" }
      name { "鹿児島県瀬戸内町" }
      yomi { "かごしまけんせとうちちょう" }
      short_name { "瀬戸内町" }
      short_yomi { "せとうちちょう" }
    end

    factory :jmaxml_forecast_region_c4652700 do
      code { "4652700" }
      name { "鹿児島県龍郷町" }
      yomi { "かごしまけんたつごうちょう" }
      short_name { "龍郷町" }
      short_yomi { "たつごうちょう" }
    end

    factory :jmaxml_forecast_region_c4652900 do
      code { "4652900" }
      name { "鹿児島県喜界町" }
      yomi { "かごしまけんきかいちょう" }
      short_name { "喜界町" }
      short_yomi { "きかいちょう" }
    end

    factory :jmaxml_forecast_region_c4653000 do
      code { "4653000" }
      name { "鹿児島県徳之島町" }
      yomi { "かごしまけんとくのしまちょう" }
      short_name { "徳之島町" }
      short_yomi { "とくのしまちょう" }
    end

    factory :jmaxml_forecast_region_c4653100 do
      code { "4653100" }
      name { "鹿児島県天城町" }
      yomi { "かごしまけんあまぎちょう" }
      short_name { "天城町" }
      short_yomi { "あまぎちょう" }
    end

    factory :jmaxml_forecast_region_c4653200 do
      code { "4653200" }
      name { "鹿児島県伊仙町" }
      yomi { "かごしまけんいせんちょう" }
      short_name { "伊仙町" }
      short_yomi { "いせんちょう" }
    end

    factory :jmaxml_forecast_region_c4653300 do
      code { "4653300" }
      name { "鹿児島県和泊町" }
      yomi { "かごしまけんわどまりちょう" }
      short_name { "和泊町" }
      short_yomi { "わどまりちょう" }
    end

    factory :jmaxml_forecast_region_c4653400 do
      code { "4653400" }
      name { "鹿児島県知名町" }
      yomi { "かごしまけんちなちょう" }
      short_name { "知名町" }
      short_yomi { "ちなちょう" }
    end

    factory :jmaxml_forecast_region_c4653500 do
      code { "4653500" }
      name { "鹿児島県与論町" }
      yomi { "かごしまけんよろんちょう" }
      short_name { "与論町" }
      short_yomi { "よろんちょう" }
    end

    factory :jmaxml_forecast_region_c4720100 do
      code { "4720100" }
      name { "沖縄県那覇市" }
      yomi { "おきなわけんなはし" }
      short_name { "那覇市" }
      short_yomi { "なはし" }
    end

    factory :jmaxml_forecast_region_c4720500 do
      code { "4720500" }
      name { "沖縄県宜野湾市" }
      yomi { "おきなわけんぎのわんし" }
      short_name { "宜野湾市" }
      short_yomi { "ぎのわんし" }
    end

    factory :jmaxml_forecast_region_c4720700 do
      code { "4720700" }
      name { "沖縄県石垣市" }
      yomi { "おきなわけんいしがきし" }
      short_name { "石垣市" }
      short_yomi { "いしがきし" }
    end

    factory :jmaxml_forecast_region_c4720800 do
      code { "4720800" }
      name { "沖縄県浦添市" }
      yomi { "おきなわけんうらそえし" }
      short_name { "浦添市" }
      short_yomi { "うらそえし" }
    end

    factory :jmaxml_forecast_region_c4720900 do
      code { "4720900" }
      name { "沖縄県名護市" }
      yomi { "おきなわけんなごし" }
      short_name { "名護市" }
      short_yomi { "なごし" }
    end

    factory :jmaxml_forecast_region_c4721000 do
      code { "4721000" }
      name { "沖縄県糸満市" }
      yomi { "おきなわけんいとまんし" }
      short_name { "糸満市" }
      short_yomi { "いとまんし" }
    end

    factory :jmaxml_forecast_region_c4721100 do
      code { "4721100" }
      name { "沖縄県沖縄市" }
      yomi { "おきなわけんおきなわし" }
      short_name { "沖縄市" }
      short_yomi { "おきなわし" }
    end

    factory :jmaxml_forecast_region_c4721200 do
      code { "4721200" }
      name { "沖縄県豊見城市" }
      yomi { "おきなわけんとみぐすくし" }
      short_name { "豊見城市" }
      short_yomi { "とみぐすくし" }
    end

    factory :jmaxml_forecast_region_c4721300 do
      code { "4721300" }
      name { "沖縄県うるま市" }
      yomi { "おきなわけんうるまし" }
      short_name { "うるま市" }
      short_yomi { "うるまし" }
    end

    factory :jmaxml_forecast_region_c4721400 do
      code { "4721400" }
      name { "沖縄県宮古島市" }
      yomi { "おきなわけんみやこじまし" }
      short_name { "宮古島市" }
      short_yomi { "みやこじまし" }
    end

    factory :jmaxml_forecast_region_c4721500 do
      code { "4721500" }
      name { "沖縄県南城市" }
      yomi { "おきなわけんなんじょうし" }
      short_name { "南城市" }
      short_yomi { "なんじょうし" }
    end

    factory :jmaxml_forecast_region_c4730100 do
      code { "4730100" }
      name { "沖縄県国頭村" }
      yomi { "おきなわけんくにがみそん" }
      short_name { "国頭村" }
      short_yomi { "くにがみそん" }
    end

    factory :jmaxml_forecast_region_c4730200 do
      code { "4730200" }
      name { "沖縄県大宜味村" }
      yomi { "おきなわけんおおぎみそん" }
      short_name { "大宜味村" }
      short_yomi { "おおぎみそん" }
    end

    factory :jmaxml_forecast_region_c4730300 do
      code { "4730300" }
      name { "沖縄県東村" }
      yomi { "おきなわけんひがしそん" }
      short_name { "東村" }
      short_yomi { "ひがしそん" }
    end

    factory :jmaxml_forecast_region_c4730600 do
      code { "4730600" }
      name { "沖縄県今帰仁村" }
      yomi { "おきなわけんなきじんそん" }
      short_name { "今帰仁村" }
      short_yomi { "なきじんそん" }
    end

    factory :jmaxml_forecast_region_c4730800 do
      code { "4730800" }
      name { "沖縄県本部町" }
      yomi { "おきなわけんもとぶちょう" }
      short_name { "本部町" }
      short_yomi { "もとぶちょう" }
    end

    factory :jmaxml_forecast_region_c4731100 do
      code { "4731100" }
      name { "沖縄県恩納村" }
      yomi { "おきなわけんおんなそん" }
      short_name { "恩納村" }
      short_yomi { "おんなそん" }
    end

    factory :jmaxml_forecast_region_c4731300 do
      code { "4731300" }
      name { "沖縄県宜野座村" }
      yomi { "おきなわけんぎのざそん" }
      short_name { "宜野座村" }
      short_yomi { "ぎのざそん" }
    end

    factory :jmaxml_forecast_region_c4731400 do
      code { "4731400" }
      name { "沖縄県金武町" }
      yomi { "おきなわけんきんちょう" }
      short_name { "金武町" }
      short_yomi { "きんちょう" }
    end

    factory :jmaxml_forecast_region_c4731500 do
      code { "4731500" }
      name { "沖縄県伊江村" }
      yomi { "おきなわけんいえそん" }
      short_name { "伊江村" }
      short_yomi { "いえそん" }
    end

    factory :jmaxml_forecast_region_c4732400 do
      code { "4732400" }
      name { "沖縄県読谷村" }
      yomi { "おきなわけんよみたんそん" }
      short_name { "読谷村" }
      short_yomi { "よみたんそん" }
    end

    factory :jmaxml_forecast_region_c4732500 do
      code { "4732500" }
      name { "沖縄県嘉手納町" }
      yomi { "おきなわけんかでなちょう" }
      short_name { "嘉手納町" }
      short_yomi { "かでなちょう" }
    end

    factory :jmaxml_forecast_region_c4732600 do
      code { "4732600" }
      name { "沖縄県北谷町" }
      yomi { "おきなわけんちゃたんちょう" }
      short_name { "北谷町" }
      short_yomi { "ちゃたんちょう" }
    end

    factory :jmaxml_forecast_region_c4732700 do
      code { "4732700" }
      name { "沖縄県北中城村" }
      yomi { "おきなわけんきたなかぐすくそん" }
      short_name { "北中城村" }
      short_yomi { "きたなかぐすくそん" }
    end

    factory :jmaxml_forecast_region_c4732800 do
      code { "4732800" }
      name { "沖縄県中城村" }
      yomi { "おきなわけんなかぐすくそん" }
      short_name { "中城村" }
      short_yomi { "なかぐすくそん" }
    end

    factory :jmaxml_forecast_region_c4732900 do
      code { "4732900" }
      name { "沖縄県西原町" }
      yomi { "おきなわけんにしはらちょう" }
      short_name { "西原町" }
      short_yomi { "にしはらちょう" }
    end

    factory :jmaxml_forecast_region_c4734800 do
      code { "4734800" }
      name { "沖縄県与那原町" }
      yomi { "おきなわけんよなばるちょう" }
      short_name { "与那原町" }
      short_yomi { "よなばるちょう" }
    end

    factory :jmaxml_forecast_region_c4735000 do
      code { "4735000" }
      name { "沖縄県南風原町" }
      yomi { "おきなわけんはえばるちょう" }
      short_name { "南風原町" }
      short_yomi { "はえばるちょう" }
    end

    factory :jmaxml_forecast_region_c4735300 do
      code { "4735300" }
      name { "沖縄県渡嘉敷村" }
      yomi { "おきなわけんとかしきそん" }
      short_name { "渡嘉敷村" }
      short_yomi { "とかしきそん" }
    end

    factory :jmaxml_forecast_region_c4735400 do
      code { "4735400" }
      name { "沖縄県座間味村" }
      yomi { "おきなわけんざまみそん" }
      short_name { "座間味村" }
      short_yomi { "ざまみそん" }
    end

    factory :jmaxml_forecast_region_c4735500 do
      code { "4735500" }
      name { "沖縄県粟国村" }
      yomi { "おきなわけんあぐにそん" }
      short_name { "粟国村" }
      short_yomi { "あぐにそん" }
    end

    factory :jmaxml_forecast_region_c4735600 do
      code { "4735600" }
      name { "沖縄県渡名喜村" }
      yomi { "おきなわけんとなきそん" }
      short_name { "渡名喜村" }
      short_yomi { "となきそん" }
    end

    factory :jmaxml_forecast_region_c4735700 do
      code { "4735700" }
      name { "沖縄県南大東村" }
      yomi { "おきなわけんみなみだいとうそん" }
      short_name { "南大東村" }
      short_yomi { "みなみだいとうそん" }
    end

    factory :jmaxml_forecast_region_c4735800 do
      code { "4735800" }
      name { "沖縄県北大東村" }
      yomi { "おきなわけんきただいとうそん" }
      short_name { "北大東村" }
      short_yomi { "きただいとうそん" }
    end

    factory :jmaxml_forecast_region_c4735900 do
      code { "4735900" }
      name { "沖縄県伊平屋村" }
      yomi { "おきなわけんいへやそん" }
      short_name { "伊平屋村" }
      short_yomi { "いへやそん" }
    end

    factory :jmaxml_forecast_region_c4736000 do
      code { "4736000" }
      name { "沖縄県伊是名村" }
      yomi { "おきなわけんいぜなそん" }
      short_name { "伊是名村" }
      short_yomi { "いぜなそん" }
    end

    factory :jmaxml_forecast_region_c4736100 do
      code { "4736100" }
      name { "沖縄県久米島町" }
      yomi { "おきなわけんくめじまちょう" }
      short_name { "久米島町" }
      short_yomi { "くめじまちょう" }
    end

    factory :jmaxml_forecast_region_c4736200 do
      code { "4736200" }
      name { "沖縄県八重瀬町" }
      yomi { "おきなわけんやえせちょう" }
      short_name { "八重瀬町" }
      short_yomi { "やえせちょう" }
    end

    factory :jmaxml_forecast_region_c4737500 do
      code { "4737500" }
      name { "沖縄県多良間村" }
      yomi { "おきなわけんたらまそん" }
      short_name { "多良間村" }
      short_yomi { "たらまそん" }
    end

    factory :jmaxml_forecast_region_c4738100 do
      code { "4738100" }
      name { "沖縄県竹富町" }
      yomi { "おきなわけんたけとみちょう" }
      short_name { "竹富町" }
      short_yomi { "たけとみちょう" }
    end

    factory :jmaxml_forecast_region_c4738200 do
      code { "4738200" }
      name { "沖縄県与那国町" }
      yomi { "おきなわけんよなぐにちょう" }
      short_name { "与那国町" }
      short_yomi { "よなぐにちょう" }
    end
  end
end
