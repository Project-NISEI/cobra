class NrdbPublicController < ApplicationController
  before_action :skip_authorization

  def printings
    conn = Faraday.new(
      url: 'https://api-preview.netrunnerdb.com/api/v3/public/printings',
      params: {
        'fields[printings]': 'card_id,card_type_id,title,side_id,faction_id,minimum_deck_size,influence_limit,influence_cost',
        'filter[id]': params.require(:ids),
        'page[limit]': 1000,
      }) do |faraday|
      faraday.adapter :net_http
    end
    render json: conn.get.body
  end
end
