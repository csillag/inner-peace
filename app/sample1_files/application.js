var APP = (function($) {
    var app = {},
        path = window.location.pathname.split('/'),
        $el;

    app.skipWall = function(){
      //alert('skip');
      $.colorbox.close();
      $('#comment-form').submit();
    };

    app.hopWallCreateWebAccount = function(){
      var comment = $('#comment-textarea').val(),
          aid = $('#a-id').val();

      window.location = "/accounts/new?comment=" + comment +"&aid=" + aid;
    };

    app.hopWallForgotPassword = function(){
      var comment = $('#comment-textarea').val(),
          aid = $('#a-id').val();
      window.location = "/accounts/forgot-password?comment=" + comment +"&aid=" + aid;
    };

    app.createCookie = function(name,value,days) {
      var date,
          expires;

      if (days) {
        date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        expires = "; expires="+date.toGMTString();
      } else {
        expires = "";
        document.cookie = name+"="+value+expires+"; path=/";
      }
    };

    app.readCookie = function(name) {
      var nameEQ = name + "=";
      var ca = document.cookie.split(';');
      for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0) ===' ') { c = c.substring(1,c.length); }
        if (c.indexOf(nameEQ) === 0) { return c.substring(nameEQ.length,c.length); }
      }
      return null;
    };

    app.eraseCookie = function(name) {
      app.createCookie(name,"",-1);
    };

    function init() {

      if (!Modernizr.input.placeholder) { placeholder(); }
      if (path[path.length-1] === 'fulltext') { setup_google_plus(); }
      if(window.location.hostname.substring(0,2) === 'm.') {
        remove_empty_spans();
      }

      setup_jplayer();
      archive_nav();

      $('form label.inField').inFieldLabels();

      $(".showModal").colorbox({
        width:"auto",
        inline:true,
        href:"#signup",
        scrolling: false,
        'opacity': 0.6,
        onComplete:function(){
          $.colorbox.resize();
        }
      });

      $('.closeBox, #cboxClose').click(function(){
        $.colorbox.close();
        $('#popOverForm')[0].reset();
      });

      $('.miniWidgetName').click(function() {
        $el = $(this);
        $el.siblings('.filterItems').toggle();
        $el.toggleClass('expanded');
      });

      /* video highlights page */
      $('.videoSingle iframe').siblings('p').children('a').parent('p').remove();
      $('#video-highlights .videoSingle').each( function () { $(this).fadeIn('slow').show(); });
      $('#articleFullText .videoThumb iframe, #articleFullText .videoThumb object').each( function() {
        $el = $(this);
        if($el.attr('height') !== 255 ) { $el.attr('height', 255); }
        if($el.attr('width') !== 360 ) { $el.attr('width', 360); }
      });

      /* signin box */
      $('.portaInputSignIn input').focus(function() {
        $(this).parent().addClass('portaInputSignInActive');
      });

      $('.portaInputSignIn input').blur(function() {
        $(this).parent().removeClass('portaInputSignInActive');
      });

      $('.openSignIn a').click(function(){
        $('.openSignIn').hide();
        $('.secondContent').hide();
        $('.thirdContent').hide();
        $('.firstContent').show();
        $('.openCreateAccount').show();
        $.colorbox.resize();
      });

      $('.openCreateAccount a').click(function(){
        $('.openCreateAccount').hide();
        $('.firstContent').hide();
        $('.thirdContent').hide();
        $('.secondContent').show();
        $('.openSignIn').show();
        $.colorbox.resize();
      });

      $('.createFromLightbox').click(function(){
        $('.thirdContent').show();
        $('.secondContent').hide();
        $.colorbox.resize();
      });

      $('.smallBlueI').click(function(){
        if($('.'+$(this).attr('id')).css('display') === 'block'){
          $('.'+$(this).attr('id')).css('display','none');
          $(this).css('background','url("images/buttons/small_buttons.png") -14px 0px');
        }
        else{
          $('.'+$(this).attr('id')).css('display','block');
          $(this).css('background','url("images/buttons/small_buttons.png") -14px -28px');
        }
        return false;
      });

      $('.bestWidget, .jobsWidget, .popWidget').hover(
        function() {
          $el = $(this);
          if ($el.find('.hiddenTextWidget').css('display') === 'none') {
            $el.find('.WidgetHelpHoverEye').show();
          } else {
            $el.find('.WidgetHelpHoverEye').hide();
          }
        },
        function() {
          $(this).find('.WidgetHelpHoverEye').hide();
        }
      );

      $('.WidgetHelpHoverEye').click(function(){
        $el = $(this);

        $el.closest('.widget').find('.hiddenTextWidget').toggle();

        if($el.closest('.widget').find('.hiddenTextWidget').css('display') === 'block') {
          $el.hide();
          $el.closest('.widget').find('.hiddenTextWidget').css('border', '1px solid #0095C9');
        } else {
          $(this).closest('.widget').find('.hiddenTextWidget').css('border', 'none' );
        }
      });

      $('.expand, .collapse').click( function(){
        $('#more-dates').toggle();
        $('.expand, .collapse').toggle();
      });

      $('a.close').click(
        function(){
        $(this).parent().hide();
        $(this).parent().parent().find('.WidgetHelpHoverEye').show();
      });

      $('#page-links a:last-child').css('borderRight', 0);

      $('.smallWhiteI').click(function(e){
        if($('.'+$(this).attr('id')).css('display') === 'block'){
          $('.'+$(this).attr('id')).css('display','none');
          $(this).css('background','url("images/buttons/small_buttons.png") -14px -14px');
        } else {
          $('.'+$(this).attr('id')).css('display','block');
          $(this).css('background','url("images/buttons/small_buttons.png") -14px -42px');
        }
        e.preventDefault();
      });

      $('.smallBlueI').hover(
        function() {
          if($('.'+$(this).attr('id')).css('display') !== 'block'){
            $(this).css('background','url("/images/img.widget-help-hover.gif")');
          } else {
            $(this).css('background','url("/images/img.widget-help-hover.gif")');
          }
        },
        function() {
          if($('.'+$(this).attr('id')).css('display') !== 'block'){
            $(this).css('background','url("images/buttons/small_buttons.png") 0px 0px');
          } else {
            $(this).css('background','url("images/buttons/small_buttons.png") 0px -28px');
          }
        }
      );

      $('.smallWhiteI').hover(
        function() {
          if($('.'+$(this).attr('id')).css('display') !== 'block'){
            $(this).css('background','url("images/buttons/small_buttons.png") -14px -14px');
          } else {
            $(this).css('background','url("images/buttons/small_buttons.png") -14px -42px');
          }
        },
        function() {
          if($('.'+$(this).attr('id')).css('display') !== 'block'){
            $(this).css('background','url("images/buttons/small_buttons.png") 0px -14px');
          } else {
            $(this).css('background','url("images/buttons/small_buttons.png") 0px -42px');
          }
        }
      );

      $('.videoCont a').hover(
        function() {
          $(this).css('background','url("images/backgrounds/video_overlay.png") top no-repeat');
          $(this).parent().next().find('a').css('color','#077FBA');
        },
        function() {
          $(this).css('background','url("images/backgrounds/video_overlay.png") bottom no-repeat');
          $(this).parent().next().find('a').css('color','#003356');
        }
      );

      $('.singleVideo h5 a').hover(
        function() {
          $(this).parent().prev().find('a').css('background','url("images/backgrounds/video_overlay.png") top no-repeat');
        },
        function() {
          $(this).parent().prev().find('a').css('background','url("images/backgrounds/video_overlay.png") bottom no-repeat');
          $(this).css('color','#003356');
        }
      );

      $('.selectYearDropdown').hover(
        function() {
          $(this).find('ul').show();
        },
        function() {
          $(this).find('ul').hide();
        }
      );

      $('.faqTitle').click(function(){
        $(this).closest('.faqItem').toggleClass('faqItemOn');
      });

      $('input.jt-search-bar').focus(function(){
        $(this).fadeTo('fast', 0.5);
      });

      $('input.jt-search-bar').blur(function(){
        $(this).fadeTo('fast', 1);
      });

      $('#searchInput, #searchSubmit').focus(function(){
        $(this).parents('#topForm').css({'background-position': '0px -25px'});
      });

      $('#searchInput, #searchSubmit').blur(function(){
       $(this).parents('#topForm').css({'background-position': '0px 0px'});
      });

      $('#searchSubmit').click(function(){
        $(this).parents('#topForm').css({'background-position': '0px -50px'});
      });

      $('#bigSearch, #goBigSearch').focus(function(){
       $(this).closest('.bigSearchContainer').css('background','url("images/backgrounds/big_search_bg.png") no-repeat 180px -35px');
      });
      $('#bigSearch, #goBigSearch').blur(function(){
        $(this).closest('.bigSearchContainer').css('background','url("images/backgrounds/big_search_bg.png") no-repeat 180px 0px');
      });
      $('#goBigSearch').click(function(){
       $(this).closest('.bigSearchContainer').css('background','url("images/backgrounds/big_search_bg.png") no-repeat 180px -70px');
      });

      $('#bigSearch').focus(function() {
        if($(this).val() === $(this).data('placeholder')) {
          $(this).val('');
        }
      });
      $('#bigSearch').blur(function() {
        if($(this).val() === '') {
          $(this).val($(this).data('placeholder'));
        }
      });

      $('#bigSearch').data('placeholder', $('#bigSearch').val());

      $('header nav ul li').hover(
        function() {
          $(this).find('.menuLinks').stop(true,true).slideDown('fast');
        }, 
        function() {
          $(this).find('.menuLinks').stop(true,true).slideUp('fast');
        }
      );

      if($('.fav_bar a').length>0) { $('.fav_bar a').tipsy({gravity: 's', opacity: 1.0}); }

      $('button.normalButton').hover( function() {
        $(this).css('background','#003356');
      }, function() {
        $(this).css('background','#000000');
      });

      $('header nav ul li').hover( function() {
        $(this).find('.menuText').css({
          'padding':'10px 0px 0px 0px',
          'position':'relative',
          'border-top':'4px solid #a8b2b5',
          'z-index':'101',
          'color':'#077fba'
        });
      }, function() {
        $(this).find('.menuText').css({
          'padding':'14px 0px 0px 0px',
          'position':'relative',
          'border-top':'0',
          'z-index':'101',
          'color':'#000'
        });
      });

      $('header nav ul li').hover(function() {
        $(this).find('.withMenu').css('padding','10px 0px 13px 0px');
      }, function() {
        $(this).find('.withMenu').css('padding','14px 0px 0px 0px');
      });

      //header functionality

      $('.sectionLink a').mouseover(function() {
        var sectionLink,
            pos;

        if( $('.articlesList:animated').length > 0) { return; }

        $('.sectionLink.selected').removeClass('selected');
        $('#articlesLists').show();

        sectionLink = $(this).closest('.sectionLink');
        pos = sectionLink.prevAll('.sectionLink').length;

        $('.sectionLink.selected').removeClass('selected');
        sectionLink.addClass('selected');

        $('.articlesListSelected').removeClass('articlesListSelected').hide();
        $('#articlesLists .articlesList:eq(' + pos + ')').addClass('articlesListSelected').show();
      });

      $('#topBox').mouseleave(function() {
        $('#articlesLists').hide();
        $('.sectionLink.selected').removeClass('selected');
      });

      $('.articlesList a[data-tooltip]').live('mouseenter', function() {
        var $el = $(this),
            tipText = $el.attr('data-tooltip'),
            toolTip = $('<div />').addClass('toolTip').append(
              $('<p />').addClass('toolTipText').html( $el.attr('data-tooltip') )
            );

         $('.toolTip').remove();
         toolTip.css({ 'top': ($el.position().top + 5) + 'px' });
         $el.append(toolTip);
         $el.css({ 'z-index': '98' });
         toolTip.show();
      });

      $('.articlesList a[data-tooltip]').live('mouseleave', function() {
        $('.toolTip').remove();
        $(this).css({ 'z-index': 1 });
      });
      //end header functionality

      //archive nav
      $('.archYear').click(function(e){
        var year = $(this).attr('rel');
        $('.archMonth-' + year).toggle();
        e.preventDefault();
      });

      //send article
      $('#sendByEmail').click(function(){
        $.ajax({
          type:'get',
          url:'/otls',
          data: {
            'url': document.URL
          },
          success: function(response) {
            window.addthis_share = {
              url_transforms : {
                add: {
                  otl: response
                }
              }
            };
            return addthis_sendto('email');
          },
          error: function(response) {
            return addthis_sendto('email');
          }
        });
      });

      //comment form
      $('#comment-submit-anon').click(function(e){
        var comment = $('#comment-textarea').val(),
						$container = $('#comment_text_container');

				if($container.val().length) {
					$container.val() == "";
				}

				if(comment.length) {
					$container.val(comment);
				}

        if(comment !== ''){
          $.colorbox({
            width:"auto",
            inline:true,
            href:"#signup",
            scrolling: false,
            'opacity': 0.6,
            onComplete:function(){
              $.colorbox.resize();
            }
          });
        } else {
          alert('Comment cannot be blank');
        }
        e.preventDefault();
      });

      $('#acmWidget').children('.singleBest').removeClass('firstBest');
      $('#acmWidget').children('.singleBest').first().addClass('firstBest');

      // expand/collapse search results
      $('.fname').click(function() {
        var $el = $(this);
        $el.toggleClass('collapsed expanded');
        $el.next('.filters').find('.more').show();
        $el.parent().find('.filters').toggle();
        $el.parent().find('.more-filters').hide();
      });

      $('.more').click(function() {
        $el = $(this);
        $el.parent().next('.more-filters').toggle();
        $el.hide();
      });
    }

    /* END INIT */

    function archive_nav() {
      var currentYear = $('#archive-current-year').val();
      $('.archMonth').hide();
      $('.archMonth-' + currentYear).show();
    }

    function remove_empty_spans() {
      $('.posts > li p > span').each(function() {
        var $el = $(this);
        $el.parent().text( $el.text() );
      });
    }

    function setup_google_plus() {
      var po = document.createElement('script'),
          s = document.getElementsByTagName('script')[0]; 

          po.type = 'text/javascript';
          po.src = 'https://apis.google.com/js/plusone.js';
          po.async = true;
          s.parentNode.insertBefore(po, s);
    }

    function setup_jplayer() {
      var src = {},
      format = document.URL.split('/').pop();
      src.m4v = String($('.video-link').attr('href'));
      $("#jquery_jplayer_1").jPlayer({
        ready: function () {
          $(this).jPlayer("setMedia", src );
        },
        swfPath: "/javascripts/lib",
        supplied: "m4v",
        cssSelectorAncestor: "#jp_container_1",
        solution: "flash, html",
        size: {
          width: (format === 'fulltext' ? '360px' : '220px'),
          height: (format === 'fulltext' ? '255px' : '155px'),
          cssClass: (format === 'fulltext' ? 'jp-video-255p' : 'jp-video-220p')
        },
        repeat: function(event) { // Override the default jPlayer repeat event handler
          if(event.jPlayer.options.loop) {
            $(this).unbind(".jPlayerRepeat").unbind(".jPlayerNext");
            $(this).bind($.jPlayer.event.ended + ".jPlayer.jPlayerRepeat", function() {
              $(this).jPlayer("play");
            });
          } else {
            $(this).unbind(".jPlayerRepeat").unbind(".jPlayerNext");
            $(this).bind($.jPlayer.event.ended + ".jPlayer.jPlayerNext", function() {
              $("#jquery_jplayer_1").jPlayer("play", 0);
            });
          }
        }
      });
    }

    function placeholder() {
      var attr = 'placeholder';
      $('input[' + attr + '!=""]').each(function(idx, el){
          $el = $(el);
          var d = $el.attr(attr);
          if (d === undefined) { return; }
          $el.focus(function onFocus() {
              $el.removeClass(attr);
              if (this.value === d) { this.value = ''; }
          }).blur(function onBlur() {
              $el.addClass(attr);
              if ($.trim(this.value) === '') { this.value = d; }
          });
          $el.blur();
      });
    }

    $(init);
    return app;
} (jQuery));

