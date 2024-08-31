# frozen_string_literal: true

require 'graph_matching'

module SwissImplementation
  def self.pair(players, options = {}, &block)
    Pairer.new(options).pair(players, &block)
  end

  class Player
    attr_accessor :delta, :exclude, :label

    def initialize(label = '')
      @delta = 0
      @exclude = []
      @label = label
    end
  end

  class Bye; end

  class Pairer
    def initialize(options = {})
      @delta_key = options[:delta_key] || :delta
      @exclude_key = options[:exclude_key] || :exclude
      @bye_delta = options[:bye_delta] || -1
    end

    def pair(player_data, &block)
      @player_data = player_data
      edges = graph(&block).maximum_weighted_matching(true).edges
      edges.map do |pairing|
        [players[pairing[0]], players[pairing[1]]]
      end
    end

    private

    attr_reader :delta_key, :exclude_key, :bye_delta

    def graph
      edges = [].tap do |e|
        (0...players.length).to_a.combination(2).each do |p1_index, p2_index|
          p1 = players[p1_index]
          p2 = players[p2_index]

          if block_given?
            weight = yield(p1, p2)
            e << [p1_index, p2_index, weight] unless weight.nil?
          elsif permitted?(p1, p2)
            e << [p1_index, p2_index, delta(p1, p2)]
          end
        end
      end
      GraphMatching::Graph::WeightedGraph.send('[]', *edges)
    end

    def permitted?(a, b)
      targets(a).include?(b) && targets(b).include?(a)
    end

    def delta(a, b)
      0 - (delta_value(a) - delta_value(b))**2
    end

    def targets(player)
      players - [player] - excluded_opponents(player)
    end

    def delta_value(player)
      return player.send(delta_key) if player.respond_to?(delta_key)
      return bye_delta if player == Bye

      0
    end

    def excluded_opponents(player)
      return player.send(exclude_key) if player.respond_to?(exclude_key)

      []
    end

    def players
      @players ||= @player_data.clone.tap do |data|
        data << Bye unless data.length.even?
      end.shuffle
    end
  end
end
