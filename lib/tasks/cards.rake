namespace :cards do
  desc 'update cards'
  task update: :environment do
    Nrdb::Connection.new.update_cards
  end
end
