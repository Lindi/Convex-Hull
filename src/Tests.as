package
{
	import flash.display.Sprite;
	import flash.geom.Vector3D;

	public class Tests extends Sprite 
	{
		public function Tests()
		{
			var a:Vector3D = new Vector3D( 1, 1 );
			trace( a.length );
			a.normalize();
			var b:Vector3D = new Vector3D( 1, 0 );
			trace( a.dotProduct( Vector3D.X_AXIS ));
			trace( b.dotProduct( Vector3D.X_AXIS ));
		}
	}
}