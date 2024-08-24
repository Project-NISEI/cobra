# frozen_string_literal: true

RSpec.describe Standing do
  let(:player) { create(:player) }
  let(:standing) { described_class.new(player) }

  describe '#corp_identity' do
    let!(:identity) { create(:identity, name: 'RP') }

    before do
      player.corp_identity = 'RP'
      player.save!
    end

    it 'delegates to player' do
      expect(standing.corp_identity).to eq(identity)
    end
  end

  describe '#runner_identity' do
    let!(:identity) { create(:identity, name: 'Reina Roja') }

    before do
      player.runner_identity = 'Reina Roja'
      player.save!
    end

    it 'delegates to player' do
      expect(standing.runner_identity).to eq(identity)
    end
  end

  describe 'sorting' do
    # manual seeding should be ignored on unflagged tournaments
    let(:other) { create(:player, manual_seed: 1) }

    it 'sorts by points' do
      expect(
        described_class.new(player, points: 3) <=> described_class.new(other, points: 0)
      ).to eq(-1)
      expect(
        described_class.new(player, points: 2) <=> described_class.new(other, points: 2)
      ).to eq(0)
      expect(
        described_class.new(player, points: 1) <=> described_class.new(other, points: 5)
      ).to eq(1)
    end

    it 'sorts by sos' do
      expect(
        described_class.new(
          player, points: 3, sos: 2.0
        ) <=> described_class.new(
          other, points: 3, sos: 1.8
        )
      ).to eq(-1)
      expect(
        described_class.new(
          player, points: 3, sos: 2.0
        ) <=> described_class.new(
          other, points: 3, sos: 2.0
        )
      ).to eq(0)
      expect(
        described_class.new(
          player, points: 3, sos: 1.4
        ) <=> described_class.new(
          other, points: 3, sos: 1.8
        )
      ).to eq(1)
    end

    it 'sorts by extended sos' do
      expect(
        described_class.new(
          player, points: 3, sos: 2.0, extended_sos: 3.3
        ) <=> described_class.new(
          other, points: 3, sos: 2.0, extended_sos: 1.3
        )
      ).to eq(-1)
      expect(
        described_class.new(
          player, points: 3, sos: 2.0, extended_sos: 3.3
        ) <=> described_class.new(
          other, points: 3, sos: 2.0, extended_sos: 3.3
        )
      ).to eq(0)
      expect(
        described_class.new(
          player, points: 3, sos: 2.0, extended_sos: 0.3
        ) <=> described_class.new(
          other, points: 3, sos: 2.0, extended_sos: 1.3
        )
      ).to eq(1)
    end

    context 'with manual seed tournament' do
      let(:tournament) { create(:tournament, manual_seed: true) }
      let(:other) { create(:player, tournament:, manual_seed: 2) }

      context 'when player is seeded' do
        let(:player) { create(:player, tournament:, manual_seed: 1) }

        it 'sorts by points' do
          expect(
            described_class.new(player, points: 3) <=> described_class.new(other, points: 0)
          ).to eq(-1)
          expect(
            described_class.new(player, points: 1) <=> described_class.new(other, points: 5)
          ).to eq(1)
        end

        it 'sorts by seed before sos' do
          expect(
            described_class.new(
              player, points: 3, sos: 2.0
            ) <=> described_class.new(
              other, points: 3, sos: 1.8
            )
          ).to eq(-1)
          expect(
            described_class.new(
              player, points: 3, sos: 2.0
            ) <=> described_class.new(
              other, points: 3, sos: 2.0
            )
          ).to eq(-1)
          expect(
            described_class.new(
              player, points: 3, sos: 1.4
            ) <=> described_class.new(
              other, points: 3, sos: 1.8
            )
          ).to eq(-1)
        end

        context 'when seed is equal' do
          let(:other) { create(:player, tournament:, manual_seed: 1) }

          it 'sorts by sos' do
            expect(
              described_class.new(
                player, points: 3, sos: 2.0
              ) <=> described_class.new(
                other, points: 3, sos: 1.8
              )
            ).to eq(-1)
            expect(
              described_class.new(
                player, points: 3, sos: 2.0
              ) <=> described_class.new(
                other, points: 3, sos: 2.0
              )
            ).to eq(0)
            expect(
              described_class.new(
                player, points: 3, sos: 1.4
              ) <=> described_class.new(
                other, points: 3, sos: 1.8
              )
            ).to eq(1)
          end
        end
      end

      context 'when player is unseeded' do
        let(:player) { create(:player, tournament:, manual_seed: nil) }

        it 'sorts by points' do
          expect(
            described_class.new(player, points: 3) <=> described_class.new(other, points: 0)
          ).to eq(-1)
          expect(
            described_class.new(player, points: 1) <=> described_class.new(other, points: 5)
          ).to eq(1)
        end

        it 'sorts by seed before sos' do
          expect(
            described_class.new(
              player, points: 3, sos: 2.0
            ) <=> described_class.new(
              other, points: 3, sos: 1.8
            )
          ).to eq(1)
          expect(
            described_class.new(
              player, points: 3, sos: 2.0
            ) <=> described_class.new(
              other, points: 3, sos: 2.0
            )
          ).to eq(1)
          expect(
            described_class.new(
              player, points: 3, sos: 1.4
            ) <=> described_class.new(
              other, points: 3, sos: 1.8
            )
          ).to eq(1)
        end

        context 'when seed is equal' do
          let(:other) { create(:player, tournament:, manual_seed: nil) }

          it 'sorts by sos' do
            expect(
              described_class.new(
                player, points: 3, sos: 2.0
              ) <=> described_class.new(
                other, points: 3, sos: 1.8
              )
            ).to eq(-1)
            expect(
              described_class.new(
                player, points: 3, sos: 2.0
              ) <=> described_class.new(
                other, points: 3, sos: 2.0
              )
            ).to eq(0)
            expect(
              described_class.new(
                player, points: 3, sos: 1.4
              ) <=> described_class.new(
                other, points: 3, sos: 1.8
              )
            ).to eq(1)
          end
        end
      end
    end
  end
end
