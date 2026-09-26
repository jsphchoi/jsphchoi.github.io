// Navbar toggler and site search, adapted from shin.mit.edu (mit-shin-group/web, MIT license)
( function () {
	'use strict';

	var index = null;

	function esc( s ) {
		return String( s ).replace( /[&<>"]/g, function ( c ) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[ c ];
		} );
	}

	// Match q against /search-index.json: [{ title, url, text }]
	function suggest( q ) {
		q = q.toLowerCase();
		var load = index ? Promise.resolve( index ) :
			fetch( '/search-index.json' ).then( function ( r ) { return r.json(); } )
				.then( function ( d ) { index = d; return d; } );
		return load.then( function ( data ) {
			var res = [];
			data.forEach( function ( p ) {
				var pos = p.text.toLowerCase().indexOf( q );
				if ( p.title.toLowerCase().indexOf( q ) >= 0 || pos >= 0 ) {
					var snip = '';
					if ( pos >= 0 ) {
						var s = Math.max( 0, pos - 30 );
						snip = ( s > 0 ? '…' : '' ) + p.text.substr( s, 90 ) + '…';
					}
					res.push( { title: p.title, url: p.url, snip: snip } );
				}
			} );
			return res;
		} );
	}

	function resultsBox( form ) {
		var box = form.querySelector( '.search-results' );
		if ( !box ) {
			box = document.createElement( 'div' );
			box.className = 'search-results';
			form.appendChild( box );
		}
		return box;
	}

	// Toggler opens the menu. Clicking outside the search collapses it.
	document.addEventListener( 'click', function ( e ) {
		var t = e.target.closest ? e.target.closest( '.topbar .navbar-toggler' ) : null;
		if ( t ) {
			var c = document.getElementById( 'navbarNav' );
			if ( c ) { c.classList.toggle( 'show' ); }
			return;
		}
		document.querySelectorAll( '.nav-search' ).forEach( function ( f ) {
			if ( !f.contains( e.target ) ) {
				f.classList.remove( 'expanded' );
				var b = f.querySelector( '.search-results' );
				if ( b ) { b.style.display = 'none'; }
			}
		} );
	} );

	var timer;
	document.addEventListener( 'input', function ( e ) {
		var i = e.target;
		if ( !i.matches || !i.matches( '.nav-search input[type=search]' ) ) { return; }
		var box = resultsBox( i.closest( '.nav-search' ) );
		var q = i.value.trim();
		clearTimeout( timer );
		if ( !q ) { box.style.display = 'none'; box.innerHTML = ''; return; }
		timer = setTimeout( function () {
			suggest( q ).then( function ( res ) {
				box.innerHTML = res.length
					? res.map( function ( r ) {
						return '<a class="search-item" href="' + r.url + '"><b>' + esc( r.title ) + '</b>' +
							( r.snip ? '<span>' + esc( r.snip ) + '</span>' : '' ) + '</a>';
					} ).join( '' )
					: '<div class="search-none">No results</div>';
				box.style.display = 'block';
			} ).catch( function () { box.style.display = 'none'; } );
		}, 150 );
	} );

	document.addEventListener( 'focusin', function ( e ) {
		var i = e.target;
		if ( i.matches && i.matches( '.nav-search input[type=search]' ) ) {
			i.closest( '.nav-search' ).classList.add( 'expanded' );
		}
	} );

	// Magnifier click expands the input. Enter goes to the first result.
	document.addEventListener( 'submit', function ( e ) {
		var form = e.target.closest ? e.target.closest( '.nav-search' ) : null;
		if ( !form ) { return; }
		e.preventDefault();
		var i = form.querySelector( 'input[type=search]' );
		if ( i && getComputedStyle( i ).display === 'none' ) {
			form.classList.add( 'expanded' );
			i.focus();
			return;
		}
		var first = form.querySelector( '.search-item' );
		if ( first ) { window.location = first.getAttribute( 'href' ); }
	} );
}() );
