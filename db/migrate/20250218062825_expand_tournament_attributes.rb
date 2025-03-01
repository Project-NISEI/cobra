# frozen_string_literal: true

class ExpandTournamentAttributes < ActiveRecord::Migration[7.2]
  def change
    # Supporting data join tables.
    create_table :tournament_types do |t|
      t.string :name, null: false
      t.boolean :nsg_format, default: false, null: false
      t.integer :position, null: false, default: 0
      t.string :description

      t.timestamps
      t.index :name, unique: true
      t.index :position, unique: true
    end

    create_table :formats do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
      t.index :name, unique: true
      t.index :position, unique: true
    end

    create_table :deckbuilding_restrictions, id: :string do |t|
      t.string :name
      t.date :date_start
      t.string :play_format_id

      t.timestamps
      t.index :name, unique: true
    end

    create_table :official_prize_kits do |t|
      t.string :name, null: false
      t.string :link
      t.string :image_url
      t.string :description
      t.integer :position, null: false, default: 0

      t.timestamps
      t.index :name, unique: true
      t.index :position, unique: true
    end

    # Add columns for the join tables to tournaments.
    add_reference :tournaments, :tournament_type, foreign_key: { to_table: :tournament_types }, null: true
    add_reference :tournaments, :format, foreign_key: { to_table: :formats }, null: true
    add_reference :tournaments, :deckbuilding_restriction,
                  type: :string, foreign_key: { to_table: :deckbuilding_restrictions },
                  null: true

    create_table :custom_prizes do |t|
      t.string :name, null: false
      t.string :description
      t.string :image_url

      t.timestamps
      t.index :name, unique: true
    end
    add_reference :custom_prizes, :tournament, foreign_key: true, null: false # rubocop:disable Rails/NotNullColumn

    create_table :card_sets, id: :string do |t|
      t.string :name
      t.date :date_release

      t.timestamps
      t.index :name, unique: true
    end

    # Add new attributes for tournaments.
    add_column :tournaments, :registration_starts, :string
    add_column :tournaments, :tournament_starts, :string
    add_column :tournaments, :decklist_required, :boolean, default: false, null: false
    add_column :tournaments, :organizer_contact, :string
    add_column :tournaments, :event_link, :string
    add_column :tournaments, :description, :text
    add_column :tournaments, :additional_prizes_description, :text
  end
end
