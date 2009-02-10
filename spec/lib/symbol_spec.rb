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

describe Symbol, '.valid_owner_symbol' do
  describe '引数がnilの場合' do
    it 'invalid(false)になること' do
      Symbol.valid_owner_symbol(nil).should be_false
    end
  end
  describe '引数がnil以外の場合' do
    describe 'uid:で始まる場合' do
      it 'valid(true)になること' do
        Symbol.valid_owner_symbol('uid:foo').should be_true
      end
    end
    describe 'gid:で始まる場合' do
      it 'valid(true)になること' do
        Symbol.valid_owner_symbol('gid:foo').should be_true
      end
    end
    describe '上記以外の場合' do
      it 'invalid(false)になること' do
        Symbol.valid_owner_symbol('zid:foo').should be_false
      end
    end
  end
end
