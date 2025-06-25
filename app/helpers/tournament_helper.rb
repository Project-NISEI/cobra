# frozen_string_literal: true

module TournamentHelper
  def short_date(tournament)
    return unless tournament.date

    tournament.date.strftime('%-d %b %Y')
  end

  def tournament_settings_json(tournament)
    {
      tournament: {
        id: tournament.id,
        name: tournament.name,
        date: tournament.date,
        stream_url: tournament.stream_url,
        private: tournament.private,
        manual_seed: tournament.manual_seed,
        self_registration: tournament.self_registration,
        allow_streaming_opt_out: tournament.allow_streaming_opt_out,
        nrdb_deck_registration: tournament.nrdb_deck_registration,
        swiss_format: tournament.swiss_format,
        time_zone: tournament.time_zone,
        registration_starts: tournament.registration_starts,
        tournament_starts: tournament.tournament_starts,
        tournament_type_id: tournament.tournament_type_id,
        format_id: tournament.format_id,
        card_set_id: tournament.card_set_id,
        deckbuilding_restriction_id: tournament.deckbuilding_restriction_id,
        decklist_required: tournament.decklist_required,
        organizer_contact: tournament.organizer_contact,
        event_link: tournament.event_link,
        description: tournament.description,
        official_prize_kit_id: tournament.official_prize_kit_id,
        additional_prizes_description: tournament.additional_prizes_description,
        allow_self_reporting: tournament.allow_self_reporting,
        abr_code: tournament.abr_code
      }.compact,
      options: {
        tournament_types: TournamentType.all.map { |t| { id: t.id, name: t.name } },
        formats: Format.all.map { |f| { id: f.id, name: f.name } },
        card_sets: CardSet.all.map { |c| { id: c.id, name: c.name } },
        deckbuilding_restrictions: DeckbuildingRestriction.all.map { |d| { id: d.id, name: d.name } },
        time_zones: ActiveSupport::TimeZone.all.map { |z| { id: z.name, name: z.to_s } },
        official_prize_kits: OfficialPrizeKit.order(position: :desc).map { |p| { id: p.id, name: p.name } }
      },
      feature_flags: {
        single_sided_swiss: Flipper.enabled?(:single_sided_swiss, current_user),
        nrdb_deck_registration: Flipper.enabled?(:nrdb_deck_registration),
        allow_self_reporting: Flipper.enabled?(:allow_self_reporting),
        streaming_opt_out: Flipper.enabled?(:streaming_opt_out)
      },
      csrf_token: form_authenticity_token
    }
  end
end
