FactoryGirl.define do
  factory :rss_weather_xml_region_base, class: Rss::WeatherXmlRegion do
    transient do
      site nil
    end

    cur_site { site ? site : cms_site }

    factory :rss_weather_xml_region_135 do
      name "宗谷支庁北部"
      code "135"
      order 135
    end

    factory :rss_weather_xml_region_136 do
      name "宗谷支庁南部"
      code "136"
      order 136
    end

    factory :rss_weather_xml_region_125 do
      name "上川支庁北部"
      code "125"
      order 125
    end

    factory :rss_weather_xml_region_126 do
      name "上川支庁中部"
      code "126"
      order 126
    end

    factory :rss_weather_xml_region_127 do
      name "上川支庁南部"
      code "127"
      order 127
    end

    factory :rss_weather_xml_region_130 do
      name "留萌支庁中北部"
      code "130"
      order 130
    end

    factory :rss_weather_xml_region_131 do
      name "留萌支庁南部"
      code "131"
      order 131
    end

    factory :rss_weather_xml_region_139 do
      name "北海道利尻礼文"
      code "139"
      order 139
    end

    factory :rss_weather_xml_region_150 do
      name "日高支庁西部"
      code "150"
      order 150
    end

    factory :rss_weather_xml_region_151 do
      name "日高支庁中部"
      code "151"
      order 151
    end

    factory :rss_weather_xml_region_152 do
      name "日高支庁東部"
      code "152"
      order 152
    end

    factory :rss_weather_xml_region_145 do
      name "胆振支庁西部"
      code "145"
      order 145
    end

    factory :rss_weather_xml_region_146 do
      name "胆振支庁中東部"
      code "146"
      order 146
    end

    factory :rss_weather_xml_region_110 do
      name "檜山支庁"
      code "110"
      order 110
    end

    factory :rss_weather_xml_region_105 do
      name "渡島支庁北部"
      code "105"
      order 105
    end

    factory :rss_weather_xml_region_106 do
      name "渡島支庁東部"
      code "106"
      order 106
    end

    factory :rss_weather_xml_region_107 do
      name "渡島支庁西部"
      code "107"
      order 107
    end

    factory :rss_weather_xml_region_140 do
      name "網走支庁網走"
      code "140"
      order 140
    end

    factory :rss_weather_xml_region_141 do
      name "網走支庁北見"
      code "141"
      order 141
    end

    factory :rss_weather_xml_region_142 do
      name "網走支庁紋別"
      code "142"
      order 142
    end

    factory :rss_weather_xml_region_165 do
      name "根室支庁北部"
      code "165"
      order 165
    end

    factory :rss_weather_xml_region_166 do
      name "根室支庁中部"
      code "166"
      order 166
    end

    factory :rss_weather_xml_region_167 do
      name "根室支庁南部"
      code "167"
      order 167
    end

    factory :rss_weather_xml_region_160 do
      name "釧路支庁北部"
      code "160"
      order 160
    end

    factory :rss_weather_xml_region_161 do
      name "釧路支庁中南部"
      code "161"
      order 161
    end

    factory :rss_weather_xml_region_155 do
      name "十勝支庁北部"
      code "155"
      order 155
    end

    factory :rss_weather_xml_region_156 do
      name "十勝支庁中部"
      code "156"
      order 156
    end

    factory :rss_weather_xml_region_157 do
      name "十勝支庁南部"
      code "157"
      order 157
    end

    factory :rss_weather_xml_region_119 do
      name "北海道奥尻島"
      code "119"
      order 119
    end

    factory :rss_weather_xml_region_120 do
      name "空知支庁北部"
      code "120"
      order 120
    end

    factory :rss_weather_xml_region_121 do
      name "空知支庁中部"
      code "121"
      order 121
    end

    factory :rss_weather_xml_region_122 do
      name "空知支庁南部"
      code "122"
      order 122
    end

    factory :rss_weather_xml_region_100 do
      name "石狩支庁北部"
      code "100"
      order 100
    end

    factory :rss_weather_xml_region_101 do
      name "石狩支庁中部"
      code "101"
      order 101
    end

    factory :rss_weather_xml_region_102 do
      name "石狩支庁南部"
      code "102"
      order 102
    end

    factory :rss_weather_xml_region_115 do
      name "後志支庁北部"
      code "115"
      order 115
    end

    factory :rss_weather_xml_region_116 do
      name "後志支庁東部"
      code "116"
      order 116
    end

    factory :rss_weather_xml_region_117 do
      name "後志支庁西部"
      code "117"
      order 117
    end

    factory :rss_weather_xml_region_200 do
      name "青森県津軽北部"
      code "200"
      order 200
    end

    factory :rss_weather_xml_region_201 do
      name "青森県津軽南部"
      code "201"
      order 201
    end

    factory :rss_weather_xml_region_202 do
      name "青森県三八上北"
      code "202"
      order 202
    end

    factory :rss_weather_xml_region_203 do
      name "青森県下北"
      code "203"
      order 203
    end

    factory :rss_weather_xml_region_230 do
      name "秋田県沿岸北部"
      code "230"
      order 230
    end

    factory :rss_weather_xml_region_231 do
      name "秋田県沿岸南部"
      code "231"
      order 231
    end

    factory :rss_weather_xml_region_232 do
      name "秋田県内陸北部"
      code "232"
      order 232
    end

    factory :rss_weather_xml_region_233 do
      name "秋田県内陸南部"
      code "233"
      order 233
    end

    factory :rss_weather_xml_region_210 do
      name "岩手県沿岸北部"
      code "210"
      order 210
    end

    factory :rss_weather_xml_region_211 do
      name "岩手県沿岸南部"
      code "211"
      order 211
    end

    factory :rss_weather_xml_region_212 do
      name "岩手県内陸北部"
      code "212"
      order 212
    end

    factory :rss_weather_xml_region_213 do
      name "岩手県内陸南部"
      code "213"
      order 213
    end

    factory :rss_weather_xml_region_220 do
      name "宮城県北部"
      code "220"
      order 220
    end

    factory :rss_weather_xml_region_221 do
      name "宮城県南部"
      code "221"
      order 221
    end

    factory :rss_weather_xml_region_222 do
      name "宮城県中部"
      code "222"
      order 222
    end

    factory :rss_weather_xml_region_240 do
      name "山形県庄内"
      code "240"
      order 240
    end

    factory :rss_weather_xml_region_241 do
      name "山形県最上"
      code "241"
      order 241
    end

    factory :rss_weather_xml_region_242 do
      name "山形県村山"
      code "242"
      order 242
    end

    factory :rss_weather_xml_region_243 do
      name "山形県置賜"
      code "243"
      order 243
    end

    factory :rss_weather_xml_region_250 do
      name "福島県中通り"
      code "250"
      order 250
    end

    factory :rss_weather_xml_region_251 do
      name "福島県浜通り"
      code "251"
      order 251
    end

    factory :rss_weather_xml_region_252 do
      name "福島県会津"
      code "252"
      order 252
    end

    factory :rss_weather_xml_region_300 do
      name "茨城県北部"
      code "300"
      order 300
    end

    factory :rss_weather_xml_region_301 do
      name "茨城県南部"
      code "301"
      order 301
    end

    factory :rss_weather_xml_region_310 do
      name "栃木県北部"
      code "310"
      order 310
    end

    factory :rss_weather_xml_region_311 do
      name "栃木県南部"
      code "311"
      order 311
    end

    factory :rss_weather_xml_region_320 do
      name "群馬県北部"
      code "320"
      order 320
    end

    factory :rss_weather_xml_region_321 do
      name "群馬県南部"
      code "321"
      order 321
    end

    factory :rss_weather_xml_region_330 do
      name "埼玉県北部"
      code "330"
      order 330
    end

    factory :rss_weather_xml_region_331 do
      name "埼玉県南部"
      code "331"
      order 331
    end

    factory :rss_weather_xml_region_332 do
      name "埼玉県秩父"
      code "332"
      order 332
    end

    factory :rss_weather_xml_region_350 do
      name "東京都23区"
      code "350"
      order 350
    end

    factory :rss_weather_xml_region_351 do
      name "東京都多摩東部"
      code "351"
      order 351
    end

    factory :rss_weather_xml_region_352 do
      name "東京都多摩西部"
      code "352"
      order 352
    end

    factory :rss_weather_xml_region_354 do
      name "神津島"
      code "354"
      order 354
    end

    factory :rss_weather_xml_region_355 do
      name "伊豆大島"
      code "355"
      order 355
    end

    factory :rss_weather_xml_region_356 do
      name "新島"
      code "356"
      order 356
    end

    factory :rss_weather_xml_region_357 do
      name "三宅島"
      code "357"
      order 357
    end

    factory :rss_weather_xml_region_358 do
      name "八丈島"
      code "358"
      order 358
    end

    factory :rss_weather_xml_region_359 do
      name "小笠原"
      code "359"
      order 359
    end

    factory :rss_weather_xml_region_340 do
      name "千葉県北東部"
      code "340"
      order 340
    end

    factory :rss_weather_xml_region_341 do
      name "千葉県北西部"
      code "341"
      order 341
    end

    factory :rss_weather_xml_region_342 do
      name "千葉県南部"
      code "342"
      order 342
    end

    factory :rss_weather_xml_region_360 do
      name "神奈川県東部"
      code "360"
      order 360
    end

    factory :rss_weather_xml_region_361 do
      name "神奈川県西部"
      code "361"
      order 361
    end

    factory :rss_weather_xml_region_420 do
      name "長野県北部"
      code "420"
      order 420
    end

    factory :rss_weather_xml_region_421 do
      name "長野県中部"
      code "421"
      order 421
    end

    factory :rss_weather_xml_region_422 do
      name "長野県南部"
      code "422"
      order 422
    end

    factory :rss_weather_xml_region_410 do
      name "山梨県東部"
      code "410"
      order 410
    end

    factory :rss_weather_xml_region_411 do
      name "山梨県中・西部"
      code "411"
      order 411
    end

    factory :rss_weather_xml_region_412 do
      name "山梨県東部・富士五湖"
      code "412"
      order 412
    end

    factory :rss_weather_xml_region_440 do
      name "静岡県伊豆"
      code "440"
      order 440
    end

    factory :rss_weather_xml_region_441 do
      name "静岡県東部"
      code "441"
      order 441
    end

    factory :rss_weather_xml_region_442 do
      name "静岡県中部"
      code "442"
      order 442
    end

    factory :rss_weather_xml_region_443 do
      name "静岡県西部"
      code "443"
      order 443
    end

    factory :rss_weather_xml_region_450 do
      name "愛知県東部"
      code "450"
      order 450
    end

    factory :rss_weather_xml_region_451 do
      name "愛知県西部"
      code "451"
      order 451
    end

    factory :rss_weather_xml_region_430 do
      name "岐阜県飛騨"
      code "430"
      order 430
    end

    factory :rss_weather_xml_region_431 do
      name "岐阜県美濃東部"
      code "431"
      order 431
    end

    factory :rss_weather_xml_region_432 do
      name "岐阜県美濃中西部"
      code "432"
      order 432
    end

    factory :rss_weather_xml_region_460 do
      name "三重県北部"
      code "460"
      order 460
    end

    factory :rss_weather_xml_region_461 do
      name "三重県中部"
      code "461"
      order 461
    end

    factory :rss_weather_xml_region_462 do
      name "三重県南部"
      code "462"
      order 462
    end

    factory :rss_weather_xml_region_370 do
      name "新潟県上越"
      code "370"
      order 370
    end

    factory :rss_weather_xml_region_371 do
      name "新潟県中越"
      code "371"
      order 371
    end

    factory :rss_weather_xml_region_372 do
      name "新潟県下越"
      code "372"
      order 372
    end

    factory :rss_weather_xml_region_375 do
      name "新潟県佐渡"
      code "375"
      order 375
    end

    factory :rss_weather_xml_region_380 do
      name "富山県東部"
      code "380"
      order 380
    end

    factory :rss_weather_xml_region_381 do
      name "富山県西部"
      code "381"
      order 381
    end

    factory :rss_weather_xml_region_390 do
      name "石川県能登"
      code "390"
      order 390
    end

    factory :rss_weather_xml_region_391 do
      name "石川県加賀"
      code "391"
      order 391
    end

    factory :rss_weather_xml_region_400 do
      name "福井県嶺北"
      code "400"
      order 400
    end

    factory :rss_weather_xml_region_401 do
      name "福井県嶺南"
      code "401"
      order 401
    end

    factory :rss_weather_xml_region_500 do
      name "滋賀県北部"
      code "500"
      order 500
    end

    factory :rss_weather_xml_region_501 do
      name "滋賀県南部"
      code "501"
      order 501
    end

    factory :rss_weather_xml_region_510 do
      name "京都府北部"
      code "510"
      order 510
    end

    factory :rss_weather_xml_region_511 do
      name "京都府南部"
      code "511"
      order 511
    end

    factory :rss_weather_xml_region_520 do
      name "大阪府北部"
      code "520"
      order 520
    end

    factory :rss_weather_xml_region_521 do
      name "大阪府南部"
      code "521"
      order 521
    end

    factory :rss_weather_xml_region_530 do
      name "兵庫県北部"
      code "530"
      order 530
    end

    factory :rss_weather_xml_region_531 do
      name "兵庫県南東部"
      code "531"
      order 531
    end

    factory :rss_weather_xml_region_532 do
      name "兵庫県南西部"
      code "532"
      order 532
    end

    factory :rss_weather_xml_region_535 do
      name "兵庫県淡路島"
      code "535"
      order 535
    end

    factory :rss_weather_xml_region_540 do
      name "奈良県"
      code "540"
      order 540
    end

    factory :rss_weather_xml_region_550 do
      name "和歌山県北部"
      code "550"
      order 550
    end

    factory :rss_weather_xml_region_551 do
      name "和歌山県南部"
      code "551"
      order 551
    end

    factory :rss_weather_xml_region_580 do
      name "岡山県北部"
      code "580"
      order 580
    end

    factory :rss_weather_xml_region_581 do
      name "岡山県南部"
      code "581"
      order 581
    end

    factory :rss_weather_xml_region_590 do
      name "広島県北部"
      code "590"
      order 590
    end

    factory :rss_weather_xml_region_591 do
      name "広島県南東部"
      code "591"
      order 591
    end

    factory :rss_weather_xml_region_592 do
      name "広島県南西部"
      code "592"
      order 592
    end

    factory :rss_weather_xml_region_570 do
      name "島根県東部"
      code "570"
      order 570
    end

    factory :rss_weather_xml_region_571 do
      name "島根県西部"
      code "571"
      order 571
    end

    factory :rss_weather_xml_region_575 do
      name "島根県隠岐"
      code "575"
      order 575
    end

    factory :rss_weather_xml_region_560 do
      name "鳥取県東部"
      code "560"
      order 560
    end

    factory :rss_weather_xml_region_562 do
      name "鳥取県中部"
      code "562"
      order 562
    end

    factory :rss_weather_xml_region_563 do
      name "鳥取県西部"
      code "563"
      order 563
    end

    factory :rss_weather_xml_region_600 do
      name "徳島県北部"
      code "600"
      order 600
    end

    factory :rss_weather_xml_region_601 do
      name "徳島県南部"
      code "601"
      order 601
    end

    factory :rss_weather_xml_region_610 do
      name "香川県東部"
      code "610"
      order 610
    end

    factory :rss_weather_xml_region_611 do
      name "香川県西部"
      code "611"
      order 611
    end

    factory :rss_weather_xml_region_620 do
      name "愛媛県東予"
      code "620"
      order 620
    end

    factory :rss_weather_xml_region_621 do
      name "愛媛県中予"
      code "621"
      order 621
    end

    factory :rss_weather_xml_region_622 do
      name "愛媛県南予"
      code "622"
      order 622
    end

    factory :rss_weather_xml_region_630 do
      name "高知県東部"
      code "630"
      order 630
    end

    factory :rss_weather_xml_region_631 do
      name "高知県中部"
      code "631"
      order 631
    end

    factory :rss_weather_xml_region_632 do
      name "高知県西部"
      code "632"
      order 632
    end

    factory :rss_weather_xml_region_700 do
      name "山口県北部"
      code "700"
      order 700
    end

    factory :rss_weather_xml_region_701 do
      name "山口県東部"
      code "701"
      order 701
    end

    factory :rss_weather_xml_region_702 do
      name "山口県西部"
      code "702"
      order 702
    end

    factory :rss_weather_xml_region_710 do
      name "福岡県福岡"
      code "710"
      order 710
    end

    factory :rss_weather_xml_region_711 do
      name "福岡県北九州"
      code "711"
      order 711
    end

    factory :rss_weather_xml_region_712 do
      name "福岡県筑豊"
      code "712"
      order 712
    end

    factory :rss_weather_xml_region_713 do
      name "福岡県筑後"
      code "713"
      order 713
    end

    factory :rss_weather_xml_region_750 do
      name "大分県北部"
      code "750"
      order 750
    end

    factory :rss_weather_xml_region_751 do
      name "大分県中部"
      code "751"
      order 751
    end

    factory :rss_weather_xml_region_752 do
      name "大分県南部"
      code "752"
      order 752
    end

    factory :rss_weather_xml_region_753 do
      name "大分県西部"
      code "753"
      order 753
    end

    factory :rss_weather_xml_region_730 do
      name "長崎県北部"
      code "730"
      order 730
    end

    factory :rss_weather_xml_region_731 do
      name "長崎県南西部"
      code "731"
      order 731
    end

    factory :rss_weather_xml_region_732 do
      name "長崎県島原半島"
      code "732"
      order 732
    end

    factory :rss_weather_xml_region_735 do
      name "長崎県対馬"
      code "735"
      order 735
    end

    factory :rss_weather_xml_region_736 do
      name "長崎県壱岐"
      code "736"
      order 736
    end

    factory :rss_weather_xml_region_737 do
      name "長崎県五島"
      code "737"
      order 737
    end

    factory :rss_weather_xml_region_720 do
      name "佐賀県北部"
      code "720"
      order 720
    end

    factory :rss_weather_xml_region_721 do
      name "佐賀県南部"
      code "721"
      order 721
    end

    factory :rss_weather_xml_region_740 do
      name "熊本県阿蘇"
      code "740"
      order 740
    end

    factory :rss_weather_xml_region_741 do
      name "熊本県熊本"
      code "741"
      order 741
    end

    factory :rss_weather_xml_region_742 do
      name "熊本県球磨"
      code "742"
      order 742
    end

    factory :rss_weather_xml_region_743 do
      name "熊本県天草・芦北"
      code "743"
      order 743
    end

    factory :rss_weather_xml_region_760 do
      name "宮崎県北部平野部"
      code "760"
      order 760
    end

    factory :rss_weather_xml_region_761 do
      name "宮崎県北部山沿い"
      code "761"
      order 761
    end

    factory :rss_weather_xml_region_762 do
      name "宮崎県南部平野部"
      code "762"
      order 762
    end

    factory :rss_weather_xml_region_763 do
      name "宮崎県南部山沿い"
      code "763"
      order 763
    end

    factory :rss_weather_xml_region_770 do
      name "鹿児島県薩摩"
      code "770"
      order 770
    end

    factory :rss_weather_xml_region_771 do
      name "鹿児島県大隅"
      code "771"
      order 771
    end

    factory :rss_weather_xml_region_774 do
      name "鹿児島県十島村"
      code "774"
      order 774
    end

    factory :rss_weather_xml_region_775 do
      name "鹿児島県甑島"
      code "775"
      order 775
    end

    factory :rss_weather_xml_region_776 do
      name "鹿児島県種子島"
      code "776"
      order 776
    end

    factory :rss_weather_xml_region_777 do
      name "鹿児島県屋久島"
      code "777"
      order 777
    end

    factory :rss_weather_xml_region_778 do
      name "鹿児島県奄美北部"
      code "778"
      order 778
    end

    factory :rss_weather_xml_region_779 do
      name "鹿児島県奄美南部"
      code "779"
      order 779
    end

    factory :rss_weather_xml_region_800 do
      name "沖縄県本島北部"
      code "800"
      order 800
    end

    factory :rss_weather_xml_region_801 do
      name "沖縄県本島中南部"
      code "801"
      order 801
    end

    factory :rss_weather_xml_region_802 do
      name "沖縄県久米島"
      code "802"
      order 802
    end

    factory :rss_weather_xml_region_803 do
      name "沖縄県大東島"
      code "803"
      order 803
    end

    factory :rss_weather_xml_region_804 do
      name "沖縄県宮古島"
      code "804"
      order 804
    end

    factory :rss_weather_xml_region_805 do
      name "沖縄県石垣島"
      code "805"
      order 805
    end

    factory :rss_weather_xml_region_806 do
      name "沖縄県与那国島"
      code "806"
      order 806
    end

    factory :rss_weather_xml_region_807 do
      name "沖縄県西表島"
      code "807"
      order 807
    end
  end
end
