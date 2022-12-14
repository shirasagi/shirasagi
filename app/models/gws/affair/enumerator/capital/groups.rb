class Gws::Affair::Enumerator::Capital::Groups < Gws::Affair::Enumerator::Base
  def initialize(prefs, capitals, groups, opts = {})
    @prefs = prefs
    @capitals = capitals
    @groups = groups

    @title = opts[:title]
    @encoding = opts[:encoding]
    @total = opts[:total].present?

    super() do |y|
      set_title_and_headers(y)
      @capitals.each do |basic_code, name|
        enum_capital(y, basic_code, name)
      end
      enum_total(y)
    end
  end

  def headers
    terms = []
    terms << I18n.t("gws/affair.labels.overtime.capitals.capital")
    @groups.each do |group|
      terms << group.trailing_name
    end
    terms << I18n.t("gws/affair.labels.overtime.capitals.total") if @total
    terms
  end

  def enum_capital(yielder, basic_code, name)
    line = []
    line << name

    total = 0
    @groups.each do |group|
      minute = @prefs.dig(group.group_id, basic_code).to_i
      minute += group.descendants.map { |g| @prefs.dig(g.group_id, basic_code).to_i }.sum

      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total) if @total
    yielder << encode(line.to_csv)
  end

  def enum_total(yielder)
    line = []
    line << I18n.t("gws/affair.labels.overtime.capitals.total_capitals")

    total = 0
    @groups.each do |group|
      minute = @prefs.dig(group.group_id, "total").to_i
      minute += group.descendants.map { |g| @prefs.dig(g.group_id, "total").to_i }.sum

      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total) if @total
    yielder << encode(line.to_csv)
  end
end
