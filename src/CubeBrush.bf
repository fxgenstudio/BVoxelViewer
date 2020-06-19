using BNA;
using BNA.Graphics;
using BNA.Math;
using System;

namespace VoxelViewer
{
	public class CubeBrush
	{
		#region -- Fields --
		public CubeArray3D m_array;
		public Color[] m_colPalette;//256 colors palette per brush

		GenMesh m_genMesh;
		bool[] m_bVertexComputed;//For each vertices
		Vec3[] m_vertComputed;
		Color[] m_vertCols;
		Color[] m_shadowVerts;

		Texture2D m_tex2DBorder;

		public Vec3 m_vec3Origin;//Accessed by Edit

		public Matrix4x4 m_worldMtx;//Accessed by Edit
		public Vec2 m_manipAngles;//Accessed by Edit
		public Vec3Int m_vec3CubeOrigin;//Accessed by Edit for Miror

		public const int AO_CUBESIZE_X = CubeArray3D.CHUNKSIZE + (2 + 2);
		public const int AO_CUBESIZE_Y = CubeArray3D.CHUNKSIZE + (2 + 2);
		public const int AO_CUBESIZE_Z = CubeArray3D.CHUNKSIZE + (2 + 2);
		public const int FlattenOffsetAO = (AO_CUBESIZE_Y * AO_CUBESIZE_Z);//3darray[(x * (sy*sz)) + (z * sy) + y]
		static protected uint8 [] m_abyOcclusionCubeMap = new uint8[AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z];//Array
		// for occlusion

		Vec3 LightDir = Vec3(0.0f, 0.0f, -1.0f);

		#endregion

		#region -- Properties --
		public String UserName { get; set; }
		public GenMesh GenMesh { get { return m_genMesh; } }

		public bool ShowGridOnVoxel { get; set; }

		public Game Game { get; set; }

		#endregion

		#region -- ctor --
		public this(Game _game, int _sizeX, int _sizeY, int _sizeZ, bool _createDummy)
		{
			Game = _game;


			//Array size
			SetSize(_sizeX, _sizeY, _sizeZ);

			//Create a plane at bottom
			if (_createDummy)
			{
				SmallCube cube;
				cube.byMatL0 = 16;

				int x, y, z;
				y = 0;
				for (x = 0; x < _sizeX; x++)
				{
					for (z = 0; z < _sizeZ; z++)
					{
						m_array.SetCube(x, y, z, cube);
					}
				}
			}

			//Create Palette
			BuildDefaultColorPalette();

			//Meshes
			m_genMesh = new GenMesh();
		}

		public this(Game _game, CubeArray3D _carray, Color[] _palette)
		{
			Game = _game;


			//Set Palette
			m_colPalette = _palette;

			//Set Array
			m_array = _carray;
			InitFromNewArray();

			//Meshes
			m_genMesh = new GenMesh();
		}

		public ~this()
		{
			//TODO
			/*delete m_bVertexComputed;
			delete m_vertComputed;
			delete m_vertCols;
			delete m_shadowVerts;*/
			if (m_genMesh!=null)
				delete m_genMesh;
		}


		#endregion

		#region -- Edition --

		public void SetSize(int _sizeX, int _sizeY, int _sizeZ)
		{
			//Check if size have changed
			if (m_array != null && (_sizeX == m_array.CUBESIZEX && _sizeY == m_array.CUBESIZEY && _sizeZ == m_array.CUBESIZEZ))
				return;

			//3D Array
			if (m_array == null)
			{
				m_array = new CubeArray3D();
				m_array.SetSize(_sizeX, _sizeY, _sizeZ);
			}
			else
			{
				m_array = CubeArray3D.ReSize(m_array, _sizeX, _sizeY, _sizeZ);
			}

			//Init
			InitFromNewArray();
		}

		public void ApplyEditorEffect()
		{
			if (m_genMesh.m_meshGPU != null)
			{
				var gd = this.Game.GraphicsDevice;

				//Load Texture for voxel grid
				//m_tex2DBorder = Game.Content.Load<Texture2D>("Border");

				//Load Voxel Effect
				if (Effect.Load(gd, @".\Content\Shaders\CubeBrushShader.fxo") case .Ok(let effect))
				{
					//Assign Effect to GPU Mesh
					m_genMesh.m_meshGPU.SingleEffect = effect;
					//effect.SetVec3("xDirectionalLightDir", LightDir);
				}
			}
		}

		void InitFromNewArray()
		{
			//Center World Matrix
			int middleX = (m_array.CUBESIZEX >> 1);
			int middleY = (m_array.CUBESIZEY >> 1);
			int middleZ = (m_array.CUBESIZEZ >> 1);

			m_vec3CubeOrigin.X = middleX;
			m_vec3CubeOrigin.Y = middleY;
			m_vec3CubeOrigin.Z = middleZ;

			//int offset = middle;
			m_vec3Origin = Vec3(-middleX, -middleY, -middleZ);//Default center

			m_worldMtx = Matrix4x4.Translate(m_vec3Origin);
			//m_worldMtx.Translation = m_vec3Origin;
		}
		#endregion

		#region -- Cubes Access --

		public void GetCube(int _x, int _y, int _z, out SmallCube _c)
		{
			m_array.GetCube(_x, _y, _z, out _c);
		}

		public void SetCube(int _x, int _y, int _z, SmallCube _c)
		{
			if (_x < 0 || _y < 0 || _z < 0) return;
			if (_x >= m_array.CUBESIZEX || _y >= m_array.CUBESIZEY || _z >= m_array.CUBESIZEZ) return;

			m_array.SetCube(_x, _y, _z, _c);
		}

		/*public bool RayCast(Vec3 _o, Vec3 _ray, float _dist, ref BoundingBox _obb, ref Vec3Int _oposcubeTrack, out
		SmallCube _ocube)
		{
			float cs = 1.0f;

			//Step from _o to _ray
			float d = 0.0f;

			Vec3 p = _o;

			_ocube = CubeArray3D.m_emptyCube;

			//Debug.WriteLine("RayCast start at {0} dir {1}", p, _ray);

			while (d < _dist)
			{
				//Get cube at _o
				int cx = (int)(p.X / CubeHelpers.CUBE_SIZE); //World To Cube unit
				int cy = (int)(p.Y / CubeHelpers.CUBE_SIZE);
				int cz = (int)(p.Z / CubeHelpers.CUBE_SIZE);

				if (cx >= 0 && cy >= 0 && cz >= 0
				  && cx < m_array.CUBESIZEX && cy < m_array.CUBESIZEY && cz < m_array.CUBESIZEZ)
				{
					SmallCube cube;
					m_array.GetCube(cx, cy, cz, out cube);

					if (cube.byMatL0 != 0)
					{
						//Debug.WriteLine("Cube Found at {0},{1},{2}", cx, cy, cz);

						_oposcubeTrack.X = cx;//In cube unit
						_oposcubeTrack.Y = cy;//In cube unit
						_oposcubeTrack.Z = cz;

						//BB
						_obb.Min.X = (float)(cx * CubeHelpers.CUBE_SIZE); //To world coords
						_obb.Min.Y = (float)(cy * CubeHelpers.CUBE_SIZE); //To world coords
						_obb.Min.Z = (float)(cz * CubeHelpers.CUBE_SIZE); //To world coords

						_obb.Max.X = _obb.Min.X + cs;
						_obb.Max.Y = _obb.Min.Y + cs;
						_obb.Max.Z = _obb.Min.Z + cs;

						_ocube = cube;

						return true;
					}
				}

				d += 1.0f;
				p += _ray;
			}
			//Debug.WriteLine("RayCast end at {0}", p);


			return false;
		}*/

		/// <summary>
		/// Optimized ray cube intersection for shadow
		/// </summary>
		/// <param name="_o">start position in world coords</param>
		/// <param name="_dir"></param>
		/// <param name="_maxRayLen"></param>
		/// <param name="_from"></param>
		/// <returns></returns>
		public bool RayCastShadow(Vec3 _o, Vec3 _dir, float _maxRayLen, out float _ofFoundDist)
		{
			//Step from _o
			float d = 0.0f;
			_ofFoundDist = 0.0f;

			Vec3 p = _o;//In world unit

			while (d < _maxRayLen)
			{
				_ofFoundDist = d;

				//Get cube at p (p is in world unit)
				int cx = (int)(p.x);//To voxel unit
				int cy = (int)(p.y);
				int cz = (int)(p.z);

				if (cx >= 0 && cy >= 0 && cz >= 0
					&& cx < m_array.CUBESIZEX && cy < m_array.CUBESIZEY && cz < m_array.CUBESIZEZ)
				{
					SmallCube cube;
					m_array.GetCube(cx, cy, cz, out cube);

					if (cube.byMatL0 != 0)
					{
						return true;
					}
				}

				d += 1.0f;
				p += _dir;
			}

			return false;
		}

		#endregion

		#region -- Drawing for edition --
		public void Draw(Matrix4x4 view, Matrix4x4 proj)
		{
			if (m_genMesh.m_meshGPU == null)
				return;

			MeshGPU meshGPU = m_genMesh.m_meshGPU;

			if (meshGPU.m_npartsCount < 0)
				return;

			var effect = meshGPU.SingleEffect;

		
				//(CurrentTechnique = effect.Techniques["Technique1"];
			effect.SetMatrix4x4("xWorld", m_worldMtx);
			effect.SetMatrix4x4("xView", view);
			effect.SetMatrix4x4("xProjection", proj);


			//effect.SetVec3("xDirectionalLightDir", LightDir);

			//effect.SetFloat("xGridPower", 0.0f);

			//if (m_tex2DBorder != null)
			//    effect.Parameters["xTexSlot0"].SetValue(m_tex2DBorder);

			//if (ShowGridOnVoxel == true)
			//    effect.Parameters["xGridPower"].SetValue(1.0f);
			//else
			//    effect.Parameters["xGridPower"].SetValue(0.0f);

			// Create a vertex buffer, and copy our vertex data into it.
			GraphicsDevice device = this.Game.GraphicsDevice;

			

			/*device.RasterizerState = RasterizerState.CullCounterClockwise;// CullClockwise;
			device.DepthStencilState = DepthStencilState.Default;
			device.BlendState = BlendState.Opaque;*/
			effect.SetTechnique(0);
			effect.ApplyEffect(0);


			//Draw Grouped by Effect Slot
			for (int i = 0; i < meshGPU.m_npartsCount; i++)
			{
				MeshGPUPart part = meshGPU.m_meshParts[i];

				device.DrawIndexedPrimitives(PrimitiveType.TriangleList, part.m_gpuVertexBuffer, part.m_gpuIndexBuffer.IndicesCount / 3, part.m_gpuIndexBuffer);
			}
		}
		#endregion

		#region -- VBO --
		public GenMesh GenerateMesh()
		{
			m_bVertexComputed = new bool[8];//For each vertices
			m_vertComputed = new Vec3[8];
			m_vertCols = new Color[24];
			m_shadowVerts = new Color[4];

			//VBO
			m_genMesh.Clear();//Set Dirty too

			int x, y, z;
			for (x = 0; x < m_array.CHUNKSIZEX; x++)
			{
				for (y = 0; y < m_array.CHUNKSIZEY; y++)
				{
					for (z = 0; z < m_array.CHUNKSIZEZ; z++)
					{
						CubeChunk3D chunk = m_array.GetChunk(x, y, z);
						if (chunk != null)
						{
							// PASS 1=> precalcul des occlusions par voxel
							GenOcclusionForChunk(chunk, x << CubeArray3D.CHUNKSIZE_OPSHIFT, y << CubeArray3D.CHUNKSIZE_OPSHIFT, z << CubeArray3D.CHUNKSIZE_OPSHIFT);

							// PASS 2=> Calcul des VBO
							GenChunkVBO(chunk, x << CubeArray3D.CHUNKSIZE_OPSHIFT, y << CubeArray3D.CHUNKSIZE_OPSHIFT, z << CubeArray3D.CHUNKSIZE_OPSHIFT);
						}
					}
				}
			}

			m_genMesh.CreateGPUMesh(Game.GraphicsDevice, false);

			delete m_bVertexComputed;
			delete m_vertComputed;
			delete m_vertCols;
			delete m_shadowVerts;


			return m_genMesh;
		}




		//Generate cubes for a chunk
		//.position in chunk idx
		void GenChunkVBO(CubeChunk3D _chunk, int _chX, int _chY, int _chZ)
		{
			SmallCube c;
			int x, y, z;
			for (x = 0; x < CubeArray3D.CHUNKSIZE; x++)
			{
				for (y = 0; y < CubeArray3D.CHUNKSIZE; y++)
				{
					for (z = 0; z < CubeArray3D.CHUNKSIZE; z++)
					{
						_chunk.GetCube(x, y, z, out c);
						if (c.byMatL0 != 0)
							GenCubeVBO2(c, _chX + x, _chY + y, _chZ + z, x, y, z);
					}
				}
			}
		}

		//Generate a cube VBO
		//.position in CubeArray3D
		void GenCubeVBO2(SmallCube _c, int _cx, int _cy, int _cz, int _x, int _y, int _z)
		{
			int i, j;

			////////////////////////// COMPUTE VISIBLES FACES MASK
			uint8 byVFMask = CalcVisibleFaces(_c, _cx, _cy, _cz);
			if (byVFMask == 0)
				return;

			////////////////////////// COMPUTE VERTICES POS
			int nNumVertex;

			for (j = 0; j < 8; j++)
			{
				m_bVertexComputed[j] = false;
				m_vertComputed[j] = Vec3.Zero;
			}

			int wcx = _cx;//To World coord
			int wcy = _cy;//To World coord
			int wcz = _cz;//To World Coord


			//For each Cube's faces
			for (i = 0; i < 6; i++)//6 faces
			{
				//If face visibility precalc mask
				if ((byVFMask & (1 << i)) != 0)
					for (j = 0; j < 4; j++)//4 corners
					{
						nNumVertex = CubeHelpers.fv[i, j];//Face,Corner

						if (m_bVertexComputed[nNumVertex] == false)//if never calc
						{
							CubeHelpers.GetSolidWorldVertex(wcx, wcy, wcz, nNumVertex, out m_vertComputed[nNumVertex]);


							m_bVertexComputed[nNumVertex] = true;
						}
					}
			}

			////////////////////////// COMPUTE SHADOW LIGHTING
			GenCubeShadowLightAO(_c, _cx, _cy, _cz, _x, _y, _z, byVFMask, ref m_vertCols);

			////////////////////////// COMPUTE CUBE FACES

			int v0, v1, v2, v3;
			int iv0, iv1, iv2, iv3;

			for (i = 0; i < 6; i++)//6 faces
			{
				if ((byVFMask & (1 << i)) == 0)
					continue;//Face invisible


				v0 = CubeHelpers.fv[i, 0];//Face,Corner
				v1 = CubeHelpers.fv[i, 1];//Face,Corner
				v2 = CubeHelpers.fv[i, 2];//Face,Corner
				v3 = CubeHelpers.fv[i, 3];//Face,Corner


				//int dim = i >> 1;  // 0,0,1,1,2,2 X,Y,Z

				j = i << 2;//Color index in m_vertCols

				/////////////////////
				//Get face normal
				Vec3 n1 = CubeHelpers.FacesPerSideNormal[i];

				////////////////////////////////
				//Add vertices

				//V0
				iv0 = m_genMesh.AddVertex(ref m_vertComputed[v0], ref m_vertCols[j], ref n1);

				//V1
				iv1 = m_genMesh.AddVertex(ref m_vertComputed[v1], ref m_vertCols[j + 1], ref n1);

				//V2
				iv2 = m_genMesh.AddVertex(ref m_vertComputed[v2], ref m_vertCols[j + 2], ref n1);

				//V3
				iv3 = m_genMesh.AddVertex(ref m_vertComputed[v3], ref m_vertCols[j + 3], ref n1);

				////////////////////////////////
				//Add Face

				m_genMesh.AddQuad((uint16)iv0, (uint16)iv1, (uint16)iv2, (uint16)iv3);
			}
		}

		public uint8 CalcVisibleFaces(SmallCube c, int cx, int cy, int cz)
		{
			uint8 byVFMask = 0x00;//By default no faces visibles

			if (c.byMatL0 == 0)
				return byVFMask;

			//For each Cube's faces
			SmallCube nc;
			int i;

			for (i = 0; i < 6; i++)//6 faces
			{
				bool bvis = true;

				//check if neighbour face is solid
				m_array.GetNeighbourCube(cx, cy, cz, (CubeHelpers.SIDE)i, out nc);

				if (nc.byMatL0 != 0)
					bvis = false;

				//Update visible face
				if (bvis)
				{
					byVFMask |= (uint8)(1 << i);
				}
			}

			return byVFMask;
		}

		#endregion

		#region -- AO 3DArray Generating --

		/// <summary>
		/// Done while BuildVBO generating
		/// </summary>
		void GenOcclusionForChunk(CubeChunk3D _chunk, int _chX, int _chY, int _chZ)
		{
			int x, y, z;

			//Reset occlusion map
			Array.Clear(m_abyOcclusionCubeMap, 0, m_abyOcclusionCubeMap.Count);

			//Make occlusion
			SmallCube c;
			for (x = 0; x < CubeArray3D.CHUNKSIZE; x++)
			{
				for (y = 0; y < CubeArray3D.CHUNKSIZE; y++)
				{
					for (z = 0; z < CubeArray3D.CHUNKSIZE; z++)
					{
						_chunk.GetCube(x, y, z, out c);

						//Opaque
						if (c.byMatL0 != 0)
						{
							_GenOcclusionPerCube(_chX + x, _chY + y, _chZ + z, x, y, z);
						}
					}
				}
			}
		}

		/// <summary>
		///
		/// </summary>
		/// _cx pos in zone (cube unit)
		/// _x pos in chunk (cube unit)
		void _GenOcclusionPerCube(int _cx, int _cy, int _cz, int _x, int _y, int _z)
		{
			Vec3 pos = Vec3(_cx, _cy, _cz);//Cube pos into world (in cube unit)
			//pos *= CubeHelpers.CUBE_SIZE; //=> to world unit

			float fDelta = 1.0f;
			Vec3 vec3Dir = Vec3(-1, fDelta, 0);//Light Dir

			float maxRayLength = Math.Max(Math.Max(m_array.CUBESIZEX, m_array.CUBESIZEY), m_array.CUBESIZEZ);

			float ofFoundDist;

			int aox = _x + 1;//For array border
			int aoy = _y + 1;//For array border
			int aoz = _z + 1;//For array border

			//RayCast around voxel
			Vec3 posO = Vec3.Zero;
			int x, y, z;
			for (x = -1; x <= 1; x++)
			{
				posO.x = pos.x + x;

				for (z = -1; z <= 1; z++)
				{
					int offset = ((aox + x) * (FlattenOffsetAO)) + ((aoz + z) * AO_CUBESIZE_Y) + aoy;

					posO.z = pos.z + z;

					for (y = -1; y <= 1; y++)
					{
						if (m_abyOcclusionCubeMap[offset + y] != 0)
							continue;

						posO.y = pos.y;

						bool bOccluded = RayCastShadow(posO, vec3Dir, maxRayLength, out ofFoundDist);
						if (bOccluded == true)
							m_abyOcclusionCubeMap[offset + y] = 2;//Parsed and Occluded
						else
							m_abyOcclusionCubeMap[offset + y] = 1;//Just parsed
					}
				}
			}
		}


		#endregion

		#region -- AO Lighting --


		public Color Lerp(Color value1, Color value2, float amount)
		{
			uint8 Red = (uint8)MathUtils.Clamp(MathUtils.Lerp(value1.r, value2.r, amount), uint8.MinValue, uint8.MaxValue);
			uint8 Green = (uint8)MathUtils.Clamp(MathUtils.Lerp(value1.g, value2.g, amount), uint8.MinValue, uint8.MaxValue);
			uint8 Blue = (uint8)MathUtils.Clamp(MathUtils.Lerp(value1.b, value2.b, amount), uint8.MinValue, uint8.MaxValue);
			uint8 Alpha = (uint8)MathUtils.Clamp(MathUtils.Lerp(value1.a, value2.a, amount), uint8.MinValue, uint8.MaxValue);

			return Color(Red, Green, Blue, Alpha);
		}

		/// <summary>
		/// Done while BuildVBO generating (position in AOArray)
		/// </summary>
		void GenCubeShadowLightAO(SmallCube _cube, int _cx, int _cy, int _cz, int _aox, int _aoy, int _aoz, uint8 _byVFMask, ref Color[] _colors)
		{
			int i, j;

			Color gradCol = m_colPalette[_cube.byMatL0 - 1];

			//Lighting to face
			for (i = 0; i < 6; i++)//6 faces
			{
				if ((_byVFMask & (1 << i)) == 0)
					continue;//Face invisible

				for (j = 0; j < 4; j++)
				{
					int nNumVertex = CubeHelpers.fv[i, j];//Face,Corner

					uint8 byOcclusion = SmoothOcclusion(_cube, _aox, _aoy, _aoz, nNumVertex, i);

					//byOcclusion = 255;
					m_shadowVerts[j] = Lerp(gradCol, Color.Black, (float)byOcclusion / 6.0f);
				}


				int k = i << 2;//*4

				_colors[k] = m_shadowVerts[0];
				_colors[k + 1] = m_shadowVerts[1];
				_colors[k + 2] = m_shadowVerts[2];
				_colors[k + 3] = m_shadowVerts[3];
			}
		}

		/// <summary>
		/// Smooth occlusion per face (position in AOArray)
		/// </summary>
		uint8 SmoothOcclusion(SmallCube _cube, int _aox, int _aoy, int _aoz, int _vidx, int _side)
		{
			uint8 oc = 0;
			int offset;

			Vec3Int o = Vec3Int(_aox, _aoy, _aoz);

			Vec3Int r = CubeHelpers.SolidVertex[_vidx];


			int sign = _side & 1;
			int dim = _side >> 1;

			if (sign != 0)
				o[CubeHelpers.D[dim]] += 1;
			else
				o[CubeHelpers.D[dim]] -= 1;


			//current
			int x, y, z;
			int xx, yy, zz;
			x = o[0]; y = o[1]; z = o[2];

			x = x + 1;
			y = y + 1;
			z = z + 1;

			xx = x; yy = y; zz = z;

			offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;//3darray[(x * (sy*sz)) + (z * sy) + y]
			offset = Math.Max(0, offset);
			offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
			oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

			if (dim == 0)//X
			{
				int s1 = 1;
				int s2 = 1;
				if (r[1] == 0) s1 = -s1;//corner
				if (r[2] == 0) s2 = -s2;//corner

				//Y-Z
				yy = y; zz = z + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				yy = y + s1; zz = z;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				yy = y + s1; zz = z + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);
			}
			else if (dim == 1)//Y
			{
				int s1 = 1;
				int s2 = 1;
				if (r[0] == 0) s1 = -s1;//corner
				if (r[2] == 0) s2 = -s2;//corner

				//X-Z
				xx = x; zz = z + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				xx = x + s1; zz = z;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				xx = x + s1; zz = z + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);
			}
			else if (dim == 2)//Z
			{
				int s1 = 1;
				int s2 = 1;
				if (r[0] == 0) s1 = -s1;//corner
				if (r[1] == 0) s2 = -s2;//corner

				//X-Y
				xx = x; yy = y + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				xx = x + s1; yy = y;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);

				xx = x + s1; yy = y + s2;
				offset = (xx * (FlattenOffsetAO)) + (zz * AO_CUBESIZE_Y) + yy;
				offset = Math.Max(0, offset);
				offset = Math.Min(offset, (AO_CUBESIZE_X * AO_CUBESIZE_Y * AO_CUBESIZE_Z) - 1);
				oc += (uint8)((int)m_abyOcclusionCubeMap[offset] >> 1);
			}


			return oc;
		}

		#endregion

		#region -- Helpers --
		void BuildDefaultColorPalette()
		{
			m_colPalette = new Color[256];

			//Build colors palette
			int idx = 0;
			float h, s, l;

			//Build greys
			for (l = 0; l < 1.0f; l += (1.0f / 16.0f))
			{
				m_colPalette[idx++] = HSLToColor(0, 0, l);
			}

			//Build colored
			s = 1f;
			for (l = 0; l < 1.0f; l += (1.0f / 16.0f))
			{
				for (h = 0; h < 360; h += (360 / 14))
				{
					m_colPalette[idx++] = HSLToColor(h, s, (l * 0.90f) + 0.1f);
				}
				if (idx >= m_colPalette.Count) break;
			}
		}
		#endregion


		public Color HSLToColor(float h, float s, float l)
		{
			if (s == 0)
			{
			  // achromatic color (gray scale)
				return Color(
					(uint8)(l * 255.0),
					(uint8)(l * 255.0),
					(uint8)(l * 255.0)
					);
			}
			else
			{
				float q = (l < 0.5f) ? (l * (1.0f + s)) : (l + s - (l * s));
				float p = (2.0f * l) - q;

				float Hk = h / 360.0f;
				float[] T = new float[3];
				T[0] = Hk + (1.0f / 3.0f);// Tr
				T[1] = Hk;// Tb
				T[2] = Hk - (1.0f / 3.0f);// Tg

				for (int i = 0; i < 3; i++)
				{
					if (T[i] < 0) T[i] += 1.0f;
					if (T[i] > 1) T[i] -= 1.0f;

					if ((T[i] * 6) < 1)
					{
						T[i] = p + ((q - p) * 6.0f * T[i]);
					}
					else if ((T[i] * 2.0) < 1)//(1.0/6.0)<=T[i] && T[i]<0.5
					{
						T[i] = q;
					}
					else if ((T[i] * 3.0) < 2)// 0.5<=T[i] && T[i]<(2.0/3.0)
					{
						T[i] = p + (q - p) * ((2.0f / 3.0f) - T[i]) * 6.0f;
					}
					else T[i] = p;
				}

				return Color(
					(uint8)(T[0] * 255.0),
					(uint8)(T[1] * 255.0),
					(uint8)(T[2] * 255.0)
					);
			}
		}


	}
}
