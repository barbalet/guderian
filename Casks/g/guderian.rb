cask "guderian" do
  version "1.0.0"
  sha256 "b760be06ebbdfc44a881bc038c17c3ed585885bfbf6a0f68675f93fba29cf874"

  url "https://github.com/barbalet/guderian/releases/download/v#{version}/Guderian-#{version}.zip"
  name "Guderian"
  desc "World War II campaign wargame"
  homepage "https://github.com/barbalet/guderian"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Guderian.app"

  zap trash: [
    "~/Library/Preferences/com.barbalet.guderian.plist",
    "~/Library/Saved Application State/com.barbalet.guderian.savedState",
  ]
end
