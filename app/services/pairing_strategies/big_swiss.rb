module PairingStrategies
  class BigSwiss
    # this class is not a real pairing strategy but a special-case class that
    # is used for very large fields to improve performance
    attr_reader :stage

    def initialize(stage, base_pairing_strategy = PairingStrategies::Swiss)
      @stage = stage
      @base_pairing_strategy = base_pairing_strategy

      @overflow = []
    end

    def pair!
      grouped_standings.map do |batch|
        to_pair = players_to_pair(batch)

        paired = pair_batch(to_pair)

        # rescue players who were not paired for some reason (e.g. no valid pairings)
        @overflow += to_pair - paired.flatten

        paired
      end.sum(Array.new) + panic_pair(@overflow)
    end

    private

    def grouped_standings
      @grouped_standings ||= stage.standings.group_by(&:points).values
    end

    def players_to_pair(batch)
      to_pair = active_players_in_standing_batch(batch) + @overflow

      if to_pair.count.odd? && batch != grouped_standings.last
        # find a player to pair down (eliminate those already paired down)
        if (to_pair - @overflow).empty?
          # only overflow players (i.e. all in this batch dropped)
          @overflow = to_pair
          to_pair = []
        else
          @overflow = [(to_pair - @overflow).sample]
          to_pair -= @overflow
        end
      else
        @overflow = []
      end

      to_pair
    end

    def active_players_in_standing_batch(standings)
      standings.map(&:player).select(&:active?)
    end

    def pair_batch(players)
      chunk(players).map do |batch|
        @base_pairing_strategy.get_pairings(batch)
      end.sum(Array.new)
    end

    def panic_pair(players)
      # last chance to add players who fell through the cracks, this bit needs
      # human intervention really so just naively do the easiest thing
      @overflow = []
      players.shuffle.in_groups_of(2, SwissImplementation::Bye)
    end

    def chunk(players)
      # return players in manageable chunks for faster pairing
      return [[]] if players.empty?

      num_chunks = (players.length / 50.0).ceil
      chunk_size = 2 * (1 + players.length / (2 * num_chunks))

      players.shuffle.each_slice(chunk_size)
    end
  end
end
