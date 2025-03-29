# frozen_string_literal: true

namespace :tournament_metadata do
  desc 'update tournament metadata'
  task seed: :environment do
    # Formats
    formats = [
      { name: 'Standard', position: 1 },
      { name: 'Random Access Memories', position: 2 },
      { name: 'Startup', position: 3 },
      { name: 'Snapshot', position: 4 },
      { name: 'Eternal', position: 5 },
      { name: 'Cube Draft', position: 6 },
      { name: 'Other', position: 99 }
    ]

    formats.each do |format|
      f = Format.find_or_create_by(name: format[:name])
      f.position = format[:position]
      f.save
    end

    # Tournament Types
    tournament_types = [
      { name: 'Game Night Kit', nsg_format: true, position: 1 },
      { name: 'Casual Tournament Kit', nsg_format: true, position: 2 },
      { name: 'District Championship', nsg_format: true, position: 3 },
      { name: 'Megacity Championship', nsg_format: true, position: 4 },
      { name: 'Continental Championship', nsg_format: true, position: 5 },
      { name: 'World Championship', nsg_format: true, position: 6 },
      { name: 'Circuit Breaker Invitational', nsg_format: true, position: 7 },
      { name: 'Accelerated Meta Test', nsg_format: true, position: 8 },
      { name: 'NANPC Event', nsg_format: false, position: 9 },
      { name: 'Asynchronous', nsg_format: false, position: 10 },
      { name: 'Community', nsg_format: false, position: 11 },
      { name: 'Non-Tournament Event', nsg_format: false, position: 12 }
    ]

    tournament_types.each do |tournament_type|
      TournamentType.find_or_create_by(name: tournament_type[:name])
                    .update(nsg_format: tournament_type[:nsg_format],
                            position: tournament_type[:position])
    end

    official_prize_kits = [
      { name: '2025 District Championship Kit', position: 4 },
      { name: '2025 H1 Casual Tournament Kit', position: 3 },
      { name: '2025 Q2 Game Night Kit', position: 2 },
      { name: '2025 Q1 Game Night Kit', position: 1 }
    ]

    official_prize_kits.each do |k|
      OfficialPrizeKit.find_or_create_by(name: k[:name])
                      .update(position: k[:position])
    end
  end
end
