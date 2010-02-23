class Member
  include MongoMapper::EmbeddedDocument

  key :admin, Boolean
  key :notify_by_email, Boolean, :default => true
  key :notify_removal_by_email, Boolean, :default => true
  key :email, String
  key :status, Integer, :default => 0

  AWAITING = 0
  UNVALIDATE = 1
  VALIDATE = 2

  key :user_id, ObjectId
  belongs_to :user

  validates_presence_of :user_id, :if => Proc.new { email.blank? }

  def notify_by_email!
    self.notify_by_email = true
    self.save
  end

  def update_data
    unless user_id
      self.status = AWAITING
    else
      if user.confirmed?
        self.status = VALIDATE
      else
        self.status = UNVALIDATE
      end
      self.email = user.email
    end
  end

end
