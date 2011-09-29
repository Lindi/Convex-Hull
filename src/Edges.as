package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Timer;
	
	import geometry.Line2d;
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class Edges extends Sprite
	{
		private var polygon:Polygon2d ;
		private var timer:Timer ;
		
		public function Edges()
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
			
			//	Sort points lexicographically
			for ( i = 1; i < points.length; i++ )
			{
				var j:int = i - 1;
				var point:Vector2d = points[i];
				while ( j >= 0 && lessThan( point, points[j] ))
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
				while ( j >= 1 && angleLessThan( point, points[j], min ))
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
			draw( points ) ;
			
			//	Listen for the mouse move event to highlight the nearest polygon edge
			//	stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener( MouseEvent.CLICK, click ) ;
		}
		
		/**
		 * Click event handler 
		 * @param event
		 * 
		 */		
		private function click( event:MouseEvent ):void
		{
			if ( timer != null )
				return ;
			
			//	Store the mouse
			var mouse:Vector2d = new Vector2d( event.stageX, event.stageY );
			
			//	Store a point representing the middle of the polygon
			var center:Vector2d = polygon.centroid ;
			
			//	Make a vector from the centroid to the mouse
			var direction:Vector2d = mouse.Subtract( center ) ;
			
			//	Initialize indices for the extreme vertex calculation
			var i:int, j:int = 0 ;
			
			drawPolygonEdges( i , j );
			graphics.lineStyle(1,0x0000ff);
			graphics.moveTo( center.x, center.y );
			graphics.lineTo( mouse.x, mouse.y ) ;

			//	Create a timer that performs the extreme vertex calculation
			timer = new Timer( 500 ) ;
			timer.addEventListener( TimerEvent.TIMER, 
				function ( event:TimerEvent ):void
				{
					var mid:int = getMiddleIndex( i, j, polygon.vertices.length );
					var terminate:Boolean = false ;
					if ( polygon.getEdge( mid ).dot( direction ) > 0 )
					{
						if ( i != mid )
						{
							i = mid ;
						} else
						{
							j = mid ;
							terminate = true ;
						}
					} else {
						if ( polygon.getEdge( mid ).dot( direction ) < 0 )
						{
							if ( j != mid )
							{
								j = mid ;
							} else {
								
								i = mid ;
								terminate = true ;
							}
						}
					}
					
					drawPolygonEdges( i , j );
					graphics.lineStyle(1,0x0000ff);
					graphics.moveTo( center.x, center.y );
					graphics.lineTo( mouse.x, mouse.y ) ;
					if ( terminate )
					{
						graphics.lineStyle( undefined ) ;
						graphics.beginFill( 0x00aaff );
						graphics.drawCircle( polygon.getVertex( mid ).x, polygon.getVertex( mid ).y, 4 );
						graphics.endFill();
						
						timer.stop();
						timer.removeEventListener(TimerEvent.TIMER,arguments.callee );
						timer = null ;
					}
				});
			timer.start();
		}
		
		/**
		 * Draws the polygon and highlights the edges corresponding
		 * to the specified indices 
		 * @param i
		 * @param j
		 * 
		 */		
		private function drawPolygonEdges( m:int, n:int ):void
		{
			graphics.clear();
			var vertices:Vector.<Vector2d> = polygon.vertices ;
			var normals:Vector.<Vector2d> = polygon.normals ;
			for ( var i:int = 0; i < vertices.length; i++ )
			{
				if ( i == m )
					graphics.lineStyle(2,0x00ff00);
				else if ( i == n )
					graphics.lineStyle(2,0xff0000);
				else graphics.lineStyle(2);
				
				var a:Vector2d = vertices[i] ;
				var b:Vector2d = vertices[(i+1) % vertices.length] ;
				graphics.moveTo( a.x, a.y ) ;
				graphics.lineTo( b.x, b.y ) ;
				
				var x:Number = a.x + ( b.x - a.x )/2 ;
				var y:Number = a.y + ( b.y - a.y )/2 ;
				var dx:Number = normals[i].x * 5 ;
				var dy:Number = normals[i].y * 5 ;
				graphics.moveTo( x, y );
				graphics.lineTo( x + dx, y + dy );
			}
		}
		
		/**
		 * Returns the index 'between' i and j 
		 * @param i
		 * @param j
		 * 
		 */		
		private function getMiddleIndex( i:int, j:int, n:int ):int
		{
			if ( i < j )
				return int( i + j ) / 2 ;
			return int(( i + j + n ) / 2 ) % n ;
		}
		
		/**
		 * Mouse move event handler.
		 * Figure out the nearest edge and highlight it 
		 * @param event
		 * 
		 */		
		private function mouseMove( event:MouseEvent ):void
		{
			//	What's the mouse location
			var mouse:Vector2d = new Vector2d( event.stageX, event.stageY );
			
			//	Find the nearest line to the polygon
			var points:Vector.<Vector2d> = polygon.vertices ;
			var edges:Vector.<Vector2d> = polygon.edges ;
			var normals:Vector.<Vector2d> = polygon.normals ;
			var min:Number = Number.MAX_VALUE ;
			var minIndex:int ;
			for ( var i:int = 0; i < points.length; i++ )
			{				
				//	Grab the points on each line segment
				var a:Vector2d = points[i] ;
				var b:Vector2d = points[(i+1) % points.length] ;
				
				var distance:Number = SquaredDistanceToLineSegment( a, b, mouse ) ;
				if ( distance < min )
				{
					min = distance ;
					minIndex = i ;
				}
			}
			
			
			//	Draw the polygons with outward-facing edge normals
			graphics.clear();
			for ( i = 0; i < points.length; i++ )
			{
				if ( i == minIndex )
					graphics.lineStyle(1,0x00ff00);
				else graphics.lineStyle(1);
				
				a = points[i] ;
				b = points[(i+1) % points.length] ;
				graphics.moveTo( a.x, a.y ) ;
				graphics.lineTo( b.x, b.y ) ;
								
				var x:Number = a.x + ( b.x - a.x )/2 ;
				var y:Number = a.y + ( b.y - a.y )/2 ;
				var dx:Number = normals[i].x * 5 ;
				var dy:Number = normals[i].y * 5 ;
				graphics.moveTo( x, y );
				graphics.lineTo( x + dx, y + dy );
				
			}
			
			//	Draw a line defined by the mouse location and the 
			//	center of the polygon from an edge of the stage to the center of the polygon
			var w:Number = stage.stageWidth ;
			var h:Number = stage.stageHeight ;
			var center:Vector2d = polygon.centroid ;
			a = getEdgeIntersection( mouse, center, "left" );
			if ( a == null )
				a = getEdgeIntersection( mouse, center, "top" );
			b = getEdgeIntersection( mouse, center, "right" );
			if ( b == null )
				b = getEdgeIntersection( mouse, center, "bottom" );
			
			if ( a != null && b != null )
			{
				graphics.moveTo( a.x, a.y );
				graphics.lineTo( b.x, b.y ) ;
			}
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
		private function getEdgeIntersection( a:Vector2d, b:Vector2d, edge:String ):Vector2d
		{
			var w:Number = stage.stageWidth ;
			var h:Number = stage.stageHeight ;
			
			switch ( edge )
			{
				case "top":
					return getLineIntersection( a, b, new Vector2d(), new Vector2d( w, 0));
				case "left":
					return getLineIntersection( a, b, new Vector2d(), new Vector2d( 0, h));
				case "bottom":
					return getLineIntersection( a, b, new Vector2d(0,h), new Vector2d( w, h));
				case "right":
					return getLineIntersection( a, b, new Vector2d(w,0), new Vector2d( w, h));
			}
			return null ;
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
		private function getLineIntersection( a:Vector2d, b:Vector2d, c:Vector2d, d:Vector2d ):Vector2d
		{
			var cross:Number = (( a.x - b.x ) * ( c.y - d.y )) - (( a.y - b.y ) * ( c.x - d.x ));
			if ( cross == 0 )
				return null ;
			var x:Number = (( a.x * b.y - b.x * a.y ) * ( c.x - d.x ) - ( a.x - b.x ) * ( c.x * d.y - d.x * c.y ))/ cross ;
			var y:Number = (( a.x * b.y - b.x * a.y ) * ( c.y - d.y ) - ( a.y - b.y ) * ( c.x * d.y - d.x * c.y ))/ cross ;
			return new Vector2d( x, y ) ;
		}

		/**
		 * Returns the square of the distance of a point to a line segment 
		 * @param a
		 * @param b
		 * @param c
		 * @return 
		 * 
		 */		
		private function SquaredDistanceToLineSegment( a:Vector2d, b:Vector2d, c:Vector2d ):Number 
		{
			var ab:Vector2d = b.Subtract(a);
			var ac:Vector2d = c.Subtract(a);
			var bc:Vector2d = c.Subtract(b);

			//	If the projection of c falls before point a
			var e:Number = ac.dot(ab);
			if ( e <= 0 )
				return ac.dot(ac);
			
			//	If the projection of c falls after point b ;
			var f:Number = ab.dot(ab);
			if ( e >= f )
				return bc.dot(bc);
			
			//	Return the squared distance from ab to c
			return ac.dot(ac) - ( e * e / f );
		}
		
		/**
		 * Draw the polygon 
		 * 
		 */		
		private function draw( points:Vector.<Vector2d> ):void
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
		 * Returns true of a.y is less than b.y or
		 * if a.x is less than b.x
		 * @param a
		 * @param b
		 * 
		 */		
		private function lessThan( a:Vector2d, b:Vector2d ):Boolean
		{
			if ( a.y < b.y )
				return true ;
			return false ;
		}

		/**
		 * Returns true if the dot product of point a with point min
		 * is less than the dot product of point b with min 
		 * @param a
		 * @param b
		 * @param min
		 * 
		 */		
		private function angleLessThan( a:Vector2d, b:Vector2d, min:Vector2d ):Boolean
		{
			var ax:Number = ( a.x - min.x ) ;
			var ay:Number = ( a.y - min.y ) ;
			var bx:Number = ( b.x - min.x ) ;
			var by:Number = ( b.y - min.y ) ;
			return ( ax/Math.sqrt(ax * ax + ay * ay) < bx/Math.sqrt(bx * bx + by * by));
		}
	}
}