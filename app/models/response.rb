class Response < String
  attr_accessor :text

  def initialize(text = '')
    super
    @text = text
  end

  def add_default_message
    self.text += <<~TEXT
      \n#{'=' * 15}
      次はどうする？
      ↓↓番号を選択↓↓
        1. ゴミの登録
        2. 登録内容の確認
        3. 登録内容の編集
        4. 次回のゴミ収集日の確認
    TEXT
  end

  def add_asking_trash_name_message
    self.text += <<~TEXT
      ゴミの名前を何にする？一つだけ答えてね！
      (例)燃えるゴミ
    TEXT
  end

  def add_show_trashes_message(user)
    self.text += <<~TEXT
      登録内容の確認だね！
      今登録している内容は以下の通りだよ！
      #{user.show_trashes}
    TEXT
  end

  def add_edit_message(user)
    self.text += <<~TEXT
      登録内容の編集だね！
      どれを編集する？
      #{user.show_editable_trashes}
    TEXT
  end

  def add_next_trash_colleciton_day_message
    self.text += <<~TEXT
      ## この機能は未実装です ##
      ↓↓以下、やりたいことのイメージ↓↓
      次回のゴミ収集日は、
        燃えるゴミ
        毎週
        月曜日・木曜日
      だよ！
      当日の朝6時に通知するからね！
    TEXT
  end

  def add_day_of_week_message(trash_name)
    self.text += <<~TEXT
      「#{trash_name}」の収集日はいつにする？
      週2回捨てるゴミは、2つつなげて送ってね！
        月曜・木曜のときの例 => 1 4
      #{'=' * 15}
        1: 月曜日
        2: 火曜日
        3: 水曜日
        4: 木曜日
        5: 金曜日
        6: 土曜日
        7: 日曜日
        0: ゴミの登録をやめる\n
    TEXT
  end

  def add_cycle_message(trash_name)
    self.text += <<~TEXT
      「#{trash_name}」の周期はどうする？
        1: 毎週
        2: 今週から隔週
        3: 来週から隔週
        4: 第１・３
        5: 第２・４
        0: やめる
    TEXT
  end

  def add_notification_message(trash_name)
    self.text += <<~TEXT
      「#{trash_name}」は何時に通知する？
      10分単位で設定できるよ！
        (例1)6:40
        (例2)7時20分
        (例3)8時半

        0: ゴミの登録をやめる
    TEXT
  end

  def add_registration_completed_message(trash)
    self.text += <<~TEXT
      登録したよ！
      「#{trash.name}」の収集日は
      「#{trash.cycle.name_i18n}」の「#{trash.collection_days_list}」
      「#{I18n.l trash.notification.notify_at}」に通知するからね！
    TEXT
  end

  def add_message_which_item_to_edit(trash)
    self.text += <<~TEXT
      「#{trash.name}」が選択されたよ！
      どの項目を編集する？
        1: 収集物の名前
        2: 曜日
        3: 周期
        4: #{trash.name}の登録を削除する
        0: 編集をやめる
    TEXT
  end

  def add_edit_item_message(item)
    self.text += "変更するのは「#{item}」だね！\n"
  end

  def add_delete_confirm_message
    self.text += <<~TEXT
      本当に削除してよろしいですか？
      元には戻せません。
        1: 削除を実行する
        0: 中止する
    TEXT
  end

  def add_edit_completed_message(trash)
    self.text += <<~TEXT
      編集完了したよ！
      新しい登録内容は、
        #{trash.name}
        #{trash.cycle.name_i18n}
        #{trash.collection_days_list}
      だよ！\n
    TEXT
  end

  def add_delete_completed_message
    self.text += '削除が完了したよ！'
  end

  def add_cancel_message
    self.text += '中止だね！'
  end

  def add_alert_message
    self.text += '正しく入力してね！'
  end

  def add_non_text_received_message
    self.text += '画像や動画は対応してません。'
  end
end
