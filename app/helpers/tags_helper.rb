module TagsHelper
  def tag_url(tag)
    "/tags/#{tag.slug}"
  end
end
