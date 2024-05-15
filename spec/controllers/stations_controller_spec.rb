require 'rails_helper'

RSpec.describe StationsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # Station. As you add validations to Station, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    skip('Add a hash of attributes valid for your model')
  end

  let(:invalid_attributes) do
    skip('Add a hash of attributes invalid for your model')
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # StationsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before(:each) do
    stationdose_auth
  end

  describe 'GET #index' do
    it 'assigns all stations as @stations' do
      station = Station.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:stations)).to eq([station])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested station as @station' do
      station = Station.create! valid_attributes
      get :show, params: { id: station.to_param }, session: valid_session
      expect(assigns(:station)).to eq(station)
    end
  end

  describe 'GET #new' do
    it 'assigns a new station as @station' do
      get :new, params: {}, session: valid_session
      expect(assigns(:station)).to be_a_new(Station)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested station as @station' do
      station = Station.create! valid_attributes
      get :edit, params: { id: station.to_param }, session: valid_session
      expect(assigns(:station)).to eq(station)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Station' do
        expect do
          post(
            :create,
            params: { station: valid_attributes },
            session: valid_session
          )
        end.to change(Station, :count).by(1)
      end

      it 'assigns a newly created station as @station' do
        post(
          :create,
          params: { station: valid_attributes },
          session: valid_session
        )
        expect(assigns(:station)).to be_a(Station)
        expect(assigns(:station)).to be_persisted
      end

      it 'redirects to the created station' do
        post(
          :create,
          params: { station: valid_attributes },
          session: valid_session
        )
        expect(response).to redirect_to(Station.last)
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved station as @station' do
        post(
          :create,
          params: { station: invalid_attributes },
          session: valid_session
        )
        expect(assigns(:station)).to be_a_new(Station)
      end

      it "re-renders the 'new' template" do
        post(
          :create,
          params: { station: invalid_attributes },
          session: valid_session
        )
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        skip('Add a hash of attributes valid for your model')
      end

      it 'updates the requested station' do
        station = Station.create! valid_attributes
        put(
          :update,
          params: { id: station.to_param, station: new_attributes },
          session: valid_session
        )
        station.reload
        skip('Add assertions for updated state')
      end

      it 'assigns the requested station as @station' do
        station = Station.create! valid_attributes
        put(
          :update,
          params: { id: station.to_param, station: valid_attributes },
          session: valid_session
        )
        expect(assigns(:station)).to eq(station)
      end

      it 'redirects to the station' do
        station = Station.create! valid_attributes
        put(
          :update,
          params: { id: station.to_param, station: valid_attributes },
          session: valid_session
        )
        expect(response).to redirect_to(station)
      end
    end

    context 'with invalid params' do
      it 'assigns the station as @station' do
        station = Station.create! valid_attributes
        put(
          :update,
          params: { id: station.to_param, station: invalid_attributes },
          session: valid_session
        )
        expect(assigns(:station)).to eq(station)
      end

      it "re-renders the 'edit' template" do
        station = Station.create! valid_attributes
        put(
          :update,
          params: { id: station.to_param, station: invalid_attributes },
          session: valid_session
        )
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested station' do
      station = Station.create! valid_attributes
      expect do
        delete(
          :destroy,
          params: { id: station.to_param },
          session: valid_session
        )
      end.to change(Station, :count).by(-1)
    end

    it 'redirects to the stations list' do
      station = Station.create! valid_attributes
      delete :destroy, params: { id: station.to_param }, session: valid_session
      expect(response).to redirect_to(stations_url)
    end
  end
end
