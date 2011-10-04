package
{
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import geometry.AABB;
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	[SWF(width='600',height='600',backgroundColor='#71969f')]
	public class SeparatingAxes extends Sprite
	{
		private var polygon:Polygon2d ;
		private var polygons:Vector.<Polygon2d> = new Vector.<Polygon2d>(2,true);
		private var velocity:Vector.<Vector2d> = new Vector.<Vector2d>(2,true);
		private var colors:Vector.<Number> = new Vector.<Number>(2,true);
		private var sprites:Vector.<Sprite> = new Vector.<Sprite>(2,true);
		private var omega:Number = 0 ;
		private var backgroundColor:Number ;
		private var intersect:Boolean ;
		
		public function SeparatingAxes()
		{
			super();
			init();
		}
		
		private function init():void
		{
			//	Create two polygons
			var margin:int = 20 ;
			var sprite:Sprite ;
			var dx:Number, dy:Number ;
			var centroid:Vector2d = new Vector2d( stage.stageWidth/2, stage.stageHeight/2 ) ;//new Vector2d( margin + int( Math.random() * ( stage.stageWidth-margin * 2) ), margin + int( Math.random() * (stage.stageHeight-margin*2)));
			polygons[0] = createPolygon( centroid );
			dx = 2 + int( Math.random() * 3 ) * ( 1 - 2 * int( Math.random() * 2 ));
			dy = 2 + int( Math.random() * 3 ) * ( 1 - 2 * int( Math.random() * 2 ));
			velocity[0] = new Vector2d( dx, dy );
			colors[0] = 0xd71921 ;
			sprites[0] = sprite = new Sprite();
			//sprite.blendMode = BlendMode.ADD ;
			addChild( sprite ) ;
			
			centroid = new Vector2d( stage.stageWidth/2, stage.stageHeight/2 ) ;//new Vector2d( margin + int( Math.random() * ( stage.stageWidth-margin * 2)), margin + int( Math.random() * (stage.stageHeight-margin*2)));
			polygons[1] = createPolygon( centroid );
			dx = 2 + int( Math.random() * 3 ) * ( 1 - 2 * int( Math.random() * 2 ));
			dy = 2 + int( Math.random() * 3 ) * ( 1 - 2 * int( Math.random() * 2 ));
			velocity[1] = new Vector2d( dx, dy );
			colors[1] = 0x00324d ;
			sprites[1] = sprite = new Sprite();
			//sprite.blendMode = BlendMode.ADD ;
			addChild( sprite ) ;
			

			
			//	Enter frame draws everything
			addEventListener( Event.ENTER_FRAME, frame );
			
			
		}
		
		private function getAABB( polygon:Polygon2d ):AABB 
		{
			var xmin:Number = Number.MAX_VALUE ;
			var ymin:Number = Number.MAX_VALUE ;
			var xmax:Number = Number.MIN_VALUE ;
			var ymax:Number = Number.MIN_VALUE ;
			for each ( var vertex:Vector2d in polygon.vertices )
			{
				xmin = Math.min( xmin, vertex.x );
				xmax = Math.max( xmax, vertex.x );
				ymin = Math.min( ymin, vertex.y );
				ymax = Math.max( ymax, vertex.y );
			}
			var aabb:AABB = new AABB( xmin, ymin, xmax, ymax );
			return aabb ;
		}
		
		
		private function frame( event:Event ):void
		{
			//	Update the "angular velocity"
			omega += 10 ;
			omega %= 360 ;
			
			intersect = true ;
			var xmin:Number = Number.MAX_VALUE ;
			var ymin:Number = Number.MAX_VALUE ;
			var xmax:Number = Number.MIN_VALUE ;
			var ymax:Number = Number.MIN_VALUE ;
			for ( var i:int = 0; i < polygons.length; i++)
			{
				var graphics:Graphics = sprites[i].graphics ;
				graphics.clear();
				
				//	Get a reference to the polygon
				var polygon:Polygon2d = polygons[i] ;
				
				//	Get the AABB
				var aabb:AABB = getAABB( polygon ) ;
				xmin = Math.min( xmin, aabb.xmin );
				xmax = Math.max( xmax, aabb.xmax );
				ymin = Math.min( ymin, aabb.ymin );
				ymax = Math.max( ymax, aabb.ymax ) ;
				
				
				//	Get the centroid
				var centroid:Vector2d = polygon.centroid.clone() ;
				
				//	Wrap the polygon position if it's offstage
				if ( aabb.xmax < 0 )
					centroid.x = stage.stageWidth + ( centroid.x - aabb.xmin ) - 1;
				if ( aabb.xmin > stage.stageWidth )
					centroid.x = ( centroid.x - aabb.xmax + 1 );
				if ( aabb.ymax < 0 )
					centroid.y = stage.stageHeight + ( centroid.y - aabb.ymin ) - 1;
				if ( aabb.ymin > stage.stageHeight )
					centroid.y = ( centroid.y - aabb.ymax + 1 );
				
				//	Move the polygons
				centroid.x += velocity[i].x ;
				centroid.y += velocity[i].y ;
				
				//	Rotate the polygons
				var vertices:Vector.<Vector2d> = polygon.vertices ;
				//var angle:Number = ( Math.PI / 180 ) * ( 360 / vertices.length ) ;
				//var scale:Number = 60 ;
				for ( var j:int = 0; j < vertices.length; j++ )
				{
					var alpha:Number = Math.PI / 90 ;//( angle * j ) + omega ;
					var vertex:Vector2d = vertices[j] ;	
					vertex.x -= polygon.centroid.x ;
					vertex.y -= polygon.centroid.y ;
					var x:Number = vertex.x * Math.cos( alpha ) - vertex.y * Math.sin( alpha ) ;
					var y:Number = vertex.x * Math.sin( alpha ) + vertex.y * Math.cos( alpha ) ; 
					vertex.x = x + centroid.x ;
					vertex.y = y + centroid.y ;
				}
				

				polygon.centroid.x = centroid.x ;
				polygon.centroid.y = centroid.y ;
								
				//	Update their lines
				polygon.updateLines();
				
				//	Draw their separation
				separateAxes( polygons[i % 2], polygons[(i+1) % 2], colors[ i % 2], colors[(i+1) % 2], graphics );
				
			}
			
			this.graphics.clear();
			if ( intersect  )
			{
				//	Fill with background color
				this.graphics.beginFill( 0x55808b ) ;
				this.graphics.drawRect( xmin, ymin, xmax-xmin, ymax - ymin );
				this.graphics.endFill();				
			}

			
		}
		/**
		 * Determines the overlap, if any, of two line segments on the same line
		 * Line segment p is defined by the points a and b
		 * Line segment q is defined by the points c and d
		 * @param a
		 * @param b
		 * @param c
		 * @param d
		 * @return 
		 * 
		 */		
		private function getLineSegmentOverlap( a:Vector2d, b:Vector2d, c:Vector2d, d:Vector2d ):Array
		{
			//	Does point c fall on the line segment ab?
			var epsilon:Number = .00001;
			var array:Array = new Array();
			var segments:Array = [[a,b],[c,d]];
			for ( var i:int = 0; i < 4; i++ )
			{
				var index:int = ((int( i/2 ) + 1) % 2 );
				var segment:Array = segments[ index ] ;
				var p:Vector2d = segments[(( index + 1 ) % 2 )][ i % 2] ;
				var u:Vector2d = segment[0] as Vector2d ;
				var v:Vector2d = segment[1] as Vector2d ;
				
				var crossProduct:Number = ( p.y - u.y ) * ( v.x - u.x ) - ( p.x - u.x ) * ( v.y - u.y ) ;
				if ( crossProduct <= epsilon )
				{
					var dotProduct:Number = ( p.x - u.x ) * ( v.x - u.x ) + ( p.y - u.y ) * ( v.y - u.y );
					var squaredLength:Number = ( v.x - u.x ) * ( v.x - u.x ) + ( v.y - u.y ) * ( v.y - u.y ) ;
					if ( dotProduct > 0 && dotProduct < squaredLength )
						array.push( p ) ;
				}
			}
			
			if ( array.length )
				return array ;
			return null ;
		}
		
		/**
		 * Creates a polygon with a number of vertices between
		 * 3 and 6 ; 
		 * 
		 */		
		private function createPolygon( centroid:Vector2d ):Polygon2d
		{
			
			//	Create a polygon
			var polygon:Polygon2d = new Polygon2d( );
			
			//	The polygon should have at least 3 and at most six points
			var points:int = 3 + int( Math.random() * 3 );
			
			//	Add points to the polygon
			var angle:Number = ( Math.PI / 180 ) * ( 360 / points ) ;
			var scale:Number = 60 ;
			for ( var i:int = 0; i < points; i++ )
			{
				var alpha:Number = angle * i ;
				var x:Number = Math.cos( alpha ) - Math.sin( alpha ) ;
				var y:Number = Math.sin( alpha ) + Math.cos( alpha ) ; 
				polygon.addVertex( new Vector2d(( x * scale ) + centroid.x, ( y * scale ) + centroid.y ));
			}
			
			//	Grab the polygon points (should probably name these vertices)
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			
			//	Sort vertices by y-coordinate
			for ( i = 1; i < vertices.length; i++ )
			{
				var j:int = i - 1;
				var point:Vector2d = vertices[i];
				while ( j >= 0 && Main.lessThan( point, vertices[j] ))
				{
					var tmp:Vector2d = vertices[j] ;
					vertices[j] = point ;
					vertices[j+1] = tmp ;
					j-- ;
				}
				vertices[ j+1]= point ;
			}
			
			//	Grab the minimum vertices
			var min:Vector2d = vertices[0] ;
			
			//	Sort the rest of the list in order of dot product with the x-axis
			for ( i = 2; i < vertices.length; i++ )
			{
				j = i - 1 ;
				point = vertices[i] ;
				while ( j >= 1 && Main.angleLessThan( point, vertices[j], min ))
				{
					tmp = vertices[j]   ;
					vertices[j] = point ;
					vertices[j+1] = tmp ;
					j--;
				}
				vertices[j+1]= point ;
			}
			
			//	Create the collection of polygon edges
			polygon.updateLines();
			
			//	Return the polygon
			return polygon ;
			
		}
		
		
		private function separateAxes( a:Polygon2d, b:Polygon2d, acolor:Number, bcolor:Number, graphics:Graphics ):void
		{
			//	Go through each edge, and extend the edge to the stage edges	
			var intersections:int = 0 ;
			var edges:Vector.<Vector2d> = a.edges ;
			var vertices:Vector.<Vector2d> = a.vertices ;
			for ( var i:int = 0; i < vertices.length; i++ )
			{
				var edge:Vector2d = edges[i] ;
				var vertex:Vector2d = vertices[i];
				var endpoint:Vector2d = vertex.Add( edge );
				
				//	Add the edge vector to the vertex to get the second point on the line segment
				var c:Vector2d = new Vector2d();
				var d:Vector2d = new Vector2d();
				AxisProjection.getEdgeIntersection( vertex, endpoint, c, d, stage.stageWidth, stage.stageHeight ) ;
				
				//	Draw the line
				graphics.lineStyle(.5,acolor,.6);
				graphics.moveTo( c.x, c.y ) ;
				graphics.lineTo( d.x, d.y ) ;
				
				var index:int = AxisProjection.getExtremeIndex( b, edge );
				var e:Vector2d = ProjectPointOntoLine( c, d, b.vertices[index]);
				index = AxisProjection.getExtremeIndex( b, edge.Negate());
				var f:Vector2d = ProjectPointOntoLine( c, d, b.vertices[index]);

				//	Draw the line
				if ( e != null && f != null )
				{
					graphics.lineStyle(1,bcolor);
					graphics.moveTo( e.x, e.y ) ;
					graphics.lineTo( f.x, f.y ) ;
				}
				
				//	Draw the line
				graphics.lineStyle(3,acolor);
				graphics.moveTo( vertex.x, vertex.y ) ;
				graphics.lineTo( endpoint.x, endpoint.y ) ;

//				//				//	Draw the overlap if any
				var intersection:Array = getLineSegmentOverlap( vertex, endpoint, e, f);
				if ( intersection != null && intersection.length == 2 )
				{
					intersections++ ;
					c = intersection[0] as Vector2d ;
					d = intersection[1] as Vector2d ;
					//	Draw the overlap
					graphics.lineStyle(3,0xfce4a8);
					graphics.moveTo( c.x, c.y ) ;
					graphics.lineTo( d.x, d.y ) ;
				} else {
					intersect = false ;
				}
				

			}
		}
		
		/**
		 * Projects a point q onto the line segment defined by points a and b and
		 * returns the point that is the projection.
		 * See http://cs.nyu.edu/~yap/classes/visual/03s/hw/h2/math.pdf for
		 * the derivation
		 * 
		 * @param a
		 * @param b
		 * @param q
		 * @return 
		 * 
		 */		
		internal static function ProjectPointOntoLine( a:Vector2d, b:Vector2d, q:Vector2d ):Vector2d
		{
			var c:Number = ( b.x - a.x ) ;
			var d:Number = ( b.y - a.y ) ;
			var e:Number = q.x * c + q.y * d ;
			var f:Number = a.y * c - a.x * d ;
			if ( c == 0  )
			{
				//	The line ab is a vertical line, so return the point
				//	that has the same x-value, and the y-value of q
				return new Vector2d( b.x, q.y );
			}
			var y:Number = (( f * c ) + ( d * e ))/ (( c * c ) + ( d * d )) ;
			var x:Number = ( e - ( d * y )) / c ;
			return new Vector2d( x, y ) ;
		}
	}
}