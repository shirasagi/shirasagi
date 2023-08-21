module Cms::PublicFilter::ConditionalTag
  extend ActiveSupport::Concern

  def render_conditional_tag(html)
    html.gsub!(conditional_tag_template) do
      interpret_conditional_tag(Regexp.last_match)
    end
    html
  end

  private

  def conditional_tag_template(cond = 'if')
    template = [
      '(?<template>\#\{ ?',
      cond,
      " (?<cond>[^(]*)\\('?\\/?(?<path>[^')]*)'?\\) ?\\}",
      "(?<data>.*?(\\#\\{ ?else?if.*?|\\#\\{ ?else ?\\}.*?)*)\\#\\{ ?end(|if)? ?\\})"
    ].join
    ::Regexp.compile(template, Regexp::MULTILINE)
  end

  def interpret_conditional_tag(matchdata)
    interpret_condition_if(matchdata).presence || interpret_condition_elsif(matchdata).presence || interpret_condition_else(matchdata)
  end

  def conditional_tag_data(cond = 'if')
    template = [
      '\#\{ ?',
      cond,
      " (?<cond>[^(]*)\\('?\\/?(?<path>[^')]*)'?\\) ?\\}",
      "(?<data>.*?)(\\#\\{ ?else?if[^}]*\\}|\\#\\{ ?else ?\\})"
    ].join
    ::Regexp.compile(template, Regexp::MULTILINE)
  end

  def interpret_condition_if(matchdata)
    data = (conditional_tag_data.match(matchdata[:template]).presence || matchdata)[:data]
    conditional_tag_handler(matchdata, data)
  end

  def interpret_condition_elsif(parent_matchdata)
    return false if parent_matchdata.blank?
    matchdata = conditional_tag_template('else?if').match(parent_matchdata[:template])
    return false if matchdata.blank?
    data = (conditional_tag_data('else?if').match(matchdata[:template]).presence || matchdata)[:data]
    return @data if conditional_tag_handler(matchdata, data)
    template = conditional_tag_template('else?if').match("#{matchdata[:data]}\#\{end\}")
    interpret_condition_elsif(template).presence || false
  end

  def interpret_condition_else(matchdata)
    @data = /\#\{ ?else ?\}(?<data>.*?)\#\{ ?end(|if)? ?\}/m.match(matchdata[:template]).try(:[], :data).to_s
  end

  def conditional_tag_handler(matchdata, data)
    case matchdata[:cond]
    when 'is_page' then condition = @cur_page && @cur_page.filename.to_s.start_with?(matchdata[:path])
    when 'is_node' then condition = !@cur_page && @cur_node.filename.to_s.start_with?(matchdata[:path])
    when 'in_node'
      @cur_item = @cur_page || @cur_node
      condition = @cur_item.filename.to_s.start_with?(matchdata[:path])
    when 'has_pages'
      return false if @cur_page
      condition = Cms::Page.where({ filename: /^#{::Regexp.escape(@cur_node.filename)}\// }).present?
      condition ||= Cms::Page.in({ category_ids: @cur_node.try(:id) }).present?
    else return false
    end
    @data = condition ? data : false
  end
end
