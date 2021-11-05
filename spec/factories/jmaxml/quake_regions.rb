FactoryBot.define do
  factory :jmaxml_region_base, class: Jmaxml::QuakeRegion do
    transient do
      site { nil }
    end

    cur_site { site || cms_site }

    factory :jmaxml_region_c135 do
      name { "宗谷支庁北部" }
      code { "135" }
      order { 135 }
    end

    factory :jmaxml_region_c136 do
      name { "宗谷支庁南部" }
      code { "136" }
      order { 136 }
    end

    factory :jmaxml_region_c125 do
      name { "上川支庁北部" }
      code { "125" }
      order { 125 }
    end

    factory :jmaxml_region_c126 do
      name { "上川支庁中部" }
      code { "126" }
      order { 126 }
    end

    factory :jmaxml_region_c127 do
      name { "上川支庁南部" }
      code { "127" }
      order { 127 }
    end

    factory :jmaxml_region_c130 do
      name { "留萌支庁中北部" }
      code { "130" }
      order { 130 }
    end

    factory :jmaxml_region_c131 do
      name { "留萌支庁南部" }
      code { "131" }
      order { 131 }
    end

    factory :jmaxml_region_c139 do
      name { "北海道利尻礼文" }
      code { "139" }
      order { 139 }
    end

    factory :jmaxml_region_c150 do
      name { "日高支庁西部" }
      code { "150" }
      order { 150 }
    end

    factory :jmaxml_region_c151 do
      name { "日高支庁中部" }
      code { "151" }
      order { 151 }
    end

    factory :jmaxml_region_c152 do
      name { "日高支庁東部" }
      code { "152" }
      order { 152 }
    end

    factory :jmaxml_region_c145 do
      name { "胆振支庁西部" }
      code { "145" }
      order { 145 }
    end

    factory :jmaxml_region_c146 do
      name { "胆振支庁中東部" }
      code { "146" }
      order { 146 }
    end

    factory :jmaxml_region_c110 do
      name { "檜山支庁" }
      code { "110" }
      order { 110 }
    end

    factory :jmaxml_region_c105 do
      name { "渡島支庁北部" }
      code { "105" }
      order { 105 }
    end

    factory :jmaxml_region_c106 do
      name { "渡島支庁東部" }
      code { "106" }
      order { 106 }
    end

    factory :jmaxml_region_c107 do
      name { "渡島支庁西部" }
      code { "107" }
      order { 107 }
    end

    factory :jmaxml_region_c140 do
      name { "網走支庁網走" }
      code { "140" }
      order { 140 }
    end

    factory :jmaxml_region_c141 do
      name { "網走支庁北見" }
      code { "141" }
      order { 141 }
    end

    factory :jmaxml_region_c142 do
      name { "網走支庁紋別" }
      code { "142" }
      order { 142 }
    end

    factory :jmaxml_region_c165 do
      name { "根室支庁北部" }
      code { "165" }
      order { 165 }
    end

    factory :jmaxml_region_c166 do
      name { "根室支庁中部" }
      code { "166" }
      order { 166 }
    end

    factory :jmaxml_region_c167 do
      name { "根室支庁南部" }
      code { "167" }
      order { 167 }
    end

    factory :jmaxml_region_c160 do
      name { "釧路支庁北部" }
      code { "160" }
      order { 160 }
    end

    factory :jmaxml_region_c161 do
      name { "釧路支庁中南部" }
      code { "161" }
      order { 161 }
    end

    factory :jmaxml_region_c155 do
      name { "十勝支庁北部" }
      code { "155" }
      order { 155 }
    end

    factory :jmaxml_region_c156 do
      name { "十勝支庁中部" }
      code { "156" }
      order { 156 }
    end

    factory :jmaxml_region_c157 do
      name { "十勝支庁南部" }
      code { "157" }
      order { 157 }
    end

    factory :jmaxml_region_c119 do
      name { "北海道奥尻島" }
      code { "119" }
      order { 119 }
    end

    factory :jmaxml_region_c120 do
      name { "空知支庁北部" }
      code { "120" }
      order { 120 }
    end

    factory :jmaxml_region_c121 do
      name { "空知支庁中部" }
      code { "121" }
      order { 121 }
    end

    factory :jmaxml_region_c122 do
      name { "空知支庁南部" }
      code { "122" }
      order { 122 }
    end

    factory :jmaxml_region_c100 do
      name { "石狩支庁北部" }
      code { "100" }
      order { 100 }
    end

    factory :jmaxml_region_c101 do
      name { "石狩支庁中部" }
      code { "101" }
      order { 101 }
    end

    factory :jmaxml_region_c102 do
      name { "石狩支庁南部" }
      code { "102" }
      order { 102 }
    end

    factory :jmaxml_region_c115 do
      name { "後志支庁北部" }
      code { "115" }
      order { 115 }
    end

    factory :jmaxml_region_c116 do
      name { "後志支庁東部" }
      code { "116" }
      order { 116 }
    end

    factory :jmaxml_region_c117 do
      name { "後志支庁西部" }
      code { "117" }
      order { 117 }
    end

    factory :jmaxml_region_c200 do
      name { "青森県津軽北部" }
      code { "200" }
      order { 200 }
    end

    factory :jmaxml_region_c201 do
      name { "青森県津軽南部" }
      code { "201" }
      order { 201 }
    end

    factory :jmaxml_region_c202 do
      name { "青森県三八上北" }
      code { "202" }
      order { 202 }
    end

    factory :jmaxml_region_c203 do
      name { "青森県下北" }
      code { "203" }
      order { 203 }
    end

    factory :jmaxml_region_c230 do
      name { "秋田県沿岸北部" }
      code { "230" }
      order { 230 }
    end

    factory :jmaxml_region_c231 do
      name { "秋田県沿岸南部" }
      code { "231" }
      order { 231 }
    end

    factory :jmaxml_region_c232 do
      name { "秋田県内陸北部" }
      code { "232" }
      order { 232 }
    end

    factory :jmaxml_region_c233 do
      name { "秋田県内陸南部" }
      code { "233" }
      order { 233 }
    end

    factory :jmaxml_region_c210 do
      name { "岩手県沿岸北部" }
      code { "210" }
      order { 210 }
    end

    factory :jmaxml_region_c211 do
      name { "岩手県沿岸南部" }
      code { "211" }
      order { 211 }
    end

    factory :jmaxml_region_c212 do
      name { "岩手県内陸北部" }
      code { "212" }
      order { 212 }
    end

    factory :jmaxml_region_c213 do
      name { "岩手県内陸南部" }
      code { "213" }
      order { 213 }
    end

    factory :jmaxml_region_c220 do
      name { "宮城県北部" }
      code { "220" }
      order { 220 }
    end

    factory :jmaxml_region_c221 do
      name { "宮城県南部" }
      code { "221" }
      order { 221 }
    end

    factory :jmaxml_region_c222 do
      name { "宮城県中部" }
      code { "222" }
      order { 222 }
    end

    factory :jmaxml_region_c240 do
      name { "山形県庄内" }
      code { "240" }
      order { 240 }
    end

    factory :jmaxml_region_c241 do
      name { "山形県最上" }
      code { "241" }
      order { 241 }
    end

    factory :jmaxml_region_c242 do
      name { "山形県村山" }
      code { "242" }
      order { 242 }
    end

    factory :jmaxml_region_c243 do
      name { "山形県置賜" }
      code { "243" }
      order { 243 }
    end

    factory :jmaxml_region_c250 do
      name { "福島県中通り" }
      code { "250" }
      order { 250 }
    end

    factory :jmaxml_region_c251 do
      name { "福島県浜通り" }
      code { "251" }
      order { 251 }
    end

    factory :jmaxml_region_c252 do
      name { "福島県会津" }
      code { "252" }
      order { 252 }
    end

    factory :jmaxml_region_c300 do
      name { "茨城県北部" }
      code { "300" }
      order { 300 }
    end

    factory :jmaxml_region_c301 do
      name { "茨城県南部" }
      code { "301" }
      order { 301 }
    end

    factory :jmaxml_region_c310 do
      name { "栃木県北部" }
      code { "310" }
      order { 310 }
    end

    factory :jmaxml_region_c311 do
      name { "栃木県南部" }
      code { "311" }
      order { 311 }
    end

    factory :jmaxml_region_c320 do
      name { "群馬県北部" }
      code { "320" }
      order { 320 }
    end

    factory :jmaxml_region_c321 do
      name { "群馬県南部" }
      code { "321" }
      order { 321 }
    end

    factory :jmaxml_region_c330 do
      name { "埼玉県北部" }
      code { "330" }
      order { 330 }
    end

    factory :jmaxml_region_c331 do
      name { "埼玉県南部" }
      code { "331" }
      order { 331 }
    end

    factory :jmaxml_region_c332 do
      name { "埼玉県秩父" }
      code { "332" }
      order { 332 }
    end

    factory :jmaxml_region_c350 do
      name { "東京都23区" }
      code { "350" }
      order { 350 }
    end

    factory :jmaxml_region_c351 do
      name { "東京都多摩東部" }
      code { "351" }
      order { 351 }
    end

    factory :jmaxml_region_c352 do
      name { "東京都多摩西部" }
      code { "352" }
      order { 352 }
    end

    factory :jmaxml_region_c354 do
      name { "神津島" }
      code { "354" }
      order { 354 }
    end

    factory :jmaxml_region_c355 do
      name { "伊豆大島" }
      code { "355" }
      order { 355 }
    end

    factory :jmaxml_region_c356 do
      name { "新島" }
      code { "356" }
      order { 356 }
    end

    factory :jmaxml_region_c357 do
      name { "三宅島" }
      code { "357" }
      order { 357 }
    end

    factory :jmaxml_region_c358 do
      name { "八丈島" }
      code { "358" }
      order { 358 }
    end

    factory :jmaxml_region_c359 do
      name { "小笠原" }
      code { "359" }
      order { 359 }
    end

    factory :jmaxml_region_c340 do
      name { "千葉県北東部" }
      code { "340" }
      order { 340 }
    end

    factory :jmaxml_region_c341 do
      name { "千葉県北西部" }
      code { "341" }
      order { 341 }
    end

    factory :jmaxml_region_c342 do
      name { "千葉県南部" }
      code { "342" }
      order { 342 }
    end

    factory :jmaxml_region_c360 do
      name { "神奈川県東部" }
      code { "360" }
      order { 360 }
    end

    factory :jmaxml_region_c361 do
      name { "神奈川県西部" }
      code { "361" }
      order { 361 }
    end

    factory :jmaxml_region_c420 do
      name { "長野県北部" }
      code { "420" }
      order { 420 }
    end

    factory :jmaxml_region_c421 do
      name { "長野県中部" }
      code { "421" }
      order { 421 }
    end

    factory :jmaxml_region_c422 do
      name { "長野県南部" }
      code { "422" }
      order { 422 }
    end

    factory :jmaxml_region_c410 do
      name { "山梨県東部" }
      code { "410" }
      order { 410 }
    end

    factory :jmaxml_region_c411 do
      name { "山梨県中・西部" }
      code { "411" }
      order { 411 }
    end

    factory :jmaxml_region_c412 do
      name { "山梨県東部・富士五湖" }
      code { "412" }
      order { 412 }
    end

    factory :jmaxml_region_c440 do
      name { "静岡県伊豆" }
      code { "440" }
      order { 440 }
    end

    factory :jmaxml_region_c441 do
      name { "静岡県東部" }
      code { "441" }
      order { 441 }
    end

    factory :jmaxml_region_c442 do
      name { "静岡県中部" }
      code { "442" }
      order { 442 }
    end

    factory :jmaxml_region_c443 do
      name { "静岡県西部" }
      code { "443" }
      order { 443 }
    end

    factory :jmaxml_region_c450 do
      name { "愛知県東部" }
      code { "450" }
      order { 450 }
    end

    factory :jmaxml_region_c451 do
      name { "愛知県西部" }
      code { "451" }
      order { 451 }
    end

    factory :jmaxml_region_c430 do
      name { "岐阜県飛騨" }
      code { "430" }
      order { 430 }
    end

    factory :jmaxml_region_c431 do
      name { "岐阜県美濃東部" }
      code { "431" }
      order { 431 }
    end

    factory :jmaxml_region_c432 do
      name { "岐阜県美濃中西部" }
      code { "432" }
      order { 432 }
    end

    factory :jmaxml_region_c460 do
      name { "三重県北部" }
      code { "460" }
      order { 460 }
    end

    factory :jmaxml_region_c461 do
      name { "三重県中部" }
      code { "461" }
      order { 461 }
    end

    factory :jmaxml_region_c462 do
      name { "三重県南部" }
      code { "462" }
      order { 462 }
    end

    factory :jmaxml_region_c370 do
      name { "新潟県上越" }
      code { "370" }
      order { 370 }
    end

    factory :jmaxml_region_c371 do
      name { "新潟県中越" }
      code { "371" }
      order { 371 }
    end

    factory :jmaxml_region_c372 do
      name { "新潟県下越" }
      code { "372" }
      order { 372 }
    end

    factory :jmaxml_region_c375 do
      name { "新潟県佐渡" }
      code { "375" }
      order { 375 }
    end

    factory :jmaxml_region_c380 do
      name { "富山県東部" }
      code { "380" }
      order { 380 }
    end

    factory :jmaxml_region_c381 do
      name { "富山県西部" }
      code { "381" }
      order { 381 }
    end

    factory :jmaxml_region_c390 do
      name { "石川県能登" }
      code { "390" }
      order { 390 }
    end

    factory :jmaxml_region_c391 do
      name { "石川県加賀" }
      code { "391" }
      order { 391 }
    end

    factory :jmaxml_region_c400 do
      name { "福井県嶺北" }
      code { "400" }
      order { 400 }
    end

    factory :jmaxml_region_c401 do
      name { "福井県嶺南" }
      code { "401" }
      order { 401 }
    end

    factory :jmaxml_region_c500 do
      name { "滋賀県北部" }
      code { "500" }
      order { 500 }
    end

    factory :jmaxml_region_c501 do
      name { "滋賀県南部" }
      code { "501" }
      order { 501 }
    end

    factory :jmaxml_region_c510 do
      name { "京都府北部" }
      code { "510" }
      order { 510 }
    end

    factory :jmaxml_region_c511 do
      name { "京都府南部" }
      code { "511" }
      order { 511 }
    end

    factory :jmaxml_region_c520 do
      name { "大阪府北部" }
      code { "520" }
      order { 520 }
    end

    factory :jmaxml_region_c521 do
      name { "大阪府南部" }
      code { "521" }
      order { 521 }
    end

    factory :jmaxml_region_c530 do
      name { "兵庫県北部" }
      code { "530" }
      order { 530 }
    end

    factory :jmaxml_region_c531 do
      name { "兵庫県南東部" }
      code { "531" }
      order { 531 }
    end

    factory :jmaxml_region_c532 do
      name { "兵庫県南西部" }
      code { "532" }
      order { 532 }
    end

    factory :jmaxml_region_c535 do
      name { "兵庫県淡路島" }
      code { "535" }
      order { 535 }
    end

    factory :jmaxml_region_c540 do
      name { "奈良県" }
      code { "540" }
      order { 540 }
    end

    factory :jmaxml_region_c550 do
      name { "和歌山県北部" }
      code { "550" }
      order { 550 }
    end

    factory :jmaxml_region_c551 do
      name { "和歌山県南部" }
      code { "551" }
      order { 551 }
    end

    factory :jmaxml_region_c580 do
      name { "岡山県北部" }
      code { "580" }
      order { 580 }
    end

    factory :jmaxml_region_c581 do
      name { "岡山県南部" }
      code { "581" }
      order { 581 }
    end

    factory :jmaxml_region_c590 do
      name { "広島県北部" }
      code { "590" }
      order { 590 }
    end

    factory :jmaxml_region_c591 do
      name { "広島県南東部" }
      code { "591" }
      order { 591 }
    end

    factory :jmaxml_region_c592 do
      name { "広島県南西部" }
      code { "592" }
      order { 592 }
    end

    factory :jmaxml_region_c570 do
      name { "島根県東部" }
      code { "570" }
      order { 570 }
    end

    factory :jmaxml_region_c571 do
      name { "島根県西部" }
      code { "571" }
      order { 571 }
    end

    factory :jmaxml_region_c575 do
      name { "島根県隠岐" }
      code { "575" }
      order { 575 }
    end

    factory :jmaxml_region_c560 do
      name { "鳥取県東部" }
      code { "560" }
      order { 560 }
    end

    factory :jmaxml_region_c562 do
      name { "鳥取県中部" }
      code { "562" }
      order { 562 }
    end

    factory :jmaxml_region_c563 do
      name { "鳥取県西部" }
      code { "563" }
      order { 563 }
    end

    factory :jmaxml_region_c600 do
      name { "徳島県北部" }
      code { "600" }
      order { 600 }
    end

    factory :jmaxml_region_c601 do
      name { "徳島県南部" }
      code { "601" }
      order { 601 }
    end

    factory :jmaxml_region_c610 do
      name { "香川県東部" }
      code { "610" }
      order { 610 }
    end

    factory :jmaxml_region_c611 do
      name { "香川県西部" }
      code { "611" }
      order { 611 }
    end

    factory :jmaxml_region_c620 do
      name { "愛媛県東予" }
      code { "620" }
      order { 620 }
    end

    factory :jmaxml_region_c621 do
      name { "愛媛県中予" }
      code { "621" }
      order { 621 }
    end

    factory :jmaxml_region_c622 do
      name { "愛媛県南予" }
      code { "622" }
      order { 622 }
    end

    factory :jmaxml_region_c630 do
      name { "高知県東部" }
      code { "630" }
      order { 630 }
    end

    factory :jmaxml_region_c631 do
      name { "高知県中部" }
      code { "631" }
      order { 631 }
    end

    factory :jmaxml_region_c632 do
      name { "高知県西部" }
      code { "632" }
      order { 632 }
    end

    factory :jmaxml_region_c700 do
      name { "山口県北部" }
      code { "700" }
      order { 700 }
    end

    factory :jmaxml_region_c701 do
      name { "山口県東部" }
      code { "701" }
      order { 701 }
    end

    factory :jmaxml_region_c702 do
      name { "山口県西部" }
      code { "702" }
      order { 702 }
    end

    factory :jmaxml_region_c710 do
      name { "福岡県福岡" }
      code { "710" }
      order { 710 }
    end

    factory :jmaxml_region_c711 do
      name { "福岡県北九州" }
      code { "711" }
      order { 711 }
    end

    factory :jmaxml_region_c712 do
      name { "福岡県筑豊" }
      code { "712" }
      order { 712 }
    end

    factory :jmaxml_region_c713 do
      name { "福岡県筑後" }
      code { "713" }
      order { 713 }
    end

    factory :jmaxml_region_c750 do
      name { "大分県北部" }
      code { "750" }
      order { 750 }
    end

    factory :jmaxml_region_c751 do
      name { "大分県中部" }
      code { "751" }
      order { 751 }
    end

    factory :jmaxml_region_c752 do
      name { "大分県南部" }
      code { "752" }
      order { 752 }
    end

    factory :jmaxml_region_c753 do
      name { "大分県西部" }
      code { "753" }
      order { 753 }
    end

    factory :jmaxml_region_c730 do
      name { "長崎県北部" }
      code { "730" }
      order { 730 }
    end

    factory :jmaxml_region_c731 do
      name { "長崎県南西部" }
      code { "731" }
      order { 731 }
    end

    factory :jmaxml_region_c732 do
      name { "長崎県島原半島" }
      code { "732" }
      order { 732 }
    end

    factory :jmaxml_region_c735 do
      name { "長崎県対馬" }
      code { "735" }
      order { 735 }
    end

    factory :jmaxml_region_c736 do
      name { "長崎県壱岐" }
      code { "736" }
      order { 736 }
    end

    factory :jmaxml_region_c737 do
      name { "長崎県五島" }
      code { "737" }
      order { 737 }
    end

    factory :jmaxml_region_c720 do
      name { "佐賀県北部" }
      code { "720" }
      order { 720 }
    end

    factory :jmaxml_region_c721 do
      name { "佐賀県南部" }
      code { "721" }
      order { 721 }
    end

    factory :jmaxml_region_c740 do
      name { "熊本県阿蘇" }
      code { "740" }
      order { 740 }
    end

    factory :jmaxml_region_c741 do
      name { "熊本県熊本" }
      code { "741" }
      order { 741 }
    end

    factory :jmaxml_region_c742 do
      name { "熊本県球磨" }
      code { "742" }
      order { 742 }
    end

    factory :jmaxml_region_c743 do
      name { "熊本県天草・芦北" }
      code { "743" }
      order { 743 }
    end

    factory :jmaxml_region_c760 do
      name { "宮崎県北部平野部" }
      code { "760" }
      order { 760 }
    end

    factory :jmaxml_region_c761 do
      name { "宮崎県北部山沿い" }
      code { "761" }
      order { 761 }
    end

    factory :jmaxml_region_c762 do
      name { "宮崎県南部平野部" }
      code { "762" }
      order { 762 }
    end

    factory :jmaxml_region_c763 do
      name { "宮崎県南部山沿い" }
      code { "763" }
      order { 763 }
    end

    factory :jmaxml_region_c770 do
      name { "鹿児島県薩摩" }
      code { "770" }
      order { 770 }
    end

    factory :jmaxml_region_c771 do
      name { "鹿児島県大隅" }
      code { "771" }
      order { 771 }
    end

    factory :jmaxml_region_c774 do
      name { "鹿児島県十島村" }
      code { "774" }
      order { 774 }
    end

    factory :jmaxml_region_c775 do
      name { "鹿児島県甑島" }
      code { "775" }
      order { 775 }
    end

    factory :jmaxml_region_c776 do
      name { "鹿児島県種子島" }
      code { "776" }
      order { 776 }
    end

    factory :jmaxml_region_c777 do
      name { "鹿児島県屋久島" }
      code { "777" }
      order { 777 }
    end

    factory :jmaxml_region_c778 do
      name { "鹿児島県奄美北部" }
      code { "778" }
      order { 778 }
    end

    factory :jmaxml_region_c779 do
      name { "鹿児島県奄美南部" }
      code { "779" }
      order { 779 }
    end

    factory :jmaxml_region_c800 do
      name { "沖縄県本島北部" }
      code { "800" }
      order { 800 }
    end

    factory :jmaxml_region_c801 do
      name { "沖縄県本島中南部" }
      code { "801" }
      order { 801 }
    end

    factory :jmaxml_region_c802 do
      name { "沖縄県久米島" }
      code { "802" }
      order { 802 }
    end

    factory :jmaxml_region_c803 do
      name { "沖縄県大東島" }
      code { "803" }
      order { 803 }
    end

    factory :jmaxml_region_c804 do
      name { "沖縄県宮古島" }
      code { "804" }
      order { 804 }
    end

    factory :jmaxml_region_c805 do
      name { "沖縄県石垣島" }
      code { "805" }
      order { 805 }
    end

    factory :jmaxml_region_c806 do
      name { "沖縄県与那国島" }
      code { "806" }
      order { 806 }
    end

    factory :jmaxml_region_c807 do
      name { "沖縄県西表島" }
      code { "807" }
      order { 807 }
    end
  end
end
