using System;


namespace VoxelViewer
{
	class Program
	{
		public static int Main(String[] args)
		{
			using(let game = scope MyGame("BNA Voxel View !", 1280, 720))
			{
			    game.Run();
			}
			return 0;
		}
	}
}