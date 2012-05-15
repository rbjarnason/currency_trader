class CreateTradingTimeFrames < ActiveRecord::Migration
  def change
    create_table :trading_time_frames do |t|
      t.string "time_frame"
      t.timestamps
    end
  end
end
