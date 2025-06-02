# frozen_string_literal: true

require 'redcarpet'

module ApplicationHelper

  class ResponsiveImgRenderer < Redcarpet::Render::HTML 
    def image(link, _title, alt_text) 
      %(<img class="img-fluid" src=#{link} alt=#{alt_text}>)
    end
  end

  def markdown(text)
    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: 'nofollow', target: '_blank' },
      space_after_headers: true,
      fenced_code_blocks: true
    }

    renderer = ResponsiveImgRenderer.new(options)
    markdown = Redcarpet::Markdown.new(renderer)

    markdown.render(text).html_safe # rubocop:disable Rails/OutputSafety
  end

  def tournament_types
    TournamentType.order(nsg_format: :desc, position: :asc)
  end
end
