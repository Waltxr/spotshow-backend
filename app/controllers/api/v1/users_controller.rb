class Api::V1::UsersController < ApplicationController
  skip_before_action :authorized, only: [:create, :show]

  def create
    auth_params = SpotifyAdapter.get_auth_params(params[:code])
    user_data = SpotifyAdapter.get_user_data(auth_params["access_token"])
    encodedAccess = issue_token({token: auth_params["access_token"]})
    encodedRefresh = issue_token({token: auth_params["refresh_token"]})
    @user = User.find_or_create_by(user_params(user_data))
    queued_job = GetUserArtistsJob.perform_later(@user, auth_params)
    job = BackgroundJob.create(
      job_name: 'GetUserArtistsJob',
      job_uid: queued_job.job_id,
      status: ActiveJobStatus.fetch(queued_job.job_id).status
    )
    render json: user_with_token(@user, job)
  end

  def show
    encrypted_user_id = params["jwt"]
    user_id = JWT.decode(encrypted_user_id, ENV["MY_SECRET"], ENV["ALG"])
    @user = User.find_by(id: user_id[0]["user_id"])

    render :json => @user, :include => [:events => { :include => { :artists => { :except => [:created_at, :updated_at] },
                                                                   :venue => { }}}]
  end

  private

  def user_with_token(user, job)
    payload = {user_id: user.id}
    jwt = issue_token(payload)
    {currentUser: user, code: jwt, job_id: job.id}
  end

  def user_params(user_data)
    params = {
      username: user_data["id"],
      spotify_url: user_data["external_urls"]["spotify"],
      href: user_data["href"],
      uri: user_data["uri"],
    }
  end

end
