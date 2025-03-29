# frozen_string_literal: true

class TournamentsController < ApplicationController
  before_action :set_tournament, only: %i[
    show info edit update destroy
    upload_to_abr save_json cut qr registration timer
    close_registration open_registration lock_player_registrations unlock_player_registrations
    id_and_faction_data cut_conversion_rates side_win_percentages stats
  ]

  def index
    authorize Tournament

    where_clause = 'NOT private'
    if params['type_id'].present?

      @tournament_type = TournamentType.find_by id: params['type_id']
      unless @tournament_type.nil?
        where_clause += ActiveRecord::Base.sanitize_sql(
          [' AND tournament_type_id = ?', params['type_id']]
        )
      end
    end
    @tournaments = Tournament.includes(:user, :tournament_type)
                             .where(where_clause)
                             .order(date: :desc)
                             .limit(20)
  end

  def my
    authorize Tournament

    @tournaments = current_user.tournaments.includes(:tournament_type).order(date: :desc)
  end

  def stats
    authorize @tournament, :show?
  end

  def show
    authorize @tournament

    respond_to do |format|
      format.html do
        set_tournament_view_data
        set_overview_notices
      end
      format.json do
        headers['Access-Control-Allow-Origin'] = '*'
        render json: NrtmJson.new(@tournament).data(tournament_url(@tournament.slug, @request))
      end
    end
  end

  def info
    authorize @tournament, :show?
  end

  def timer
    authorize @tournament, :show?
    @round = @tournament.rounds.last
    @timer = @round.timer
    render layout: 'fullscreen'
  end

  def registration
    authorize @tournament, :register?

    set_tournament_view_data
    unless @current_user_player
      redirect_to tournament_path(@tournament)
      return
    end

    return unless @tournament.nrdb_deck_registration?
    return if @current_user_player.registration_locked?

    begin
      @decks = Nrdb::Connection.new(current_user).decks
    rescue StandardError
      redirect_to login_path(return_to: request.path)
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

    params = tournament_params

    error_found = false

    if params[:swiss_format] != @tournament.swiss_format
      first_stage = @tournament.stages.first
      if !first_stage.nil? &&
         ((params[:swiss_format] == 'single_sided' && first_stage.swiss?) ||
         (params[:swiss_format] == 'double_sided' && first_stage.single_sided_swiss?))
        if !@tournament.rounds.empty?
          flash[:alert] = "Can't change Swiss format when rounds exist."
          error_found = true
        else
          case params[:swiss_format] # rubocop:disable Metrics/BlockNesting
          when 'single_sided'
            first_stage.single_sided_swiss!
          when 'double_sided'
            first_stage.swiss!
          end
          first_stage.save
        end
      end
    end

    unless error_found
      if params[:swiss_deck_visibility]
        unless params[:cut_deck_visibility]
          params[:cut_deck_visibility] = Tournament.max_visibility_cut_or_swiss(
            @tournament.cut_deck_visibility, params[:swiss_deck_visibility]
          )
        end
      elsif params[:cut_deck_visibility]
        params[:swiss_deck_visibility] = Tournament.min_visibility_swiss_or_cut(
          @tournament.swiss_deck_visibility, params[:cut_deck_visibility]
        )
      end
      @tournament.update(params)
    end

    redirect_back_or_to edit_tournament_path(@tournament)
  end

  def destroy
    authorize @tournament

    Tournament.includes(players: %i[decks registrations standing_rows]).find(@tournament.id).destroy!

    redirect_to tournaments_path
  end

  def upload_to_abr
    authorize @tournament

    response = AbrUpload.upload!(@tournament, tournament_url(@tournament.slug, @request))

    @tournament.update(abr_code: response[:code]) if response[:code]

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
    format = params[:elimination_type] == 'single' ? :single_elim : :double_elim
    return redirect_to standings_tournament_players_path(@tournament) unless [3, 4, 8, 16].include? number

    @tournament.cut_to!(format, number)

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
    authorize @tournament, :show?
  end

  def close_registration
    authorize @tournament, :edit?

    @tournament.close_registration!
    redirect_back(fallback_location: tournament_rounds_path(@tournament))
  end

  def open_registration
    authorize @tournament, :edit?

    @tournament.open_registration!
    redirect_back(fallback_location: tournament_rounds_path(@tournament))
  end

  def lock_player_registrations
    authorize @tournament, :edit?

    @tournament.lock_player_registrations!
    redirect_back(fallback_location: tournament_rounds_path(@tournament))
  end

  def unlock_player_registrations
    authorize @tournament, :edit?

    @tournament.unlock_player_registrations!
    redirect_back(fallback_location: tournament_rounds_path(@tournament))
  end

  def cut_conversion_rates
    authorize @tournament, :show?

    render json: @tournament.cut_conversion_rates_data
  end

  def side_win_percentages
    authorize @tournament, :show?

    render json: @tournament.side_win_percentages_data
  end

  def id_and_faction_data
    authorize @tournament, :show?

    render json: @tournament.id_and_faction_data
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:name, :date, :private, :stream_url, :manual_seed,
                                       :self_registration, :allow_streaming_opt_out, :nrdb_deck_registration,
                                       :cut_deck_visibility, :swiss_deck_visibility, :swiss_format,
                                       :time_zone, :registration_starts, :tournament_starts, :tournament_type_id,
                                       :card_set_id, :format_id, :deckbuilding_restriction_id, :decklist_required,
                                       :organizer_contact, :event_link, :description, :official_prize_kit_id,
                                       :additional_prizes_description)
  end

  def set_tournament_view_data
    @players = @tournament.players.active.sort_by { |p| p.name || '' }
    @dropped = @tournament.players.dropped.sort_by { |p| p.name || '' }

    return unless current_user

    @current_user_is_running_tournament = @tournament.user_id == current_user.id
    @current_user_player = @players.find { |p| p.user_id == current_user.id }
    @current_user_dropped = @dropped.any? { |p| p.user_id == current_user.id }
  end

  def set_overview_notices
    @overview_notices = [registration_notice].compact
  end

  def registration_notice
    return unless @tournament.nrdb_deck_registration?

    if @tournament.registration_open?
      'Registration is open' unless @current_user_player&.registration_locked?
    elsif @current_user_player
      if @tournament.all_players_unlocked?
        'Registration is editable'
      elsif !@current_user_player.registration_locked?
        'Your registration is unlocked for editing'
      end
    elsif @current_user_is_running_tournament
      if @tournament.all_players_unlocked?
        'Registration is editable'
      elsif @tournament.any_player_unlocked?
        'One or more players are unlocked for editing'
      end
    end
  end
end
