FactoryBot.define do
  factory :jmaxml_tsunami_region_base, class: Jmaxml::TsunamiRegion do
    cur_site { cms_site }

    factory :jmaxml_tsunami_region_c100 do
      code { "100" }
      name { "北海道太平洋沿岸東部" }
      yomi { "ほっかいどうたいへいようえんがんとうぶ" }
    end

    factory :jmaxml_tsunami_region_c101 do
      code { "101" }
      name { "北海道太平洋沿岸中部" }
      yomi { "ほっかいどうたいへいようえんがんちゅうぶ" }
    end

    factory :jmaxml_tsunami_region_c102 do
      code { "102" }
      name { "北海道太平洋沿岸西部" }
      yomi { "ほっかいどうたいへいようえんがんせいぶ" }
    end

    factory :jmaxml_tsunami_region_c110 do
      code { "110" }
      name { "北海道日本海沿岸北部" }
      yomi { "ほっかいどうにほんかいえんがんほくぶ" }
    end

    factory :jmaxml_tsunami_region_c111 do
      code { "111" }
      name { "北海道日本海沿岸南部" }
      yomi { "ほっかいどうにほんかいえんがんなんぶ" }
    end

    factory :jmaxml_tsunami_region_c120 do
      code { "120" }
      name { "オホーツク海沿岸" }
      yomi { "おほーつくかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c191 do
      code { "191" }
      name { "北海道太平洋沿岸" }
      yomi { "ほっかいどうたいへいようえんがん" }
    end

    factory :jmaxml_tsunami_region_c192 do
      code { "192" }
      name { "北海道日本海沿岸" }
      yomi { "ほっかいどうにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c193 do
      code { "193" }
      name { "オホーツク海沿岸" }
      yomi { "おほーつくかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c200 do
      code { "200" }
      name { "青森県日本海沿岸" }
      yomi { "あおもりけんにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c201 do
      code { "201" }
      name { "青森県太平洋沿岸" }
      yomi { "あおもりけんたいへいようえんがん" }
    end

    factory :jmaxml_tsunami_region_c202 do
      code { "202" }
      name { "陸奥湾" }
      yomi { "むつわん" }
    end

    factory :jmaxml_tsunami_region_c210 do
      code { "210" }
      name { "岩手県" }
      yomi { "いわてけん" }
    end

    factory :jmaxml_tsunami_region_c220 do
      code { "220" }
      name { "宮城県" }
      yomi { "みやぎけん" }
    end

    factory :jmaxml_tsunami_region_c230 do
      code { "230" }
      name { "秋田県" }
      yomi { "あきたけん" }
    end

    factory :jmaxml_tsunami_region_c240 do
      code { "240" }
      name { "山形県" }
      yomi { "やまがたけん" }
    end

    factory :jmaxml_tsunami_region_c250 do
      code { "250" }
      name { "福島県" }
      yomi { "ふくしまけん" }
    end

    factory :jmaxml_tsunami_region_c281 do
      code { "281" }
      name { "青森県" }
      yomi { "あおもりけん" }
    end

    factory :jmaxml_tsunami_region_c291 do
      code { "291" }
      name { "東北地方太平洋沿岸" }
      yomi { "とうほくちほうたいへいようえんがん" }
    end

    factory :jmaxml_tsunami_region_c292 do
      code { "292" }
      name { "東北地方日本海沿岸" }
      yomi { "とうほくちほうにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c300 do
      code { "300" }
      name { "茨城県" }
      yomi { "いばらきけん" }
    end

    factory :jmaxml_tsunami_region_c310 do
      code { "310" }
      name { "千葉県九十九里・外房" }
      yomi { "ちばけんくじゅうくりそとぼう" }
    end

    factory :jmaxml_tsunami_region_c311 do
      code { "311" }
      name { "千葉県内房" }
      yomi { "ちばけんうちぼう" }
    end

    factory :jmaxml_tsunami_region_c312 do
      code { "312" }
      name { "東京湾内湾" }
      yomi { "とうきょうわんないわん" }
    end

    factory :jmaxml_tsunami_region_c320 do
      code { "320" }
      name { "伊豆諸島" }
      yomi { "いずしょとう" }
    end

    factory :jmaxml_tsunami_region_c321 do
      code { "321" }
      name { "小笠原諸島" }
      yomi { "おがさわらしょとう" }
    end

    factory :jmaxml_tsunami_region_c330 do
      code { "330" }
      name { "相模湾・三浦半島" }
      yomi { "さがみわんみうらはんとう" }
    end

    factory :jmaxml_tsunami_region_c340 do
      code { "340" }
      name { "新潟県上中下越" }
      yomi { "にいがたけんじょうちゅうかえつ" }
    end

    factory :jmaxml_tsunami_region_c341 do
      code { "341" }
      name { "佐渡" }
      yomi { "さど" }
    end

    factory :jmaxml_tsunami_region_c350 do
      code { "350" }
      name { "富山県" }
      yomi { "とやまけん" }
    end

    factory :jmaxml_tsunami_region_c360 do
      code { "360" }
      name { "石川県能登" }
      yomi { "いしかわけんのと" }
    end

    factory :jmaxml_tsunami_region_c361 do
      code { "361" }
      name { "石川県加賀" }
      yomi { "いしかわけんかが" }
    end

    factory :jmaxml_tsunami_region_c370 do
      code { "370" }
      name { "福井県" }
      yomi { "ふくいけん" }
    end

    factory :jmaxml_tsunami_region_c380 do
      code { "380" }
      name { "静岡県" }
      yomi { "しずおかけん" }
    end

    factory :jmaxml_tsunami_region_c390 do
      code { "390" }
      name { "愛知県外海" }
      yomi { "あいちけんそとうみ" }
    end

    factory :jmaxml_tsunami_region_c391 do
      code { "391" }
      name { "伊勢・三河湾" }
      yomi { "いせみかわわん" }
    end

    factory :jmaxml_tsunami_region_c400 do
      code { "400" }
      name { "三重県南部" }
      yomi { "みえけんなんぶ" }
    end

    factory :jmaxml_tsunami_region_c481 do
      code { "481" }
      name { "千葉県" }
      yomi { "ちばけん" }
    end

    factory :jmaxml_tsunami_region_c482 do
      code { "482" }
      name { "神奈川県" }
      yomi { "かながわけん" }
    end

    factory :jmaxml_tsunami_region_c483 do
      code { "483" }
      name { "新潟県" }
      yomi { "にいがたけん" }
    end

    factory :jmaxml_tsunami_region_c484 do
      code { "484" }
      name { "石川県" }
      yomi { "いしかわけん" }
    end

    factory :jmaxml_tsunami_region_c485 do
      code { "485" }
      name { "愛知県" }
      yomi { "あいちけん" }
    end

    factory :jmaxml_tsunami_region_c486 do
      code { "486" }
      name { "三重県" }
      yomi { "みえけん" }
    end

    factory :jmaxml_tsunami_region_c491 do
      code { "491" }
      name { "関東地方" }
      yomi { "かんとうちほう" }
    end

    factory :jmaxml_tsunami_region_c492 do
      code { "492" }
      name { "伊豆・小笠原諸島" }
      yomi { "いずおがさわらしょとう" }
    end

    factory :jmaxml_tsunami_region_c493 do
      code { "493" }
      name { "北陸地方" }
      yomi { "ほくりくちほう" }
    end

    factory :jmaxml_tsunami_region_c494 do
      code { "494" }
      name { "東海地方" }
      yomi { "とうかいちほう" }
    end

    factory :jmaxml_tsunami_region_c500 do
      code { "500" }
      name { "京都府" }
      yomi { "きょうとふ" }
    end

    factory :jmaxml_tsunami_region_c510 do
      code { "510" }
      name { "大阪府" }
      yomi { "おおさかふ" }
    end

    factory :jmaxml_tsunami_region_c520 do
      code { "520" }
      name { "兵庫県北部" }
      yomi { "ひょうごけんほくぶ" }
    end

    factory :jmaxml_tsunami_region_c521 do
      code { "521" }
      name { "兵庫県瀬戸内海沿岸" }
      yomi { "ひょうごけんせとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c522 do
      code { "522" }
      name { "淡路島南部" }
      yomi { "あわじしまなんぶ" }
    end

    factory :jmaxml_tsunami_region_c530 do
      code { "530" }
      name { "和歌山県" }
      yomi { "わかやまけん" }
    end

    factory :jmaxml_tsunami_region_c540 do
      code { "540" }
      name { "鳥取県" }
      yomi { "とっとりけん" }
    end

    factory :jmaxml_tsunami_region_c550 do
      code { "550" }
      name { "島根県出雲・石見" }
      yomi { "しまねけんいずもいわみ" }
    end

    factory :jmaxml_tsunami_region_c551 do
      code { "551" }
      name { "隠岐" }
      yomi { "おき" }
    end

    factory :jmaxml_tsunami_region_c560 do
      code { "560" }
      name { "岡山県" }
      yomi { "おかやまけん" }
    end

    factory :jmaxml_tsunami_region_c570 do
      code { "570" }
      name { "広島県" }
      yomi { "ひろしまけん" }
    end

    factory :jmaxml_tsunami_region_c580 do
      code { "580" }
      name { "徳島県" }
      yomi { "とくしまけん" }
    end

    factory :jmaxml_tsunami_region_c590 do
      code { "590" }
      name { "香川県" }
      yomi { "かがわけん" }
    end

    factory :jmaxml_tsunami_region_c600 do
      code { "600" }
      name { "愛媛県宇和海沿岸" }
      yomi { "えひめけんうわかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c601 do
      code { "601" }
      name { "愛媛県瀬戸内海沿岸" }
      yomi { "えひめけんせとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c610 do
      code { "610" }
      name { "高知県" }
      yomi { "こうちけん" }
    end

    factory :jmaxml_tsunami_region_c681 do
      code { "681" }
      name { "兵庫県" }
      yomi { "ひょうごけん" }
    end

    factory :jmaxml_tsunami_region_c682 do
      code { "682" }
      name { "島根県" }
      yomi { "しまねけん" }
    end

    factory :jmaxml_tsunami_region_c683 do
      code { "683" }
      name { "愛媛県" }
      yomi { "えひめけん" }
    end

    factory :jmaxml_tsunami_region_c691 do
      code { "691" }
      name { "近畿四国太平洋沿岸" }
      yomi { "きんきしこくたいへいようえんがん" }
    end

    factory :jmaxml_tsunami_region_c692 do
      code { "692" }
      name { "近畿中国日本海沿岸" }
      yomi { "きんきちゅうごくにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c693 do
      code { "693" }
      name { "瀬戸内海沿岸" }
      yomi { "せとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c700 do
      code { "700" }
      name { "山口県日本海沿岸" }
      yomi { "やまぐちけんにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c701 do
      code { "701" }
      name { "山口県瀬戸内海沿岸" }
      yomi { "やまぐちけんせとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c710 do
      code { "710" }
      name { "福岡県瀬戸内海沿岸" }
      yomi { "ふくおかけんせとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c711 do
      code { "711" }
      name { "福岡県日本海沿岸" }
      yomi { "ふくおかけんにほんかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c712 do
      code { "712" }
      name { "有明・八代海" }
      yomi { "ありあけやつしろかい" }
    end

    factory :jmaxml_tsunami_region_c720 do
      code { "720" }
      name { "佐賀県北部" }
      yomi { "さがけんほくぶ" }
    end

    factory :jmaxml_tsunami_region_c730 do
      code { "730" }
      name { "長崎県西方" }
      yomi { "ながさきけんせいほう" }
    end

    factory :jmaxml_tsunami_region_c731 do
      code { "731" }
      name { "壱岐・対馬" }
      yomi { "いきつしま" }
    end

    factory :jmaxml_tsunami_region_c740 do
      code { "740" }
      name { "熊本県天草灘沿岸" }
      yomi { "くまもとけんあまくさなだえんがん" }
    end

    factory :jmaxml_tsunami_region_c750 do
      code { "750" }
      name { "大分県瀬戸内海沿岸" }
      yomi { "おおいたけんせとないかいえんがん" }
    end

    factory :jmaxml_tsunami_region_c751 do
      code { "751" }
      name { "大分県豊後水道沿岸" }
      yomi { "おおいたけんぶんごすいどうえんがん" }
    end

    factory :jmaxml_tsunami_region_c760 do
      code { "760" }
      name { "宮崎県" }
      yomi { "みやざきけん" }
    end

    factory :jmaxml_tsunami_region_c770 do
      code { "770" }
      name { "鹿児島県東部" }
      yomi { "かごしまけんとうぶ" }
    end

    factory :jmaxml_tsunami_region_c771 do
      code { "771" }
      name { "種子島・屋久島地方" }
      yomi { "たねがしまやくしまちほう" }
    end

    factory :jmaxml_tsunami_region_c772 do
      code { "772" }
      name { "奄美群島・トカラ列島" }
      yomi { "あまみぐんとうとかられっとう" }
    end

    factory :jmaxml_tsunami_region_c773 do
      code { "773" }
      name { "鹿児島県西部" }
      yomi { "かごしまけんせいぶ" }
    end

    factory :jmaxml_tsunami_region_c781 do
      code { "781" }
      name { "山口県" }
      yomi { "やまぐちけん" }
    end

    factory :jmaxml_tsunami_region_c782 do
      code { "782" }
      name { "福岡県" }
      yomi { "ふくおかけん" }
    end

    factory :jmaxml_tsunami_region_c783 do
      code { "783" }
      name { "佐賀県" }
      yomi { "さがけん" }
    end

    factory :jmaxml_tsunami_region_c784 do
      code { "784" }
      name { "長崎県" }
      yomi { "ながさきけん" }
    end

    factory :jmaxml_tsunami_region_c785 do
      code { "785" }
      name { "熊本県" }
      yomi { "くまもとけん" }
    end

    factory :jmaxml_tsunami_region_c786 do
      code { "786" }
      name { "大分県" }
      yomi { "おおいたけん" }
    end

    factory :jmaxml_tsunami_region_c787 do
      code { "787" }
      name { "鹿児島県" }
      yomi { "かごしまけん" }
    end

    factory :jmaxml_tsunami_region_c791 do
      code { "791" }
      name { "九州地方東部" }
      yomi { "きゅうしゅうちほうとうぶ" }
    end

    factory :jmaxml_tsunami_region_c792 do
      code { "792" }
      name { "九州地方西部" }
      yomi { "きゅうしゅうちほうせいぶ" }
    end

    factory :jmaxml_tsunami_region_c793 do
      code { "793" }
      name { "薩南諸島" }
      yomi { "さつなんしょとう" }
    end

    factory :jmaxml_tsunami_region_c800 do
      code { "800" }
      name { "沖縄本島地方" }
      yomi { "おきなわほんとうちほう" }
    end

    factory :jmaxml_tsunami_region_c801 do
      code { "801" }
      name { "大東島地方" }
      yomi { "だいとうじまちほう" }
    end

    factory :jmaxml_tsunami_region_c802 do
      code { "802" }
      name { "宮古島・八重山地方" }
      yomi { "みやこじまやえやまちほう" }
    end

    factory :jmaxml_tsunami_region_c891 do
      code { "891" }
      name { "沖縄県地方" }
      yomi { "おきなわけんちほう" }
    end

    factory :jmaxml_tsunami_region_c990 do
      code { "990" }
      name { "GPS波浪計" }
      yomi { "じーぴーえすはろうけい" }
    end
  end
end
