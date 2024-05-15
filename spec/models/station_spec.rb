require 'rails_helper'

RSpec.describe Station, type: :model do
  before { @station = FactoryGirl.build(:station) }

  subject { @station }

  it { should respond_to(:tracks) }
  it { should respond_to(:name) }
  it { should be_valid }
  it { should validate_presence_of(:name) }
  it { should have_many(:tracks) }

  it 'should come with some tracks' do
    station = FactoryGirl.create :station
    expect(station.tracks.count).to be > 0
  end

  describe '#generate_playlist' do
    it 'should generate a playlist' do
      station = FactoryGirl.create :station

      playlist = station.generate_playlist

      expect(playlist.tracks.count).to be > 0
      # expect(playlist.undergroundness).to eq 3
      # expect(playlist.profile_name).not_to be(nil)
      expect(playlist.summary).not_to be(nil)
      expect(playlist.summary[:criteria][:undergroundness]).not_to be(nil)
      expect(playlist.summary[:criteria][:undergroundness].target).to eq 3
      expect(playlist.station).to eq station
    end

    it 'should generate a featured or sponsored playlist' do
      station = FactoryGirl.create(:station, station_type: 'featured')
      playlist = station.generate_playlist

      expect(playlist.tracks.count).to be > 0
    end
  end
end
