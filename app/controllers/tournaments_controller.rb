class TournamentsController < ApplicationController
  before_action :set_tournament, only: [
      :show, :edit, :update, :destroy,
      :upload_to_abr, :save_json, :cut, :qr, :registration, :timer
    ]

  def index
    authorize Tournament

    @tournaments = Tournament.where(private: false)
      .order(date: :desc)
      .limit(20)
  end

  def my
    authorize Tournament

    @tournaments = current_user.tournaments.order(date: :desc)
  end

  def show
    authorize @tournament

    respond_to do |format|
      format.html do
        set_tournament_view_data
      end
      format.json do
        headers['Access-Control-Allow-Origin'] = '*'
        render json: NrtmJson.new(@tournament).data(tournament_url(@tournament.slug, @request))
      end
    end
  end

  def timer
    authorize @tournament, :show?
    @round = @tournament.rounds.last
    @timer = @round.timer
    render layout:'fullscreen'
  end

  def registration
    authorize @tournament, :register?

    set_tournament_view_data
    unless @current_user_player
      redirect_to tournament_path(@tournament)
    end

    if @tournament.nrdb_deck_registration?
      begin
        @decks = Nrdb::Connection.new(current_user).decks
      rescue
        redirect_to login_path(:return_to => request.path)
      end
    end
  end

  def set_tournament_view_data
    @players = @tournament.players.active.sort_by { |p| p.name || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name || '' }

    if current_user
      @current_user_is_running_tournament = @tournament.user_id == current_user.id
      @current_user_player = @players.find { |p| p.user_id == current_user.id }
      @current_user_dropped = @dropped.any? { |p| p.user_id == current_user.id }
    end
  end

  def new
    authorize Tournament

    @new_tournament = current_user.tournaments.new
    @new_tournament.date = Date.current
  end

  def create
    authorize Tournament

    @new_tournament = current_user.tournaments.new(tournament_params)

    if @new_tournament.save
      redirect_to tournament_path(@new_tournament)
    else
      render :new
    end
  end

  def edit
    authorize @tournament
  end

  def update
    authorize @tournament

    @tournament.update(tournament_params)

    redirect_to edit_tournament_path(@tournament)
  end

  def destroy
    authorize @tournament

    @tournament.destroy!

    redirect_to tournaments_path
  end

  def upload_to_abr
    authorize @tournament

    response = AbrUpload.upload!(@tournament, tournament_url(@tournament.slug, @request))

    if(response[:code])
      @tournament.update(abr_code: response[:code])
    end

    redirect_to edit_tournament_path(@tournament)
  end

  def save_json
    authorize @tournament

    data = NrtmJson.new(@tournament).data(tournament_url(@tournament.slug, @request))

    send_data data.to_json,
      type: :json,
      disposition: :attachment,
      filename: "#{@tournament.name.underscore}.json"
  end

  def cut
    authorize @tournament

    number = params[:number].to_i
    return redirect_to standings_tournament_players_path(@tournament) unless [3,4,8,16].include? number

    @tournament.cut_to!(:double_elim, number)

    redirect_to tournament_rounds_path(@tournament)
  end

  def shortlink
    tournament = Tournament.find_by!(slug: params[:slug].upcase)

    authorize tournament, :show?

    redirect_to tournament_path(tournament)
  rescue ActiveRecord::RecordNotFound
    skip_authorization

    redirect_to not_found_tournaments_path(code: params[:slug])
  end

  def not_found
    skip_authorization

    @code = params[:code]
  end

  def qr
    authorize @tournament, :edit?
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:name, :date, :private, :stream_url, :manual_seed, :self_registration, :nrdb_deck_registration)
  end
end
