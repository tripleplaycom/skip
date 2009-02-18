$j(function(){
    $j.iuiSettings({
        endShowContent: function(){
            // 書き込みボタン押下時
            $j('#new_comment_form')
            .submit(function() {
                if(isEmpty($j('#board_entry_comment_contents').val())) {
                    return false;
                }
                var url = relative_url_root + '/board_entries/ado_create_comment/' + $j('#entry_id', '#new_comment_form').val();
                $j.ajax({
                    type:'POST',
                    url:url,
                    data:$j('#new_comment_form').serialize(),
                    complete:function(request) {
                        $j('#board_entry_comments').append(request.responseText);
                        $j('#board_entry_comment_contents').val('');
                        setupCommentEditLink();
                        setupCommentCancelButton();
                        setupCommentInputForm();
                        setupCommentNestLink();
                        setupToggleMenu();
                    }
                });
                return false;
            });

            // 引数の文字列が空白以外で1文字以上かどうか
            var isEmpty = function(text) {
                if($j.trim(text).length == 0) {
                    alert("空白以外で1文字以上入力してください。");
                    return true;
                }
                return false;
            };

            // 編集ボタン押下時の処理
            var setupCommentEditLink = function() {
                $j('.comment_edit_link')
                .click(function() {
                    commentId = this.id.split('_')[3];
                    $j('#comment_contents_' + commentId).fadeOut(0, function() {
                        $j('#comment_area_' + commentId).fadeIn('fast', function() {
                            $j('#comment_input_form_' + commentId + ' textarea').focus();
                        });
                    });
                    return false;
                });
            };
            setupCommentEditLink();

            // コメント編集フォームのキャンセルボタン押下時の処理
            var setupCommentCancelButton = function() {
                $j('.comment_cancel_button')
                .click(function() {
                    commentId = this.id.split('_')[3];
                    if ($j('#comment_area_' + commentId).is(':visible')) {
                        $j('#comment_area_' + commentId).fadeOut(0, function() {
                            $j('#comment_contents_' + commentId).fadeIn('fast');
                        });
                    }
                    return false;
                });
            };
            setupCommentCancelButton();

            // コメント編集フォームをサブミットした時の処理
            var setupCommentInputForm = function() {
                $j('.comment_input_form')
                .submit(function() {
                    commentId = this.id.split('_')[3];
                    if(isEmpty($j('#comment_input_form_' + commentId + ' textarea').val())) {
                        return false;
                    }
                    var url = relative_url_root + '/board_entries/ado_edit_comment/' + commentId;
                    $j.ajax({
                        type:'POST',
                        url:url,
                        data:$j('#comment_input_form_' + commentId).serialize() + '&authenticity_token=' + $j('#authenticity_token').val(),
                        complete:function(request) {
                            $j('#comment_contents_' + commentId).html(request.responseText);
                            if ($j('#comment_area_' + commentId).is(':visible')) {
                                $j('#comment_area_' + commentId).fadeOut(0, function() {
                                    $j('#comment_contents_' + commentId).fadeIn('fast');
                                });
                            }
                        }
                    });
                    return false;
                });
            };
            setupCommentInputForm();

            // 「このコメントに返信」ボタン押下時の処理
            var setupCommentNestLink = function() {
                $j('.comment_nest_link')
                .click(function() {
                    commentId = this.id.split('_')[3];
                    level = this.id.split('_')[4] - 0 + 1;
                    // ネストレベルを保持するhiddenフィールドを作成
                    var hiddenLevel = function() {
                        return $j(document.createElement('input')).attr({type:'hidden', name:'level', value:level});
                    };

                    // トークン
                    var hiddenToken = function() {
                        return $j(document.createElement('input')).attr({type:'hidden', name:'authenticity_token', value:$j('#authenticity_token').val()});
                    };

                    // 説明を作成
                    var divDesc = function() {
                        return $j('<label>このコメントに返信</label>')
                    };

                    // コメント入力用テキストエリアを作成
                    var divText = function() {
                        return $j(document.createElement('textarea')).attr({rows:5, name:'contents'})
                    };

                    // 保存ボタンを作成
                    var saveButton = function(jform) {
                        return $j(document.createElement('input'))
                        .attr({type:'button', value:'保存'})
                        .click(function() {
                            if(isEmpty(jform.find('textarea').val())) {
                                return false;
                            }
                            var url = relative_url_root + '/board_entries/ado_create_nest_comment/' + commentId;
                            $j.ajax({
                                type:'POST',
                                url: url,
                                data:jform.serialize(),
                                success:function(html) {
                                    jform.fadeOut('0', function(){
                                        $j('#link_nest_comment_' + commentId).show();
                                        $j(document.createElement('div'))
                                        .appendTo('#view_nest_comment_' + commentId)
                                        .html(html)
                                        .hide()
                                        .fadeIn('fast', function() {
                                            setupCommentEditLink();
                                            setupCommentCancelButton();
                                            setupCommentInputForm();
                                            setupCommentNestLink();
                                            setupToggleMenu();
                                        });
                                        jform.remove();
                                    });
                                },
                                error:function(request) {
                                    alert(request.responseText);
                                }
                            });
                            return false;
                        });
                    };

                    // キャンセルボタンを作成
                    var cancelButton = function(jform) {
                        return $j(document.createElement('input'))
                        .attr({type:'button', value:'キャンセル'})
                        .click(function() {
                            jform.fadeOut('0', function(){
                                $j('#link_nest_comment_' + commentId).show();
                                jform.remove();
                            });
                            return false;
                        });
                    };

                    $j('#link_nest_comment_' + commentId).hide();
                    $j('#edit_nest_comment_' + commentId).empty();
                    // コメント返信フォームを作成して表示
                    var jform = $j(document.createElement('form'));
                    jform
                    .append(
                        $j(document.createElement('fieldset'))
                        .append(
                            $j(document.createElement('div'))
                            .addClass('row')
                            .append(hiddenLevel())
                            .append(hiddenToken())
                            .append(divDesc())
                            .append(divText())
                        )
                    )
                    .append(
                        $j(document.createElement('div'))
                        .append(saveButton(jform))
                        .append(cancelButton(jform))
                    )
                    .hide()
                    .fadeIn('fast')
                    .appendTo('#edit_nest_comment_' + commentId);

                    $j("textarea").jGrow({ rows: 25 });
                });
            };
            setupCommentNestLink();

            // 「メニュー」押下時の操作メニューのトグル
            var setupToggleMenu = function() {
                $j('.operation')
                .click(function() {
                    $j(this).find('ul').toggle();
                });
            };
            setupToggleMenu();
        }
    });
});
