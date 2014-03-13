beats = {};

beats._where = { orig:'where are you?', options: [ 'At SXSW', 'On 6th St', 'The Convention Center', 'Bar 96', 'Stubbs', 'Karma Lounge' ], value: '' };
beats._feel = { orig: 'doing what?', options: [ 'Getting Weird', 'Getting Lucky', 'Rocking Out', 'Dancing', 'Partying', 'Getting Jiggy Wit It' ], value: '' };
beats._with = { orig: 'with whom?', options: [ 'My Homies', 'My Pedicab Driver', 'Myself', 'Austin\'s Finest', 'Your Mom', 'Beautiful People' ], value: '' };
beats._who = { orig: 'which artist?', options: [ 'BANKS', 'DZ Deathrays', 'Kendrick Lamar', 'Phantogram', 'Talib Kweli', 'Zedd' ], value: '' };
beats._inputDefault = "write something";

beats.curOptionId = null;

beats.addHandlers = function() {
	beats.$main.find('div.action').each( function( index, elem ) {
		$(elem).click( beats.onOptionClicked );
	});
	
	beats.$author.find('input').click( function( e ) {
		if ( $(this).val() === beats._inputDefault ) {
			$(this).val('');
		}
		e.stopPropagation();
		return false;
	});

	beats.$author.find('.input-holder i').click( function( e ) {
		var $input = $(this).prev();
		if ( $input.val() === beats._inputDefault ) {
			$input.val('');
		}
		$input.focus();
		e.stopPropagation();
		return false;
	});

	$('div.tweet').click( function() {
		var url = 'http://sentenceshare.beatsmusic.com/test.html/card?where=' + beats.getText('where') + '&what=' + beats.getText('feel') + '&who=' + beats.getText('with') + '&artist=' + beats.getText('who');
		console.log( 'tweet, url:',url );
		//window.location.replace( url );
	});

	beats.$author.click( beats.showMainScreen );
	beats.$author.find('div.option').click( beats.setOptionValue );

	// 'write something' input keypress
	beats.$input.bind( "keypress", function(e){
		if ( e.charCode === 13 ) {
	    	beats[ "_" + beats.curOptionId ].value = $(this).val();
	    	beats.showMainScreen();
	    } 
	});

	// 'write something' input blur
	beats.$input.bind( "blur", function(e){
		beats[ "_" + beats.curOptionId ].value = $(this).val();
	    beats.showMainScreen();
	});

	beats.$input.bind( "onsubmit", function(e){
		beats.showMainScreen();
		console.log( 'onsubmit e:',e.charCode );
	});
};

beats.getText = function ( section ) {
	var data = beats[ '_' + section ];
	var str;
	var str = ( data.value === '' || data.value === data.orig ) ? data.orig.toUpperCase() : data.value.toUpperCase();
	return encodeURIComponent( str );
};

beats.transition = function( screen ) {
	if ( screen === 'main' ) {
		beats.$main.find('div.action').each( function( index, elem ) {
			$(elem).removeClass( 'hidden' );
		});
	}
	else if  ( screen === 'author' ) {

	}
};

beats.setOptionValue = function( e ) {
	console.log('e:',e);
	var elem = e.target;
	if ( elem.tagName.toLowerCase() === 'div' ) {
		beats[ "_" + beats.curOptionId ].value = $(elem).text();
		beats.showMainScreen();	
	}
	
	e.stopPropagation();
	return false;
};

beats.onOptionClicked = function( e ) {
	var elem = e.target;
	var $elem = $( elem );
	if ( $elem[0].tagName.toLowerCase() !== "div" ) {
		elem = $elem.parent()[0];
	}
	beats.showAuthoringScreen( elem );
};

beats.showAuthoringScreen = function ( elem ) {
	var $elem = $(elem);
	var $input = beats.$author.find('input');
	var $icon = beats.$author.find('i');

	beats.curOptionId = $elem.attr('id');
	beats.$author.find('span.static').text( $elem.prev().text() );
	$input.val( beats._inputDefault );

	var options = beats[ '_' + beats.curOptionId ].options;
	beats.$author.find('div.option').each( function (index, elem) {
		$(elem).text( options[index] );
	});

	beats.showScreen( 'author' );
};

beats.showMainScreen = function () {
	beats.$main.find('div.action').each( function (index, elem) {
		var id = $(elem).attr('id');
		var data = beats['_'+id];
		var textValue = ( data.value !== '' &&  data.value !== data.orig ) ? data.value : data.orig;
		$(elem).text( textValue )
	});

	beats.showScreen( 'main' );
}

beats.showScreen = function ( screen ) {
	switch ( screen ) {
	case 'main':
		beats.$main.removeClass( 'hidden' );
		beats.$tweet.removeClass( 'hidden' );
		beats.$author.addClass( 'hidden' );
		break;
	case 'author':
		beats.$main.addClass( 'hidden' );
		beats.$tweet.addClass( 'hidden' );
		beats.$author.removeClass( 'hidden' );
		break;
	}
}

$(document).ready(function() {
	beats.$main = $('div.main-screen');
	beats.$author = $('div.author-screen');
	beats.$input = beats.$author.find('input');
	beats.$tweet = $('div.tweet');

	beats.addHandlers();
	beats.transition( 'main' );
	beats.showMainScreen();
});