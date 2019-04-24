class Article < PermissionModel
  TITLE_MIN = 10
  TITLE_MAX = 1000

  TLDR_MAX = 1500

  BODY_MIN = 128
  
  belongs_to :author, class_name: "User", foreign_key: :author_id, optional: true
  has_and_belongs_to_many :tags

  validates :title, presence: true, length: {maximum: TITLE_MAX, minimum: TITLE_MIN}

  validates :tldr, length: {maximum: TLDR_MAX}

  validates :body, presence: true, length: {minimum: BODY_MIN}

  has_one_attached :tldr_image

  def self.search(q=nil, tags: nil, author: nil)
    query = Article.left_outer_joins(:tags, :author).all
    query = search_by_author(query, author)
    query = search_by_tags(query, tags)
    q.blank? ? query : omnisearch(query, q)
  end

  def owner
    self.author
  end

  private
  def self.omnisearch(query_chain, query)
    query_chain.where "title ilike :q or tldr ilike :q or body ilike :q", q: "%#{query}%"
  end

  def self.search_by_tags(query_chain, tags)
    case tags
    when Array, ActiveRecord::Relation
      tags.each {|tag| query_chain = search_by_tags(query_chain, tag)}
      return query_chain
    when Tag
      query_chain.where 'tags.id = ?', tags.id
    when String
      tags.empty? ? query_chain : query_chain.where('tags.name = ?', tags.downcase)
    when NilClass
      query_chain
    else
      raise TypeError
    end
  end

  def self.search_by_author(query_chain, author)
    case author
    when User
      query_chain.where author: author
    when String
      author.empty? ? query_chain : query_chain.where('users.handle like :author', author: author)
    when NilClass
      query_chain
    else
      raise TypeError
    end
  end
end
