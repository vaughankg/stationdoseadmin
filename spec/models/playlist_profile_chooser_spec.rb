require 'rails_helper'

describe PlaylistProfileChooser do
  subject { PlaylistProfileChooser }

  describe 'templates' do
    it 'should have loaded the templates' do
      expect(subject.playlist_profile_templates.count).to eq 7
    end
  end

  it 'should initialize with empty options' do
    playlist_profile = subject.new.playlist_profile
    expect(playlist_profile).not_to be nil
    expect(playlist_profile.criteria.size).to be > 0
  end

  it 'should take name as an argument' do
    args = {
      name: 'club'
    }
    playlist_profile = subject.new(args).playlist_profile
    expect(playlist_profile.name).to eq 'club'
  end

  it 'should take undergroundness as an argument' do
    args = {
      name: 'chill',
      undergroundness: 4.0
    }
    playlist_profile = subject.new(args).playlist_profile
    expect(playlist_profile.name).to eq 'chill'
    criteria = playlist_profile.criteria[:undergroundness]
    expect(criteria).not_to be nil
    expect(criteria.target).to be 4.0
  end
end
