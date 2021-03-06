class User < ApplicationRecord
  has_many :trashes, dependent: :destroy
  has_many :messages, dependent: :destroy

  enum status: {
    top: 0,
    registration: 1,
    show_all: 2,
    edit: 3,
    show_next: 4,
    add_day_of_week: 5,
    add_cycle: 6,
    which_trash_to_edit: 7,
    which_item_to_edit: 8,
    edit_complete: 9,
    delete_confirm: 10,
    add_notification: 11
  }

  # [[燃えるゴミ, 毎週, 月曜日], [燃えないゴミ, 隔週, 木曜日], ...] のような二次配列を返す
  def trashes_lists
    trashes.includes(:cycle, :collection_days, :notification).map do |trash|
      [
        trash.name,
        trash.cycle.name_i18n,
        trash.collection_days_list,
        "#{I18n.l trash.notification.notify_at}に通知"
      ]
    end
  end

  # ゴミ一覧表示用の文字列を整形する
  def show_trashes
    str = ''
    if trashes.present?
      trashes_lists.each do |trashes_list|
        str << "#{'=' * 15}\n"
        trashes_list.each { |line| str << ("#{line}\n") }
      end
      str << "#{'=' * 15}\n"
    else
      str << "登録しているゴミはありません.\n"
    end
  end

  # 編集可能なゴミを一覧表示するための文字列を整形する
  def show_editable_trashes
    if trashes.present?
      str = ''

      trashes_lists.each.with_index(1) do |trashes_list, index|
        str << "#{'=' * 15}\n#{index}:\n"
        trashes_list.each { |line| str << "  #{line}\n" }
      end

      str << "#{'=' * 15}\n0: 編集を中止する"
    else
      "登録しているゴミはありません.\n"
    end
  end
end
