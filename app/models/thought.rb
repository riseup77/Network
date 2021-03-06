class Thought < ActiveRecord::Base
    belongs_to :user
    has_many :comments
    has_many :likes
    has_many :users_who_like, :through => :likes, :source => :user
    
    validates :content, presence: true
    
    def the_likes
        @likes = self.likes.count - 1
        return @likes 
    end
end
