using System;
using System.Diagnostics;

namespace VoxelViewer
{


	public struct Vec2Int
	{
	  private const String TWO_COMPONENTS = "Array must contain exactly two components, (X,Y)";

	  public int X;
	  public int Y;

	  public this(int x, int y)
	  {
	    this.X = x;
	    this.Y = y;
	  }

	  //value1 + (value2 - value1) * amount
	  public static void Lerp(
	           ref Vec2Int value1,
	           ref Vec2Int value2,
	           float amount,
	           out Vec2Int result
	  )
	  {
	    result.X = (int)(value1.X + (value2.X - value1.X) * amount);
	    result.Y = (int)(value1.Y + (value2.Y - value1.Y) * amount);
	  }


	  public int this[int index]
	  {
	    get
	    {
	      switch (index)
	      {
	        case 0: { return X; }
	        case 1: { return Y; }
	        default: Debug.Assert(false); return 0;
	      }
	    }
	    set mut
	    {
	      switch (index)
	      {
	        case 0: { X = value; break; }
	        case 1: { Y = value; break; }
	        default: Debug.Assert(false); 
	      }
	    }
	  }

	  public bool Equals(Vec2Int other)
	  {
	    return ((this.X == other.X) && (this.Y == other.Y));
	  }

	  public static bool operator ==(Vec2Int value1, Vec2Int value2)
	  {
	    return ((value1.X == value2.X) && (value1.Y == value2.Y));
	  }

	  public static bool operator !=(Vec2Int value1, Vec2Int value2)
	  {
	    if (value1.X == value2.X ) return value1.Y != value2.Y;
	    return true;
	  }

	  public static Vec2Int operator *(Vec2Int value1, Vec2Int value2)
	  {
	    Vec2Int v;
	    v.X = value1.X * value2.X;
	    v.Y = value1.Y * value2.Y;
	    return v;
	  }

	  public static Vec2Int operator -(Vec2Int value1, Vec2Int value2)
	  {
	    Vec2Int v;
	    v.X = value1.X - value2.X;
	    v.Y = value1.Y - value2.Y;
	    return v;
	  }
	  public static Vec2Int operator *(Vec2Int value1, int value2)
	  {
	    Vec2Int v;
	    v.X = value1.X * value2;
	    v.Y = value1.Y * value2;
	    return v;
	  }

	  public static Vec2Int operator /(Vec2Int value1, int value2)
	  {
	    Vec2Int v;
	    v.X = value1.X / value2;
	    v.Y = value1.Y / value2;
	    return v;
	  }

	  public int Dot(Vec2Int _o)
	  {
	    return (X * _o.X + Y * _o.Y);
	  }

	  public int Cross(Vec2Int _o)
	  {
	    return (X * _o.Y - Y * _o.X);
	  }

	}


	public struct Vec3Int
	{
		public int X;
		public int Y;
		public int Z;


		public this(int x, int y, int z)
		{
			this.X = x;
			this.Y = y;
			this.Z = z;
		}

		//value1 + (value2 - value1) * amount
		public static void Lerp(
			ref Vec3Int value1,
			ref Vec3Int value2,
			float amount,
			out Vec3Int result
			)
		{
			result.X = (int)(value1.X + (value2.X - value1.X) * amount);
			result.Y = (int)(value1.Y + (value2.Y - value1.Y) * amount);
			result.Z = (int)(value1.Z + (value2.Z - value1.Z) * amount);
		}


		public int this[int index]
		{
			get
			{
				switch (index)
				{
				case 0: { return X; }
				case 1: { return Y; }
				case 2: { return Z; }
				default: Debug.Assert(false); return 0;
				}
			}
			set mut
			{
				switch (index)
				{
				case 0: { X = value; break; }
				case 1: { Y = value; break; }
				case 2: { Z = value; break; }
				default: Debug.Assert(false);
				}
			}
		}

	  public bool Equals(Vec3Int other)
	  {
	    return ((this.X == other.X) && (this.Y == other.Y) && (this.Z == other.Z));
	  }

	  public static bool operator ==(Vec3Int value1, Vec3Int value2)
	  {
	    return ((value1.X == value2.X) && (value1.Y == value2.Y)  && (value1.Z == value2.Z));
	  }

	  public static bool operator !=(Vec3Int value1, Vec3Int value2)
	  {
	    if (value1.X == value2.X && value1.Y == value2.Y) return value1.Z != value2.Z;
	    return true;
	  }

	  public static Vec3Int operator *(Vec3Int value1, Vec3Int value2)
	  {
	    Vec3Int v;
	    v.X = value1.X * value2.X;
	    v.Y = value1.Y * value2.Y;
	    v.Z = value1.Z * value2.Z;
	    return v;
	  }

	  public static Vec3Int operator *(Vec3Int value1, int value2)
	  {
	    Vec3Int v;
	    v.X = value1.X * value2;
	    v.Y = value1.Y * value2;
	    v.Z = value1.Z * value2;
	    return v;
	  }

	  public static Vec3Int operator /(Vec3Int value1, int value2)
	  {
	    Vec3Int v;
	    v.X = value1.X / value2;
	    v.Y = value1.Y / value2;
	    v.Z = value1.Z / value2;
	    return v;
	  }

	}




}
