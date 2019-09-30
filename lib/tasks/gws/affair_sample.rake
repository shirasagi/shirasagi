namespace :affair do
  task create_sample: :environment do
    puts "Please input site_id: site=[site_id]" or exit if ENV['site'].blank?
    puts "Please input user_id name: user=[user_id]" or exit if ENV['user'].blank?

    @site = Gws::Group.find(ENV['site'])
    @user = Gws::User.find(ENV['user'])

    current = Time.zone.now.to_datetime
    end_of_month = current.end_of_month.day

    @start_day = (ENV['start_day'] || 1).to_i
    @end_day = (ENV['end_day'] || end_of_month).to_i

    @capital_ids = Gws::Affair::Capital.site(@site).allow(:read, @user, site: @site).pluck(:id)
    @compensatory_minutes =[[465, 0], [0, 465]]

    @time_card = Gws::Attendance::TimeCard.site(@site).user(@user).find_by(date: current.change(day: 1, hour: 0, min: 0, sec: 0))
    @time_card.records.destroy_all

    duty_calendar = @user.effective_duty_calendar(@site)
    duty_hour = duty_calendar.default_duty_hour

    duty_start_hour = duty_hour.affair_start(current).hour
    duty_end_hour = duty_hour.affair_end(current).hour

    overtime_total = 0
    aggregated_minute = 0

    (@start_day..@end_day).each do |day|
      date = current.change(day: day, hour: 0, min: 0, sec: 0)

      if duty_calendar.leave_day?(date)
        overtime_hour = (duty_end_hour - duty_start_hour) + rand(2..8)
        break_time_minute = 45

        item = Gws::Affair::OvertimeFile.new
        item.cur_site = @site
        item.cur_user = @user
        item.name = "[休祝日] 参院選事務 #{date.strftime("%Y/%m/%d")}"
        item.overtime_name = "参院選事務"
        item.date = date
        item.start_at = date.change(hour: duty_start_hour, min: 0, sec: 0)
        item.end_at = item.start_at.advance(hours: overtime_hour)
        item.capital_id = @capital_ids.sample
        item.remark = "備考です。"
        item.week_in_compensatory_minute, item.week_out_compensatory_minute = @compensatory_minutes.sample

        # workflow
        item.state = "approve"
        item.workflow_user_id = @user.id
        item.workflow_state = "approve"
        item.workflow_current_circulation_level = 0
        item.workflow_approvers = [
          { "level" =>1, "user_id" =>1, "editable" => "", "state" => "approve", "comment" => "承認しました。", "file_ids" => nil }
        ]
        item.workflow_required_counts = [false]
        item.approved = Time.zone.now

        # groups
        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]
        item.save!

        # result
        item.in_results = {
          item.id => {
            "start_at_date" => item.start_at.strftime("%Y/%m/%d"),
            "start_at_hour" => item.start_at.hour,
            "start_at_minute" => item.start_at.minute,
            "end_at_date" => item.end_at.strftime("%Y/%m/%d"),
            "end_at_hour" => item.end_at.hour,
            "end_at_minute" => item.end_at.minute,
            "break_time_minute" => break_time_minute
          }
        }
        item.save_results

        # time_card
        record = @time_card.records.where(date: date).first
        record ||= @time_card.records.create(date: date)
        record.set(enter: duty_hour.affair_start(date))
        record.set(leave: item.end_at)

        overtime_total += overtime_hour
        aggregated_minute += overtime_hour * 60
        aggregated_minute -= item.week_in_compensatory_minute
        aggregated_minute -= break_time_minute

        puts "[休祝日] #{date.strftime("%Y/%m/%d")} 時間外：#{overtime_hour}"
      else
        overtime_hour = rand(1..4)
        overtime_total += overtime_hour
        break_time_minute = 0

        item = Gws::Affair::OvertimeFile.new
        item.cur_site = @site
        item.cur_user = @user
        item.name = "[勤務日] 参院選事務 #{date.strftime("%Y/%m/%d")}"
        item.overtime_name = "参院選事務"
        item.date = date
        item.start_at = date.change(hour: duty_end_hour, min: 0, sec: 0)
        item.end_at = item.start_at.advance(hours: overtime_hour)
        item.capital_id = @capital_ids.sample
        item.remark = "備考です。"

        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]

        # workflow
        item.state = "approve"
        item.workflow_user_id = @user.id
        item.workflow_state = "approve"
        item.workflow_current_circulation_level = 0
        item.workflow_approvers = [
          { "level" =>1, "user_id" =>1, "editable" => "", "state" => "approve", "comment" => "承認しました。", "file_ids" => nil }
        ]
        item.workflow_required_counts = [false]
        item.approved = Time.zone.now

        # groups
        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]
        item.save!

        # result
        item.in_results = {
          item.id => {
            "start_at_date" => item.start_at.strftime("%Y/%m/%d"),
            "start_at_hour" => item.start_at.hour,
            "start_at_minute" => item.start_at.minute,
            "end_at_date" => item.end_at.strftime("%Y/%m/%d"),
            "end_at_hour" => item.end_at.hour,
            "end_at_minute" => item.end_at.minute,
            "break_time_minute" => break_time_minute
          }
        }
        item.save_results

        # time_card
        record = @time_card.records.where(date: date).first
        record ||= @time_card.records.create(date: date)
        record.set(enter: duty_hour.affair_start(date))
        record.set(leave: item.end_at)

        overtime_total += overtime_hour
        aggregated_minute += overtime_hour * 60
        aggregated_minute -= item.week_in_compensatory_minute
        aggregated_minute -= break_time_minute

        puts "[勤務日] #{date.strftime("%Y/%m/%d")} 時間外：#{overtime_hour}"
      end
    end

    puts "計 #{overtime_total}h (#{aggregated_minute.to_f / 60}h)"
  end

  task set_staff_address_uid: :environment do
    uids = [
        [517801,551],
        [691526,509],
        [1698605,675],
        [763195,761],
        [1769987,721],
        [1698974,678],
        [1618016,650],
        [1866729,803],
        [1572288,631],
        [1769928,733],
        [1802194,755],
        [205087,566],
        [622257,664],
        [476790,728],
        [1019430,541],
        [1835203,786],
        [270849,783],
        [1574698,730],
        [1866737,805],
        [1572148,624],
        [919331,557],
        [213527,515],
        [1899643,830],
        [365521,491],
        [1229400,602],
        [448842,635],
        [1835181,785],
        [1734768,702],
        [1014420,539],
        [490741,553],
        [1866710,802],
        [1606824,643],
        [4651,505],
        [1094297,550],
        [1015435,534],
        [404012,486],
        [79332,535],
        [1007491,514],
        [471925,480],
        [469173,487],
        [1007483,499],
        [1835130,778],
        [163775,788],
        [1537792,610],
        [1734741,708],
        [63053,548],
        [666327,710],
        [1898914,823],
        [1698613,686],
        [1258532,573],
        [1145169,561],
        [1007394,384],
        [1080423,793],
        [248312,713],
        [1007432,403],
        [43141,562],
        [1773089,765],
        [672157,712],
        [1007459,463],
        [678180,738],
        [1867121,813],
        [1111086,809],
        [570648,612],
        [6000583,666],
        [853810,707],
        [251810,568],
        [502847,607],
        [1146114,583],
        [168955,524],
        [1019449,542],
        [670502,504],
        [834807,530],
        [1819917,766],
        [847526,656],
        [1331833,592],
        [1835114,787],
        [1769910,732],
        [1105485,556],
        [1769979,737],
        [1698559,690],
        [1105477,555],
        [166278,438],
        [905186,485],
        [86797,512],
        [726940,522],
        [500089,735],
        [410241,810],
        [797774,532],
        [7358,437],
        [635251,506],
        [113433,385],
        [109517,412],
        [1819950,771],
        [1769952,734],
        [1540254,770],
        [1001531,426],
        [838144,521],
        [1503081,601],
        [307939,446],
        [1802127,747],
        [732711,701],
        [1136143,776],
        [562611,488],
        [50903,460],
        [1001590,472],
        [1767429,724],
        [531634,615],
        [1537822,614],
        [282367,597],
        [1000977,519],
        [784559,276],
        [1637410,657],
        [1802224,759],
        [1572245,629],
        [31348,493],
        [1898973,829],
        [1898841,815],
        [682101,774],
        [1698575,685],
        [1258540,574],
        [28894,469],
        [1898957,827],
        [1842773,796],
        [1734725,711],
        [1842803,798],
        [1785397,799],
        [1842790,797],
        [1537806,611],
        [1698591,692],
        [1570854,630],
        [1835122,773],
        [1802151,751],
        [1698621,687],
        [1802143,750],
        [1734709,709],
        [594679,586],
        [1898850,816],
        [593371,655],
        [714909,749],
        [1866753,807],
        [1289012,578],
        [520357,638],
        [162167,461],
        [1282352,580],
        [1698583,677],
        [1255142,575],
        [32018,545],
        [122271,605],
        [1001353,415],
        [697761,636],
        [1637398,652],
        [1866761,808],
        [494950,653],
        [1734750,697],
        [468533,633],
        [1734733,698],
        [41904,492],
        [1898876,818],
        [165522,387],
        [646261,503],
        [1001230,502],
        [851663,510],
        [1183818,565],
        [1802178,753],
        [807711,723],
        [1604805,719],
        [1503073,599],
        [897141,777],
        [757179,628],
        [495573,579],
        [1001078,473],
        [1731858,703],
        [1666541,667],
        [1734687,699],
        [329797,613],
        [1000942,497],
        [1222422,570],
        [1769839,718],
        [1734695,705],
        [1666533,665],
        [1898892,821],
        [1312405,695],
        [1001167,531],
        [1105493,554],
        [1606794,642],
        [1322230,683],
        [1898868,817],
        [1802186,754],
        [1666517,661],
        [1543431,775],
        [1734679,706],
        [1063243,547],
        [1145142,559],
        [1606778,632],
        [1698966,679],
        [1057952,546],
        [159361,538],
        [79944,423],
        [1001647,517],
        [1225740,763],
        [1699032,684],
        [1898930,825],
        [1769901,731],
        [551694,645],
        [1698982,681],
        [765376,806],
        [754463,746],
        [160059,484],
        [1001418,494],
        [1758861,782],
        [1898884,820],
        [1769863,727],
        [1001434,533],
        [46965,552],
        [632945,676],
        [1802208,757],
        [1331795,588],
        [1898329,819],
        [1255169,572],
        [1735527,704],
        [635243,404],
        [258725,567],
        [1898949,826],
        [1770144,741],
        [203777,498],
        [1666592,670],
        [1819941,769],
        [1637401,654],
        [1842811,800],
        [19283,389],
        [1769960,736],
        [1572261,623],
        [1829211,804],
        [1001663,458],
        [1835157,784],
        [1835165,780],
        [1701401,772],
        [351407,356],
        [74772,558],
        [1572253,622],
        [1769898,729],
        [49697,495],
        [1239520,745],
        [680541,696],
        [466620,639],
        [1835149,779],
        [1898906,822],
        [1000934,451],
        [1898922,824],
        [32069,232],
        [1835190,789],
        [1537784,609],
        [1666584,669],
        [5959,540],
        [1001108,520],
        [278289,571],
        [1769995,722],
        [1184709,616],
        [1698990,689],
        [408549,459],
        [1255150,576],
        [1819925,767],
        [1898965,828],
        [1771230,760],
        [227161,577],
        [464864,625],
        [1802160,752],
        [1867180,812],
        [1841874,811],
        [1835173,781],
        [1835211,790],
        [1331108,587],
        [1331787,585],
        [1802216,758],
        [926582,814],
        [1637380,649],
        [1835220,792],
        [1666525,662],
        [1801058,756],
        [153621,791],
        [1666550,668],
        [1001450,278],
        [1698567,688],
        [1001116,500],
        [816736,525],
        [1665812,663],
        [112941,455],
      ].to_h

      puts "正規職員"

      uids.each do |staff_address_uid, uid|
        staff_address_uid = staff_address_uid.to_s
        uid = uid.to_s

        user = Gws::User.unscoped.where(staff_category: "正規職員").where(uid: uid.to_s).first

        if user.nil?
          puts "#{uid}: not found!"
        else
          #puts "#{uid}:#{user.name}"
          user.set(staff_address_uid: staff_address_uid)
        end
      end

      uids = [
        524069,
        1838075,
        1290568,
        1615912,
        1724410,
        73423,
        130001,
        160415,
        160962,
        221767,
        296651,
        315184,
        466239,
        565377,
        575089,
        627232,
        672785,
        771970,
        844233,
        864838,
        875724,
        893595,
        1008102,
        1052462,
        1093428,
        1135910,
        1161369,
        1182340,
        1227130,
        1242598,
        1245015,
        1546953,
        1556452,
        1578502,
        1617672,
        1720791,
        1861344,
        1868209,
        1900714,
        480827,
        1803972,
        1837443,
        1804308,
        1804316,
        1869841,
        1888536,
        13978,
        1868160,
        1825461,
        1001272,
        1867830,
        1657305,
        134236,
        138584,
        73806,
        1803220,
        1867849,
        749583,
        1080032,
        87068,
        89770,
        1328093,
        1665251,
        497673,
        1874128,
        1277022,
        1668781,
        1846442,
        702382,
        716006,
        1837494,
        1553275,
        1581228,
        1678922,
        1837990,
        1853775,
        1770276,
        691607,
        1900315,
        506273,
        809713,
        643599,
        836001,
        1609661,
        1730169,
        931306,
        711420,
        909165,
        968781,
        1557084,
        1667173,
        1703897,
        1868365,
        1885936,
        1559370,
        1829777,
        1230174,
        16934,
        1843222,
        1910450,
        1824872,
        1069918,
        1675257,
        1900323,
        1311115,
        1620851,
        1741535,
        1595660,
        1829106,
        13242,
        698628,
        1082876,
        1693271,
        1875442,
        565351,
        728993,
        739511,
        1025368,
        1075063,
        1231499,
        1571915,
        1592165,
        1900331,
        1868322,
        1900358,
        1013750,
        1837397,
        1868403,
        1900340,
        826952,
        1285483,
        1630709,
        1837478,
        460826,
        1805584,
        1610511,
        1732374,
        1736213,
        1770209,
        1610333,
        454770,
        801542,
        1690558,
        946711,
        1746537,
        740420,
        1770195,
        220663,
        279714,
        608891,
        841471,
        1094459,
        1108514,
        1294423,
        1911651,
        86614,
        779695,
        874248,
        1076884,
        1171232,
        1538403,
        1733753,
        1764667,
        1818546,
        112976,
        188549,
        1022202,
        1083694,
        1299484,
        1739123,
        1913484,
        345202,
        623164,
        632538,
        1067494,
        1084917,
        1190954,
        1228188,
        1547305,
        1588443,
        1805835,
        1838563,
        69868,
        1837524,
        1900730,
        94102,
        96172,
        524638,
        799599,
        1243578,
        1274236,
        1839810,
        1847775,
        8374082,
        487881,
        778524,
        1150782,
        1282590,
        1747150,
        1771485,
        1900366,
        1912364,
        937282,
        94081,
        682039,
        1013289,
        1522221,
        1609530,
        1809504,
        1913476,
        1023527,
        1327143,
        1640283,
        1806343,
        1825607,
        1913492,
        715964,
        1079867,
        1540645,
        1738690,
        1838547,
        1900382,
        682853,
        691402,
        769215,
        750581,
        880621,
        1312200,
        1599437,
        1623478,
        1739085,
        1834355,
        1904965,
        1904655,
        1033166,
        1265504,
        1786350,
        550248,
        1009761,
        1172026,
        515191,
        1248103,
        1612220,
        1720015,
        784826,
        1706691,
        1236350,
        1900374,
        1009001,
        1857614,
        1701428,
        1771795,
        691348,
        1913395,
        1868349,
        1867555,
        1900528,
        547832,
        883387,
        1804120,
        1225685,
        138550,
        1337742,
        1058568,
        46931,
        1913107,
        609200,
        796387,
        1012673,
    ]

    puts ""
    puts "会計年度任用職員"

    uids.each do |staff_address_uid|
      staff_address_uid = staff_address_uid.to_s

      user = Gws::User.unscoped.where(staff_category: "会計年度任用職員").where(uid: staff_address_uid).first

      if user.nil?
        puts "#{staff_address_uid}: not found!"
      else
        #puts "#{staff_address_uid}:#{user.name}"
        user.set(staff_address_uid: staff_address_uid)
      end
    end
  end

  task staff_address_unknown_users: :environment do
    Gws::User.unscoped.where({ :staff_address_uid.exists => false }).each do |user|
      puts "#{user.uid}:#{user.name}"
    end
  end

  task reset_capital_members: :environment do
    Gws::Affair::Capital.each do |capital|
      capital.member_ids = []
      capital.member_group_ids = []
      capital.update
    end
  end

  task set_soumu_capital_members: :environment do
    puts "総務ユーザーに原資区分を設定"
    item = Gws::Affair::Capital.where(project_code: 693, detail_code: 78).first

    group = Gws::Group.where(name: "那珂川市/市長・副市長/総務部").first
    groups = [group] + group.descendants.to_a
    group_ids = groups.map(&:id)

    site = Gws::Group.find(1)
    member_ids = []
    Gws::User.each do |user|
      if group_ids.include?(user.gws_main_group(site).id)
        puts user.name
        member_ids << user.id
      end
    end

    item.member_ids = member_ids
    item.update
  end

  task set_capital_members: :environment do
    puts "#正規職員"
    path = "#{Rails.root}/lib/tasks/gws/affair/capitals/regular.csv"

    table = CSV.read(path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      staff_address_uid = row["宛名番号"]
      project_code = row["事業コード"]
      detail_code = row["明細"]

      user = Gws::User.unscoped.where(staff_category: "正規職員").where(staff_address_uid: staff_address_uid).first

      if user.nil?
        puts "user not found (#{staff_address_uid})"
        next
      end

      capital = Gws::Affair::Capital.where(project_code: project_code, detail_code: detail_code).first

      if capital.nil?
        puts "capital not found (#{project_code}, #{detail_code})"
        next
      end

      capital.member_ids = (capital.member_ids.to_a + [user.id]).uniq
      capital.update
    end
    puts ""

    puts "#会計年度任用職員"
    path = "#{Rails.root}/lib/tasks/gws/affair/capitals/part_time.csv"

    table = CSV.read(path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      staff_address_uid = row["宛名番号"]
      project_code = row["時間外事業"]
      detail_code = row["時間外明細"]

      next if project_code == "#N/A" || detail_code == "#N/A"
      detail_code.sub!(/000$/, "")

      user = Gws::User.unscoped.where(staff_category: "会計年度任用職員").where(staff_address_uid: staff_address_uid).first

      if user.nil?
        puts "user not found (#{staff_address_uid})"
        next
      end

      capital = Gws::Affair::Capital.where(project_code: project_code, detail_code: detail_code).first

      if capital.nil?
        puts "capital not found (#{project_code}, #{detail_code})"
        next
      end

      capital.member_ids = (capital.member_ids.to_a + [user.id]).uniq
      capital.update
    end
  end

  #task capital_unknown_users: :environment do
  #  Gws::User.unscoped.where({ :staff_address_uid.exists => false }).each do |user|
  #    puts "#{user.uid}:#{user.name}"
  #  end
  #end
end
