class DecksController < ApplicationController
  before_action :skip_authorization

  def index
    render json: Nrdb::Connection.new(current_user).decks
  end
end
