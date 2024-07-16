RSpec.describe SwissImplementation do
  describe '#pair' do
    10.times do |i|
      let("player#{i}") { SwissImplementation::Player.new }
    end

    let(:players) do
      [player0, player1, player2, player3, player4,
        player5, player6, player7, player8, player9]
    end
    let(:paired) { SwissImplementation.pair(players) }

    it 'pairs correctly' do
      expect(paired.length).to eq(5)
      expect(paired.flatten).to match_array(players)
    end

    context 'with some games played' do
      before do
        player1.delta = 3
        player2.delta = 3
        player3.delta = 1
        player4.delta = 1
      end

      let(:paired) { SwissImplementation.pair(players) }

      it 'pairs players on matching score' do
        paired.each do |p|
          expect(p).to match_array([player1, player2]) if p.include?(player1)
          expect(p).to match_array([player3, player4]) if p.include?(player3)
        end
      end
    end

    context 'with some matchups excluded' do
      before do
        player1.exclude = (players - [player0, player1])
        player2.exclude = [player1]
      end

      let(:paired) { SwissImplementation.pair(players) }

      it 'excludes those matchups' do
        paired.each do |p|
          expect(p).to match_array([player1, player0]) if p.include?(player1)
        end
      end
    end

    context 'with odd number of players' do
      %i(snap crackle pop).each do |name|
        let(name) { SwissImplementation::Player.new }
      end
      let(:players) { [snap, crackle, pop] }

      it 'pairs correctly' do
        expect(paired.length).to eq(2)
        expect(paired.flatten).to match_array(players + [SwissImplementation::Bye])
      end

      it 'prevents players from receiving a second bye' do
        snap.exclude = [SwissImplementation::Bye]
        crackle.exclude = [SwissImplementation::Bye]

        paired.each do |p|
          expect(p).to match_array([pop, SwissImplementation::Bye]) if p.include?(pop)
        end
      end

      it 'always give bye to lowest players' do
        snap.delta = 1
        crackle.delta = 0
        pop.delta = 0

        paired.each do |p|
          expect(p).not_to match_array([snap, SwissImplementation::Bye]) if p.include?(SwissImplementation::Bye)
        end
      end
    end
  end
end
