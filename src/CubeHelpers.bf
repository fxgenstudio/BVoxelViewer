using BNA.Math;

namespace VoxelViewer
{
	public class CubeHelpers
	{
		//public const int CUBE_SIZE = 2;

		//   y
		//   |
		//   |---x
		//  /
		// /z
		//
		
		/// <summary>
		/// Cube's faces side 
		/// </summary>
		public enum SIDE
		{
			INVALID = -1,
			O_LEFT = 0,//-x
			O_RIGHT,//+x
			O_BOTTOM,//-y
			O_TOP,//+y
			O_BACK,//-z
			O_FRONT//+z
		};

		static public readonly SIDE[] oppositeSide = new .(
			SIDE.O_RIGHT,
			SIDE.O_LEFT,
			SIDE.O_TOP,
			SIDE.O_BOTTOM,
			SIDE.O_FRONT,
			SIDE.O_BACK
			);

		static public readonly Vec3Int[] SolidVertex = new .(

			.(0, 0, 0),
			.(1, 0, 0),
			.(0, 1, 0),
			.(1, 1, 0),
			.(0, 0, 1),
			.(1, 0, 1),
			.(0, 1, 1),
			.(1, 1, 1)
			);

		static public readonly int[,] fv = new .(// indexes for voxelcoords, per face orientation

			(0, 2, 6, 4),//-X
			(5, 7, 3, 1),//+X
			(0, 4, 5, 1),//-y
			(6, 2, 3, 7),//+y
			(1, 3, 2, 0),//-Z
			(4, 6, 7, 5)//+Z
			);



		static public readonly Vec3[] FacesPerSideNormal = new .(//Face normals

			.(-1f, 0, 0),//-X
			.(1f, 0, 0),//+X

			.(0, -1f, 0),//-Y
			.(0, 1f, 0),//+Y

			.(0, 0, -1f),//-Z
			.(0, 0, 1f)//+Z
			);

		  // DIM:                            X  Y  Z
		static public readonly int[] R = new .(1, 2, 1);// row
		static public readonly int[] C = new .(2, 0, 0);// col
		static public readonly int[] D = new .(0, 1, 2);// depth

		 /* static public readonly Color[] dimColor =
		  {
			Color.Red,    //X
			Color.Green,  //Y
			Color.Blue    //Z
		  };*/



		public static void GetSolidWorldVertex(int _wcx, int _wcy, int _wcz, int _nNumVertex, out Vec3 _vtx)
		{
			var vtx = SolidVertex[_nNumVertex];
			_vtx = Vec3(
				vtx.X + (float)_wcx,
				vtx.Y + (float)_wcy,
				vtx.Z + (float)_wcz);
		
		}

	}

}
