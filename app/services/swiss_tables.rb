# frozen_string_literal: true

module SwissTables
  def self.assign_table_numbers!(pairings)
    PairingOrder.new(pairings).apply_numbers!
  end

  class PairingOrder
    def initialize(pairings)
      @non_byes = []
      @byes = []
      @fixed_tables = []
      pairings.each do |pairing|
        if pairing.fixed_table_number?
          @fixed_tables << pairing
        elsif pairing.bye?
          @byes << pairing
        else
          @non_byes << pairing
        end
      end
    end

    def apply_numbers!
      numbers = Numbers.new
      @fixed_tables.each do |pairing|
        number = pairing.fixed_table_number
        numbers.exclude_fixed number
        pairing.update(table_number: number)
      end
      PairingSorters::Ranked.sort(@non_byes).each do |pairing|
        pairing.update(table_number: numbers.next)
      end
      @byes.each do |pairing|
        pairing.update(table_number: numbers.next)
      end
    end
  end

  class Numbers
    def initialize
      @fixed_numbers = Set[]
      @next_number = 1
    end

    def exclude_fixed(number)
      @fixed_numbers << number
    end

    def next
      @next_number += 1 while @fixed_numbers.include? @next_number
      number = @next_number
      @next_number += 1
      number
    end
  end
end
