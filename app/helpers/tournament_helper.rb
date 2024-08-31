# frozen_string_literal: true

module TournamentHelper
  def short_date(tournament)
    return unless tournament.date

    tournament.date.strftime('%-d %b %Y')
  end
end
