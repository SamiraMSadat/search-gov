class FlickrProfile < ActiveRecord::Base
  attr_readonly :url, :profile_type, :profile_id
  belongs_to :affiliate

  before_validation :assign_profile_type_and_profile_id,
                    on: :create,
                    if: Proc.new { |fp| fp.url? && (fp.profile_id.blank? || fp.profile_type.blank?) }

  validates_presence_of :affiliate_id, :url
  validates_presence_of :profile_type, :profile_id,
                        on: :create,
                        if: :url?,
                        message: 'invalid Flickr URL'
  validates_inclusion_of :profile_type,
                         on: :create,
                         in: %w{user group},
                         if: :profile_type?
  validates_uniqueness_of :profile_id,
                          on: :create,
                          scope: [:affiliate_id, :profile_type],
                          case_sensitive: false,
                          message: 'has already been added',
                          if: Proc.new { |fp| fp.affiliate_id? && fp.profile_type? && fp.profile_id? }

  after_create :notify_oasis
  scope :users, where(profile_type: 'user')
  scope :groups, where(profile_type: 'group')

  private

  def assign_profile_type_and_profile_id
    NormalizeUrl.new :url
    self.profile_type = FlickrData.detect_profile_type url
    self.profile_id = FlickrData.lookup_profile_id(profile_type, url) if profile_type.present? && profile_id.blank?
  end

  def notify_oasis
    Oasis.subscribe_to_flickr(self.profile_id, self.url.sub(/\/$/,'').split('/').last, self.profile_type)
  end

end
