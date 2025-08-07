class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  has_many :tasks, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :omniauthable, omniauth_providers: %i[line]

  def social_profile(provider)
    social_profiles.select { |sp| sp.provider == provider.to_s }.first
  end

  def set_values(omniauth)
    return if provider.to_s != omniauth["provider"].to_s || uid != omniauth["uid"]
    credentials = omniauth["credentials"]
    info = omniauth["info"]

    access_token = credentials["refresh_token"]
    access_secret = credentials["secret"]
    credentials = credentials.to_json
    name = info["name"]
  end

  def set_values_by_raw_info(raw_info)
    self.raw_info = raw_info.to_json
    self.save!
  end

  def self.from_omniauth(auth) #LINEログイン時にconfirmed_atを自動で埋める
    user = User.where(provider: auth.provider, uid: auth.uid).first_or_initialize

    user.email = auth.info.email || "#{auth.uid}@line.me"
    user.name = auth.info.name
    user.password = Devise.friendly_token[0, 20]

    user.skip_confirmation! if user.new_record?

    user.save!
    user
  end

  def line_login_user?
    provider == "line"
  end

end
