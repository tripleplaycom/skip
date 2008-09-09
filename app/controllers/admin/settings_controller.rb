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

class Admin::SettingsController < Admin::ApplicationController
  N_('Admin::SettingsController|literal')
  N_('Admin::SettingsController|mail')
  N_('Admin::SettingsController|other')
  N_('Admin::SettingsController|feed')

  def index
    params[:tab] ||= 'literal'
    @topics = [[_("#{self.class.name}|#{params[:tab]}")]]
  end

  def update_all
    settings = (params[:settings] || {}).dup.symbolize_keys
    settings.each do |name, value|
      # remove blank values in array settings
      value.delete_if {|v| v.blank? } if value.is_a?(Array)
      if [:antenna_default_group, :mypage_feed_settings].include? name
        value = value.values
      end
      Admin::Setting[name] = value
    end
    if params[:tab] == 'mail'
      ActionMailer::Base.smtp_settings = {
        :address => Admin::Setting.smtp_settings_address,
        :domain => Admin::Setting.smtp_settings_domain,
        :port => Admin::Setting.smtp_settings_port,
        :user_name => Admin::Setting.smtp_settings_user_name,
        :password => Admin::Setting.smtp_settings_password,
        :authentication => Admin::Setting.smtp_settings_authentication }
    end
    flash[:notice] = _('保存しました。')
    redirect_to :action => params[:tab] ? params[:tab] : 'index'
  end

  def ado_feed_item
    @feed_setting = {:url => '', :title => ''}
    @index =  params[:index]
    render :partial => 'feed_item'
  end

  def ado_antenna_default_group
    @antenna = ''
    @index =  params[:index]
    render :partial => 'antenna_default_group'
  end
end