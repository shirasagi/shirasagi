class Cms::PublicHelper::Paginator < Kaminari::Helpers::Paginator
  def page_tag(page)
    @last = Cms::PublicHelper::Paginator::Page.new self, @template, **@options.merge(page: page)
  end

  %w[first_page prev_page next_page last_page gap].each do |tag|
    eval <<-DEF, nil, __FILE__, __LINE__ + 1
      def #{tag}_tag
        @last = Cms::PublicHelper::Paginator::#{tag.classify}.new self, @template, **@options
      end
    DEF
  end

  def canonical_cur_path
    @cur_path ||= begin
      path = @template.instance_variable_get(:@cur_path)
      path = path.sub(/\.p\d+\.html$/, ".html")
      path
    end
  end

  module PageUrlFor
    extend ActiveSupport::Concern

    def initialize(*args, **options)
      @paginator = args.shift
      super(*args, **options)
    end

    def page_url_for(page)
      path = @paginator.canonical_cur_path
      path = path.sub(".html", ".p#{page}.html") if page && page > 1

      params = params_for(page)
      params = params.symbolize_keys
      params.reverse_merge!(@template.url_options)

      params[:path] = path

      ActionDispatch::Http::URL.path_for(params)
    end
  end

  class Page < Kaminari::Helpers::Page
    include PageUrlFor
  end

  class FirstPage < Kaminari::Helpers::FirstPage
    include PageUrlFor
  end

  class PrevPage < Kaminari::Helpers::PrevPage
    include PageUrlFor
  end

  class NextPage < Kaminari::Helpers::NextPage
    include PageUrlFor
  end

  class LastPage < Kaminari::Helpers::LastPage
    include PageUrlFor
  end

  class Gap < Kaminari::Helpers::Gap
    include PageUrlFor
  end
end
