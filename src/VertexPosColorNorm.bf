using System;
using System.Reflection;

using BNA;
using BNA.Math;
using BNA.Graphics;

namespace VoxelViewer
{
	[Packed, Reflect]
	public struct VertexPosColorNorm
	{
	    [VertexUsage(.Position)]
	    public Vec4 Pos;
		//private float _padding0;

	    [VertexUsage(.Normal)]
	    public Vec3 Normal;
	    private float _padding1;

		[VertexUsage(.Color)]
		public Vec4 Color; // NOTE: don't want to use Color here, because instead of doing any kind of conversion BNA will just copy this struct's raw memory right into the vertex buffer, but note that Color can implicitly cast to a Vec4 anyway!


		public this(Vec3 _pos, Vec4 _col, Vec3 _norm)
		{
		   	Pos = _pos;
			Pos.w = 1.0f;
			Color = _col;
		   	Normal = _norm;
			//_padding0=0;
			_padding1=0;
		}
	}

}
