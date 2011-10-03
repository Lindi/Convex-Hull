package
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import geometry.Line2d;
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class AxisProjection extends Sprite
	{
		private var polygon:Polygon2d ;
		public function AxisProjection()
		{
			super();
			init();
		}
		
		public function init( ):void
		{
			//	Create a polygon
			polygon = new Polygon2d( );
			
			//	Add points to the polygon
			var angle:Number = ( Math.PI / 180 ) * 60 ;
			var scale:Number = 60 ;
			for ( var i:int = 0; i < 6; i++ )
			{
				var alpha:Number = angle * i ;
				var x:Number = Math.cos( alpha ) - Math.sin( alpha ) ;
				var y:Number = Math.sin( alpha ) + Math.cos( alpha ) ; 
				polygon.addVertex( new Vector2d(( x * scale ) + stage.stageWidth/2, ( y * scale ) + stage.stageHeight/2 ));
			}
			
			
			//	Grab the polygon points (should probably name these vertices)
			var points:Vector.<Vector2d> = polygon.vertices ;
			
			//	Sort points by y-coordinate
			for ( i = 1; i < points.length; i++ )
			{
				var j:int = i - 1;
				var point:Vector2d = points[i];
				while ( j >= 0 && Main.lessThan( point, points[j] ))
				{
					var tmp:Vector2d = points[j] ;
					points[j] = point ;
					points[j+1] = tmp ;
					j-- ;
				}
				points[ j+1]= point ;
			}
			
			//	Grab the minimum points
			var min:Vector2d = points[0] ;
			
			//	Sort the rest of the list in order of dot product with the x-axis
			for ( i = 2; i < points.length; i++ )
			{
				j = i - 1 ;
				point = points[i] ;
				while ( j >= 1 && Main.angleLessThan( point, points[j], min ))
				{
					tmp = points[j] ;
					points[j] = point ;
					points[j+1] = tmp ;
					j--;
				}
				
				points[j+1]= point ;
			}
			
			//	Create the collection of polygon edges
			polygon.updateLines();
			
			//	Draw the polygon
			draw( points, graphics ) ;
			
			//	Listen for the mouse move event to highlight the nearest polygon edge
			//	stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener( MouseEvent.MOUSE_MOVE, move ) ;
		}
		
		/**
		 * Draw the polygon 
		 * 
		 */		
		internal static function draw( points:Vector.<Vector2d>, graphics:Graphics ):void
		{
			//	Now the points should be counter clockwise
			//	Draw the polygon
			graphics.clear();
			graphics.lineStyle(1);
			for ( var i:int = 1; i <= points.length; i++ )
			{
				var a:Vector2d = points[i-1] ;
				var b:Vector2d = points[i % points.length] ;
				graphics.moveTo( a.x, a.y ) ;
				graphics.lineTo( b.x, b.y ) ;
			}
		}
		
		
		/**
		 * Mouse move event handler.
		 * Figure out the nearest edge and highlight it 
		 * @param event
		 * 
		 */		
		private function move( event:MouseEvent ):void
		{
			//	The center of the stage
			var w:Number = stage.stageWidth ;
			var h:Number = stage.stageHeight ;

			//	Grab the polygon vertices, normals and edges
			var points:Vector.<Vector2d> = polygon.vertices ;
			var edges:Vector.<Vector2d> = polygon.edges ;
			var normals:Vector.<Vector2d> = polygon.normals ;

			//	What's the mouse location
			var mouse:Vector2d = new Vector2d( event.stageX, event.stageY );
			
			//	Some vector pointers to work with 
			var a:Vector2d, b:Vector2d, c:Vector2d, d:Vector2d ;

			//	Draw the polygon
			graphics.clear();
			graphics.lineStyle( 1, 0x999999 ) ;
			for ( var i:int = 0; i < points.length; i++ )
			{				
				a = points[i] ;
				b = points[(i+1) % points.length] ;
				graphics.moveTo( a.x, a.y ) ;
				graphics.lineTo( b.x, b.y ) ;
			}
			
			//	Grab the polygon's center
			var center:Vector2d = polygon.centroid ;
			
			//	Get the direction from the center of the stage to the mouse
			var direction:Vector2d = mouse.Subtract( center ) ;
			
			//	Displace the direction vector 100 pixels in the normal direction
			var scale:int = 100 ;	

			var unit:Vector2d = direction.clone();
			unit.normalize();
			
			var normal:Vector2d = unit.perp() ;
			graphics.lineStyle( .5, 0xcccccc ) ;
			a = center.Add( new Vector2d( normal.x * scale, normal.y * scale ));
			b = mouse.Add( new Vector2d( normal.x * scale, normal.y * scale ));
			c = new Vector2d();
			d = new Vector2d();
			getEdgeIntersection( a, b, c, d, w, h ) ;
			if ( c != null && d != null )
			{
				graphics.moveTo( c.x, c.y );
				graphics.lineTo( d.x, d.y ) ;
			}
			a = center.Add( new Vector2d( -normal.x * scale, -normal.y * scale ));
			b = mouse.Add( new Vector2d( -normal.x * scale, -normal.y * scale ));
			getEdgeIntersection( a, b, c, d, w, h ) ;
			if ( c != null && d != null )
			{
				graphics.moveTo( c.x, c.y );
				graphics.lineTo( d.x, d.y ) ;
			}
			
			//	Project the vector from the polygon centroid to the extreme vertex
			//	on to the vector from the middle of the polygon to the mouse
			
			//	First, get the extreme vertex and draw it
			var extreme:int = getExtremeIndex( polygon, direction );
			var vertex:Vector2d = polygon.getVertex( extreme ) ;
			graphics.lineStyle( undefined ) ;
			graphics.beginFill( 0xff0000 );
			graphics.drawCircle( vertex.x, vertex.y, 3 ) ;
			graphics.endFill();
			
			//	Get the vector from the center point to the extreme vertex
			var v:Vector2d = vertex.Subtract( center ) ;
			
			//	Take the dot product of that vector onto the direction vector
			//	and divide by the length of the direction vector to get the
			//	length of the projection. 
			var projection:Number = v.dot( direction );
			projection /= direction.length ;
			unit = direction.clone();
			unit.normalize();
			
			//	Draw the projection in red
			graphics.lineStyle(3,0xff0000);
			var p:Number = ( unit.x * projection ) + center.x + ( normal.x * scale ) ;
			var q:Number = ( unit.y * projection ) + center.y + ( normal.y * scale ) ;
			var r:Number = ( -unit.x * projection ) + center.x + ( normal.x * scale ) ;
			var s:Number = ( -unit.y * projection ) + center.y + ( normal.y * scale ) ;
			graphics.moveTo( p, q );
			graphics.lineTo( r, s );
			
			p = ( unit.x * projection ) + center.x + ( -normal.x * scale ) ;
			q = ( unit.y * projection ) + center.y + ( -normal.y * scale ) ;
			r = ( -unit.x * projection ) + center.x + ( -normal.x * scale ) ;
			s = ( -unit.y * projection ) + center.y + ( -normal.y * scale ) ;
			graphics.moveTo( p, q );
			graphics.lineTo( r, s ) ;
			
			//	Now do it in the other direction
			direction.negate();
			extreme = getExtremeIndex( polygon, direction );
			vertex = polygon.getVertex( extreme ) ;
			graphics.lineStyle( undefined ) ;
			graphics.beginFill( 0xff0000 );
			graphics.drawCircle( vertex.x, vertex.y, 3 ) ;
			graphics.endFill();

			v = vertex.Subtract( center ) ;
			projection = v.dot( direction );
			projection /= direction.length ;
			unit = direction.clone();
			unit.normalize();
			
			//	Draw the projection in red
			graphics.lineStyle(3,0xff0000);
			p = ( unit.x * projection ) + center.x + ( normal.x * scale ) ;
			q = ( unit.y * projection ) + center.y + ( normal.y * scale ) ;
			r = ( -unit.x * projection ) + center.x + ( normal.x * scale ) ;
			s = ( -unit.y * projection ) + center.y + ( normal.y * scale ) ;
			graphics.moveTo( p, q );
			graphics.lineTo( r, s ) ;
			p = ( unit.x * projection ) + center.x + ( -normal.x * scale ) ;
			q = ( unit.y * projection ) + center.y + ( -normal.y * scale ) ;
			r = ( -unit.x * projection ) + center.x + ( -normal.x * scale ) ;
			s = ( -unit.y * projection ) + center.y + ( -normal.y * scale ) ;
			graphics.moveTo( p, q );
			graphics.lineTo( r, s ) ;
			
			//	Now draw a line from the center to the mouse
			graphics.lineStyle( .5, 0x999999 ) ;
			graphics.moveTo( center.x, center.y ) ;
			graphics.lineTo( mouse.x, mouse.y ) ;
			
			//	Draw a border
//			graphics.lineStyle( 1, 0x999999 ) ;
//			graphics.drawRect( 0, 0, stage.stageWidth-1, stage.stageHeight-1 );
			
		}
		
		
		/**
		 * Returns the intersection of a line defined by points a and b with the
		 * specified edge 
		 * @param a - line endpoint
		 * @param b - line endpoint
		 * @param edge - String describing an edge
		 * @return 
		 * 
		 */		
		internal static function getEdgeIntersection( a:Vector2d, b:Vector2d, c:Vector2d, d:Vector2d, w:Number, h:Number ):void 
		{
			var intersection:Vector2d ;
			
			//	Get the intersection with the top edge
			intersection = getLineIntersection( a, b, new Vector2d(), new Vector2d( w, 0));
			if ( intersection == null )
			{
				//	Get the intersection with the left edge
				intersection = getLineIntersection( a, b, new Vector2d(), new Vector2d( 0, h));
			}
			c.x = intersection.x ;
			c.y = intersection.y ;
			
			//	Get the intersection with the bottom edge
			intersection = getLineIntersection( a, b, new Vector2d(0,h), new Vector2d( w, h));
			if ( intersection == null )
			{
				//	Get the intersection with the right edge
				intersection = getLineIntersection( a, b, new Vector2d(w,0), new Vector2d( w, h));
			}
			d.x = intersection.x ;
			d.y = intersection.y ;
		}
		
		/**
		 * Given two pairs of points, each of which define a line segment, find the intersection between
		 * the points 
		 * @param a
		 * @param b
		 * @param c
		 * @param d
		 * @return 
		 * 
		 */		
		internal static function getLineIntersection( a:Vector2d, b:Vector2d, c:Vector2d, d:Vector2d ):Vector2d
		{
			var determinant:Number = (( a.x - b.x ) * ( c.y - d.y )) - (( a.y - b.y ) * ( c.x - d.x ));
			if ( determinant == 0 )
				return null ;
			var x:Number = (( a.x * b.y - b.x * a.y ) * ( c.x - d.x ) - ( a.x - b.x ) * ( c.x * d.y - d.x * c.y ))/ determinant ;
			var y:Number = (( a.x * b.y - b.x * a.y ) * ( c.y - d.y ) - ( a.y - b.y ) * ( c.x * d.y - d.x * c.y ))/ determinant ;
			return new Vector2d( x, y ) ;
		}

		
		/**
		 * Returns the extreme index of the polygon 
		 * @param polygon
		 * @return 
		 * 
		 */		
		internal static function getExtremeIndex( polygon:Polygon2d, direction:Vector2d ):int
		{
			var i:int, j:int = 0 ;
			while ( true ) 
			{
				var mid:int = getMiddleIndex( i, j, polygon.vertices.length );
				if ( polygon.getEdge( mid ).dot( direction ) > 0 )
				{
					if ( i != mid )
					{
						i = mid ;
					} else
					{
						return j ;
					}
				} else {
					if ( polygon.getEdge( mid-1 ).dot( direction ) < 0 )
					{
						j = mid ;
					} else {
						
						return mid ;
					}
				}
			}
			return 0 ;
		}
		
		/**
		 * Returns the index 'between' i and j 
		 * @param i
		 * @param j
		 * 
		 */		
		internal static function getMiddleIndex( i:int, j:int, n:int ):int
		{
			if ( i < j )
				return int( i + j ) / 2 ;
			return int(( i + j + n ) / 2 ) % n ;
		}
	}
}