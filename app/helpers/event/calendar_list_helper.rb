module Event::CalendarListHelper
  include Cms::ListHelper

  def default_table_day_loop_liquid
    <<~HTML
      <div class="date">
        <div class="daily">
          {% if active? and events.size > 0 %}
            <a href="{{ daily_url }}">{{ day }}</a>
          {% else %}
            {{ day }}
          {% endif %}
        </div>
        {% if holiday? %}
          <div class="holiday">{{ holiday_name }}</div>
        {% endif %}
        {% if events.size == 0 %}
          <div class="no-event">{{ substitute_html }}</div>
        {% endif %}
        {% for event in events %}
          <div class="page {{ event.multiple_or_single_days }}" data-id="{{ event.data_id }}" data-start-date="{{ event.data_start_date }}" data-end-date="{{ event.data_end_date }}">
            {% if event.category %}
              <div class="data {{ event.category.basename }}">
                <a href="{{ event.category.url }}">{{ event.category.name }}</a>
              </div>
            {% endif %}
            <div class="event">
              <a href="{{ event.url }}">{{ event.name }}</a>
            </div>
          </div>
        {% endfor %}
      </div>
    HTML
  end

  def default_list_day_loop_liquid
    <<~HTML
      <dl class="{{ dl_class }}">
        <dt>
          <time datetime="{{ date | ss_date: "iso" }}">
            {% if active? and events.size > 0 %}
              <a href="{{ daily_url }}">{{ date_label }}</a>
            {% else %}
              {{ date_label }}
            {% endif %}
            <span class="wday">
              (<abbr title="{{ wday_label }}曜日">{{ wday_label }}</abbr><span class="unit">曜日</span>)
            </span>
          </time>
        </dt>
        {% if holiday? %}
          <dd class="holiday">{{ holiday_name }}</dd>
        {% endif %}
        {% if events.size == 0 %}
          <dd class="no-event">{{ substitute_html }}</dd>
        {% endif %}
        {% for event in events %}
          <dd class="page {{ event.multiple_or_single_days }}" data-id="{{ event.data_id }}" data-start-date="{{ event.data_start_date }}" data-end-date="{{ event.data_end_date }}">
            <article class="{% if event.page.new? %}new{% endif %}">
              {% if event.category %}
                <div class="data {{ event.category.basename }}">
                  <a href="{{ event.category.url }}">{{ event.category.name }}</a>
                </div>
              {% endif %}
              <header>
                <h2> <a href="{{ event.url }}">{{ event.name }}</a></h2>
              </header>
            </article>
          </dd>
        {% endfor %}
      </dl>
    HTML
  end

  def example_table_day_loop_liquid
    default_table_day_loop_liquid
  end

  def example_list_day_loop_liquid
    default_list_day_loop_liquid
  end

  def render_table_day_events(date, cell)
    source = @cur_node.table_day_loop_liquid || default_table_day_loop_liquid
    assigns = cell.assigns
    assigns.merge!({
      "date_label" => "#{date.month}#{t_date('month')}#{date.day}#{t_date('day')}",
      "wday_label" => t_wday(date),
      "dl_class" => event_dl_class(date)
    })
    render_list_with_liquid(source, assigns)
  end

  def render_list_day_events(date, cell)
    source = @cur_node.list_day_loop_liquid || default_list_day_loop_liquid
    assigns = cell.assigns
    assigns.merge!({
      "date_label" => "#{date.month}#{t_date('month')}#{date.day}#{t_date('day')}",
      "wday_label" => t_wday(date),
      "dl_class" => event_dl_class(date)
    })
    render_list_with_liquid(source, assigns)
  end
end
