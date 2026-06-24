-- ============================================================
--  HertaIX Assets  |  images.lua
--  画像アセット定義ファイル
--
--  【使い方】
--  このファイルにエントリを追加することで、HertaIX.lua から
--  HertaIX:GetImage("名前") で画像のカスタムアセットIDを取得できます。
--
--  【エントリの形式】
--    ["任意の名前"] = {
--        url      = "https://...",   -- ダウンロード元URL（rawリンク等）
--        filename = "ファイル名.png" -- ローカル保存ファイル名（拡張子必須）
--    },
--
--  【対応フォーマット】
--    .png / .jpg / .jpeg / .bmp / .tga
--
--  【注意】
--    - filename はこのファイル内で一意にしてください。
--    - url は直接ダウンロードできるリンクを指定してください。
--    - ファイルは HertaIX_Assets/images/ フォルダに保存されます。
-- ============================================================

return {

    -- ここにエントリを追加してください。
    -- 例:
    -- ["my_icon"] = {
    --     url      = "https://raw.githubusercontent.com/yourname/yourrepo/main/my_icon.png",
    --     filename = "my_icon.png",
    -- },
    -- ["banner"] = {
    --     url      = "https://raw.githubusercontent.com/yourname/yourrepo/main/banner.png",
    --     filename = "banner.png",
    -- },

}
