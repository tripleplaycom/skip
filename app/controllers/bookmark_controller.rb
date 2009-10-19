# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

require 'uri'
class BookmarkController < ApplicationController
  include UserHelper
  verify :method => :post, :only => [:update, :destroy, :ado_set_stared ], :redirect_to => { :action => :show }

  before_filter :check_params, :only => [:new, :new_without_bookmarklet]
  before_filter :load_user, :only => [:list]

  protect_from_forgery :except => [:new]

  def new_url
    render :layout => 'subwindow'
  end

  def new
    @bookmark = if url = params[:url]
                  Bookmark.find_by_url Bookmark.unescaped_url(url)
                end || Bookmark.new(:url => url, :title => SkipUtil.toutf8_without_ascii_encoding(params[:title]))
    @bookmark_comment = unless @bookmark.new_record?
                          @bookmark.bookmark_comments.find_by_user_id(current_user.id)
                        end || BookmarkComment.new(:public => true)
    render :new, :layout => 'subwindow'
  rescue Bookmark::InvalidMultiByteURIError => e
    flash[:error] = _('URL format invalid.')
    redirect_to root_url
  end

  def new_with_bookmarklet
    @bookmarklet = true
    new_without_bookmarklet
  end
  alias_method_chain :new, :bookmarklet

  # ブックマークの更新（存在しない場合は作成）
  def update
    url = Bookmark.unescaped_url(params[:bookmark][:url])

    unless check_url_format? url
      messages = []
      messages << _('This URL cannot be bookmarked.')
      render :partial => "system/error_messages_for", :locals=> { :messages => messages }
      return
    end

    @bookmark = Bookmark.find_by_url(url) || Bookmark.new
    @bookmark.attributes = params[:bookmark]
    @bookmark.url = url

    @bookmark_comment = @bookmark.bookmark_comments.find(:first, :conditions => ["bookmark_comments.user_id = ?", session[:user_id]]) || @bookmark.bookmark_comments.build
    @bookmark_comment.attributes = params[:bookmark_comment]
    @bookmark_comment.user_id ||= session[:user_id]
    @bookmark_comment.public ||= true if @bookmark.is_type_user?

    is_new_record = @bookmark.new_record?
    Bookmark.transaction do
      # 親が存在しない場合は、親保存時に子も保存される。既存の親の場合は親を保存しても子が保存されないので子のみ保存
      @bookmark_comment.save! unless is_new_record
      @bookmark.save!
      if @bookmark.is_type_user?
        uid = @bookmark.url.slice(/^\/user\/(.*)/, 1)
        user = User.find_by_uid(uid)
        link_url = url_for(:controller => 'user', :uid => uid,
                           :action => 'social', :menu => 'social_postit')
        Message.save_message("POSTIT", user.id, link_url)
      end
    end

    unless params[:bookmarklet] == 'true'
      flash[:notice] = is_new_record ? _('Bookmark was successfully created.') : _('Bookmark was successfully updated.')
    end
    render :text => 'success'
  rescue ActiveRecord::RecordInvalid => ex
    messages = []
    messages.concat @bookmark.errors.full_messages.reject{|msg| msg.include?("Bookmark comments")} unless @bookmark.valid?
    messages.concat @bookmark_comment.errors.full_messages unless @bookmark_comment.valid?

    render :partial => "system/error_messages_for", :locals=> { :messages => messages }
  rescue Bookmark::InvalidMultiByteURIError => e
    render :partial => "system/error_messages_for", :locals=> { :messages => [_('URL format invalid.')] }
  end

  def ado_get_title
    render :text => Bookmark.get_title_from_url(Bookmark.unescaped_url(params[:url]))
  rescue Bookmark::InvalidMultiByteURIError => e
    render :text => _('URL format invalid.'), :status => :bad_request
  end

  # tab_menu
  def show
    uri = params[:uri] ? Bookmark.unescaped_url(params[:uri]) : ""
    unless @bookmark = Bookmark.find_by_url(uri, :include => :bookmark_comments )
      flash[:warn] = _("URL not bookmarked by anyone.")
      redirect_to :controller => 'mypage', :action => 'index'
      return
    end

    @main_menu = _('Bookmarks')
    @title = _("Bookmark[%{title}]") % {:title => @bookmark.title}

    # TODO: SQLを発行しなくても判断できるのでrubyで処理する様に
    comment =  BookmarkComment.find(:first,
                                    :conditions => ["bookmark_id = ? and user_id = ?", @bookmark.id, session[:user_id]])

    @tags = BookmarkComment.get_tagcloud_tags @bookmark.url

    @create_button_show =  comment ? false : true
  end

  # ブックマークコメントの削除
  def destroy
    comment = BookmarkComment.find(params[:comment_id])

    # 権限チェック
    redirect_to_with_deny_auth and return unless comment.user_id == session[:user_id]

    comment.destroy
    flash[:notice] = _('Deletion completed.')
    redirect_to  :action =>'show', :uri => comment.bookmark.url
  end

  #ユーザのブックマークコメント一覧表示(ユーザのページからのリンクでくる)
  def list
    @main_menu = user_main_menu @user
    @title = user_title @user
    @tab_menu_option = { :uid => @user.uid }

    find_params = {
      :user_id => @user.id,
      :page => params[:page],
      :keyword => params[:keyword],
      :category => params[:category],
      :type => params[:type]
    }

    #タグ検索用
    @tags = BookmarkComment.get_tags @user.id

    #結果表示用
    conditions = BookmarkComment.make_conditions_for_comment(current_user.id, find_params)
    @pages, @bookmark_comments = paginate(:bookmark_comments,
                                          :per_page => 20,
                                          :conditions => conditions,
                                          :order =>'bookmark_comments.created_on DESC' ,
                                          :include => :bookmark)
    unless @bookmark_comments && @bookmark_comments.size > 0
      if params[:commit] || params[:category] || params[:type]
        flash.now[:notice] = _('No matching bookmarks found.')
      else
        flash.now[:notice] = _('No bookmarks have been registered.')
      end
    end
  end

  def ado_set_stared
    bookmark_comment = BookmarkComment.find_by_id(params[:bookmark_comment_id])
    # 権限チェック
    unless bookmark_comment.user_id == session[:user_id]
      render :nothing => true
      return false
    end
    bookmark_comment.update_attribute(:stared, params[:stared])
    render :partial => "bookmark/stared", :locals => {:bookmark_comment => bookmark_comment}
  end

  def bookmark_count
    @bookmark = Bookmark.find(:all,
                              :select => "bookmark_comments_count",
                              :conditions => ["url = ?", params[:uri]])
    count = @bookmark[0] ? @bookmark[0].bookmark_comments_count : 0
    render :text => count.to_s
  end


private
  def check_params
    unless params[:url] && check_url_format?(params[:url])
      flash[:warn] = _("The URL is invalid.")
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

  def check_url_format? url
    # 社内用URLのチェックは、bookmarkと重複している。
    ((url =~ /^\/user\/.*/) || (url =~ /^\/page\/.*/) || url =~ /^https?:\/\/.*/) && !(url =~ /.*javascript:.*/)
  end
end
