module SS::AutoLink
  extend ActiveSupport::Concern

  def ss_auto_link(text, *args, &block)
    return ''.html_safe if text.blank?

    # this is necessary because the old auto_link API has a Hash as its last parameter
    options = args.size == 2 ? {} : args.extract_options!
    unless args.empty?
      options[:link] = args[0] || :all
      options[:html] = args[1] || {}
    end
    options.reverse_merge!(:link => :all, :html => {})
    sanitize = (options[:sanitize] != false)
    sanitize_options = options[:sanitize_options] || {}
    text = conditional_sanitize(text, sanitize, sanitize_options).to_str
    case options[:link].to_sym
    when :all
      text = auto_link_email_addresses(ss_auto_link_urls(text, options[:html], options, &block), options[:html], &block)
    when :email_addresses
      text = auto_link_email_addresses(text, options[:html], &block)
    when :urls
      text = ss_auto_link_urls(text, options[:html], options, &block)
    end
    conditional_html_safe(text, sanitize)
  end

  private

  def ss_auto_link_urls(text, html_options = {}, options = {})
    link_attributes = html_options.stringify_keys
    text.gsub(::ActionView::Helpers::TextHelper::AUTO_LINK_RE) do
      scheme = $1
      href = $&
      punctuation = []

      if auto_linked?($`, $')
        # do not change string; URL is already linked
        href
      else
        # don't include trailing punctuation character as part of the URL
        while href.sub!(/[^#{::ActionView::Helpers::TextHelper::WORD_PATTERN}\/-=&]$/, '')
          punctuation.push $&
          bracket = ::ActionView::Helpers::TextHelper::BRACKETS[punctuation.last]
          if opening = bracket and href.scan(opening).size > href.scan(punctuation.last).size
            href << punctuation.pop
            break
          end
        end

        link_text = block_given?? yield(href) : href
        href = 'http://' + href unless scheme

        unless options[:sanitize] == false
          link_text = sanitize(link_text)
          href      = sanitize(href)
        end

        escapes = options[:sanitize] ? true : false
        attributes = link_attributes.merge('href' => href)
        link = options[:link_to].call(link_text, attributes, escapes) if options[:link_to]
        link ||= content_tag(:a, link_text, attributes, escapes)
        link + punctuation.reverse.join('')
      end
    end
  end
end
