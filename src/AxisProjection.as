package
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import geometry.Polygon2d;
	import geometry.Vector2d;
	import geometry.LineSegment2d ;
	
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
			
			//	Order the polygon's vertices counter-clockwise
			polygon.orderVertices();
			
			//	Create the collection of polygon edges
			polygon.updateLines();
			
			//	Create the binary space partitioning tree
			polygon.createTree();
			
			//	Draw the polygon
			draw( polygon.vertices, graphics ) ;
			
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
			var extreme:int = Polygon2d.getExtremeIndex( polygon, direction );
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
			extreme = Polygon2d.getExtremeIndex( polygon, direction );
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
			intersection = LineSegment2d.getLineIntersection( a, b, new Vector2d(), new Vector2d( w, 0));
			if ( intersection == null )
			{
				//	Get the intersection with the left edge
				intersection = LineSegment2d.getLineIntersection( a, b, new Vector2d(), new Vector2d( 0, h));
			}
			c.x = intersection.x ;
			c.y = intersection.y ;
			
			//	Get the intersection with the bottom edge
			intersection = LineSegment2d.getLineIntersection( a, b, new Vector2d(0,h), new Vector2d( w, h));
			if ( intersection == null )
			{
				//	Get the intersection with the right edge
				intersection = LineSegment2d.getLineIntersection( a, b, new Vector2d(w,0), new Vector2d( w, h));
			}
			d.x = intersection.x ;
			d.y = intersection.y ;
		}
		
	}
}