class Users::OmniauthCallbacksController < ApplicationController
  before_action :check_team_membership, except: :failure

  def github
    Rails.logger.info("[omniauth-debug] github callback entered (user_signed_in=#{user_signed_in?}, " \
                      "uid=#{omniauth&.uid.inspect}, nickname=#{omniauth&.info&.nickname.inspect}, " \
                      "email=#{omniauth&.info&.email.inspect})")

    if user_signed_in?
      current_user.update_from_omniauth!(omniauth)
      redirect_to :root, :notice => "Done!"
    else
      user = User.find_or_create_from_omniauth!(omniauth)

      flash[:notice] = after_sign_in_notice_for(user)
      sign_in_and_redirect(user)
    end
  rescue => e
    Rails.logger.error("[omniauth-debug] github callback FAILED: #{e.class}: #{e.message}")
    Rails.logger.error("[omniauth-debug] omniauth.auth present? #{request.env['omniauth.auth'].present?}")
    Rails.logger.error(e.backtrace.first(20).join("\n"))
    raise
  end

  def failure
  end

  private

  def omniauth
    request.env['omniauth.auth']
  end

  def after_sign_in_notice_for(user)
    if user.just_created?
      "Signed up with github!"
    else
      "Logged in with github"
    end
  end

  def check_team_membership
    login = omniauth.info.nickname

    unless client.team_member?(ENV.fetch('GITHUB_TEAM_ID'), login)
      render :status => :forbidden, :text => "Sorry!"
    end
  end

  def client
    GithubClient.new(:access_token => omniauth.credentials.token)
  end
end
