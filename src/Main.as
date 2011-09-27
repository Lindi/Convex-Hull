package
{
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Timer;
	
	import org.osmf.events.TimeEvent;
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class Main extends Sprite
	{
		private var points:Vector.<Point> = new Vector.<Point>( ) ;
		private var min:Point  ;	
		
		public function Main()
		{
			//	Add a bunch of points 
			var margin:int = 20 ;
			var n:int = int( Math.random() * 40 ) + 20 ;
			for ( var i:int = 0; i < n; i++ )
			{
				var x:int = margin + int( Math.random() * ( stage.stageWidth - margin ));
				var y:int = margin + int( Math.random() * ( stage.stageHeight - margin ));
				var point:Point = new Point( x, y );
				points.push( point );
			}
			
			//	Sort points lexicographically
			for ( i = 1; i < points.length; i++ )
			{
				var j:int = i - 1;
				point = points[i];
				while ( j >= 0 && lessThan( point, points[j] ))
				{
					var tmp:Point = points[j] ;
					points[j] = point ;
					points[j+1] = tmp ;
					j-- ;
				}
				
				points[ j+1]= point ;
			}
			

			
			//	Grab the minimum point, which is the first in the list
			min = points[0] ;
			
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
			
			var clone:Vector.<Point> = new Vector.<Point>( points.length );
			for ( i=0; i <points.length; i++)
			{
				clone[i] = points[i].clone();
			}
			convexHull( points, clone );
		
/*			//	Determine the convex hull
			var m:int = 2 ;
			n = points.length ;
			for ( i = 3; i < n; i++ )
			{
				if ( i >= points.length )
					break ;
				while ( ccw( points[m-1], points[m], points[i] ) <= 0 )
				{
					if ( m == 2 )
					{
						tmp = points[m] ;
						points[m] = points[i] ;
						points[i] = tmp ;
						i++ ;
						trace("i(ccw)", i, m);
					} else {
						m-- ;
						trace("i(m--)", i, m);
					}
				}
				m++ ;
				tmp = points[ m ] ;
				points[m] = points[i] ;
				points[i] = tmp ;
			}
			
			// Plot the points
			graphics.clear();
			plot( points ) ;
			
			//	Draw the convex hull
			graphics.lineStyle(1,0xff0000);
			for ( i = 0; i < points.length-1; i++ )
			{
				var a:Point = points[i] ;
				var b:Point = points[i+1] ;
				graphics.moveTo( a.x, a.y );
				graphics.lineTo( b.x, b.y );
			}
			
			b = points[0] ;
			graphics.moveTo( a.x, a.y );
			graphics.lineTo( b.x, b.y );
*/			
		}
		
		private function convexHull( points:Vector.<Point>, clone:Vector.<Point> ):void
		{
			var m:int = 2 ;
			var n:int = points.length ;
			var i:int = 3 ;
			var tmp:Point ;
			var timer:Timer = new Timer( 250 );
			timer.addEventListener(TimerEvent.TIMER,
				function ( event:TimerEvent ):void
				{
					if ( i >= points.length )
					{
						timer.removeEventListener( TimerEvent.TIMER, arguments.callee );
						timer.stop();
						points[m+1] = min ;
						foo( points, clone, m+1 );
						graphics.moveTo( min.x, min.y );
						graphics.lineTo( points[1].x, points[1].y );
						plot( clone );
						return ;
					}
					while ( ccw( points[m-1], points[m], points[i] ) >= 0 )
					{
						if ( m == 2 )
						{
							tmp = points[m] ;
							points[m] = points[i] ;
							points[i] = tmp ;
							i++ ;
							foo( points, clone, m );
							plot( clone );
						} else {
							m-- ;
							foo( points, clone, m );
							plot( clone );
						}
					}
					m++ ;
					tmp = points[ m ] ;
					points[m] = points[i] ;
					points[i] = tmp ;
					i++;
					foo( points, clone, m );
					plot( clone );
					
					
				});
			timer.start();
		}
		
		private function foo( points:Vector.<Point>, clone:Vector.<Point>, m:int  ):void
		{
			graphics.clear();
			graphics.lineStyle(1,0xff0000);
			for ( var j:int = 1; j < m; j++ )
			{
				var a:Point = points[j];
				var b:Point = points[j+1];
				graphics.moveTo( a.x, a.y );
				graphics.lineTo( b.x, b.y );
			}
			
		}
		
		/**
		 * Plot points with vectors 
		 * @param points
		 * 
		 */		
		private function plot( points:Vector.<Point> ):void
		{
			//	Draw the points
			graphics.lineStyle( undefined );
			for each ( var point:Point in points )
			{
				graphics.beginFill( 0x0000ff );
				graphics.drawCircle( point.x, point.y, 3 );
				graphics.endFill() ;
			}
			
		}
		
		/**
		 * Draw the points 
		 * @param points
		 * 
		 */		
		private function draw( points:Vector.<Point> ):void
		{
			plot( points );
			
			//	Draw the convex hull
			graphics.lineStyle(1,0xff0000);
			for ( var i:int = 0; i < points.length-1; i++ )
			{
				var a:Point = points[i] ;
				var b:Point = points[i+1] ;
				graphics.moveTo( a.x, a.y );
				graphics.lineTo( b.x, b.y );
			}
			
			
		}
		
		/**
		 * Three points are counter clockwise if ccw < 0
		 * Three points are clockwise if ccw > 0, and they're
		 * collinear if ccw == 0 
		 * @param a
		 * @param b
		 * @param c
		 * @return 
		 * 
		 */		
		private function ccw( a:Point, b:Point, c:Point ):Number 
		{
			return ( b.x - a.x ) * ( c.y - a.y ) - ( b.y - a.y ) * ( c.x - a.x );
		}
		
		/**
		 * Sort the points.  Use bubble sort to sort the
		 * points by dot product
		 * @param points
		 * 
		 */		
		private function sort( points:Vector.<Point> ):void
		{
			for ( var i:int = 1; i < points.length; i++ )
			{
				var j:int = i-1;
				var point:Point = points[ i ] ;
				while ( j >= 0 && angleLessThan( point, points[j], min ))
				{
					var tmp:Point = point ;
					points[ i ] = points[ j ] ;
					points[ j ] = tmp ;
					j-- ;
				}
				points[ j+1] = point ;
			}
		}
		
		/**
		 * Returns true of a.y is less than b.y or
		 * if a.x is less than b.x
		 * @param a
		 * @param b
		 * 
		 */		
		private function lessThan( a:Point, b:Point ):Boolean
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
		private function angleLessThan( a:Point, b:Point, min:Point ):Boolean
		{
			var ax:Number = ( a.x - min.x ) ;
			var ay:Number = ( a.y - min.y ) ;
			var bx:Number = ( b.x - min.x ) ;
			var by:Number = ( b.y - min.y ) ;
			
			return ( ax/Math.sqrt(ax * ax + ay * ay) < bx/Math.sqrt(bx * bx + by * by));
		}
		
		/**
		 * Returns the dot product of one point with another
		 * @param a
		 * @param b
		 * @return 
		 * 
		 */		
		private function dot( a:Point, b:Point ):Number
		{
			return ( a.x * b.x + a.y * b.y );
		}
	}
}