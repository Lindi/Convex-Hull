package
{
	import flash.display.Sprite;
	
	import geometry.Polygon2d;
	import geometry.Vector2d;
	
	[SWF(width='400',height='400',backgroundColor='#ffffff')]
	public class SeparatingAxes extends Sprite
	{
		private var polygon:Polygon2d ;
		private var polygons:Vector.<Polygon2d> = new Vector.<Polygon2d>(2,true);
		
		public function SeparatingAxes()
		{
			super();
			init();
		}
		
		private function init():void
		{
			//	Create two polygons
			var margin:int = 20 ;
			var centroid:Vector2d = new Vector2d( margin + int( Math.random() * ( stage.stageWidth-margin * 2) ), margin + int( Math.random() * (stage.stageHeight-margin*2)));
			polygons[0] = createPolygon( centroid );
			centroid = new Vector2d( margin + int( Math.random() * ( stage.stageWidth-margin * 2)), margin + int( Math.random() * (stage.stageHeight-margin*2)));
			polygons[1] = createPolygon( centroid );
			
			separateAxes( polygons[0], polygons[1] );
			separateAxes( polygons[1], polygons[0] );
			
			
			
//			//	Draw the polygon
//			AxisProjection.draw( points, graphics ) ;
//			
//			//	Let's see if our projection function works
//			var a:Vector2d = new Vector2d( int( Math.random() * stage.stageWidth ), 0 );
//			var b:Vector2d = new Vector2d( int( Math.random() * stage.stageWidth ), stage.stageHeight );
//			var v:Vector2d = new Vector2d( b.x - a.x, b.y - a.y );
//			var c:Vector2d ;
//			{
//				c = new Vector2d( 20 + int( Math.random() * (stage.stageWidth-40) ), 20 + int( Math.random() * (stage.stageHeight-40)));
//			}
//			
//			var d:Vector2d = ProjectPointOntoLine( a, b, c );
//			if ( d != null )
//			{
//				graphics.moveTo( a.x, a.y );
//				graphics.lineTo( b.x, b.y );
//				graphics.moveTo( c.x, c.y );
//				graphics.lineTo( d.x, d.y );
//				graphics.lineStyle( undefined ) ;
//				graphics.beginFill( 0xff0000 );
//				graphics.drawCircle( c.x, c.y, 5 ) ;
//				graphics.endFill();
//			}
			
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
			var pxmin:Number = Math.min( a.x, b.x ) ;
			var pxmax:Number = Math.max( a.x, b.x ) ;
			var pymin:Number = Math.min( a.y, b.y ) ;
			var pymax:Number = Math.max( a.y, b.y ) ;

			var qxmin:Number = Math.min( c.x, d.x ) ;
			var qxmax:Number = Math.max( c.x, d.x ) ;
			var qymin:Number = Math.min( c.y, d.y ) ;
			var qymax:Number = Math.max( c.y, d.y ) ;
			
			if ( qxmin > pxmax || qymin > pymax )
				return null ;
			
			if ( pymin < qymin )
			{
				return [ new Vector2d( qxmin, qymin ), new Vector2d( pxmax, pymax )];
				
			} else if ( qymin < pymin )
			{
				return [ new Vector2d( pxmin, pymin ), new Vector2d( qxmax, qymax )];
			}
			
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
		
		
		private function separateAxes( a:Polygon2d, b:Polygon2d ):void
		{
			//	Go through each edge, and extend the edge to the stage edges		
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
				graphics.lineStyle(.5,0xaaaaaa);
				graphics.moveTo( c.x, c.y ) ;
				graphics.lineTo( d.x, d.y ) ;
				
				

//
				var index:int = AxisProjection.getExtremeIndex( b, edge );
				var e:Vector2d = ProjectPointOntoLine( c, d, b.vertices[index]);
				index = AxisProjection.getExtremeIndex( b, edge.Negate());
				var f:Vector2d = ProjectPointOntoLine( c, d, b.vertices[index]);

				//	Draw the line
				if ( e != null && f != null )
				{
					graphics.lineStyle(1,0xff0000);
					graphics.moveTo( e.x, e.y ) ;
					graphics.lineTo( f.x, f.y ) ;
				}
				
				//	Draw the line
				graphics.lineStyle(3,0x0000ff,.6);
				graphics.moveTo( vertex.x, vertex.y ) ;
				graphics.lineTo( endpoint.x, endpoint.y ) ;

				//				//	Draw the overlap if any
//				var intersection:Array = getLineSegmentOverlap( vertex, endpoint, c, d);
//				if ( intersection != null )
//				{
//					c = intersection[0] as Vector2d ;
//					d = intersection[1] as Vector2d ;
//					//	Draw the overlap
//					graphics.lineStyle(1,0x00ff00);
//					graphics.moveTo( c.x, c.y ) ;
//					graphics.lineTo( d.x, d.y ) ;
//				}

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
				return null ;
			var y:Number = (( f * c ) + ( d * e ))/ (( c * c ) + ( d * d )) ;
			var x:Number = ( e - ( d * y )) / c ;
			return new Vector2d( x, y ) ;
		}
	}
}