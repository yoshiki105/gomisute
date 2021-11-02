class User < ApplicationRecord
  has_many :trashes, dependent: :destroy

  enum mode: {
    top: 0,
    registration: 1,
    show_all: 2,
    edit: 3,
    show_next: 4,
    add_day_of_week: 5,
    add_cycle: 6,
  }

  def latest_trash
    trashes.order(created_at: :desc).first
  end

  # [[燃えるゴミ, 毎週, 月曜日], [燃えないゴミ, 隔週, 木曜日], ...] のような二次配列を返す
  def trashes_lists
    trashes.map do |trash|
      [
        trash.name,
        trash.latest_collection_day.cycle_i18n,
        trash.latest_collection_day.day_of_week_i18n
      ]
    end
  end

  # ゴミ一覧表示用の文字列を整形する
  def show_trashes
    str = ''
    if trashes.present?
      trashes_lists.each do |trashes_list|
        str << "=============================\n"
        trashes_list.each{ |line| str << (line + "\n") }
      end
      str << "=============================\n"
    else
      str << "登録しているゴミはありません.\n"
    end
  end
end
