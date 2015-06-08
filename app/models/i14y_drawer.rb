class I14yDrawer < ActiveRecord::Base
  attr_accessible :description, :handle, :token
  has_many :i14y_memberships, dependent: :destroy
  has_many :affiliates, through: :i14y_memberships
  validates_presence_of :handle
  validates_uniqueness_of :handle
  validates_length_of :handle, within: (3..33)
  validates_format_of :handle, with: %r(^[a-z0-9_]+$), message: "must only contain lowercase letters, numbers, and underscore characters"
  before_validation :set_token, unless: :token?

  def label
    handle
  end

  private

  def set_token
    self.token = SecureRandom.hex(16)
  end

end