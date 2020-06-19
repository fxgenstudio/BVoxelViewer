using BNA;
using BNA.Graphics;
using BNA.Math;

namespace VoxelViewer
{
	public class MeshGPUPart
	{
		public VertexBuffer m_gpuVertexBuffer;//XNA buffer for DrawIndexedPrimitives
		public IndexBuffer m_gpuIndexBuffer;//XNA buffer for DrawIndexedPrimitives
	}


	  /// <summary>
	  /// Mesh for renderer
	  /// </summary>
	public class MeshGPU
	{

	  #region -- Properties --
		public Effect SingleEffect
		{
			get { return m_effect; }
			set { m_effect = value; }
		}
		#endregion

		#region -- Fields --

		public Matrix4x4 m_worldMtx;
		public bool m_bUseWorldSpace;//True if view matrix is unused

		public Effect m_effect;

		public int m_npartsCount;
		public MeshGPUPart[] m_meshParts;

		//public BoundingBox m_bb;
		//public BoundingSphere m_bs;

		#endregion

		public this()
		{
			m_meshParts = new MeshGPUPart[8];//Default max ...

			for (int i = 0; i < m_meshParts.Count; i++)
			{
				m_meshParts[i] = new MeshGPUPart();
			}

			m_npartsCount = 0;
		}

		public ~this()
		{
			for (int i = 0; i < m_meshParts.Count; i++)
			{
				var ib = m_meshParts[i].m_gpuIndexBuffer;
				if (ib != null)
				{
					ib.Dispose();
					delete ib;
				}
				var vb = m_meshParts[i].m_gpuVertexBuffer;
				if (vb != null)
				{
					vb.Dispose();
					delete vb;
				}

				delete m_meshParts[i];
			}

			delete m_meshParts;
		}


		public void FromGenMesh(GraphicsDevice _gd, GenMesh _mesh, bool _bComputeBounds)
		{
		  	//Clear GPU Buffers
			ClearGPUVBOBuffers();

		  	//Init
			m_npartsCount = 0;

			for (int i = 0; i < _mesh.m_genMeshParts.Count; i++)
			{
				GenMeshPart part = _mesh.m_genMeshParts[i];
				MeshGPUPart partGPU = m_meshParts[i];


				//Vertices
				let varray = new VertexPosColorNorm[part.m_vertices.Count];
				part.m_vertices.CopyTo(varray);

				partGPU.m_gpuVertexBuffer = new VertexBuffer(_gd, false);
				partGPU.m_gpuVertexBuffer.Set(varray);

				delete varray;

				//Indices
				let iarray = new uint16[part.m_indices.Count];
				part.m_indices.CopyTo(iarray);


				partGPU.m_gpuIndexBuffer = new IndexBuffer(_gd, false);
				partGPU.m_gpuIndexBuffer.Set(iarray);

				delete iarray;

				m_npartsCount++;
			}
		}


		public void ClearGPUVBOBuffers()
		{
			for (int i = 0; i < m_meshParts.Count; i++)
			{
				MeshGPUPart partGPU = m_meshParts[i];

				if (partGPU.m_gpuVertexBuffer != null)
				{
					partGPU.m_gpuVertexBuffer.Dispose();
					delete partGPU.m_gpuVertexBuffer;
					partGPU.m_gpuVertexBuffer = null;
				}

				if (partGPU.m_gpuIndexBuffer != null)
				{
					partGPU.m_gpuIndexBuffer.Dispose();
					delete partGPU.m_gpuIndexBuffer;
					partGPU.m_gpuIndexBuffer = null;
				}
			}
		}



	}
}
