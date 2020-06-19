using System.Collections;
using BNA.Graphics;
using BNA.Math;


namespace VoxelViewer
{

	public class GenMeshPart
	{
		public List<VertexPosColorNorm> m_vertices;
		public List<uint16> m_indices;
	}
	
	
	/// <summary>
	/// Mesh Generator
	/// </summary>
	public class GenMesh
	{
		public MeshGPU m_meshGPU;//Created Mesh for GPU
		public bool m_bGPUDirty;//True if m_meshGPU need to be rebuilded

		int m_vcount;//Total Vertices
		int m_icount;//Current Indices for current part
		int m_ncurPartIdx;

		public List<GenMeshPart> m_genMeshParts;//One part per 65335 indices

		public this()
		{
			m_bGPUDirty = false;
			m_genMeshParts = new List<GenMeshPart>();
			m_ncurPartIdx = -1;
		}

		public ~this()
		{
			for (int i = 0; i < m_genMeshParts.Count; i++)
			{
				GenMeshPart part = m_genMeshParts[i];
				if (part.m_vertices != null) delete part.m_vertices;
				if (part.m_indices != null) delete part.m_indices;
				delete part;
			}
			delete m_genMeshParts;

			if (m_meshGPU != null)
			{
				delete m_meshGPU;
			}
		}

		public void Clear()
		{
			m_bGPUDirty = true;

			m_vcount = 0;
			m_icount = 0;
			m_ncurPartIdx = -1;

			for (int i = 0; i < m_genMeshParts.Count; i++)
			{
				GenMeshPart part = m_genMeshParts[i];
				if (part.m_vertices != null)
				{
					part.m_vertices.Clear();
					delete part.m_vertices;
				}
				if (part.m_indices != null)
				{
					part.m_indices.Clear();
					delete part.m_indices;
				}
			}

			m_genMeshParts.Clear();

			//Add default part
			AddNewPart();
		}

		public int AddVertex(ref Vec3 _p, ref Color _c, ref Vec3 _norm)
		{
			m_vcount++;
			GenMeshPart part = m_genMeshParts[m_ncurPartIdx];
			part.m_vertices.Add(VertexPosColorNorm(_p, _c, _norm));
			return part.m_vertices.Count - 1;
		}

		public void AddQuad(uint16 _v0, uint16 _v1, uint16 _v2, uint16 _v3)
		{
			GenMeshPart part = m_genMeshParts[m_ncurPartIdx];

			//Tri1
			part.m_indices.Add(_v0);
			part.m_indices.Add(_v1);
			part.m_indices.Add(_v2);
			//Tri2
			part.m_indices.Add(_v0);
			part.m_indices.Add(_v2);
			part.m_indices.Add(_v3);

			m_icount += 6;

			//Create New part if index buffer too big (>65536)
			if (m_icount > uint16.MaxValue - 6)
			{
				AddNewPart();
			}
		}

		private void AddNewPart()
		{
			GenMeshPart part = new GenMeshPart();
			part.m_vertices = new List<VertexPosColorNorm>();
			part.m_indices = new List<uint16>();
			m_genMeshParts.Add(part);//New part
			m_ncurPartIdx++;
			m_icount = 0;
		}


		// Queries the index of the current vertex. This starts at
		// zero, and increments every time AddVertex is called.
		public int CurrentVertex
		{
			get { return m_vcount; }
		}

		// Create a mesh objet for GPU
		public void CreateGPUMesh(GraphicsDevice _gd, bool _bComputeBounds)
		{
			if (m_meshGPU == null)
				m_meshGPU = new MeshGPU();

			m_meshGPU.FromGenMesh(_gd, this, _bComputeBounds);

			m_bGPUDirty = false;
		}

	}
}
