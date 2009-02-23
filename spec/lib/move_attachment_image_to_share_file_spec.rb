# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__) + '/../spec_helper'

describe MoveAttachmentImageToShareFile, '.execute' do
  before do
    @move_attachment_image_to_share_file =  MoveAttachmentImageToShareFile.new
    MoveAttachmentImageToShareFile.stub!(:new).and_return(@move_attachment_image_to_share_file)
  end
end

describe MoveAttachmentImageToShareFile, '.new_share_file' do
  describe '移行対象の画像が添付された記事が存在する場合' do
    before do
      @board_entry = stub_model(BoardEntry, :symbol => 'symbol', :publication_type => 'publication_type', :publication_symbols_value => 'publication_symbols_value')
      MoveAttachmentImageToShareFile.should_receive(:image_attached_entry).and_return(@board_entry)
      @share_file = MoveAttachmentImageToShareFile.new_share_file(99, '99_image_file.png')
    end
    it '共有ファイルの値が設定されること' do
      @share_file.file_name.should == 'image_file.png'
      @share_file.owner_symbol.should == 'symbol'
      @share_file.date.should_not be_nil
      @share_file.user_id.should == 99
      @share_file.content_type.should == 'image/png'
      @share_file.publication_type.should == 'publication_type'
      @share_file.publication_symbols_value == 'publication_symbols_value'
    end
  end
  describe '移行対象の画像が添付された記事が存在しない場合' do
    before do
      MoveAttachmentImageToShareFile.should_receive(:image_attached_entry).and_return(nil)
    end
    it 'nilが返ること' do
      MoveAttachmentImageToShareFile.new_share_file(99, '99_image_file.png').should be_nil
    end
  end
end

describe MoveAttachmentImageToShareFile, '.share_file_name' do
  it '共有ファイルに登録するファイル名が取得出来ること' do
    MoveAttachmentImageToShareFile.share_file_name('7_image_name.png').should == 'image_name.png'
  end
end

describe MoveAttachmentImageToShareFile, '.image_attached_entry' do
  it '画像の添付対象記事を取得しようとすること' do
    BoardEntry.should_receive(:find_by_id).with(7)
    MoveAttachmentImageToShareFile.image_attached_entry('7_image_name.png')
  end
end

#def self.new_share_file created_user_id, filename
#
#end
