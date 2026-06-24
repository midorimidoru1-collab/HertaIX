-- ============================================================
--  HertaIX Assets  |  audio.lua
--  音声アセット定義ファイル
--
--  【使い方】
--  このファイルにエントリを追加することで、HertaIX.lua から
--  HertaIX:GetAudio("名前") で音声のカスタムアセットIDを取得できます。
--
--  【エントリの形式】
--    ["任意の名前"] = {
--        url      = "https://...",   -- ダウンロード元URL（rawリンク等）
--        filename = "ファイル名.mp3" -- ローカル保存ファイル名（拡張子必須）
--    },
--
--  【対応フォーマット】
--    .mp3 / .ogg / .wav
--
--  【注意】
--    - filename はこのファイル内で一意にしてください。
--    - url は直接ダウンロードできるリンクを指定してください。
--    - ファイルは HertaIX_Assets/audio/ フォルダに保存されます。
-- ============================================================

return {

    -- ここにエントリを追加してください。
    -- 例:
    -- ["click_se"] = {
    --     url      = "https://raw.githubusercontent.com/yourname/yourrepo/main/click.mp3",
    --     filename = "click.mp3",
    -- },
    -- ["bgm_main"] = {
    --     url      = "https://raw.githubusercontent.com/yourname/yourrepo/main/bgm.ogg",
    --     filename = "bgm.ogg",
    -- },

}
