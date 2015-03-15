
RSpec.describe HasArrayOf::AssociatedBelongs do
  include_context "Video model belonging to Playlist"
  include_context "Playlist model"
  include_context "TV series"

  it "should respond to association method" do
    expect(return_of_harmony).to respond_to(:playlists)
  end

  it "should fetch correct results" do
    expect(return_of_harmony.playlists).to contain_exactly(mlp_season2, my_cool_list)
  end
end
