require 'rails_helper'

RSpec.describe Api::V1::StationsController, type: :controller do
  describe 'GET #show' do
    before(:each) do
      @station = FactoryGirl.create :station
      @user = FactoryGirl.create :user
      @station_link =
        @station.user_station_links.where(user: @user).first_or_create
      @station_link.saved_station = true
      @station_link.save
      request.headers['Authorization'] = @user.auth_token
      get :show, id: @station.id, format: :json
    end

    it 'returns the information about a reporter on a hash' do
      @station_link.reload

      station = json_response[:station]
      expect(station[:name]).to eql @station.name
      expect(station[:undergroundness]).to eql @station_link.undergroundness
      expect(station[:saved_station]).to eql @station_link.saved_station
    end

    it { should respond_with 200 }
  end

  describe '#index' do
    it 'responds with all active stations' do
      FactoryGirl.create(:station, active: true)
      FactoryGirl.create(:station, active: true)
      FactoryGirl.create(:station, active: false)
      @user = FactoryGirl.create :user
      request.headers['Authorization'] = @user.auth_token
      get :index
      expect(json_response[:stations].count).to be 2
    end
  end

  describe '#playlist_profile_chooser' do
    it 'should choose a playlist_profile from a ll' do
      ll = '33.985488,-118.475250'
      get :playlist_profile_chooser, params: { ll: ll }
      playlist_profile_chooser = json_response[:playlist_profile_chooser]
      expect(playlist_profile_chooser).not_to be nil
      expect(playlist_profile_chooser[:weather]).not_to be nil
      expect(playlist_profile_chooser[:localtime]).not_to be nil
      expect(playlist_profile_chooser[:timezone]).not_to be nil
      expect(playlist_profile_chooser[:day]).not_to be nil
      expect(playlist_profile_chooser[:name]).not_to be nil
      expect(
        playlist_profile_chooser[:all_names]
      ).to include('mellow', 'lounge', 'club')
    end
  end

  describe '#generate_tracks' do
    before(:each) do
      @station = FactoryGirl.create :station
      @user = FactoryGirl.create :user
      @station_link =
        @station.user_station_links.where(user: @user).first_or_create
      @station_link.undergroundness = 2
      @station_link.save
    end

    it 'should generate tracks without a user' do
      post :generate_tracks, id: @station.id, format: :json
      station = json_response[:station]
      expect(station[:tracks].count).to be 30
    end

    it 'should generate tracks for a user' do
      request.headers['Authorization'] = @user.auth_token
      post :generate_tracks, id: @station.id, format: :json
      station = json_response[:station]
      expect(station[:tracks].count).to be 30
      expect(station[:tracks_updated_at]).not_to be nil

      @station.reload

      station_link = @station.user_station_links.where(user: @user).first
      expect(station_link).not_to be nil
      expect(station_link.playlist.tracks.count).to be 30
    end

    it 'should persist undergroundness for a user' do
      request.headers['Authorization'] = @user.auth_token
      post :generate_tracks, params: {
        id: @station.id, name: 'mellow', undergroundness: 4, format: :json
      }
      station = json_response[:station]
      expect(station[:tracks].count).to be 30
      expect(station[:tracks_updated_at]).not_to be nil
      expect(station[:undergroundness]).to be 4

      @station.reload

      station_link = @station.user_station_links.where(user: @user).first
      expect(station_link).not_to be nil
      expect(station_link.playlist.tracks.count).to be 30
      expect(station_link.undergroundness).to be 4
    end
  end

  describe '#get_tracks' do
    it 'reponds with the same tracks' do
      @station = FactoryGirl.create :station
      @user = FactoryGirl.create :user
      request.headers['Authorization'] = @user.auth_token
      post :generate_tracks, id: @station.id, format: :json

      generated_tracks = json_response[:station][:tracks]

      get :get_tracks, id: @station.id, format: :json

      get_tracks = json_response[:station][:tracks]

      expect(generated_tracks).to eq get_tracks
    end
  end

  # #update only makes sense in the context of a users preferences.
  # The actual station is not updated
  describe '#update' do
    it 'should update a user_station_link' do
      @station = FactoryGirl.create :station
      @user = FactoryGirl.create :user
      station_link =
        @station.user_station_links.where(user: @user).first_or_create
      station_link.undergroundness = 2
      station_link.save

      station_params = {
        id: @station.id,
        undergroundness: 4,
        saved_station: '1'
      }
      request.headers['Authorization'] = @user.auth_token
      put :update, id: @station.id, station: station_params, format: :json

      station_link.reload

      # expect(station_link.undergroundness).to eq 4
      # expect(json_response[:station][:undergroundness]).to eq 4
      expect(json_response[:station][:saved_station]).to eq true
    end

    it 'should unsave a statiob' do
      @station = FactoryGirl.create :station
      @user = FactoryGirl.create :user
      station_link =
        @station.user_station_links.where(user: @user).first_or_create
      station_link.undergroundness = 2
      station_link.saved_station = true
      station_link.save

      station_params = { id: @station.id, saved_station: '0' }
      request.headers['Authorization'] = @user.auth_token
      put :update, id: @station.id, station: station_params, format: :json

      station_link.reload

      expect(json_response[:station][:saved_station]).to eq false
    end

    it 'should 401 if there is no user' do
      @station = FactoryGirl.create :station
      put :update, id: @station.id, format: :json

      expect(response.status).to eq 401
    end
  end
end
