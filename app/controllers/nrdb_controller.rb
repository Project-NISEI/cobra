class NrdbController < ApplicationController
  before_action :skip_authorization

  def decks
    render json: Nrdb::Connection.new(current_user).decks
  end
end
