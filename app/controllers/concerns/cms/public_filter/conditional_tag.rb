module Cms::PublicFilter::ConditionalTag
  extend ActiveSupport::Concern

  def conditional_tag_template(cond = 'if')
    template = [
      '(?<template>\#\{ ?',
      cond,
      " (?<cond>[^(]*)\\('?\\/?(?<path>[^')]*)'?\\) ?\\}",
      "(?<data>[^#]*(\\#\\{ ?else?if[^#]*|\\#\\{ ?else ?\\}[^#]*)*)\\#\\{ ?end(|if)? ?\\})"
    ].join
    ::Regexp.compile(template)
  end

  def render_conditional_tag(matchdata)
    return @data if render_condition_if(matchdata)
    return @data if render_condition_elsif(matchdata)
    render_condition_else(matchdata)
    @data
  end

  private

  def conditional_tag_data(cond = 'if')
    template = [
      '\#\{ ?',
      cond,
      " (?<cond>[^(]*)\\('?\\/?(?<path>[^')]*)'?\\) ?\\}",
      "(?<data>[^#]*)(\\#\\{ ?else?if[^}]*\\}|\\#\\{ ?else ?\\})"
    ].join
    ::Regexp.compile(template)
  end

  def render_condition_if(matchdata)
    if matchdata[:template] =~ conditional_tag_data
      data = ::Regexp.last_match[:data]
    else
      data = matchdata[:data]
    end
    conditional_tag_handler(matchdata, data)
  end

  def render_condition_elsif(parent_matchdata)
    if parent_matchdata[:template] =~ conditional_tag_template('elsif') ||
       parent_matchdata[:template] =~ conditional_tag_template('elseif')
      matchdata = ::Regexp.last_match
      if matchdata[:template] =~ conditional_tag_data('elsif') ||
         matchdata[:template] =~ conditional_tag_data('elseif')
        data = ::Regexp.last_match[:data]
      else
        data = matchdata[:data]
      end
      conditional_tag_handler(matchdata, data)
      return @data if @data
      if "#{matchdata[:data]}\#\{end(|if)?\}" =~ conditional_tag_template('elsif') ||
         "#{matchdata[:data]}\#\{end(|if)?\}" =~ conditional_tag_template('elseif')
        render_condition_elsif(::Regexp.last_match)
        return @data if @data
      end
    end
    false
  end

  def render_condition_else(matchdata)
    if matchdata[:template] =~ /\#\{ ?else ?\}(?<data>[^#]*)\#\{ ?end(|if)? ?\}/
      @data = ::Regexp.last_match[:data]
    else
      @data = ''
    end
  end

  def conditional_tag_handler(matchdata, data)
    case matchdata[:cond]
    when 'is_page' then return @data = data if @cur_page && @cur_page.filename.start_with?(matchdata[:path])
    when 'is_node' then return @data = data if !@cur_page && @cur_node.filename.start_with?(matchdata[:path])
    when 'in_node'
      @cur_item = @cur_page || @cur_node
      return @data = data if @cur_item.filename.start_with?(matchdata[:path])
    when 'has_pages'
      return false if @cur_page
      return @data = data if Cms::Page.where({ filename: /^#{@cur_node.filename}\// }).first.present?
      return @data = data if Cms::Page.in({ category_ids: @cur_node._id }).first.present?
    else false
    end
  end
end
