# 共通データの読み込み
require Rails.root.join('db/seeds/common.rb')

# # 環境ファイル読み込み
path = Rails.root.join("db/seeds/#{Rails.env}.rb")
require path if  File.exist?(path)
