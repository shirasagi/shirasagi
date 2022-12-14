class Gws::Affair::Enumerator::Capital::Users < Gws::Affair::Enumerator::Base
  def initialize(prefs, capitals, users, opts = {})
    @prefs = prefs
    @capitals = capitals
    @users = users

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
    @users.each do |user|
      terms << user.name
    end
    terms << I18n.t("gws/affair.labels.overtime.capitals.total")
    terms
  end

  def enum_capital(yielder, basic_code, name)
    line = []
    line << name

    total = 0
    @users.each do |user|
      minute = @prefs.dig(user.id, basic_code).to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)
    yielder << encode(line.to_csv)
  end

  def enum_total(yielder)
    line = []
    line << I18n.t("gws/affair.labels.overtime.capitals.total_capitals")

    total = 0
    @users.each do |user|
      minute = @prefs.dig(user.id, "total").to_i
      total += minute
      line << format_minute(minute)
    end
    line << format_minute(total)
    yielder << encode(line.to_csv)
  end
end
